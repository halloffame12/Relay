# Google Play listing draft

Status: **copy and declarations are ready for review; the assets and account
details marked HUMAN ACTION are still required.** Do not submit or publish
without the owner's explicit authorization.

## Store listing copy

### App name (30 characters maximum)

**Relay: PDF & EPUB Reader**

24 characters. The launcher label remains `Relay`.

### Short description (80 characters maximum)

**Read PDF and EPUB offline. Share directly to a nearby Relay device.**

67 characters.

### Full description (4,000 characters maximum)

Relay is a quiet, offline-first home for the documents you keep. Import PDF and
EPUB files through Android's system picker, read them without an account, and
return to the exact page you left. Relay keeps its own copy in app-managed
storage; your original file stays where it is.

READ, OFFLINE
- Open real PDF and EPUB documents, not samples or placeholders.
- Resume your last reading position and add bookmarks.
- Search and filter your library, and see how much space Relay uses.
- Switch between light, dark, paper and night reading themes.
- No account, no ads, no subscription and no cloud library.

SEND DIRECTLY, DEVICE TO DEVICE
- Open receive mode on one device and show a single-use QR invitation.
- Scan it with the other device, or use the manual IPv4 address, port and
  six-digit code when the camera is unavailable.
- Choose one Relay-managed document and send it after the receiver approves.
- The receiver verifies the declared size and SHA-256 checksum before importing.
- Relay uses a direct TCP connection on the local network. There is no cloud
  relay and no developer server.
- Both devices need Relay and must be able to reach each other on the same
  Wi-Fi network. Guest networks, access-point isolation, VPNs and firewalls may
  block the connection.
- Relay does not add transport encryption. Use a trusted network and check the
  receiving device before sending.
- Automatic discovery, Wi-Fi Direct, Bluetooth, internet relay, background
  transfer, resumable transfer and cloud sync are not included.
- One document at a time, up to 100 MB.

PRIVACY
- Documents, reading positions and transfer history are stored locally.
- Relay itself has no developer-operated analytics, advertising or account
  system, and does not sell data.
- The optional QR scanner uses Google ML Kit barcode scanning. ML Kit may send
  limited diagnostics and usage data to Google over HTTPS. Relay does not
  receive that data. See the privacy policy for details.
- The camera is requested only when you open the QR scanner. Manual entry
  remains available if camera access is denied.
- Relay does not request broad storage, location, contacts or microphone access.

Relay is a document library and reader, not a PDF editor, DRM-removal tool,
office suite, cloud-sync service or file manager. Android 7.0 or later is
required.

## Categorization and declarations

| Play field | Draft answer |
| --- | --- |
| App category | Books & Reference |
| Tags | PDF reader, EPUB reader, offline reading, document library, local sharing |
| Ads | No |
| In-app purchases | No |
| App access | No login or account. All library features are available without credentials. |
| Government app | No |
| News app | No |
| Health app | No |
| Financial features | No |
| COVID-19 contact tracing | No |
| Target audience | General document readers; not designed or marketed for children. Confirm the final age band in Console. |
| Content rating | Complete the questionnaire. There is no violence, sexual content, gambling, controlled substances, user-generated content or advertising. Do not guess the final rating. |
| Data safety | Use `docs/data-safety.md`; it must be reviewed against the final build. |
| Privacy policy | HUMAN ACTION: host `docs/privacy-policy.md` at a public HTTPS URL and enter that URL. |
| Developer contact email | HUMAN ACTION: use a monitored email. It is not present in the repository. |
| Developer name/address | HUMAN ACTION: use the real Play Console developer identity. Do not invent one. |

## Reviewer instructions

No test account or special access code is required.

1. Install the app and open the Library tab. Import any small PDF or EPUB with
   the system picker. The file is copied into Relay's app storage.
2. Open the imported document to verify reading and restored progress.
3. To test transfer, install Relay on a second Android device on the same Wi-Fi
   network. On device A choose **Nearby > Offer to receive**. On device B choose
   **Nearby > Scan receiver's QR code**, or use the manual address/port/code
   shown on device A.
4. Choose a managed document on device B, confirm the destination address, and
   approve the request on device A. Both devices should show the completed
   transfer and the receiver should verify the checksum.
5. Camera permission is optional. Deny it and use the manual connection path to
   verify the fallback.
6. No automatic discovery is promised or used. If a reviewer environment blocks
   direct local TCP connections, two physical devices on the same ordinary Wi-Fi
   network are required for the transfer test.

Do not include invitation tokens, keystore details or signing credentials in the
reviewer instructions.

## Graphics and assets

| Asset | Status |
| --- | --- |
| App icon 512 x 512 PNG | Available at `web/icons/Icon-512.png`; verified 512 x 512, 24 bpp, no alpha. Recheck the final icon choice before upload. |
| Feature graphic 1024 x 500 | HUMAN ACTION: missing. |
| Phone screenshots, 2-8 | HUMAN ACTION: capture from a clean install. Suggested screens: Library, Reader, Nearby receive/QR, connected send confirmation, transfer success, Privacy policy. |
| 7-inch and 10-inch tablet screenshots | Optional but recommended if tablet layout is supported. |
| Promo video | Optional; do not use one that implies discovery, Bluetooth or encryption. |
| Store listing title/short/full description | Draft above. |

Screenshot rules: use the real app, do not show a real invitation token or a real
document the owner does not want public, and do not add device-frame text that
claims features Relay does not have.

## Release tracks

- **Internal testing:** use this first for a signed bundle. It is the fastest way
  to validate the Play-installed build.
- **Closed testing:** required before production access for personal developer
  accounts created after 13 November 2023. Current Google Play guidance requires
  at least 12 testers opted in continuously for at least 14 days, followed by a
  production-access application. Confirm the account type and creation date in
  Play Console; organization accounts do not follow that personal-account path.
- **Production:** do not start until the blockers in
  `docs/release-readiness.md` are closed and the owner explicitly authorizes it.

Reference:
<https://support.google.com/googleplay/android-developer/answer/14151465>
