import 'package:flutter/foundation.dart';

import 'document.dart';
import 'library_item.dart';

enum LibrarySort { recentlyAdded, title, author, recentlyRead, fileSize }

extension LibrarySortX on LibrarySort {
  String get label => switch (this) {
    LibrarySort.recentlyAdded => 'Recently added',
    LibrarySort.title => 'Title, A–Z',
    LibrarySort.author => 'Author, A–Z',
    LibrarySort.recentlyRead => 'Recently read',
    LibrarySort.fileSize => 'Largest file',
  };
}

@immutable
class LibraryFilters {
  const LibraryFilters({this.formats = const {}, this.statuses = const {}});

  final Set<DocumentFormat> formats;
  final Set<LibraryReadingStatus> statuses;

  bool get isActive => formats.isNotEmpty || statuses.isNotEmpty;

  int get activeCount => formats.length + statuses.length;

  LibraryFilters copyWith({
    Set<DocumentFormat>? formats,
    Set<LibraryReadingStatus>? statuses,
  }) {
    return LibraryFilters(
      formats: formats ?? this.formats,
      statuses: statuses ?? this.statuses,
    );
  }
}

@immutable
class LibraryQuery {
  const LibraryQuery({
    this.search = '',
    this.sort = LibrarySort.recentlyAdded,
    this.filters = const LibraryFilters(),
  });

  final String search;
  final LibrarySort sort;
  final LibraryFilters filters;

  bool get hasSearch => search.trim().isNotEmpty;

  bool get isFiltering => filters.isActive || hasSearch;

  LibraryQuery copyWith({
    String? search,
    LibrarySort? sort,
    LibraryFilters? filters,
  }) {
    return LibraryQuery(
      search: search ?? this.search,
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
    );
  }
}

/// Pure query pipeline, kept outside providers so it is straightforward to test.
List<LibraryItem> applyLibraryQuery(
  List<LibraryItem> items,
  LibraryQuery query,
) {
  final term = query.search.trim().toLowerCase();
  final filtered = items.where((item) {
    final document = item.document;
    final matchesSearch =
        term.isEmpty ||
        document.title.toLowerCase().contains(term) ||
        document.author.toLowerCase().contains(term) ||
        document.displayFileName.toLowerCase().contains(term) ||
        document.source.toLowerCase().contains(term);
    final matchesFormat =
        query.filters.formats.isEmpty ||
        query.filters.formats.contains(document.format);
    final matchesStatus =
        query.filters.statuses.isEmpty ||
        query.filters.statuses.contains(item.readingStatus);
    return matchesSearch && matchesFormat && matchesStatus;
  }).toList();

  switch (query.sort) {
    case LibrarySort.recentlyAdded:
      filtered.sort((a, b) => b.document.addedAt.compareTo(a.document.addedAt));
    case LibrarySort.title:
      filtered.sort(
        (a, b) => a.document.title.toLowerCase().compareTo(
          b.document.title.toLowerCase(),
        ),
      );
    case LibrarySort.author:
      filtered.sort(
        (a, b) => a.document.author.toLowerCase().compareTo(
          b.document.author.toLowerCase(),
        ),
      );
    case LibrarySort.recentlyRead:
      filtered.sort((a, b) {
        final aDate = a.lastReadAt;
        final bDate = b.lastReadAt;
        if (aDate == null && bDate == null) {
          return b.document.addedAt.compareTo(a.document.addedAt);
        }
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    case LibrarySort.fileSize:
      filtered.sort(
        (a, b) => b.document.sizeBytes.compareTo(a.document.sizeBytes),
      );
  }

  return filtered;
}
