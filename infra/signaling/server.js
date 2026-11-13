import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { createServer } from "node:http";
import { WebSocketServer } from "ws";

const SESSION_ID = /^[A-Za-z0-9_-]{22}$/;
const TOKEN = /^[A-Za-z0-9_-]{43}$/;
const ROLES = new Set(["sender", "receiver"]);
const RELAY_TYPES = new Set(["offer", "answer", "ice"]);

function envInt(name, fallback, { min = 1, max = Number.MAX_SAFE_INTEGER } = {}) {
  const raw = process.env[name];
  if (raw === undefined || raw === "") return fallback;
  const value = Number.parseInt(raw, 10);
  if (!Number.isFinite(value) || value < min || value > max) {
    throw new Error(`${name} must be an integer between ${min} and ${max}`);
  }
  return value;
}

function envList(name, fallback = "") {
  return (process.env[name] ?? fallback)
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
}

function readConfig() {
  const turnSecret = process.env.TURN_SECRET ?? "";
  const turnUrls = envList("TURN_URLS");
  if (turnUrls.length > 0 && turnSecret.length < 16) {
    throw new Error(
      "TURN_SECRET must be set to at least 16 characters when TURN_URLS is configured",
    );
  }
  return {
    port: envInt("PORT", 8080),
    wsPath: process.env.WS_PATH ?? "/v1/relay",
    roomTtlMs: envInt("ROOM_TTL_MS", 600_000, { min: 30_000 }),
    maxMessageBytes: envInt("MAX_MESSAGE_BYTES", 131_072, { min: 1024 }),
    maxMessagesPerMinute: envInt("MAX_MESSAGES_PER_MINUTE", 120),
    maxConnectionsPerIp: envInt("MAX_CONNECTIONS_PER_IP", 20),
    allowedOrigins: envList("ALLOWED_ORIGINS"),
    stunUrls: envList("STUN_URLS", "stun:stun.l.google.com:19302"),
    turnUrls,
    turnSecret,
    turnTtlSeconds: envInt("TURN_TTL_SECONDS", 600, { min: 60 }),
    trustProxy: (process.env.TRUST_PROXY ?? "false").toLowerCase() === "true",
    heartbeatMs: 30_000,
  };
}

function safeEqual(left, right) {
  const a = Buffer.from(left);
  const b = Buffer.from(right);
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * coturn REST API credentials: the user name carries the expiry timestamp and
 * the password is an HMAC of that name. Nothing long-lived reaches the client.
 */
function turnCredentials(secret, ttlSeconds, now = Date.now()) {
  const username = `${Math.floor(now / 1000) + ttlSeconds}:${randomBytes(12).toString("hex")}`;
  const credential = createHmac("sha1", secret).update(username).digest("base64");
  return { username, credential };
}

function iceServers(config, now = Date.now()) {
  const servers = config.stunUrls.map((url) => ({ urls: [url] }));
  if (config.turnUrls.length > 0) {
    const { username, credential } = turnCredentials(
      config.turnSecret,
      config.turnTtlSeconds,
      now,
    );
    servers.push({ urls: config.turnUrls, username, credential });
  }
  return servers;
}

function closeWithError(socket, code, errorCode, message) {
  try {
    socket.send(JSON.stringify({ type: "error", code: errorCode, message }));
  } catch {
    // The socket may already be gone.
  }
  socket.close(code, errorCode.slice(0, 120));
}

export function startRelayServer(overrides = {}) {
  const config = { ...readConfig(), ...overrides };
  const rooms = new Map();
  const socketsByIp = new Map();
  const sockets = new Set();
  const metrics = { roomsCreated: 0, sessionsCompleted: 0, rejected: 0 };

  const server = createServer((request, response) => {
    if (request.url === "/healthz") {
      response.writeHead(200, { "content-type": "application/json" });
      response.end(
        JSON.stringify({
          status: "ok",
          rooms: rooms.size,
          connections: sockets.size,
          ...metrics,
        }),
      );
      return;
    }
    response.writeHead(404, { "content-type": "text/plain" });
    response.end("Not found\n");
  });

  const wss = new WebSocketServer({
    server,
    path: config.wsPath,
    maxPayload: config.maxMessageBytes,
    perMessageDeflate: false,
  });

  function destroyRoom(room) {
    if (!rooms.has(room.sid)) return;
    rooms.delete(room.sid);
    clearTimeout(room.timer);
    for (const peer of room.peers.keys()) {
      peer.room = null;
      if (peer.readyState === peer.OPEN) {
        closeWithError(peer, 4408, "room_expired", "This share session expired.");
      }
    }
    room.peers.clear();
  }

  function leaveRoom(socket) {
    const room = socket.room;
    socket.room = null;
    if (!room) return;
    room.peers.delete(socket);
    const peer = [...room.peers.keys()][0];
    if (peer && peer.readyState === peer.OPEN) {
      peer.send(JSON.stringify({ type: "peer-left" }));
    }
    if (room.peers.size === 0) {
      clearTimeout(room.timer);
      if (rooms.get(room.sid) === room) rooms.delete(room.sid);
    }
  }

  function clientIp(request) {
    if (config.trustProxy) {
      const forwarded = request.headers["x-forwarded-for"];
      if (typeof forwarded === "string" && forwarded.length > 0) {
        return forwarded.split(",")[0].trim();
      }
    }
    return request.socket.remoteAddress ?? "unknown";
  }

  wss.on("connection", (socket, request) => {
    const ip = clientIp(request);
    const open = (socketsByIp.get(ip) ?? 0) + 1;
    socketsByIp.set(ip, open);
    sockets.add(socket);
    socket.ip = ip;
    socket.room = null;
    socket.messageWindow = Date.now();
    socket.messageCount = 0;
    socket.alive = true;

    const cleanup = () => {
      if (!sockets.has(socket)) return;
      sockets.delete(socket);
      const remaining = (socketsByIp.get(ip) ?? 1) - 1;
      if (remaining <= 0) socketsByIp.delete(ip);
      else socketsByIp.set(ip, remaining);
      leaveRoom(socket);
    };
    socket.on("close", cleanup);
    socket.on("error", cleanup);

    if (config.allowedOrigins.length > 0) {
      const origin = request.headers.origin;
      if (origin && !config.allowedOrigins.includes(origin)) {
        metrics.rejected += 1;
        closeWithError(socket, 4400, "origin_not_allowed", "Origin is not allowed.");
        return;
      }
    }
    if (open > config.maxConnectionsPerIp) {
      metrics.rejected += 1;
      closeWithError(socket, 4429, "too_many_connections", "Too many connections.");
      return;
    }

    const url = new URL(request.url ?? "/", "http://relay.invalid");
    const sid = url.searchParams.get("sid") ?? "";
    const token = url.searchParams.get("token") ?? "";
    const role = url.searchParams.get("role") ?? "";
    const name = (url.searchParams.get("name") ?? "").trim();

    if (!SESSION_ID.test(sid)) {
      metrics.rejected += 1;
      closeWithError(socket, 4400, "invalid_session", "Invalid session.");
      return;
    }
    if (!TOKEN.test(token)) {
      metrics.rejected += 1;
      closeWithError(socket, 4400, "invalid_token", "Invalid token.");
      return;
    }
    if (!ROLES.has(role)) {
      metrics.rejected += 1;
      closeWithError(socket, 4400, "invalid_role", "Invalid role.");
      return;
    }
    if (name.length < 1 || name.length > 64 || /[\u0000-\u001F\u007F]/.test(name)) {
      metrics.rejected += 1;
      closeWithError(socket, 4400, "invalid_name", "Invalid device name.");
      return;
    }

    let room = rooms.get(sid);
    if (room && room.expiresAt <= Date.now()) {
      destroyRoom(room);
      room = undefined;
    }
    if (!room) {
      room = {
        sid,
        token,
        peers: new Map(),
        createdAt: Date.now(),
        expiresAt: Date.now() + config.roomTtlMs,
        timer: null,
      };
      room.timer = setTimeout(() => destroyRoom(room), config.roomTtlMs);
      room.timer.unref?.();
      rooms.set(sid, room);
      metrics.roomsCreated += 1;
    } else if (!safeEqual(room.token, token)) {
      metrics.rejected += 1;
      closeWithError(socket, 4401, "invalid_token", "This share code is not valid.");
      return;
    }

    for (const peer of room.peers.keys()) {
      if (peer.role === role) {
        metrics.rejected += 1;
        closeWithError(socket, 4403, "role_taken", "This session already has that device.");
        return;
      }
    }
    if (room.peers.size >= 2) {
      metrics.rejected += 1;
      closeWithError(socket, 4403, "room_full", "This share session is full.");
      return;
    }

    socket.role = role;
    socket.room = room;
    room.peers.set(socket, { role, name });

    socket.send(
      JSON.stringify({
        type: "joined",
        iceServers: iceServers(config),
      }),
    );
    for (const peer of room.peers.keys()) {
      if (peer !== socket && peer.readyState === peer.OPEN) {
        peer.send(JSON.stringify({ type: "peer-joined" }));
      }
    }

    socket.on("pong", () => {
      socket.alive = true;
    });

    socket.on("message", (data, isBinary) => {
      try {
        if (isBinary) {
          metrics.rejected += 1;
          closeWithError(socket, 4400, "invalid_message", "Binary signaling is not supported.");
          return;
        }
        const now = Date.now();
        if (now - socket.messageWindow >= 60_000) {
          socket.messageWindow = now;
          socket.messageCount = 0;
        }
        socket.messageCount += 1;
        if (socket.messageCount > config.maxMessagesPerMinute) {
          metrics.rejected += 1;
          closeWithError(socket, 4429, "rate_limited", "Too many signaling messages.");
          return;
        }

        const text = data.toString();
        if (text.length > config.maxMessageBytes) {
          metrics.rejected += 1;
          closeWithError(socket, 4400, "message_too_large", "Signaling message is too large.");
          return;
        }
        let message;
        try {
          message = JSON.parse(text);
        } catch {
          metrics.rejected += 1;
          closeWithError(socket, 4400, "invalid_message", "Malformed signaling message.");
          return;
        }
        if (message === null || typeof message !== "object" || Array.isArray(message)) {
          metrics.rejected += 1;
          closeWithError(socket, 4400, "invalid_message", "Malformed signaling message.");
          return;
        }
        const type = message.type;
        if (!RELAY_TYPES.has(type)) {
          metrics.rejected += 1;
          closeWithError(socket, 4400, "invalid_message", "Unsupported signaling message.");
          return;
        }
        if (type === "ice") {
          if (
            typeof message.candidate !== "string" ||
            message.candidate.length === 0 ||
            message.candidate.length > 4096 ||
            typeof message.sdpMLineIndex !== "number" ||
            !Number.isInteger(message.sdpMLineIndex) ||
            (message.sdpMid != null && typeof message.sdpMid !== "string")
          ) {
            metrics.rejected += 1;
            closeWithError(socket, 4400, "invalid_message", "Invalid network candidate.");
            return;
          }
        } else if (
          typeof message.sdp !== "string" ||
          message.sdp.length === 0 ||
          message.sdp.length > config.maxMessageBytes
        ) {
          metrics.rejected += 1;
          closeWithError(socket, 4400, "invalid_message", "Invalid session description.");
          return;
        }

        const room = socket.room;
        if (!room) {
          closeWithError(socket, 4408, "room_expired", "This share session expired.");
          return;
        }
        for (const peer of room.peers.keys()) {
          if (peer === socket || peer.readyState !== peer.OPEN) continue;
          peer.send(
            JSON.stringify(
              type === "ice"
                ? {
                    type,
                    candidate: message.candidate,
                    sdpMid: message.sdpMid ?? null,
                    sdpMLineIndex: message.sdpMLineIndex,
                  }
                : { type, sdp: message.sdp },
            ),
          );
        }
      } catch {
        closeWithError(socket, 4400, "invalid_message", "Signaling failed.");
      }
    });
  });

  const heartbeat = setInterval(() => {
    for (const socket of sockets) {
      if (!socket.alive) {
        socket.terminate();
        continue;
      }
      socket.alive = false;
      try {
        socket.ping();
      } catch {
        socket.terminate();
      }
    }
  }, config.heartbeatMs);
  heartbeat.unref?.();

  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(config.port, () => {
      const address = server.address();
      resolve({
        server,
        wss,
        config,
        port: typeof address === "object" && address ? address.port : config.port,
        rooms,
        metrics,
        close: () =>
          new Promise((done) => {
            clearInterval(heartbeat);
            for (const socket of sockets) socket.terminate();
            wss.close(() => server.close(() => done()));
          }),
      });
    });
  });
}

if (import.meta.url === `file://${process.argv[1]?.replace(/\\/g, "/")}`) {
  startRelayServer()
    .then(({ port, config }) => {
      console.log(
        `Relay signaling listening on :${port}${config.wsPath} ` +
          `(ttl ${Math.round(config.roomTtlMs / 1000)}s, ` +
          `turn ${config.turnUrls.length > 0 ? "enabled" : "disabled"})`,
      );
    })
    .catch((error) => {
      console.error(error instanceof Error ? error.message : error);
      process.exitCode = 1;
    });
}
