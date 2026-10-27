<!--
Publication note (not part of the policy): the current public HTTPS URL is
https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md
The repository also contains docs/index.html and docs/privacy-policy.html for a
future GitHub Pages deployment. GitHub Pages is intentionally disabled because
the account-level custom domain intercepts the project path and serves a
different site. Do not claim a Pages URL until it is verified. Enter the working
URL in Google Play Console. The contact method is the developer email already
required on the Play listing; no contact detail is invented here. Keep the
in-app policy in lib/features/settings/presentation/privacy_policy.dart in sync.
-->

# Relay privacy policy

**Effective 26 October 2026**

Relay is an offline-first Android document library and PDF/EPUB reader. This
policy explains what Relay does with information when you use the app. Relay has
no account system, advertising, subscription, cloud library or
developer-operated analytics. The developer does not receive your documents.

## 1. Documents and library data

When you choose a PDF or EPUB through Android's system file picker, Relay copies
it into app-managed storage on your device so it can open offline. Relay stores
the file, its title and author metadata, format, size, SHA-256 checksum, reading
position, bookmarks and transfer history in local app storage. Relay does not
move or modify your original file. Removing a document deletes Relay's managed
copy. Clearing Relay's app storage or uninstalling the app deletes Relay's local
data. The developer cannot access that data.

Relay does not request broad storage access. The system picker gives Relay access
only to the file you select.

## 2. Camera and QR codes

Relay requests camera permission only when you open the QR scanner. Camera frames
are used on the device to look for a Relay invitation. Relay does not save photos
or camera frames, and it does not send them to the developer.

The QR scanner uses Google ML Kit barcode scanning. Google's ML Kit SDK may
collect limited technical data, including:

- device information such as manufacturer, model, OS version and build, and
  available machine-learning hardware;
- the app package name and version;
- per-installation identifiers that are not intended to identify a person or
  physical device;
- performance metrics;
- API configuration, feature input and output sizes, feature version, event
  type and error codes.

ML Kit may send this data to Google over HTTPS for diagnostics and usage
analytics. Relay does not receive this data and does not use it to identify you.
Google's handling is governed by Google's privacy policy and ML Kit terms:

- <https://developers.google.com/ml-kit/android-data-disclosure>
- <https://policies.google.com/privacy>

## 3. Local network transfers

When you use Nearby, one Relay device opens a temporary TCP server and the other
connects directly to it over the local network. The QR invitation contains IP
addresses, a port, a session ID, a single-use token and an expiry time. Relay
does not upload the invitation or send the token to the developer.

After the receiving device approves the transfer, Relay streams the selected
document directly to that device and verifies its size and SHA-256 checksum. The
transfer is **not end-to-end encrypted by Relay**. It relies on the local network
and the single-use invitation, so someone able to observe that network may be
able to observe the transfer. The receiving device can keep, copy or forward the
document. Do not send sensitive documents over an untrusted network.

The developer does not operate a relay server and does not receive the document,
the invitation token or the transfer history. Each device stores the other
device's display name and document transfer details locally.

Relay does not provide automatic discovery, Wi-Fi Direct, Bluetooth, internet
relay, cloud sync or background transfer. Both devices must use Relay and be able
to reach each other on the same network, or through the address shown in the
invitation.

## 4. Permissions

Relay requests:

- **Internet access** for direct TCP connections and for the ML Kit scanner's
  HTTPS traffic. This normal permission does not grant access to your files.
- **Camera access**, optional, only for scanning a QR invitation. Manual address
  and pairing-code entry remains available if camera access is denied.
- **Network state access**, added by the ML Kit dependency, to read connectivity
  state.

Relay does not request location, contacts, microphone, SMS, call logs, photos or
broad storage access. Relay uses Android's system file picker for imports.

## 5. Sharing and sale of data

Relay does not sell user data. Relay does not share document contents or library
data with the developer, advertisers or data brokers. The ML Kit data described
above is processed by Google as a third-party SDK provider. A document is sent
only to the receiving device you choose, after that device approves the transfer.
The receiving user may keep, copy or forward it.

## 6. Retention and deletion

Relay's local library, reading positions, preferences and transfer history remain
on the device until you remove the relevant item, clear transfer history, clear
the app's storage or uninstall Relay. There is no developer-held account or
library to delete.

Google's ML Kit terms govern any data ML Kit sends to Google; Relay does not have
access to it and cannot delete it on your behalf. You can contact Google about
its privacy practices using the links above.

## 7. Children

Relay is a general-purpose document reader. It is not designed or marketed as a
child-directed app. The developer does not knowingly collect personal information
from children through Relay.

## 8. Changes

If this policy changes, the effective date above will be updated. The current
version is available in Relay's Settings and, when Relay is distributed through
Google Play, through the privacy-policy link on its store listing.

## 9. Contact

For privacy questions, use the developer contact email shown on Relay's Google
Play store listing. Do not send documents or invitation codes in a support
message.

## 10. Third-party components

Relay uses open-source Flutter and Dart packages, AndroidX/CameraX, Google ML Kit
barcode scanning, Pdfium through `pdfx`, and EPUB parsing through `epubx`. The
in-app open-source licenses page lists the Dart packages. Native Android
components remain subject to their own licenses and notices. ML Kit is subject to
Google's applicable terms; it is not an open-source component of Relay.
