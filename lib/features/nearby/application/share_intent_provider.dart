import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A lightweight hand-off between the library and the Nearby flow. The real
/// application will replace this with a share intent owned by the transport
/// layer; the UI contract stays the same.
final shareIntentProvider = NotifierProvider<ShareIntentController, String?>(
  ShareIntentController.new,
);

/// Incremented when the library starts a new share. The manual connection
/// fields contain a single-use pairing code, so they must not be reused for a
/// later share.
final shareIntentResetProvider =
    NotifierProvider<ShareIntentResetController, int>(
      ShareIntentResetController.new,
    );

class ShareIntentResetController extends Notifier<int> {
  @override
  int build() => 0;

  void reset() => state++;
}

class ShareIntentController extends Notifier<String?> {
  @override
  String? build() => null;

  void setDocument(String documentId) {
    state = documentId;
  }

  void clear() {
    state = null;
  }
}
