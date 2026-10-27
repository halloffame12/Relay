import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/relay_sheet.dart';
import '../../../../core/widgets/relay_search_field.dart';
import '../../../../core/widgets/status_label.dart';
import '../../../library/domain/document.dart';
import '../../../library/presentation/widgets/document_cover.dart';

Future<Document?> showNearbyDocumentPicker(
  BuildContext context, {
  required List<Document> documents,
  String? selectedId,
}) {
  return showRelaySheet<Document>(
    context,
    builder: (_) =>
        _DocumentPickerSheet(documents: documents, selectedId: selectedId),
  );
}

class _DocumentPickerSheet extends StatefulWidget {
  const _DocumentPickerSheet({required this.documents, this.selectedId});

  final List<Document> documents;
  final String? selectedId;

  @override
  State<_DocumentPickerSheet> createState() => _DocumentPickerSheetState();
}

class _DocumentPickerSheetState extends State<_DocumentPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final available = widget.documents
        .where((document) => document.isAvailableOffline)
        .toList();
    final query = _query.trim().toLowerCase();
    final filtered = available.where((document) {
      if (query.isEmpty) return true;
      return document.title.toLowerCase().contains(query) ||
          document.displayFileName.toLowerCase().contains(query) ||
          document.author.toLowerCase().contains(query);
    }).toList();

    return RelaySheetScaffold(
      title: 'Choose a document',
      subtitle:
          'Only documents Relay already manages can be sent. Reader progress '
          'and bookmarks stay on this device.',
      trailing: IconButton(
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RelaySearchField(
            controller: _searchController,
            hintText: 'Search your library',
            semanticLabel: 'Search documents to send',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 26,
                          color: colors.muted,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          available.isEmpty
                              ? 'No Relay-managed documents are available to '
                                    'send.'
                              : 'No documents match “$_query”.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: math.min(
                      MediaQuery.sizeOf(context).height * 0.46,
                      380,
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final document = filtered[index];
                        return _DocumentOption(
                          document: document,
                          selected: document.id == widget.selectedId,
                          onTap: () => Navigator.of(context).pop(document),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Relay never exposes other files on this device.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _DocumentOption extends StatelessWidget {
  const _DocumentOption({
    required this.document,
    required this.selected,
    required this.onTap,
  });

  final Document document;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.relayColors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.accentSoft : colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: selected ? colors.accent : colors.line),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                height: 51,
                child: DocumentCover(
                  document: document,
                  showShadow: false,
                  borderRadius: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusLabel(
                          label: document.format.label,
                          tone: StatusTone.outline,
                        ),
                        Text(
                          formatBytes(document.sizeBytes),
                          style: AppTypography.eyebrow(
                            colors.muted,
                          ).copyWith(fontSize: 9, letterSpacing: 0.55),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: selected ? colors.accent : colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
