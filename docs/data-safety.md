# Google Play Data safety draft

Status: **draft for the Play Console owner to review and submit.** This is not a
legal opinion. The Play Console declarations must match the final build and the
privacy policy.

## Facts about this build

Final release candidate: `io.github.halloffame12.relay` version `0.9.0`
(`versionCode 1`), min SDK 24, target SDK 36. Manifest permissions are
`INTERNET`, optional `CAMERA`, and the transitive normal `ACCESS_NETWORK_STATE`;
there is no broad storage, location, contacts, microphone, SMS, call-log or
photos permission. Camera hardware is declared optional.

- Relay itself has no accounts, ads, subscriptions, cloud library, developer
  analytics or developer-operated server.
- Documents, reading positions, settings and transfer history are stored locally.
  Local-only processing is not "collection" under Google Play's definition.
- When the user sends a document with Nearby, Relay transmits the selected file
  off the device directly to the receiving device the user chose. The developer
  never receives it. Google Play defines "collection" as transmitting data off
  the device, including by an app's libraries. The conservative reading is to
  declare this transfer as **Files and docs**, even though it is peer-to-peer.
- The QR scanner uses Google ML Kit barcode scanning through `mobile_scanner`.
  ML Kit may send technical diagnostics and usage data to Google. The Android
  data disclosure is at
  <https://developers.google.com/ml-kit/android-data-disclosure>.

## Recommended declarations

### Files and docs

- **Collected:** Yes (only when the user sends a document with Nearby).
- **Shared:** No. The transfer is a user-initiated action to the receiving device
  the user selected; the developer does not receive it and no third-party SDK
  receives it.
- **Purpose:** App functionality.
- **Optional:** Yes. The user can use the library and reader without sending
  anything, and can cancel before sending.
- **Encrypted in transit:** No. The direct TCP transfer is not encrypted by
  Relay. The recipient is chosen by the user, but network observers may be able
  to read the bytes.
- **Data types covered:** the document file and its metadata (title, author,
  format, size, SHA-256 checksum, filename), plus the display name of the sending
  or receiving Relay device.
- **Retention:** the receiving device keeps its own imported copy until the user
  removes it. Relay does not retain a server-side copy.
- **Deletion:** the user can remove the imported document on either device. A
  sender cannot delete the recipient's copy.

If the Play Console reviewer does not treat the peer-to-peer transfer as
collection, the fallback is to declare Files and docs as **not collected** and
explain the direct transfer in the privacy policy. The conservative declaration
above is recommended because it does not hide that bytes leave the device.

### Device or other IDs (ML Kit)

- **Collected:** Yes, by Google ML Kit when the QR scanner is used.
- **Shared:** **Needs an explicit decision before submission.** The conservative
  declaration is **Yes**: the ML Kit SDK may send the data to Google for Google's
  diagnostics and usage analytics, and Google is a third party. If the Play
  Console owner or legal adviser confirms that Google is acting as a service
  provider processing solely on the developer's behalf, the answer may be No.
  Do not select advertising or data-broker sharing either way.
- **Purpose:** Analytics (diagnostics and usage analytics).
- **Optional:** Yes, in practice: the user can use manual address/pairing-code
  entry and never open the scanner. Confirm whether ML Kit initializes and sends
  data before the scanner screen is opened; if it does, change this to Required.
- **Encrypted in transit:** Yes (HTTPS).
- **Data types:** per-installation identifiers, device information and app
  package/version.

### App info and performance (ML Kit)

- **Collected:** Yes, by Google ML Kit when the QR scanner is used.
- **Shared:** Same decision as Device or other IDs. The conservative declaration
  is **Yes**; do not select advertising or data-broker sharing.
- **Purpose:** Analytics (diagnostics and performance/usage analytics).
- **Optional:** Same caveat as Device or other IDs.
- **Encrypted in transit:** Yes (HTTPS).
- **Data types:** diagnostics; other app performance data. ML Kit also lists API
  configuration, feature input/output sizes, feature version, event type and
  error codes. If the Play form maps event type to App activity, add **App
  activity > Other actions** as well.

### Not collected by Relay

Do not declare these unless the final build changes: location, contacts,
microphone audio, SMS or MMS, call logs, photos or videos, health, financial
information, browsing history, installed apps, or account information. Camera
frames are processed on-device and are not saved or transmitted.

## Security practices answers

- **Is all data encrypted in transit?** No. ML Kit uses HTTPS, but Nearby document
  transfers use direct TCP without Relay encryption.
- **Do you provide a way for users to request deletion of their data?** There is
  no account or developer-held user data. Users delete local documents and
  transfer history in the app, clear app storage, or uninstall. ML Kit data is
  held by Google and is outside Relay's control. The published policy effective
  27 October 2026 offers public GitHub Issues or the Play listing email as the
  contact channel. Answer consistently with the final Play form and policy.
- **Committed to the Play Families policy?** No, unless the target audience is
  changed to include children. Relay is a general-purpose document reader.
- **Independent security review?** No claim is made.

## Human review required

1. Confirm whether the bundled ML Kit SDK sends any data before the scanner is
   opened, and adjust Optional/Required.
2. Decide whether Google must be listed as a third-party recipient for the ML Kit
   diagnostics. The conservative answer is **Shared: Yes**.
3. Confirm the final peer-to-peer Files and docs treatment with the Play Console
   account owner or legal adviser.
4. Make sure the published Markdown/HTML privacy policy and the in-app policy
   (effective 27 October 2026) use the same wording as the Data safety answers,
   including the GitHub Issues + Play email contact channel.
5. Do not submit a declaration that says "no data collected" while ML Kit is
   present.
