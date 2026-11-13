# Relay signaling service

Relay's cross-network path needs a small WebSocket service to exchange SDP and
ICE between exactly two devices. It never sees file bytes, file names, titles,
or checksums: those travel peer-to-peer over the WebRTC data channel (DTLS
encrypted) or, when a direct path fails, through your TURN relay.

This directory is a reference implementation you can deploy yourself. Relay
contains **no** vendor URL and **no** TURN credentials. Build the app with:

```bash
flutter build appbundle \
  --dart-define=RELAY_SIGNALING_URL=wss://relay-signal.example.com/v1/relay
```

When the define is empty the app runs the LAN path only and says so in the UI.

## What it enforces

- One room per Relay session id, created by the first device.
- The ephemeral QR token is required and must match for both devices.
- Exactly one `sender` and one `receiver`; a third connection is rejected.
- Rooms expire after `ROOM_TTL_MS` even if a device stays connected.
- Only `offer`, `answer`, and `ice` are relayed, only to the other peer.
- Per-socket message rate limit and a hard message size cap.
- No payload logging. Logs contain room ids only, never tokens or SDP.

## Run locally

```bash
cd infra/signaling
npm install
cp .env.example .env      # edit values
npm start
npm test
```

The service listens on `PORT` (default `8080`). Health check:

```bash
curl http://localhost:8080/healthz
```

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `PORT` | `8080` | HTTP/WebSocket port. |
| `WS_PATH` | `/v1/relay` | Upgrade path. Other paths return 404. |
| `ROOM_TTL_MS` | `600000` | Room lifetime. Keep >= the QR lifetime (10 min max). |
| `MAX_MESSAGE_BYTES` | `131072` | Maximum signaling frame. |
| `MAX_MESSAGES_PER_MINUTE` | `120` | Per-connection rate limit. |
| `MAX_CONNECTIONS_PER_IP` | `20` | Concurrent sockets from one address. |
| `ALLOWED_ORIGINS` | empty | Comma-separated origins; empty allows any (mobile clients send none). |
| `STUN_URLS` | `stun:stun.l.google.com:19302` | Comma-separated STUN URLs. Self-host for privacy. |
| `TURN_URLS` | empty | Comma-separated `turn:`/`turns:` URLs. Empty disables relay fallback. |
| `TURN_SECRET` | empty | coturn `static-auth-secret` for ephemeral credentials. |
| `TURN_TTL_SECONDS` | `600` | Lifetime of issued TURN credentials. |
| `TRUST_PROXY` | `false` | Read the client IP from `X-Forwarded-For`. |

`joined` is sent with:

```json
{
  "type": "joined",
  "iceServers": [
    { "urls": ["stun:stun.example.com:3478"] },
    { "urls": ["turn:turn.example.com:3478"], "username": "...", "credential": "..." }
  ]
}
```

The app accepts only `stun:`, `turn:`, and `turns:` URLs and caps the list at
eight entries.

## Deploying TURN (coturn)

STUN alone works for many home NATs. Symmetric NAT, carrier-grade NAT on mobile
data, and some corporate networks need TURN. coturn can run on the same small
server as signaling or separately:

```bash
docker run -d --name coturn --network host \
  -e DETECT_EXTERNAL_IP=yes \
  coturn/coturn \
  -n --log-file=stdout \
  --listening-port=3478 \
  --min-port=49160 --max-port=49200 \
  --realm=turn.example.com \
  --use-auth-secret \
  --static-auth-secret="$TURN_SECRET" \
  --fingerprint --lt-cred-mech
```

- Open `3478/tcp`, `3478/udp`, and `49160-49200/udp` in the firewall.
- For `turns:` add a TLS certificate and open `5349/tcp`.
- Set `TURN_URLS=turn:turn.example.com:3478?transport=udp,turn:turn.example.com:3478?transport=tcp`
  and the same `TURN_SECRET` in the signaling environment.
- Restrict the TURN server so it cannot relay to private address ranges
  (`--denied-peer-ip`), which prevents it being used to probe your LAN.

## Cost model

TURN bandwidth is the only meaningful recurring cost; signaling uses a few
kilobytes per session.

- **Signaling:** a 256–512 MB instance is enough. Expect roughly **$4–7/month**
  on a small VPS, or a free/low-tier container platform if it supports
  WebSockets and idle connections.
- **TURN:** billed per relayed GB. Typical VPS providers include 1–20 TB/month
  in the instance price; metered clouds charge roughly **$0.01–$0.09/GB**.
  A 200 MiB batch relayed through TURN is about 0.4 GB (both directions count
  on most providers), so roughly **$0.004–$0.04** per worst-case transfer.
- Direct connections and LAN transfers cost nothing. TURN is used only when
  ICE cannot find a direct path.

Confirm current provider pricing before budgeting; the ranges above are
planning figures, not quotes.

## Protocol

Client → server query string: `sid`, `token`, `role` (`sender` or `receiver`),
and `name`.

```text
server -> client   {"type":"joined","iceServers":[...]}
server -> peer     {"type":"peer-joined"}
client -> server   {"type":"offer","sdp":"..."}
client -> server   {"type":"answer","sdp":"..."}
client -> server   {"type":"ice","candidate":"...","sdpMid":"0","sdpMLineIndex":0}
server -> peer     the same offer/answer/ice, unmodified
server -> peer     {"type":"peer-left"}
server -> client   {"type":"error","code":"...","message":"..."}
```

Close codes: `4400` invalid request, `4401` token mismatch, `4403` room full
or role taken, `4408` room expired, `4429` rate limited.

## Security notes

- The token in the QR is the room credential. Treat the QR as sensitive while
  it is displayed; it expires after at most 10 minutes and is single-session.
- Signaling traffic is encrypted with TLS when you use `wss://`. The service
  can see SDP and ICE metadata (IP candidates) but never document contents.
- TURN sees encrypted DTLS packets, not file bytes, but it does see source and
  destination IP addresses and transfer volume.
- Do not put long-lived secrets in the app. TURN credentials are minted per
  session by this service and expire quickly.
