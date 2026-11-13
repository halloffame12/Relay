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
    String transportLabel = 'Wi-Fi',
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
    String transportLabel = 'Wi-Fi',
  }) {
    return _importService.importFile(
      PickedImportFile(
        name: manifest.fileName,
        path: temporaryPath,
        sizeBytes: manifest.sizeBytes,
        format: manifest.format,
        sha256: manifest.sha256,
        sourceLabel: 'Received from $peerName over $transportLabel',
        fallbackDescription:
            'Received directly from $peerName over $transportLabel. '
            'No cloud storage was involved.',
      ),
      onProgress: (_) {},
    );
  }
}
