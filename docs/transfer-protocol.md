# Relay transfer protocol, version 2

This document describes the direct local-network transfer implemented in
`lib/features/transfers`, plus the separate version 1 QR invitation envelope
used to pair two devices. It is deliberately small. There is no discovery,
cloud relay, or resumption.

The wire protocol and the invitation envelope are versioned independently. A
QR code may only be used with the exact wire protocol version it advertises.

| Layer | Current version | Constant |
| --- | --- | --- |
| TCP control protocol | 2 | `relayProtocolVersion` |
| QR invitation envelope | 1 | `relayInvitationVersion` |

## Transport

- TCP over IPv4. The sender connects to one of the IPv4 addresses in the
  scanned invitation, or to the manually entered address.
- One active incoming connection per receive session. One document per
  connection. A successful connection consumes the invitation.
- The control channel is UTF-8 JSON, one object per line, terminated by `\n`.
- Control messages are bounded to 64 KiB.
- After the receiver sends `accept`, the sender writes exactly the manifest
  `sizeBytes` of raw file bytes on the same connection.
- The sender then writes a `complete` control message and waits for `completed`
  or `error`.
- After a QR connection is verified, the sender may hold it open while the user
  chooses a document. The receiver waits up to the offer timeout (2 minutes)
  for the manifest. If no manifest arrives, the connection is closed and the
  invitation rotates.

Every control message has:

```json
{"v": 2, "type": "message_type", "...": "type-specific fields"}
```

`v` must equal `2`. The receiver rejects other versions with an `error` whose
code is `unsupported_version`. Unknown fields are rejected rather than ignored.

## Pairing credentials

A `hello` has exactly one of two credential forms:

1. **QR invitation:** `sessionId` and `invitationToken`.
2. **Manual fallback:** the six-digit `pairingCode`.

Sending both forms, neither form, or only half of the QR form is rejected with
`invalid_credentials`. The manual code is a fallback for troubleshooting and is
not treated as strong authentication.

Credential rules:

- `sessionId` is 22 base64url characters generated from 16 secure random bytes.
- `invitationToken` is 43 base64url characters generated from 32 secure random
  bytes.
- `pairingCode` is exactly six ASCII digits.
- All three are single-use. A successful `hello` consumes the active invitation
  and invalidates both the QR token and the manual code.
- The receiver rotates the token and pairing code after expiry, or after an
  authenticated connection ends because of failure, rejection, cancellation, or
  transfer completion. Invalid credentials alone do not rotate the active
  invitation. The listening socket and session ID stay the same for the receive
  session, so a new QR code can be issued without reopening the port.
- The receiver always asks the local user to approve the manifest. A valid
  invitation only proves that the sender saw the current QR code; it does not
  authorize a transfer by itself.

## QR invitation envelope

The receiver displays the invitation as a QR code while its receive session is
active:

```text
relay://connect?v=1&p=2&sid=<22 chars>&token=<43 chars>&addr=192.168.1.20&port=40404&exp=1770000000
```

The parser accepts only the following shape:

- scheme `relay`, host `connect`
- no user-info, no port in the authority, no path, and no fragment
- exactly these query keys: `v`, `p`, `sid`, `token`, `addr`, `port`, `exp`
- 1-4 `addr` values; duplicates are rejected
- IPv4 unicast addresses only. Hostnames, IPv6, `0.0.0.0`, multicast/reserved
  addresses (`224.0.0.0/4` and above), and link-local `169.254.0.0/16` are
  rejected.
- `port` is 1-65535
- `exp` is a Unix timestamp in seconds, must be in the future, and may not be
  more than 15 minutes away
- the entire payload is at most 1,024 bytes and may not contain whitespace or
  control characters
- unknown or duplicated fields are rejected

The default invitation lifetime is 5 minutes. The receiver refreshes it
automatically before it expires.

The scanned string is parsed as data. Relay never opens it as a URL, never uses
a scanned hostname or path, and never writes the token to transfer history,
diagnostics, or logs. `TransferInvitation.toString()` redacts the token.

The invitation's address is the network destination the receiver asked the
sender to use. Relay accepts public unicast IPv4 addresses as well as private
ones because some local networks use globally routable addressing, so scanning a
QR code is a deliberate trust action. The connected send screen shows the
resolved `address:port`, and the final confirmation repeats it, so an unexpected
destination is visible before any file bytes are sent. The TCP payload is not
encrypted by Relay; use a trusted network and verify the receiving device.

## Sequence

QR pairing with a verified connection held while the sender chooses a document:

```text
sender                                      receiver
  |                                            | start receive mode
  | <--- scan QR: sid, token, addr, port, exp -|
  | ---- TCP connect ------------------------> |
  | ---- hello (sessionId, invitationToken) -> |
  |                                            | check session, token,
  |                                            | expiry; consume credentials
  | <--- welcome (deviceName) ----------------- |
  |                                            | receiver shows connected
  |         sender chooses a managed document  |
  | ---- offer (manifest) --------------------> |
  |                                            | validates manifest
  |                                            | asks the user
  | <--- accept ------------------------------- | (or reject / error)
  | ---- exactly sizeBytes raw file bytes ----> | streams to temporary file
  | ---- complete (sizeBytes, sha256) --------> |
  |                                            | verifies size and SHA-256
  |                                            | imports / deduplicates
  | <--- completed (duplicate, title) -------- |
  |                                            | rotates token and code
```

The manual fallback follows the same sequence but `hello` contains
`pairingCode`, and the sender does not open a scan screen. The receiver rotates
the code after the connection as well.

The sender may close the connection at any time during transfer to cancel it.
The receiver treats premature closure as a failed transfer and deletes the
temporary file.

## Messages

### `hello` (sender to receiver)

QR form:

```json
{
  "v": 2,
  "type": "hello",
  "app": "relay",
  "peerName": "Relay device 1A2B",
  "sessionId": "<22 base64url characters>",
  "invitationToken": "<43 base64url characters>"
}
```

Manual form:

```json
{
  "v": 2,
  "type": "hello",
  "app": "relay",
  "peerName": "Relay device 1A2B",
  "pairingCode": "123456"
}
```

- `app` must be `relay`.
- `peerName` is 1-80 characters after trimming, with no control characters.
- `sessionId` and `invitationToken` must both be present in the QR form. They
  must match the active receive session and current token.
- `pairingCode` must match the current single-use code in the manual form.
- A consumed, expired, replaced, or stopped-session credential is rejected.
  A QR token may not be replayed, and a manual code may not be reused.

### `welcome` (receiver to sender)

```json
{"v": 2, "type": "welcome", "deviceName": "Relay device 3C4D"}
```

The device name is a locally generated label, not an account or verified
identity.

### `offer` (sender to receiver)

```json
{
  "v": 2,
  "type": "offer",
  "manifest": {
    "fileName": "notes.pdf",
    "title": "Notes",
    "format": "pdf",
    "sizeBytes": 12345,
    "sha256": "64 lowercase hexadecimal characters"
  }
}
```

Manifest rules:

- `fileName` is 1-180 characters, has no `/`, `\`, traversal, control
  characters, or directory component, and ends in `.pdf` or `.epub` matching the
  declared format.
- `format` is `pdf` or `epub`.
- `sizeBytes` is positive and no larger than the configured document limit
  (100 MiB by default).
- `sha256` is exactly 64 hexadecimal characters; uppercase input is normalized
  to lowercase.
- `title` is 1-200 characters with no control characters.
- Unknown or missing fields are rejected.

The receiver creates a local transfer ID and a local temporary filename. The
remote filename is never used as a path.

### `accept`

```json
{"v": 2, "type": "accept"}
```

Sent only after the local user approves the manifest and the receiver has
recorded the transfer as `transferring`.

### `reject`

```json
{"v": 2, "type": "reject", "reason": "The receiving device declined it."}
```

The sender records the transfer as cancelled. The receiver never imports the
file.

### Raw bytes

No framing, compression, or encryption is applied. The sender writes exactly
`sizeBytes` bytes. The receiver writes them to a temporary file and computes
SHA-256 while streaming.

### `complete`

```json
{
  "v": 2,
  "type": "complete",
  "sizeBytes": 12345,
  "sha256": "64 lowercase hexadecimal characters"
}
```

The receiver requires all of the following before importing:

- `complete.sizeBytes == manifest.sizeBytes`
- the number of bytes actually received equals the declared size
- the computed SHA-256 equals both the completion hash and the manifest hash
- the local temporary file length equals the declared size

### `completed`

```json
{
  "v": 2,
  "type": "completed",
  "duplicate": false,
  "documentTitle": "Notes"
}
```

Sent only after the receiver has committed the document to its library (or
matched it to an existing document with the same SHA-256) and recorded the
transfer as completed. `documentTitle` is optional and bounded.

If `duplicate` is true, the receiver did not overwrite or add a second copy.

### `error`

```json
{"v": 2, "type": "error", "code": "checksum_mismatch", "message": "..."}
```

Codes are 1-40 lowercase characters matching `[a-z0-9_]+`. Messages are 1-500
characters. Known codes include:

- connection and pairing: `unsupported_version`, `invalid_credentials`,
  `pairing_code`, `invitation_invalid`, `invitation_used`,
  `invitation_expired`, `busy`
- document and streaming: `invalid_offer`, `file_too_large`,
  `approval_timeout`, `checksum_mismatch`, `storage`, `timeout`,
  `disconnected`

The peer's message text is treated as untrusted display data. Local user-facing
messages are selected from known error codes where possible.

### `cancel`

```json
{"v": 2, "type": "cancel", "reason": "Transfer cancelled on this device."}
```

Best-effort notification. During raw byte streaming, cancellation is normally
represented by closing the connection so the byte count cannot be confused with
control data.

## State machine

The Drift-backed transfer states are:

```text
connecting -> awaitingApproval -> transferring -> verifying -> completed
     |               |                |              |
     +---------------+----------------+--------------+-> failed
     |               |                |
     +---------------+----------------+------------------> cancelled
```

Allowed transitions:

- `connecting` to `awaitingApproval`, `failed`, `cancelled`
- `awaitingApproval` to `transferring`, `failed`, `cancelled`
- `transferring` to `verifying`, `failed`, `cancelled`
- `verifying` to `completed`, `failed`
- terminal states never transition again

`completed` requires the exact declared byte count. The repository rejects any
attempt to complete before verification or with fewer bytes.

On startup, all non-terminal rows are marked failed with an explanation, and
all temporary transfer files are removed. This build does not resume.

## Stop conditions

The receiver must close and delete the temporary file on any of:

- invalid, oversized, or unsupported control messages
- incorrect app identifier, protocol version, or credential form
- consumed, expired, replaced, or stopped-session invitation
- reused manual pairing code
- manifest validation failure
- user rejection
- approval or offer timeout
- sender disconnect
- read/write timeout or socket error
- declared size or checksum mismatch
- import failure
- local cancellation
- storage write failure

No library row is created unless import succeeds. On duplicate, the existing
document is reused and no bytes overwrite it.

## Security and limits

Relay uses no transport encryption and is intended for two devices on a
trusted local network. A single-use, short-lived invitation prevents accidental
connections and replays, but it does not protect file bytes from an active
attacker on the same network. The receiver's blocking approval remains the
authorization boundary, and it shows the document title, format, and size before
any bytes are accepted.

The QR scanner requests camera permission only when the scan screen opens. The
camera controller is disposed with the screen, and the screen accepts only the
first valid detection to avoid duplicate connection attempts. Scanned text is
never opened as a URL. Camera access can be denied permanently; the app explains
how to change the permission and keeps the manual address/port/code fallback
available. If Android stops reporting the denial after a retry, the scanner
keeps that explanation visible instead of showing an empty camera frame, and a
retry cannot start duplicate camera sessions.

| Limit | Default |
| --- | --- |
| Maximum document | 100 MiB |
| Maximum control message | 64 KiB |
| Maximum QR invitation payload | 1,024 bytes |
| Maximum addresses in an invitation | 4 |
| Invitation lifetime | 5 min |
| Maximum invitation future window | 15 min |
| Connect / handshake timeout | 12 s |
| QR offer timeout | 2 min |
| Receiver approval timeout | 2 min |
| Verification timeout | 2 min |
| Inactivity timeout | 20 s |
| Receive connections | 1 active |

Automatic local-network discovery (NSD/mDNS) is not implemented. The QR code
remains the primary pairing path, and manual details remain the secondary
fallback.
