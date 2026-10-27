abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const giant = 56.0;
}

abstract final class AppRadii {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const gentle = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const scanner = Duration(milliseconds: 2600);
}

abstract final class AppSizes {
  static const controlHeight = 48.0;
  static const compactControlHeight = 40.0;
  static const navBarHeight = 64.0;
  static const iconSmall = 16.0;
  static const icon = 20.0;
  static const iconLarge = 24.0;

  static double screenMargin(double width) {
    if (width >= 1200) return 56;
    if (width >= 900) return 40;
    if (width >= 600) return 32;
    return 20;
  }

  static double maxContentWidth(String name) {
    return switch (name) {
      'library' => 1180,
      'detail' => 880,
      'reading' => 720,
      'nearby' => 760,
      'transfers' => 860,
      'settings' => 760,
      'reader' => 760,
      _ => 920,
    };
  }
}

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1100.0;
}

abstract final class AppConstants {
  static const appName = 'Relay';
  static const version = '0.9.0';
  static const buildLabel = 'Offline-first library';
  static const maxImportBytes = 100 * 1024 * 1024;
  static const supportedExtensions = ['pdf', 'epub'];
}
