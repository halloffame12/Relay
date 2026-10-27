import '../../import/domain/document_import_service.dart';
import '../domain/transfer_manifest.dart';

/// Commits a fully received and checksum-verified temporary file through the
/// same import path used by the system picker. This keeps duplicate detection,
/// file naming, metadata extraction, and database rollback in one place.
abstract interface class IncomingTransferHandler {
  Future<ImportResult> importVerifiedFile({
    required String temporaryPath,
    required TransferManifest manifest,
    required String peerName,
  });
}

class LocalIncomingTransferHandler implements IncomingTransferHandler {
  LocalIncomingTransferHandler(this._importService);

  final DocumentImportService _importService;

  @override
  Future<ImportResult> importVerifiedFile({
    required String temporaryPath,
    required TransferManifest manifest,
    required String peerName,
  }) {
    return _importService.importFile(
      PickedImportFile(
        name: manifest.fileName,
        path: temporaryPath,
        sizeBytes: manifest.sizeBytes,
        format: manifest.format,
        sha256: manifest.sha256,
        sourceLabel: 'Received from $peerName over Wi-Fi',
        fallbackDescription:
            'Received directly from $peerName on the local network. '
            'No cloud service was involved.',
      ),
      onProgress: (_) {},
    );
  }
}
