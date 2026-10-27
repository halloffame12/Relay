import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../reader/application/reading_providers.dart';
import '../data/drift_document_repository.dart';
import '../domain/document.dart';
import '../domain/document_repository.dart';
import '../domain/library_item.dart';
import '../domain/library_query.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DriftDocumentRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(documentFileStoreProvider),
  );
});

final documentsProvider = StreamProvider<List<Document>>((ref) {
  return ref.watch(documentRepositoryProvider).watchDocuments();
});

final libraryItemsProvider = Provider<AsyncValue<List<LibraryItem>>>((ref) {
  final documents = ref.watch(documentsProvider);
  final progress = ref.watch(readingProgressProvider);

  if (documents.isLoading || progress.isLoading) {
    return const AsyncLoading();
  }
  if (documents.hasError) {
    return AsyncError(
      documents.error!,
      documents.stackTrace ?? StackTrace.current,
    );
  }

  final progressMap = progress.value ?? const {};
  final items = [
    for (final document in documents.requireValue)
      LibraryItem(document: document, progress: progressMap[document.id]),
  ];
  return AsyncData(items);
});

final libraryQueryProvider =
    NotifierProvider<LibraryQueryController, LibraryQuery>(
      LibraryQueryController.new,
    );

class LibraryQueryController extends Notifier<LibraryQuery> {
  @override
  LibraryQuery build() => const LibraryQuery();

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  void setSort(LibrarySort sort) {
    state = state.copyWith(sort: sort);
  }

  void toggleFormat(DocumentFormat format) {
    final formats = {...state.filters.formats};
    if (!formats.add(format)) formats.remove(format);
    state = state.copyWith(filters: state.filters.copyWith(formats: formats));
  }

  void toggleStatus(LibraryReadingStatus status) {
    final statuses = {...state.filters.statuses};
    if (!statuses.add(status)) statuses.remove(status);
    state = state.copyWith(filters: state.filters.copyWith(statuses: statuses));
  }

  void clearFilters() {
    state = state.copyWith(filters: const LibraryFilters());
  }

  void clearAll() {
    state = const LibraryQuery();
  }

  void removeFormat(DocumentFormat format) {
    final formats = {...state.filters.formats}..remove(format);
    state = state.copyWith(filters: state.filters.copyWith(formats: formats));
  }

  void removeStatus(LibraryReadingStatus status) {
    final statuses = {...state.filters.statuses}..remove(status);
    state = state.copyWith(filters: state.filters.copyWith(statuses: statuses));
  }
}

final visibleLibraryProvider = Provider<AsyncValue<List<LibraryItem>>>((ref) {
  final items = ref.watch(libraryItemsProvider);
  final query = ref.watch(libraryQueryProvider);
  return items.whenData((value) => applyLibraryQuery(value, query));
});

final continueReadingProvider = Provider<List<LibraryItem>>((ref) {
  final items = ref.watch(libraryItemsProvider).value ?? const [];
  final inProgress =
      items
          .where(
            (item) =>
                item.hasProgress &&
                !item.isFinished &&
                !item.document.isMissing,
          )
          .toList()
        ..sort((a, b) {
          final aDate = a.lastReadAt;
          final bDate = b.lastReadAt;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
  return inProgress;
});

final librarySummaryProvider = Provider<LibrarySummary>((ref) {
  final documents = ref.watch(documentsProvider).value ?? const [];
  final storedDocuments = documents
      .where((document) => !document.isMissing)
      .toList();
  final totalBytes = storedDocuments.fold<int>(
    0,
    (sum, document) => sum + document.sizeBytes,
  );
  final pdfBytes = storedDocuments
      .where((doc) => doc.isPdf)
      .fold<int>(0, (sum, doc) => sum + doc.sizeBytes);
  return LibrarySummary(
    documentCount: documents.length,
    missingCount: documents.length - storedDocuments.length,
    totalBytes: totalBytes,
    pdfBytes: pdfBytes,
    epubBytes: totalBytes - pdfBytes,
    totalSizeLabel: formatBytes(totalBytes),
  );
});

final documentByIdProvider = Provider.family<AsyncValue<Document?>, String>((
  ref,
  id,
) {
  final documents = ref.watch(documentsProvider);
  return documents.whenData((list) {
    for (final document in list) {
      if (document.id == id) return document;
    }
    return null;
  });
});

final libraryItemByIdProvider = Provider.family<LibraryItem?, String>((
  ref,
  id,
) {
  final items = ref.watch(libraryItemsProvider).value ?? const [];
  for (final item in items) {
    if (item.document.id == id) return item;
  }
  return null;
});

class LibrarySummary {
  const LibrarySummary({
    required this.documentCount,
    required this.missingCount,
    required this.totalBytes,
    required this.pdfBytes,
    required this.epubBytes,
    required this.totalSizeLabel,
  });

  final int documentCount;
  final int missingCount;
  final int totalBytes;
  final int pdfBytes;
  final int epubBytes;
  final String totalSizeLabel;
}
