import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/layout.dart';
import '../../../core/widgets/relay_dialogs.dart';
import '../../../core/widgets/relay_segmented_control.dart';
import '../../../core/widgets/relay_wordmark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_label.dart';
import '../../library/application/library_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../transfers/application/transfer_providers.dart';
import '../../transfers/domain/transfer_task.dart';
import 'privacy_policy.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.relayColors;
    final width = MediaQuery.sizeOf(context).width;
    final useCompactWordmark = width < 380;
    final showDeviceLabel = width >= 600;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final summary = ref.watch(librarySummaryProvider);
    final completedTransfers =
        (ref.watch(transfersProvider).value ?? const <TransferTask>[])
            .where((task) => task.isComplete)
            .length;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.giant),
          child: RelayContent(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    RelayWordmark(
                      compact: useCompactWordmark,
                      onTap: () => context.go('/library'),
                    ),
                    const Spacer(),
                    if (showDeviceLabel)
                      const StatusLabel(
                        label: 'On this device',
                        tone: StatusTone.outline,
                        icon: Icons.offline_pin_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const PageHeading(
                  eyebrow: 'Preferences',
                  title: 'Settings',
                  subtitle:
                      'Adjust how Relay looks, how pages read, and how local '
                      'transfers behave. Your preferences stay on this device.',
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SettingsSection(
                  eyebrow: 'Look & feel',
                  title: 'Appearance',
                  description:
                      'Relay uses a warm paper palette in light mode and a '
                      'low-glare ink palette at night.',
                  children: [
                    _ControlBlock(
                      icon: Icons.brightness_6_outlined,
                      title: 'Theme',
                      subtitle:
                          'Match the system or choose a fixed appearance.',
                      child: RelaySegmentedControl<AppThemePreference>(
                        options: const [
                          RelaySegmentedOption(
                            value: AppThemePreference.system,
                            label: 'System',
                          ),
                          RelaySegmentedOption(
                            value: AppThemePreference.light,
                            label: 'Light',
                          ),
                          RelaySegmentedOption(
                            value: AppThemePreference.dark,
                            label: 'Dark',
                          ),
                        ],
                        value: settings.theme,
                        onChanged: controller.setTheme,
                      ),
                    ),
                    const Divider(),
                    _SwitchRow(
                      icon: Icons.motion_photos_off_outlined,
                      title: 'Reduce motion',
                      subtitle:
                          'Shorten page transitions and stop looping placeholder '
                          'animation throughout Relay.',
                      value: settings.reduceMotion,
                      onChanged: controller.setReduceMotion,
                    ),
                    const Divider(),
                    _ControlBlock(
                      icon: Icons.grid_view_rounded,
                      title: 'Default library view',
                      subtitle:
                          'Choose how the collection opens on the Library tab.',
                      child: RelaySegmentedControl<LibraryViewMode>(
                        options: const [
                          RelaySegmentedOption(
                            value: LibraryViewMode.grid,
                            label: 'Grid',
                            icon: Icons.grid_view_rounded,
                          ),
                          RelaySegmentedOption(
                            value: LibraryViewMode.list,
                            label: 'List',
                            icon: Icons.view_agenda_outlined,
                          ),
                        ],
                        value: settings.libraryView,
                        onChanged: controller.setLibraryView,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SettingsSection(
                  eyebrow: 'Typography',
                  title: 'Reading',
                  description:
                      'Reader preferences apply to every book and document on '
                      'this device.',
                  children: [
                    _ControlBlock(
                      icon: Icons.contrast_rounded,
                      title: 'Reading theme',
                      subtitle: 'Paper suits daylight; Night dims the page.',
                      child: RelaySegmentedControl<ReaderTheme>(
                        options: const [
                          RelaySegmentedOption(
                            value: ReaderTheme.paper,
                            label: 'Paper',
                          ),
                          RelaySegmentedOption(
                            value: ReaderTheme.night,
                            label: 'Night',
                          ),
                        ],
                        value: settings.readerTheme,
                        onChanged: controller.setReaderTheme,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ReaderPreview(theme: settings.readerTheme),
                    const Divider(),
                    _TextScaleControl(
                      step: settings.readerTextStep,
                      scale: settings.readerTextScale,
                      onChanged: (step) =>
                          controller.setReaderTextScale(_textScaleSteps[step]),
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: controller.resetReadingPreferences,
                        icon: const Icon(Icons.restart_alt_rounded, size: 17),
                        label: const Text('Reset reading preferences'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SettingsSection(
                  eyebrow: 'Storage',
                  title: 'Space on this device',
                  description:
                      'Actual space used by the documents Relay has copied '
                      'into app-managed storage. Relay does not scan your '
                      'whole device.',
                  children: [
                    _StoragePanel(
                      documentCount: summary.documentCount,
                      missingCount: summary.missingCount,
                      totalLabel: summary.totalSizeLabel,
                      pdfBytes: summary.pdfBytes,
                      epubBytes: summary.epubBytes,
                      totalBytes: summary.totalBytes,
                    ),
                    const Divider(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final note = Text(
                          summary.missingCount > 0
                              ? '${summary.missingCount} library '
                                    '${summary.missingCount == 1 ? 'file is' : 'files are'} '
                                    'missing and not counted. Remove the '
                                    '${summary.missingCount == 1 ? 'record' : 'records'} to clean up the library.'
                              : 'Calculated from the files Relay stores on this '
                                    'device, not from your whole storage.',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                        final action = TextButton.icon(
                          onPressed: () => context.go('/library'),
                          icon: const Icon(
                            Icons.library_books_outlined,
                            size: 17,
                          ),
                          label: const Text('Open library'),
                        );
                        if (constraints.maxWidth < 380) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              note,
                              const SizedBox(height: AppSpacing.xs),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: action,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: note),
                            const SizedBox(width: AppSpacing.md),
                            action,
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SettingsSection(
                  eyebrow: 'Sharing',
                  title: 'Transfers',
                  description:
                      'Relay can stream a library document directly to another '
                      'Relay device on the same Wi-Fi network. It does not use '
                      'an internet relay, an account or a cloud service.',
                  children: [
                    _SwitchRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Confirm before cancelling',
                      subtitle:
                          'Ask for confirmation when an active transfer is '
                          'cancelled.',
                      value: settings.confirmBeforeCancel,
                      onChanged: controller.setConfirmBeforeCancel,
                    ),
                    const Divider(),
                    _SettingsRow(
                      icon: Icons.history_rounded,
                      title: 'Completed transfer history',
                      subtitle: completedTransfers == 0
                          ? 'No completed transfers to clear.'
                          : '$completedTransfers completed '
                                '${completedTransfers == 1 ? 'entry' : 'entries'} '
                                'in the activity list.',
                      trailing: TextButton(
                        onPressed: completedTransfers == 0
                            ? null
                            : () => _clearTransfers(
                                context,
                                ref,
                                completedTransfers,
                              ),
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SettingsSection(
                  eyebrow: 'Privacy',
                  title: 'Your data and your choices',
                  description:
                      'Your library and reading data are stored in Relay on '
                      'this device. Nearby sends a copy only to the receiving '
                      'device you choose. There is no account, subscription or '
                      'cloud library.',
                  children: [
                    const _PrivacyPoint(
                      icon: Icons.phone_android_rounded,
                      title: 'On-device first',
                      body:
                          'Documents, reading positions and preferences are '
                          'stored in Relay’s local app data. The developer does '
                          'not receive your library.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _PrivacyPoint(
                      icon: Icons.wifi_off_rounded,
                      title: 'Direct local transfer',
                      body:
                          'Relay opens a direct TCP connection only while you '
                          'offer receive mode or send a document. Files are '
                          'never uploaded to a cloud service. The transfer is '
                          'not end-to-end encrypted, so use a trusted Wi-Fi '
                          'network and check the receiving device.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _PrivacyPoint(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Optional camera',
                      body:
                          'The camera is used only when you scan a QR code. '
                          'The scanner uses Google ML Kit, which may send '
                          'limited diagnostics and usage data to Google. Relay '
                          'does not receive that data.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _PrivacyPoint(
                      icon: Icons.person_off_outlined,
                      title: 'No identity required',
                      body:
                          'Relay does not ask for an email address, phone '
                          'number or social account.',
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => showRelayInfoDialog(
                          context,
                          title: 'Relay privacy policy',
                          message: relayPrivacyPolicyText,
                        ),
                        icon: const Icon(Icons.article_outlined, size: 17),
                        label: const Text('Read privacy policy'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SettingsSection(
                  eyebrow: 'About',
                  title: 'Relay',
                  children: [
                    const _AboutHeader(),
                    const Divider(),
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'About this app',
                      subtitle:
                          'An offline-first document library with local '
                          'PDF and EPUB reading.',
                      onTap: () => showRelayInfoDialog(
                        context,
                        title: 'About Relay',
                        message:
                            'Relay is a calm home for the documents you keep. '
                            'This build stores imported PDFs and EPUBs in '
                            'app-managed local storage and reads the real '
                            'files with restore-on-open progress.\n\n'
                            'Nearby uses a direct, explicit-address TCP '
                            'connection between two Relay installations on the '
                            'same local Wi-Fi network. The transfer is not '
                            'end-to-end encrypted, so use a trusted network. '
                            'Automatic discovery, Bluetooth, internet relay, '
                            'background transfer and cloud sync are not '
                            'included.\n\n'
                            'The QR scanner uses Google ML Kit. See the Privacy '
                            'policy for the limited data Google may collect.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                    ),
                    const Divider(),
                    _SettingsRow(
                      icon: Icons.folder_open_outlined,
                      title: 'Local library',
                      subtitle:
                          'Imported files are copied into Relay’s app storage.',
                      onTap: () => showRelayInfoDialog(
                        context,
                        title: 'Your local library',
                        message:
                            'Relay starts with an empty library. Use the '
                            'Library tab to import PDF or EPUB files through '
                            'Android’s system picker.\n\n'
                            'Relay keeps its own copy in app-managed storage '
                            'and records the original file name and format. '
                            'The original file stays where it is. If you '
                            'remove a document from Relay, only Relay’s copy '
                            'is deleted.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                    ),
                    const Divider(),
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      title: 'Open-source licenses',
                      subtitle: 'Libraries used to build this app.',
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'Relay',
                        applicationVersion: '${AppConstants.version} (1)',
                        applicationLegalese:
                            'An offline-first library for documents you keep.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                    ),
                    const Divider(),
                    _SettingsRow(
                      icon: Icons.tag_rounded,
                      title: 'Version',
                      subtitle: AppConstants.buildLabel,
                      trailing: Text(
                        '${AppConstants.version} (1)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Center(
                  child: Text(
                    'Relay · A quiet place for documents',
                    style: AppTypography.eyebrow(
                      colors.muted,
                    ).copyWith(fontSize: 9, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearTransfers(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await showRelayConfirmationDialog(
      context,
      title: 'Clear transfer history?',
      message:
          '$count completed ${count == 1 ? 'entry' : 'entries'} will be removed '
          'from the activity list. Documents and reading positions are not '
          'affected.',
      confirmLabel: 'Clear history',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(transferServiceProvider).clearCompleted();
      if (!context.mounted) return;
      showRelaySnackBar(context, 'Completed transfer history cleared.');
    } catch (_) {
      if (!context.mounted) return;
      showRelaySnackBar(
        context,
        'Transfer history could not be cleared.',
        isError: true,
      );
    }
  }
}

const _textScaleSteps = [0.85, 1.0, 1.15, 1.3, 1.45];

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.eyebrow,
    required this.title,
    required this.children,
    this.description,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(eyebrow: eyebrow, title: title, description: description),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: colors.line),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ControlBlock extends StatelessWidget {
  const _ControlBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colors.muted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.muted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: content,
    );
  }
}

class _ReaderPreview extends StatelessWidget {
  const _ReaderPreview({required this.theme});

  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    final isNight = theme == ReaderTheme.night;
    final background = isNight ? AppColors.dark.canvas : AppColors.warmPaper;
    final foreground = isNight ? AppColors.dark.ink : AppColors.forestInk;
    final muted = isNight ? AppColors.dark.muted : AppColors.oliveGray;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.standard,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.relayColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE READING ROOM',
            style: AppTypography.eyebrow(
              muted,
            ).copyWith(fontSize: 8.5, letterSpacing: 1.2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A page should ask for nothing but attention.',
            style: AppTypography.serif(
              size: 19,
              height: 1.35,
              color: foreground,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Preview text · ${isNight ? 'Night' : 'Paper'} theme',
            style: TextStyle(
              fontSize: 10,
              color: muted,
              fontFamilyFallback: AppFonts.sansFallback,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextScaleControl extends StatelessWidget {
  const _TextScaleControl({
    required this.step,
    required this.scale,
    required this.onChanged,
  });

  final int step;
  final double scale;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_size_rounded, size: 18, color: colors.muted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Text size', style: theme.textTheme.titleSmall),
              ),
              Text(
                formatTextScale(scale),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Preview text resizes immediately in the reader.',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            children: [
              ExcludeSemantics(
                child: Text(
                  'A',
                  style: AppTypography.serif(size: 14, color: colors.muted),
                ),
              ),
              Expanded(
                child: Slider(
                  value: step.toDouble(),
                  min: 0,
                  max: 4,
                  divisions: 4,
                  label: formatTextScale(scale),
                  onChanged: (value) => onChanged(value.round()),
                ),
              ),
              ExcludeSemantics(
                child: Text(
                  'A',
                  style: AppTypography.serif(size: 22, color: colors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoragePanel extends StatelessWidget {
  const _StoragePanel({
    required this.documentCount,
    required this.missingCount,
    required this.totalLabel,
    required this.pdfBytes,
    required this.epubBytes,
    required this.totalBytes,
  });

  final int documentCount;
  final int missingCount;
  final String totalLabel;
  final int pdfBytes;
  final int epubBytes;
  final int totalBytes;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    final hasData = totalBytes > 0;
    final pdfFlex = hasData ? (pdfBytes / totalBytes * 1000).round() : 1;
    final epubFlex = hasData ? (epubBytes / totalBytes * 1000).round() : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RELAY STORAGE',
                      style: AppTypography.eyebrow(colors.muted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      totalLabel,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '$documentCount '
                      '${documentCount == 1 ? 'document' : 'documents'} · '
                      '${missingCount > 0 ? '$missingCount missing' : 'stored locally'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.storage_rounded, size: 22, color: colors.muted),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: hasData
                  ? Row(
                      children: [
                        Expanded(
                          flex: pdfFlex == 0 ? 1 : pdfFlex,
                          child: ColoredBox(color: colors.accent),
                        ),
                        Expanded(
                          flex: epubFlex == 0 ? 1 : epubFlex,
                          child: ColoredBox(color: colors.sage),
                        ),
                      ],
                    )
                  : ColoredBox(color: colors.surfaceSubtle),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _LegendDot(
                color: colors.accent,
                label: 'PDF',
                value: formatBytes(pdfBytes),
              ),
              _LegendDot(
                color: colors.sage,
                label: 'EPUB',
                value: formatBytes(epubBytes),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.relayColors.ink,
          ),
        ),
      ],
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.sage,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 17, color: colors.ink),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final version = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Version ${AppConstants.version} (1)',
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          AppConstants.buildLabel,
          textAlign: TextAlign.end,
          style: AppTypography.eyebrow(
            colors.muted,
          ).copyWith(fontSize: 9, letterSpacing: 0.7),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RelayWordmark(),
                const SizedBox(height: AppSpacing.sm),
                Align(alignment: Alignment.centerLeft, child: version),
              ],
            );
          }
          return Row(
            children: [
              const RelayWordmark(),
              const Spacer(),
              Flexible(child: version),
            ],
          );
        },
      ),
    );
  }
}
