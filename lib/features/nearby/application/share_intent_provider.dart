import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A lightweight hand-off between the library and the Nearby flow. The real
/// application will replace this with a share intent owned by the transport
/// layer; the UI contract stays the same.
final shareIntentProvider = NotifierProvider<ShareIntentController, String?>(
  ShareIntentController.new,
);

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
