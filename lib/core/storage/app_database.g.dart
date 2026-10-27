// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedFileNameMeta = const VerificationMeta(
    'storedFileName',
  );
  @override
  late final GeneratedColumn<String> storedFileName = GeneratedColumn<String>(
    'stored_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Imported'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Not set'),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverDesignMeta = const VerificationMeta(
    'coverDesign',
  );
  @override
  late final GeneratedColumn<String> coverDesign = GeneratedColumn<String>(
    'cover_design',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPaletteMeta = const VerificationMeta(
    'coverPalette',
  );
  @override
  late final GeneratedColumn<String> coverPalette = GeneratedColumn<String>(
    'cover_palette',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isImportedMeta = const VerificationMeta(
    'isImported',
  );
  @override
  late final GeneratedColumn<bool> isImported = GeneratedColumn<bool>(
    'is_imported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_imported" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    originalFileName,
    storedFileName,
    format,
    sizeBytes,
    addedAt,
    lastOpenedAt,
    sha256,
    description,
    source,
    language,
    pageCount,
    coverDesign,
    coverPalette,
    isImported,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileNameMeta);
    }
    if (data.containsKey('stored_file_name')) {
      context.handle(
        _storedFileNameMeta,
        storedFileName.isAcceptableOrUnknown(
          data['stored_file_name']!,
          _storedFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storedFileNameMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('cover_design')) {
      context.handle(
        _coverDesignMeta,
        coverDesign.isAcceptableOrUnknown(
          data['cover_design']!,
          _coverDesignMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coverDesignMeta);
    }
    if (data.containsKey('cover_palette')) {
      context.handle(
        _coverPaletteMeta,
        coverPalette.isAcceptableOrUnknown(
          data['cover_palette']!,
          _coverPaletteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_coverPaletteMeta);
    }
    if (data.containsKey('is_imported')) {
      context.handle(
        _isImportedMeta,
        isImported.isAcceptableOrUnknown(data['is_imported']!, _isImportedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sha256},
  ];
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      )!,
      storedFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_file_name'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      coverDesign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_design'],
      )!,
      coverPalette: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_palette'],
      )!,
      isImported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_imported'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String title;
  final String author;
  final String originalFileName;
  final String storedFileName;
  final String format;
  final int sizeBytes;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final String sha256;
  final String description;
  final String source;
  final String language;
  final int? pageCount;
  final String coverDesign;
  final String coverPalette;
  final bool isImported;
  const DocumentRow({
    required this.id,
    required this.title,
    required this.author,
    required this.originalFileName,
    required this.storedFileName,
    required this.format,
    required this.sizeBytes,
    required this.addedAt,
    this.lastOpenedAt,
    required this.sha256,
    required this.description,
    required this.source,
    required this.language,
    this.pageCount,
    required this.coverDesign,
    required this.coverPalette,
    required this.isImported,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['original_file_name'] = Variable<String>(originalFileName);
    map['stored_file_name'] = Variable<String>(storedFileName);
    map['format'] = Variable<String>(format);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['sha256'] = Variable<String>(sha256);
    map['description'] = Variable<String>(description);
    map['source'] = Variable<String>(source);
    map['language'] = Variable<String>(language);
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['cover_design'] = Variable<String>(coverDesign);
    map['cover_palette'] = Variable<String>(coverPalette);
    map['is_imported'] = Variable<bool>(isImported);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      originalFileName: Value(originalFileName),
      storedFileName: Value(storedFileName),
      format: Value(format),
      sizeBytes: Value(sizeBytes),
      addedAt: Value(addedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      sha256: Value(sha256),
      description: Value(description),
      source: Value(source),
      language: Value(language),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      coverDesign: Value(coverDesign),
      coverPalette: Value(coverPalette),
      isImported: Value(isImported),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      originalFileName: serializer.fromJson<String>(json['originalFileName']),
      storedFileName: serializer.fromJson<String>(json['storedFileName']),
      format: serializer.fromJson<String>(json['format']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      sha256: serializer.fromJson<String>(json['sha256']),
      description: serializer.fromJson<String>(json['description']),
      source: serializer.fromJson<String>(json['source']),
      language: serializer.fromJson<String>(json['language']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      coverDesign: serializer.fromJson<String>(json['coverDesign']),
      coverPalette: serializer.fromJson<String>(json['coverPalette']),
      isImported: serializer.fromJson<bool>(json['isImported']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'originalFileName': serializer.toJson<String>(originalFileName),
      'storedFileName': serializer.toJson<String>(storedFileName),
      'format': serializer.toJson<String>(format),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'sha256': serializer.toJson<String>(sha256),
      'description': serializer.toJson<String>(description),
      'source': serializer.toJson<String>(source),
      'language': serializer.toJson<String>(language),
      'pageCount': serializer.toJson<int?>(pageCount),
      'coverDesign': serializer.toJson<String>(coverDesign),
      'coverPalette': serializer.toJson<String>(coverPalette),
      'isImported': serializer.toJson<bool>(isImported),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? title,
    String? author,
    String? originalFileName,
    String? storedFileName,
    String? format,
    int? sizeBytes,
    DateTime? addedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    String? sha256,
    String? description,
    String? source,
    String? language,
    Value<int?> pageCount = const Value.absent(),
    String? coverDesign,
    String? coverPalette,
    bool? isImported,
  }) => DocumentRow(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    originalFileName: originalFileName ?? this.originalFileName,
    storedFileName: storedFileName ?? this.storedFileName,
    format: format ?? this.format,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    addedAt: addedAt ?? this.addedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    sha256: sha256 ?? this.sha256,
    description: description ?? this.description,
    source: source ?? this.source,
    language: language ?? this.language,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    coverDesign: coverDesign ?? this.coverDesign,
    coverPalette: coverPalette ?? this.coverPalette,
    isImported: isImported ?? this.isImported,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      storedFileName: data.storedFileName.present
          ? data.storedFileName.value
          : this.storedFileName,
      format: data.format.present ? data.format.value : this.format,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      description: data.description.present
          ? data.description.value
          : this.description,
      source: data.source.present ? data.source.value : this.source,
      language: data.language.present ? data.language.value : this.language,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      coverDesign: data.coverDesign.present
          ? data.coverDesign.value
          : this.coverDesign,
      coverPalette: data.coverPalette.present
          ? data.coverPalette.value
          : this.coverPalette,
      isImported: data.isImported.present
          ? data.isImported.value
          : this.isImported,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('storedFileName: $storedFileName, ')
          ..write('format: $format, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('sha256: $sha256, ')
          ..write('description: $description, ')
          ..write('source: $source, ')
          ..write('language: $language, ')
          ..write('pageCount: $pageCount, ')
          ..write('coverDesign: $coverDesign, ')
          ..write('coverPalette: $coverPalette, ')
          ..write('isImported: $isImported')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    originalFileName,
    storedFileName,
    format,
    sizeBytes,
    addedAt,
    lastOpenedAt,
    sha256,
    description,
    source,
    language,
    pageCount,
    coverDesign,
    coverPalette,
    isImported,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.originalFileName == this.originalFileName &&
          other.storedFileName == this.storedFileName &&
          other.format == this.format &&
          other.sizeBytes == this.sizeBytes &&
          other.addedAt == this.addedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.sha256 == this.sha256 &&
          other.description == this.description &&
          other.source == this.source &&
          other.language == this.language &&
          other.pageCount == this.pageCount &&
          other.coverDesign == this.coverDesign &&
          other.coverPalette == this.coverPalette &&
          other.isImported == this.isImported);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> author;
  final Value<String> originalFileName;
  final Value<String> storedFileName;
  final Value<String> format;
  final Value<int> sizeBytes;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<String> sha256;
  final Value<String> description;
  final Value<String> source;
  final Value<String> language;
  final Value<int?> pageCount;
  final Value<String> coverDesign;
  final Value<String> coverPalette;
  final Value<bool> isImported;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.storedFileName = const Value.absent(),
    this.format = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.description = const Value.absent(),
    this.source = const Value.absent(),
    this.language = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.coverDesign = const Value.absent(),
    this.coverPalette = const Value.absent(),
    this.isImported = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String title,
    required String author,
    required String originalFileName,
    required String storedFileName,
    required String format,
    required int sizeBytes,
    required DateTime addedAt,
    this.lastOpenedAt = const Value.absent(),
    required String sha256,
    this.description = const Value.absent(),
    this.source = const Value.absent(),
    this.language = const Value.absent(),
    this.pageCount = const Value.absent(),
    required String coverDesign,
    required String coverPalette,
    this.isImported = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       author = Value(author),
       originalFileName = Value(originalFileName),
       storedFileName = Value(storedFileName),
       format = Value(format),
       sizeBytes = Value(sizeBytes),
       addedAt = Value(addedAt),
       sha256 = Value(sha256),
       coverDesign = Value(coverDesign),
       coverPalette = Value(coverPalette);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? originalFileName,
    Expression<String>? storedFileName,
    Expression<String>? format,
    Expression<int>? sizeBytes,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? sha256,
    Expression<String>? description,
    Expression<String>? source,
    Expression<String>? language,
    Expression<int>? pageCount,
    Expression<String>? coverDesign,
    Expression<String>? coverPalette,
    Expression<bool>? isImported,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (storedFileName != null) 'stored_file_name': storedFileName,
      if (format != null) 'format': format,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (addedAt != null) 'added_at': addedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (sha256 != null) 'sha256': sha256,
      if (description != null) 'description': description,
      if (source != null) 'source': source,
      if (language != null) 'language': language,
      if (pageCount != null) 'page_count': pageCount,
      if (coverDesign != null) 'cover_design': coverDesign,
      if (coverPalette != null) 'cover_palette': coverPalette,
      if (isImported != null) 'is_imported': isImported,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? author,
    Value<String>? originalFileName,
    Value<String>? storedFileName,
    Value<String>? format,
    Value<int>? sizeBytes,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<String>? sha256,
    Value<String>? description,
    Value<String>? source,
    Value<String>? language,
    Value<int?>? pageCount,
    Value<String>? coverDesign,
    Value<String>? coverPalette,
    Value<bool>? isImported,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      originalFileName: originalFileName ?? this.originalFileName,
      storedFileName: storedFileName ?? this.storedFileName,
      format: format ?? this.format,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      sha256: sha256 ?? this.sha256,
      description: description ?? this.description,
      source: source ?? this.source,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      coverDesign: coverDesign ?? this.coverDesign,
      coverPalette: coverPalette ?? this.coverPalette,
      isImported: isImported ?? this.isImported,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (storedFileName.present) {
      map['stored_file_name'] = Variable<String>(storedFileName.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (coverDesign.present) {
      map['cover_design'] = Variable<String>(coverDesign.value);
    }
    if (coverPalette.present) {
      map['cover_palette'] = Variable<String>(coverPalette.value);
    }
    if (isImported.present) {
      map['is_imported'] = Variable<bool>(isImported.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('storedFileName: $storedFileName, ')
          ..write('format: $format, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('sha256: $sha256, ')
          ..write('description: $description, ')
          ..write('source: $source, ')
          ..write('language: $language, ')
          ..write('pageCount: $pageCount, ')
          ..write('coverDesign: $coverDesign, ')
          ..write('coverPalette: $coverPalette, ')
          ..write('isImported: $isImported, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressEntriesTable extends ReadingProgressEntries
    with TableInfo<$ReadingProgressEntriesTable, ReadingProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fractionMeta = const VerificationMeta(
    'fraction',
  );
  @override
  late final GeneratedColumn<double> fraction = GeneratedColumn<double>(
    'fraction',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _locationIndexMeta = const VerificationMeta(
    'locationIndex',
  );
  @override
  late final GeneratedColumn<int> locationIndex = GeneratedColumn<int>(
    'location_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _locationOffsetMeta = const VerificationMeta(
    'locationOffset',
  );
  @override
  late final GeneratedColumn<double> locationOffset = GeneratedColumn<double>(
    'location_offset',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _locationRefMeta = const VerificationMeta(
    'locationRef',
  );
  @override
  late final GeneratedColumn<String> locationRef = GeneratedColumn<String>(
    'location_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookmarksMeta = const VerificationMeta(
    'bookmarks',
  );
  @override
  late final GeneratedColumn<String> bookmarks = GeneratedColumn<String>(
    'bookmarks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    fraction,
    locationIndex,
    locationOffset,
    locationRef,
    lastReadAt,
    bookmarks,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('fraction')) {
      context.handle(
        _fractionMeta,
        fraction.isAcceptableOrUnknown(data['fraction']!, _fractionMeta),
      );
    }
    if (data.containsKey('location_index')) {
      context.handle(
        _locationIndexMeta,
        locationIndex.isAcceptableOrUnknown(
          data['location_index']!,
          _locationIndexMeta,
        ),
      );
    }
    if (data.containsKey('location_offset')) {
      context.handle(
        _locationOffsetMeta,
        locationOffset.isAcceptableOrUnknown(
          data['location_offset']!,
          _locationOffsetMeta,
        ),
      );
    }
    if (data.containsKey('location_ref')) {
      context.handle(
        _locationRefMeta,
        locationRef.isAcceptableOrUnknown(
          data['location_ref']!,
          _locationRefMeta,
        ),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('bookmarks')) {
      context.handle(
        _bookmarksMeta,
        bookmarks.isAcceptableOrUnknown(data['bookmarks']!, _bookmarksMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ReadingProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      fraction: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fraction'],
      )!,
      locationIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_index'],
      )!,
      locationOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_offset'],
      )!,
      locationRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_ref'],
      ),
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      ),
      bookmarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookmarks'],
      )!,
    );
  }

  @override
  $ReadingProgressEntriesTable createAlias(String alias) {
    return $ReadingProgressEntriesTable(attachedDatabase, alias);
  }
}

class ReadingProgressRow extends DataClass
    implements Insertable<ReadingProgressRow> {
  final String documentId;
  final double fraction;
  final int locationIndex;
  final double locationOffset;
  final String? locationRef;
  final DateTime? lastReadAt;
  final String bookmarks;
  const ReadingProgressRow({
    required this.documentId,
    required this.fraction,
    required this.locationIndex,
    required this.locationOffset,
    this.locationRef,
    this.lastReadAt,
    required this.bookmarks,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['fraction'] = Variable<double>(fraction);
    map['location_index'] = Variable<int>(locationIndex);
    map['location_offset'] = Variable<double>(locationOffset);
    if (!nullToAbsent || locationRef != null) {
      map['location_ref'] = Variable<String>(locationRef);
    }
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt);
    }
    map['bookmarks'] = Variable<String>(bookmarks);
    return map;
  }

  ReadingProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressEntriesCompanion(
      documentId: Value(documentId),
      fraction: Value(fraction),
      locationIndex: Value(locationIndex),
      locationOffset: Value(locationOffset),
      locationRef: locationRef == null && nullToAbsent
          ? const Value.absent()
          : Value(locationRef),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      bookmarks: Value(bookmarks),
    );
  }

  factory ReadingProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      fraction: serializer.fromJson<double>(json['fraction']),
      locationIndex: serializer.fromJson<int>(json['locationIndex']),
      locationOffset: serializer.fromJson<double>(json['locationOffset']),
      locationRef: serializer.fromJson<String?>(json['locationRef']),
      lastReadAt: serializer.fromJson<DateTime?>(json['lastReadAt']),
      bookmarks: serializer.fromJson<String>(json['bookmarks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'fraction': serializer.toJson<double>(fraction),
      'locationIndex': serializer.toJson<int>(locationIndex),
      'locationOffset': serializer.toJson<double>(locationOffset),
      'locationRef': serializer.toJson<String?>(locationRef),
      'lastReadAt': serializer.toJson<DateTime?>(lastReadAt),
      'bookmarks': serializer.toJson<String>(bookmarks),
    };
  }

  ReadingProgressRow copyWith({
    String? documentId,
    double? fraction,
    int? locationIndex,
    double? locationOffset,
    Value<String?> locationRef = const Value.absent(),
    Value<DateTime?> lastReadAt = const Value.absent(),
    String? bookmarks,
  }) => ReadingProgressRow(
    documentId: documentId ?? this.documentId,
    fraction: fraction ?? this.fraction,
    locationIndex: locationIndex ?? this.locationIndex,
    locationOffset: locationOffset ?? this.locationOffset,
    locationRef: locationRef.present ? locationRef.value : this.locationRef,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    bookmarks: bookmarks ?? this.bookmarks,
  );
  ReadingProgressRow copyWithCompanion(ReadingProgressEntriesCompanion data) {
    return ReadingProgressRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      fraction: data.fraction.present ? data.fraction.value : this.fraction,
      locationIndex: data.locationIndex.present
          ? data.locationIndex.value
          : this.locationIndex,
      locationOffset: data.locationOffset.present
          ? data.locationOffset.value
          : this.locationOffset,
      locationRef: data.locationRef.present
          ? data.locationRef.value
          : this.locationRef,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      bookmarks: data.bookmarks.present ? data.bookmarks.value : this.bookmarks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressRow(')
          ..write('documentId: $documentId, ')
          ..write('fraction: $fraction, ')
          ..write('locationIndex: $locationIndex, ')
          ..write('locationOffset: $locationOffset, ')
          ..write('locationRef: $locationRef, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('bookmarks: $bookmarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    fraction,
    locationIndex,
    locationOffset,
    locationRef,
    lastReadAt,
    bookmarks,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressRow &&
          other.documentId == this.documentId &&
          other.fraction == this.fraction &&
          other.locationIndex == this.locationIndex &&
          other.locationOffset == this.locationOffset &&
          other.locationRef == this.locationRef &&
          other.lastReadAt == this.lastReadAt &&
          other.bookmarks == this.bookmarks);
}

class ReadingProgressEntriesCompanion
    extends UpdateCompanion<ReadingProgressRow> {
  final Value<String> documentId;
  final Value<double> fraction;
  final Value<int> locationIndex;
  final Value<double> locationOffset;
  final Value<String?> locationRef;
  final Value<DateTime?> lastReadAt;
  final Value<String> bookmarks;
  final Value<int> rowid;
  const ReadingProgressEntriesCompanion({
    this.documentId = const Value.absent(),
    this.fraction = const Value.absent(),
    this.locationIndex = const Value.absent(),
    this.locationOffset = const Value.absent(),
    this.locationRef = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.bookmarks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressEntriesCompanion.insert({
    required String documentId,
    this.fraction = const Value.absent(),
    this.locationIndex = const Value.absent(),
    this.locationOffset = const Value.absent(),
    this.locationRef = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.bookmarks = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId);
  static Insertable<ReadingProgressRow> custom({
    Expression<String>? documentId,
    Expression<double>? fraction,
    Expression<int>? locationIndex,
    Expression<double>? locationOffset,
    Expression<String>? locationRef,
    Expression<DateTime>? lastReadAt,
    Expression<String>? bookmarks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (fraction != null) 'fraction': fraction,
      if (locationIndex != null) 'location_index': locationIndex,
      if (locationOffset != null) 'location_offset': locationOffset,
      if (locationRef != null) 'location_ref': locationRef,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (bookmarks != null) 'bookmarks': bookmarks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressEntriesCompanion copyWith({
    Value<String>? documentId,
    Value<double>? fraction,
    Value<int>? locationIndex,
    Value<double>? locationOffset,
    Value<String?>? locationRef,
    Value<DateTime?>? lastReadAt,
    Value<String>? bookmarks,
    Value<int>? rowid,
  }) {
    return ReadingProgressEntriesCompanion(
      documentId: documentId ?? this.documentId,
      fraction: fraction ?? this.fraction,
      locationIndex: locationIndex ?? this.locationIndex,
      locationOffset: locationOffset ?? this.locationOffset,
      locationRef: locationRef ?? this.locationRef,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      bookmarks: bookmarks ?? this.bookmarks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (fraction.present) {
      map['fraction'] = Variable<double>(fraction.value);
    }
    if (locationIndex.present) {
      map['location_index'] = Variable<int>(locationIndex.value);
    }
    if (locationOffset.present) {
      map['location_offset'] = Variable<double>(locationOffset.value);
    }
    if (locationRef.present) {
      map['location_ref'] = Variable<String>(locationRef.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (bookmarks.present) {
      map['bookmarks'] = Variable<String>(bookmarks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressEntriesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('fraction: $fraction, ')
          ..write('locationIndex: $locationIndex, ')
          ..write('locationOffset: $locationOffset, ')
          ..write('locationRef: $locationRef, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('bookmarks: $bookmarks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferEntriesTable extends TransferEntries
    with TableInfo<$TransferEntriesTable, TransferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentTitleMeta = const VerificationMeta(
    'documentTitle',
  );
  @override
  late final GeneratedColumn<String> documentTitle = GeneratedColumn<String>(
    'document_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeLabelMeta = const VerificationMeta(
    'fileTypeLabel',
  );
  @override
  late final GeneratedColumn<String> fileTypeLabel = GeneratedColumn<String>(
    'file_type_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferredBytesMeta = const VerificationMeta(
    'transferredBytes',
  );
  @override
  late final GeneratedColumn<int> transferredBytes = GeneratedColumn<int>(
    'transferred_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerNameMeta = const VerificationMeta(
    'peerName',
  );
  @override
  late final GeneratedColumn<String> peerName = GeneratedColumn<String>(
    'peer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureReasonMeta = const VerificationMeta(
    'failureReason',
  );
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tempFileNameMeta = const VerificationMeta(
    'tempFileName',
  );
  @override
  late final GeneratedColumn<String> tempFileName = GeneratedColumn<String>(
    'temp_file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    direction,
    documentId,
    documentTitle,
    fileTypeLabel,
    sizeBytes,
    transferredBytes,
    state,
    peerName,
    createdAt,
    updatedAt,
    completedAt,
    failureReason,
    note,
    tempFileName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    if (data.containsKey('document_title')) {
      context.handle(
        _documentTitleMeta,
        documentTitle.isAcceptableOrUnknown(
          data['document_title']!,
          _documentTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentTitleMeta);
    }
    if (data.containsKey('file_type_label')) {
      context.handle(
        _fileTypeLabelMeta,
        fileTypeLabel.isAcceptableOrUnknown(
          data['file_type_label']!,
          _fileTypeLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileTypeLabelMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('transferred_bytes')) {
      context.handle(
        _transferredBytesMeta,
        transferredBytes.isAcceptableOrUnknown(
          data['transferred_bytes']!,
          _transferredBytesMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('peer_name')) {
      context.handle(
        _peerNameMeta,
        peerName.isAcceptableOrUnknown(data['peer_name']!, _peerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_peerNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
        _failureReasonMeta,
        failureReason.isAcceptableOrUnknown(
          data['failure_reason']!,
          _failureReasonMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('temp_file_name')) {
      context.handle(
        _tempFileNameMeta,
        tempFileName.isAcceptableOrUnknown(
          data['temp_file_name']!,
          _tempFileNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      ),
      documentTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_title'],
      )!,
      fileTypeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type_label'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      transferredBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transferred_bytes'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      peerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      failureReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_reason'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      tempFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_file_name'],
      ),
    );
  }

  @override
  $TransferEntriesTable createAlias(String alias) {
    return $TransferEntriesTable(attachedDatabase, alias);
  }
}

class TransferRow extends DataClass implements Insertable<TransferRow> {
  final String id;
  final String direction;

  /// Local library document id, when it still exists. This is intentionally
  /// not a foreign key so finished transfer history remains readable after a
  /// document is removed.
  final String? documentId;
  final String documentTitle;
  final String fileTypeLabel;
  final int sizeBytes;
  final int transferredBytes;
  final String state;
  final String peerName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? note;
  final String? tempFileName;
  const TransferRow({
    required this.id,
    required this.direction,
    this.documentId,
    required this.documentTitle,
    required this.fileTypeLabel,
    required this.sizeBytes,
    required this.transferredBytes,
    required this.state,
    required this.peerName,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failureReason,
    this.note,
    this.tempFileName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || documentId != null) {
      map['document_id'] = Variable<String>(documentId);
    }
    map['document_title'] = Variable<String>(documentTitle);
    map['file_type_label'] = Variable<String>(fileTypeLabel);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['transferred_bytes'] = Variable<int>(transferredBytes);
    map['state'] = Variable<String>(state);
    map['peer_name'] = Variable<String>(peerName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || tempFileName != null) {
      map['temp_file_name'] = Variable<String>(tempFileName);
    }
    return map;
  }

  TransferEntriesCompanion toCompanion(bool nullToAbsent) {
    return TransferEntriesCompanion(
      id: Value(id),
      direction: Value(direction),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      documentTitle: Value(documentTitle),
      fileTypeLabel: Value(fileTypeLabel),
      sizeBytes: Value(sizeBytes),
      transferredBytes: Value(transferredBytes),
      state: Value(state),
      peerName: Value(peerName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      tempFileName: tempFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(tempFileName),
    );
  }

  factory TransferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferRow(
      id: serializer.fromJson<String>(json['id']),
      direction: serializer.fromJson<String>(json['direction']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      documentTitle: serializer.fromJson<String>(json['documentTitle']),
      fileTypeLabel: serializer.fromJson<String>(json['fileTypeLabel']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      transferredBytes: serializer.fromJson<int>(json['transferredBytes']),
      state: serializer.fromJson<String>(json['state']),
      peerName: serializer.fromJson<String>(json['peerName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      note: serializer.fromJson<String?>(json['note']),
      tempFileName: serializer.fromJson<String?>(json['tempFileName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'direction': serializer.toJson<String>(direction),
      'documentId': serializer.toJson<String?>(documentId),
      'documentTitle': serializer.toJson<String>(documentTitle),
      'fileTypeLabel': serializer.toJson<String>(fileTypeLabel),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'transferredBytes': serializer.toJson<int>(transferredBytes),
      'state': serializer.toJson<String>(state),
      'peerName': serializer.toJson<String>(peerName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'failureReason': serializer.toJson<String?>(failureReason),
      'note': serializer.toJson<String?>(note),
      'tempFileName': serializer.toJson<String?>(tempFileName),
    };
  }

  TransferRow copyWith({
    String? id,
    String? direction,
    Value<String?> documentId = const Value.absent(),
    String? documentTitle,
    String? fileTypeLabel,
    int? sizeBytes,
    int? transferredBytes,
    String? state,
    String? peerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> failureReason = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> tempFileName = const Value.absent(),
  }) => TransferRow(
    id: id ?? this.id,
    direction: direction ?? this.direction,
    documentId: documentId.present ? documentId.value : this.documentId,
    documentTitle: documentTitle ?? this.documentTitle,
    fileTypeLabel: fileTypeLabel ?? this.fileTypeLabel,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    transferredBytes: transferredBytes ?? this.transferredBytes,
    state: state ?? this.state,
    peerName: peerName ?? this.peerName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    failureReason: failureReason.present
        ? failureReason.value
        : this.failureReason,
    note: note.present ? note.value : this.note,
    tempFileName: tempFileName.present ? tempFileName.value : this.tempFileName,
  );
  TransferRow copyWithCompanion(TransferEntriesCompanion data) {
    return TransferRow(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      documentTitle: data.documentTitle.present
          ? data.documentTitle.value
          : this.documentTitle,
      fileTypeLabel: data.fileTypeLabel.present
          ? data.fileTypeLabel.value
          : this.fileTypeLabel,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      transferredBytes: data.transferredBytes.present
          ? data.transferredBytes.value
          : this.transferredBytes,
      state: data.state.present ? data.state.value : this.state,
      peerName: data.peerName.present ? data.peerName.value : this.peerName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      note: data.note.present ? data.note.value : this.note,
      tempFileName: data.tempFileName.present
          ? data.tempFileName.value
          : this.tempFileName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferRow(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('documentId: $documentId, ')
          ..write('documentTitle: $documentTitle, ')
          ..write('fileTypeLabel: $fileTypeLabel, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('state: $state, ')
          ..write('peerName: $peerName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('failureReason: $failureReason, ')
          ..write('note: $note, ')
          ..write('tempFileName: $tempFileName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    direction,
    documentId,
    documentTitle,
    fileTypeLabel,
    sizeBytes,
    transferredBytes,
    state,
    peerName,
    createdAt,
    updatedAt,
    completedAt,
    failureReason,
    note,
    tempFileName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferRow &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.documentId == this.documentId &&
          other.documentTitle == this.documentTitle &&
          other.fileTypeLabel == this.fileTypeLabel &&
          other.sizeBytes == this.sizeBytes &&
          other.transferredBytes == this.transferredBytes &&
          other.state == this.state &&
          other.peerName == this.peerName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.failureReason == this.failureReason &&
          other.note == this.note &&
          other.tempFileName == this.tempFileName);
}

class TransferEntriesCompanion extends UpdateCompanion<TransferRow> {
  final Value<String> id;
  final Value<String> direction;
  final Value<String?> documentId;
  final Value<String> documentTitle;
  final Value<String> fileTypeLabel;
  final Value<int> sizeBytes;
  final Value<int> transferredBytes;
  final Value<String> state;
  final Value<String> peerName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> failureReason;
  final Value<String?> note;
  final Value<String?> tempFileName;
  final Value<int> rowid;
  const TransferEntriesCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.documentId = const Value.absent(),
    this.documentTitle = const Value.absent(),
    this.fileTypeLabel = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.transferredBytes = const Value.absent(),
    this.state = const Value.absent(),
    this.peerName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.note = const Value.absent(),
    this.tempFileName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferEntriesCompanion.insert({
    required String id,
    required String direction,
    this.documentId = const Value.absent(),
    required String documentTitle,
    required String fileTypeLabel,
    required int sizeBytes,
    this.transferredBytes = const Value.absent(),
    required String state,
    required String peerName,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.note = const Value.absent(),
    this.tempFileName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       direction = Value(direction),
       documentTitle = Value(documentTitle),
       fileTypeLabel = Value(fileTypeLabel),
       sizeBytes = Value(sizeBytes),
       state = Value(state),
       peerName = Value(peerName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransferRow> custom({
    Expression<String>? id,
    Expression<String>? direction,
    Expression<String>? documentId,
    Expression<String>? documentTitle,
    Expression<String>? fileTypeLabel,
    Expression<int>? sizeBytes,
    Expression<int>? transferredBytes,
    Expression<String>? state,
    Expression<String>? peerName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? failureReason,
    Expression<String>? note,
    Expression<String>? tempFileName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (documentId != null) 'document_id': documentId,
      if (documentTitle != null) 'document_title': documentTitle,
      if (fileTypeLabel != null) 'file_type_label': fileTypeLabel,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (transferredBytes != null) 'transferred_bytes': transferredBytes,
      if (state != null) 'state': state,
      if (peerName != null) 'peer_name': peerName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (failureReason != null) 'failure_reason': failureReason,
      if (note != null) 'note': note,
      if (tempFileName != null) 'temp_file_name': tempFileName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? direction,
    Value<String?>? documentId,
    Value<String>? documentTitle,
    Value<String>? fileTypeLabel,
    Value<int>? sizeBytes,
    Value<int>? transferredBytes,
    Value<String>? state,
    Value<String>? peerName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? failureReason,
    Value<String?>? note,
    Value<String?>? tempFileName,
    Value<int>? rowid,
  }) {
    return TransferEntriesCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      fileTypeLabel: fileTypeLabel ?? this.fileTypeLabel,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      state: state ?? this.state,
      peerName: peerName ?? this.peerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      note: note ?? this.note,
      tempFileName: tempFileName ?? this.tempFileName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (documentTitle.present) {
      map['document_title'] = Variable<String>(documentTitle.value);
    }
    if (fileTypeLabel.present) {
      map['file_type_label'] = Variable<String>(fileTypeLabel.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (transferredBytes.present) {
      map['transferred_bytes'] = Variable<int>(transferredBytes.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (peerName.present) {
      map['peer_name'] = Variable<String>(peerName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (tempFileName.present) {
      map['temp_file_name'] = Variable<String>(tempFileName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferEntriesCompanion(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('documentId: $documentId, ')
          ..write('documentTitle: $documentTitle, ')
          ..write('fileTypeLabel: $fileTypeLabel, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('transferredBytes: $transferredBytes, ')
          ..write('state: $state, ')
          ..write('peerName: $peerName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('failureReason: $failureReason, ')
          ..write('note: $note, ')
          ..write('tempFileName: $tempFileName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $ReadingProgressEntriesTable readingProgressEntries =
      $ReadingProgressEntriesTable(this);
  late final $TransferEntriesTable transferEntries = $TransferEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    readingProgressEntries,
    transferEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('reading_progress_entries', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String title,
      required String author,
      required String originalFileName,
      required String storedFileName,
      required String format,
      required int sizeBytes,
      required DateTime addedAt,
      Value<DateTime?> lastOpenedAt,
      required String sha256,
      Value<String> description,
      Value<String> source,
      Value<String> language,
      Value<int?> pageCount,
      required String coverDesign,
      required String coverPalette,
      Value<bool> isImported,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> author,
      Value<String> originalFileName,
      Value<String> storedFileName,
      Value<String> format,
      Value<int> sizeBytes,
      Value<DateTime> addedAt,
      Value<DateTime?> lastOpenedAt,
      Value<String> sha256,
      Value<String> description,
      Value<String> source,
      Value<String> language,
      Value<int?> pageCount,
      Value<String> coverDesign,
      Value<String> coverPalette,
      Value<bool> isImported,
      Value<int> rowid,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ReadingProgressEntriesTable,
    List<ReadingProgressRow>
  >
  _readingProgressEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.readingProgressEntries,
        aliasName: 'documents__id__reading_progress_entries__document_id',
      );

  $$ReadingProgressEntriesTableProcessedTableManager
  get readingProgressEntriesRefs {
    final manager = $$ReadingProgressEntriesTableTableManager(
      $_db,
      $_db.readingProgressEntries,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingProgressEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedFileName => $composableBuilder(
    column: $table.storedFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverDesign => $composableBuilder(
    column: $table.coverDesign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPalette => $composableBuilder(
    column: $table.coverPalette,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isImported => $composableBuilder(
    column: $table.isImported,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingProgressEntriesRefs(
    Expression<bool> Function($$ReadingProgressEntriesTableFilterComposer f) f,
  ) {
    final $$ReadingProgressEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.readingProgressEntries,
          getReferencedColumn: (t) => t.documentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReadingProgressEntriesTableFilterComposer(
                $db: $db,
                $table: $db.readingProgressEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedFileName => $composableBuilder(
    column: $table.storedFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverDesign => $composableBuilder(
    column: $table.coverDesign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPalette => $composableBuilder(
    column: $table.coverPalette,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isImported => $composableBuilder(
    column: $table.isImported,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storedFileName => $composableBuilder(
    column: $table.storedFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get coverDesign => $composableBuilder(
    column: $table.coverDesign,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverPalette => $composableBuilder(
    column: $table.coverPalette,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isImported => $composableBuilder(
    column: $table.isImported,
    builder: (column) => column,
  );

  Expression<T> readingProgressEntriesRefs<T extends Object>(
    Expression<T> Function($$ReadingProgressEntriesTableAnnotationComposer a) f,
  ) {
    final $$ReadingProgressEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.readingProgressEntries,
          getReferencedColumn: (t) => t.documentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReadingProgressEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.readingProgressEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentRow, $$DocumentsTableReferences),
          DocumentRow,
          PrefetchHooks Function({bool readingProgressEntriesRefs})
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> originalFileName = const Value.absent(),
                Value<String> storedFileName = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<String> coverDesign = const Value.absent(),
                Value<String> coverPalette = const Value.absent(),
                Value<bool> isImported = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                title: title,
                author: author,
                originalFileName: originalFileName,
                storedFileName: storedFileName,
                format: format,
                sizeBytes: sizeBytes,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                sha256: sha256,
                description: description,
                source: source,
                language: language,
                pageCount: pageCount,
                coverDesign: coverDesign,
                coverPalette: coverPalette,
                isImported: isImported,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String author,
                required String originalFileName,
                required String storedFileName,
                required String format,
                required int sizeBytes,
                required DateTime addedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                required String sha256,
                Value<String> description = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                required String coverDesign,
                required String coverPalette,
                Value<bool> isImported = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                title: title,
                author: author,
                originalFileName: originalFileName,
                storedFileName: storedFileName,
                format: format,
                sizeBytes: sizeBytes,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                sha256: sha256,
                description: description,
                source: source,
                language: language,
                pageCount: pageCount,
                coverDesign: coverDesign,
                coverPalette: coverPalette,
                isImported: isImported,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({readingProgressEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (readingProgressEntriesRefs) db.readingProgressEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (readingProgressEntriesRefs)
                    await $_getPrefetchedData<
                      DocumentRow,
                      $DocumentsTable,
                      ReadingProgressRow
                    >(
                      currentTable: table,
                      referencedTable: $$DocumentsTableReferences
                          ._readingProgressEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DocumentsTableReferences(
                            db,
                            table,
                            p0,
                          ).readingProgressEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.documentId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentRow, $$DocumentsTableReferences),
      DocumentRow,
      PrefetchHooks Function({bool readingProgressEntriesRefs})
    >;
typedef $$ReadingProgressEntriesTableCreateCompanionBuilder =
    ReadingProgressEntriesCompanion Function({
      required String documentId,
      Value<double> fraction,
      Value<int> locationIndex,
      Value<double> locationOffset,
      Value<String?> locationRef,
      Value<DateTime?> lastReadAt,
      Value<String> bookmarks,
      Value<int> rowid,
    });
typedef $$ReadingProgressEntriesTableUpdateCompanionBuilder =
    ReadingProgressEntriesCompanion Function({
      Value<String> documentId,
      Value<double> fraction,
      Value<int> locationIndex,
      Value<double> locationOffset,
      Value<String?> locationRef,
      Value<DateTime?> lastReadAt,
      Value<String> bookmarks,
      Value<int> rowid,
    });

final class $$ReadingProgressEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingProgressEntriesTable,
          ReadingProgressRow
        > {
  $$ReadingProgressEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DocumentsTable _documentIdTable(_$AppDatabase db) => db.documents
      .createAlias('reading_progress_entries__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingProgressEntriesTable> {
  $$ReadingProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get fraction => $composableBuilder(
    column: $table.fraction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get locationIndex => $composableBuilder(
    column: $table.locationIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationOffset => $composableBuilder(
    column: $table.locationOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationRef => $composableBuilder(
    column: $table.locationRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookmarks => $composableBuilder(
    column: $table.bookmarks,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingProgressEntriesTable> {
  $$ReadingProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get fraction => $composableBuilder(
    column: $table.fraction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get locationIndex => $composableBuilder(
    column: $table.locationIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationOffset => $composableBuilder(
    column: $table.locationOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationRef => $composableBuilder(
    column: $table.locationRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookmarks => $composableBuilder(
    column: $table.bookmarks,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingProgressEntriesTable> {
  $$ReadingProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get fraction =>
      $composableBuilder(column: $table.fraction, builder: (column) => column);

  GeneratedColumn<int> get locationIndex => $composableBuilder(
    column: $table.locationIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationOffset => $composableBuilder(
    column: $table.locationOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationRef => $composableBuilder(
    column: $table.locationRef,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookmarks =>
      $composableBuilder(column: $table.bookmarks, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingProgressEntriesTable,
          ReadingProgressRow,
          $$ReadingProgressEntriesTableFilterComposer,
          $$ReadingProgressEntriesTableOrderingComposer,
          $$ReadingProgressEntriesTableAnnotationComposer,
          $$ReadingProgressEntriesTableCreateCompanionBuilder,
          $$ReadingProgressEntriesTableUpdateCompanionBuilder,
          (ReadingProgressRow, $$ReadingProgressEntriesTableReferences),
          ReadingProgressRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$ReadingProgressEntriesTableTableManager(
    _$AppDatabase db,
    $ReadingProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ReadingProgressEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReadingProgressEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<double> fraction = const Value.absent(),
                Value<int> locationIndex = const Value.absent(),
                Value<double> locationOffset = const Value.absent(),
                Value<String?> locationRef = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<String> bookmarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressEntriesCompanion(
                documentId: documentId,
                fraction: fraction,
                locationIndex: locationIndex,
                locationOffset: locationOffset,
                locationRef: locationRef,
                lastReadAt: lastReadAt,
                bookmarks: bookmarks,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                Value<double> fraction = const Value.absent(),
                Value<int> locationIndex = const Value.absent(),
                Value<double> locationOffset = const Value.absent(),
                Value<String?> locationRef = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<String> bookmarks = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressEntriesCompanion.insert(
                documentId: documentId,
                fraction: fraction,
                locationIndex: locationIndex,
                locationOffset: locationOffset,
                locationRef: locationRef,
                lastReadAt: lastReadAt,
                bookmarks: bookmarks,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingProgressEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable:
                                    $$ReadingProgressEntriesTableReferences
                                        ._documentIdTable(db),
                                referencedColumn:
                                    $$ReadingProgressEntriesTableReferences
                                        ._documentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingProgressEntriesTable,
      ReadingProgressRow,
      $$ReadingProgressEntriesTableFilterComposer,
      $$ReadingProgressEntriesTableOrderingComposer,
      $$ReadingProgressEntriesTableAnnotationComposer,
      $$ReadingProgressEntriesTableCreateCompanionBuilder,
      $$ReadingProgressEntriesTableUpdateCompanionBuilder,
      (ReadingProgressRow, $$ReadingProgressEntriesTableReferences),
      ReadingProgressRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$TransferEntriesTableCreateCompanionBuilder =
    TransferEntriesCompanion Function({
      required String id,
      required String direction,
      Value<String?> documentId,
      required String documentTitle,
      required String fileTypeLabel,
      required int sizeBytes,
      Value<int> transferredBytes,
      required String state,
      required String peerName,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<String?> failureReason,
      Value<String?> note,
      Value<String?> tempFileName,
      Value<int> rowid,
    });
typedef $$TransferEntriesTableUpdateCompanionBuilder =
    TransferEntriesCompanion Function({
      Value<String> id,
      Value<String> direction,
      Value<String?> documentId,
      Value<String> documentTitle,
      Value<String> fileTypeLabel,
      Value<int> sizeBytes,
      Value<int> transferredBytes,
      Value<String> state,
      Value<String> peerName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<String?> failureReason,
      Value<String?> note,
      Value<String?> tempFileName,
      Value<int> rowid,
    });

class $$TransferEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransferEntriesTable> {
  $$TransferEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentTitle => $composableBuilder(
    column: $table.documentTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileTypeLabel => $composableBuilder(
    column: $table.fileTypeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transferredBytes => $composableBuilder(
    column: $table.transferredBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerName => $composableBuilder(
    column: $table.peerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempFileName => $composableBuilder(
    column: $table.tempFileName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransferEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferEntriesTable> {
  $$TransferEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentTitle => $composableBuilder(
    column: $table.documentTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileTypeLabel => $composableBuilder(
    column: $table.fileTypeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transferredBytes => $composableBuilder(
    column: $table.transferredBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerName => $composableBuilder(
    column: $table.peerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempFileName => $composableBuilder(
    column: $table.tempFileName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferEntriesTable> {
  $$TransferEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentTitle => $composableBuilder(
    column: $table.documentTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileTypeLabel => $composableBuilder(
    column: $table.fileTypeLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get transferredBytes => $composableBuilder(
    column: $table.transferredBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get peerName =>
      $composableBuilder(column: $table.peerName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get tempFileName => $composableBuilder(
    column: $table.tempFileName,
    builder: (column) => column,
  );
}

class $$TransferEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferEntriesTable,
          TransferRow,
          $$TransferEntriesTableFilterComposer,
          $$TransferEntriesTableOrderingComposer,
          $$TransferEntriesTableAnnotationComposer,
          $$TransferEntriesTableCreateCompanionBuilder,
          $$TransferEntriesTableUpdateCompanionBuilder,
          (
            TransferRow,
            BaseReferences<_$AppDatabase, $TransferEntriesTable, TransferRow>,
          ),
          TransferRow,
          PrefetchHooks Function()
        > {
  $$TransferEntriesTableTableManager(
    _$AppDatabase db,
    $TransferEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String?> documentId = const Value.absent(),
                Value<String> documentTitle = const Value.absent(),
                Value<String> fileTypeLabel = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> transferredBytes = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> peerName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tempFileName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferEntriesCompanion(
                id: id,
                direction: direction,
                documentId: documentId,
                documentTitle: documentTitle,
                fileTypeLabel: fileTypeLabel,
                sizeBytes: sizeBytes,
                transferredBytes: transferredBytes,
                state: state,
                peerName: peerName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                failureReason: failureReason,
                note: note,
                tempFileName: tempFileName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String direction,
                Value<String?> documentId = const Value.absent(),
                required String documentTitle,
                required String fileTypeLabel,
                required int sizeBytes,
                Value<int> transferredBytes = const Value.absent(),
                required String state,
                required String peerName,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> tempFileName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferEntriesCompanion.insert(
                id: id,
                direction: direction,
                documentId: documentId,
                documentTitle: documentTitle,
                fileTypeLabel: fileTypeLabel,
                sizeBytes: sizeBytes,
                transferredBytes: transferredBytes,
                state: state,
                peerName: peerName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                failureReason: failureReason,
                note: note,
                tempFileName: tempFileName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransferEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferEntriesTable,
      TransferRow,
      $$TransferEntriesTableFilterComposer,
      $$TransferEntriesTableOrderingComposer,
      $$TransferEntriesTableAnnotationComposer,
      $$TransferEntriesTableCreateCompanionBuilder,
      $$TransferEntriesTableUpdateCompanionBuilder,
      (
        TransferRow,
        BaseReferences<_$AppDatabase, $TransferEntriesTable, TransferRow>,
      ),
      TransferRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$ReadingProgressEntriesTableTableManager get readingProgressEntries =>
      $$ReadingProgressEntriesTableTableManager(
        _db,
        _db.readingProgressEntries,
      );
  $$TransferEntriesTableTableManager get transferEntries =>
      $$TransferEntriesTableTableManager(_db, _db.transferEntries);
}
