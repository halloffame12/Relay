import { strict as assert } from "node:assert";
import { after, before, test } from "node:test";
import { WebSocket } from "ws";
import { startRelayServer } from "../server.js";

const TOKEN = "b".repeat(43);
let relay;
let roomCounter = 0;

function sid() {
  roomCounter += 1;
  return `r${roomCounter}`.padEnd(22, "a");
}

before(async () => {
  relay = await startRelayServer({
    port: 0,
    stunUrls: ["stun:stun.example.test:3478"],
    turnUrls: ["turn:turn.example.test:3478"],
    turnSecret: "test-secret-that-is-long-enough",
    turnTtlSeconds: 600,
    roomTtlMs: 60_000,
    maxMessagesPerMinute: 60,
  });
});

after(async () => {
  await relay.close();
});

function connect({ sid: session = sid(), token = TOKEN, role = "sender", name = "Test phone" } = {}) {
  const url =
    `ws://127.0.0.1:${relay.port}${relay.config.wsPath}` +
    `?sid=${session}&token=${token}&role=${role}&name=${encodeURIComponent(name)}`;
  return new WebSocket(url);
}

function nextMessage(socket, type) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`timed out waiting for ${type}`)), 3000);
    const onMessage = (data) => {
      const message = JSON.parse(data.toString());
      if (type && message.type !== type) return;
      clearTimeout(timeout);
      socket.off("message", onMessage);
      resolve(message);
    };
    socket.on("message", onMessage);
  });
}

function waitForClose(socket) {
  return new Promise((resolve) => socket.once("close", (code) => resolve(code)));
}

test("health endpoint reports rooms", async () => {
  const response = await fetch(`http://127.0.0.1:${relay.port}/healthz`);
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.equal(body.status, "ok");
  assert.equal(typeof body.rooms, "number");
});

test("pairs one sender and one receiver with ephemeral TURN credentials", async () => {
  const room = sid();
  const sender = connect({ sid: room, role: "sender" });
  const joined = await nextMessage(sender, "joined");
  assert.equal(joined.iceServers.length, 2);
  assert.deepEqual(joined.iceServers[0], { urls: ["stun:stun.example.test:3478"] });
  assert.deepEqual(joined.iceServers[1].urls, ["turn:turn.example.test:3478"]);
  assert.match(joined.iceServers[1].username, /^\d+:[0-9a-f]{24}$/);
  assert.ok(joined.iceServers[1].credential.length >= 20);

  const receiver = connect({ sid: room, role: "receiver" });
  const [receiverJoined, peerJoined] = await Promise.all([
    nextMessage(receiver, "joined"),
    nextMessage(sender, "peer-joined"),
  ]);
  assert.ok(receiverJoined.iceServers.length >= 1);
  assert.equal(peerJoined.type, "peer-joined");

  sender.send(JSON.stringify({ type: "offer", sdp: "v=0 offer" }));
  const offer = await nextMessage(receiver, "offer");
  assert.equal(offer.sdp, "v=0 offer");

  receiver.send(JSON.stringify({ type: "answer", sdp: "v=0 answer" }));
  const answer = await nextMessage(sender, "answer");
  assert.equal(answer.sdp, "v=0 answer");

  receiver.send(
    JSON.stringify({
      type: "ice",
      candidate: "candidate:1 1 udp 1 192.0.2.1 5000 typ host",
      sdpMid: "0",
      sdpMLineIndex: 0,
    }),
  );
  const ice = await nextMessage(sender, "ice");
  assert.equal(ice.sdpMLineIndex, 0);
  assert.equal(ice.sdpMid, "0");

  const left = nextMessage(receiver, "peer-left");
  const closed = waitForClose(sender);
  sender.close();
  await closed;
  assert.equal((await left).type, "peer-left");
  receiver.close();
});

test("rejects a mismatched token without leaking the room token", async () => {
  const room = sid();
  const sender = connect({ sid: room, role: "sender" });
  await nextMessage(sender, "joined");
  const intruder = connect({ sid: room, role: "receiver", token: "c".repeat(43) });
  const [error, code] = await Promise.all([
    nextMessage(intruder, "error"),
    waitForClose(intruder),
  ]);
  assert.equal(error.code, "invalid_token");
  assert.equal(code, 4401);
  sender.close();
});

test("rejects a duplicate role and a third peer", async () => {
  const room = sid();
  const sender = connect({ sid: room, role: "sender" });
  await nextMessage(sender, "joined");
  const duplicate = connect({ sid: room, role: "sender" });
  const [duplicateError, duplicateCode] = await Promise.all([
    nextMessage(duplicate, "error"),
    waitForClose(duplicate),
  ]);
  assert.equal(duplicateError.code, "role_taken");
  assert.equal(duplicateCode, 4403);

  const receiver = connect({ sid: room, role: "receiver" });
  await nextMessage(receiver, "joined");
  const third = connect({ sid: room, role: "receiver" });
  const [thirdError] = await Promise.all([nextMessage(third, "error"), waitForClose(third)]);
  assert.equal(thirdError.code, "role_taken");

  sender.close();
  receiver.close();
});

test("rejects malformed credentials and binary frames", async () => {
  const badSession = connect({ sid: "short" });
  const sessionError = await nextMessage(badSession, "error");
  assert.equal(sessionError.code, "invalid_session");

  const sender = connect();
  await nextMessage(sender, "joined");
  sender.send(Buffer.from([1, 2, 3]));
  const binaryError = await nextMessage(sender, "error");
  assert.equal(binaryError.code, "invalid_message");
  sender.close();
});

test("never relays an unsupported message type", async () => {
  const room = sid();
  const sender = connect({ sid: room, role: "sender" });
  await nextMessage(sender, "joined");
  const receiver = connect({ sid: room, role: "receiver" });
  await nextMessage(receiver, "joined");

  sender.send(JSON.stringify({ type: "file", bytes: "secret" }));
  const error = await nextMessage(sender, "error");
  assert.equal(error.code, "invalid_message");
  sender.close();
  receiver.close();
});
