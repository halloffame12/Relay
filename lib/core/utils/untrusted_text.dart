/// Normalization for text that originates outside Relay: imported document
/// metadata, EPUB markup and control messages from a nearby peer.
///
/// The goal is not to make untrusted text trustworthy. It is to keep display
/// text single-line, free of terminal/bidi controls and bounded in size so a
/// malformed document cannot exhaust memory or spoof surrounding UI.
abstract final class UntrustedText {
  static const maxTitleLength = 200;
  static const maxAuthorLength = 120;
  static const maxDescriptionLength = 2000;
  static const maxLanguageLength = 35;
  static const maxChapterTitleLength = 200;
  static const maxBlockLength = 50000;

  /// Collapses whitespace and removes C0/C1 controls, bidi overrides, the BOM
  /// and zero-width space. ZWNJ/ZWJ are intentionally preserved because they
  /// are meaningful in several writing systems.
  static String clean(String? value, {required int maxLength}) {
    if (value == null || value.isEmpty || maxLength <= 0) return '';
    final normalized = value
        .replaceAll('\u00A0', ' ')
        .replaceAll(
          RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]'),
          '',
        )
        .replaceAll(
          RegExp('[\u200B\u202A-\u202E\u2060\u2066-\u2069\uFEFF]'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length <= maxLength) return normalized;

    var end = maxLength;
    if (_isHighSurrogate(normalized.codeUnitAt(end - 1))) end--;
    return normalized.substring(0, end).trimRight();
  }

  /// Accepts a conservative BCP 47-shaped language tag. Anything else becomes
  /// an empty string so the caller can show its own fallback label.
  static String language(String? value) {
    final cleaned = clean(value, maxLength: maxLanguageLength);
    if (cleaned.isEmpty) return '';
    final normalized = cleaned.replaceAll('_', '-');
    if (!RegExp(r'^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$').hasMatch(normalized)) {
      return '';
    }
    return normalized;
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
}
