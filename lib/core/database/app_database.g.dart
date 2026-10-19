// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LibraryItemsTable extends LibraryItems
    with TableInfo<$LibraryItemsTable, LibraryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($LibraryItemsTable.$convertermediaType);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WatchStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WatchStatus>($LibraryItemsTable.$converterstatus);
  static const VerificationMeta _userRatingMeta = const VerificationMeta(
    'userRating',
  );
  @override
  late final GeneratedColumn<int> userRating = GeneratedColumn<int>(
    'user_rating',
    aliasedName,
    true,
    check: () => ComparableExpr(userRating).isBetweenValues(1, 10),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tmdbId,
    mediaType,
    title,
    originalTitle,
    posterPath,
    overview,
    releaseYear,
    status,
    userRating,
    note,
    addedAt,
    updatedAt,
    watchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('user_rating')) {
      context.handle(
        _userRatingMeta,
        userRating.isAcceptableOrUnknown(data['user_rating']!, _userRatingMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tmdbId, mediaType},
  ];
  @override
  LibraryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      mediaType: $LibraryItemsTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      )!,
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      status: $LibraryItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      userRating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_rating'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      ),
    );
  }

  @override
  $LibraryItemsTable createAlias(String alias) {
    return $LibraryItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
  static JsonTypeConverter2<WatchStatus, String, String> $converterstatus =
      const EnumNameConverter<WatchStatus>(WatchStatus.values);
}

class LibraryItem extends DataClass implements Insertable<LibraryItem> {
  final int id;
  final int tmdbId;
  final MediaType mediaType;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final String overview;
  final int? releaseYear;
  final WatchStatus status;
  final int? userRating;
  final String? note;
  final DateTime addedAt;
  final DateTime updatedAt;
  final DateTime? watchedAt;
  const LibraryItem({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.originalTitle,
    this.posterPath,
    required this.overview,
    this.releaseYear,
    required this.status,
    this.userRating,
    this.note,
    required this.addedAt,
    required this.updatedAt,
    this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tmdb_id'] = Variable<int>(tmdbId);
    {
      map['media_type'] = Variable<String>(
        $LibraryItemsTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['title'] = Variable<String>(title);
    map['original_title'] = Variable<String>(originalTitle);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    map['overview'] = Variable<String>(overview);
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    {
      map['status'] = Variable<String>(
        $LibraryItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || userRating != null) {
      map['user_rating'] = Variable<int>(userRating);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || watchedAt != null) {
      map['watched_at'] = Variable<DateTime>(watchedAt);
    }
    return map;
  }

  LibraryItemsCompanion toCompanion(bool nullToAbsent) {
    return LibraryItemsCompanion(
      id: Value(id),
      tmdbId: Value(tmdbId),
      mediaType: Value(mediaType),
      title: Value(title),
      originalTitle: Value(originalTitle),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      overview: Value(overview),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      status: Value(status),
      userRating: userRating == null && nullToAbsent
          ? const Value.absent()
          : Value(userRating),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      watchedAt: watchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(watchedAt),
    );
  }

  factory LibraryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryItem(
      id: serializer.fromJson<int>(json['id']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      mediaType: $LibraryItemsTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String>(json['originalTitle']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      overview: serializer.fromJson<String>(json['overview']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      status: $LibraryItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      userRating: serializer.fromJson<int?>(json['userRating']),
      note: serializer.fromJson<String?>(json['note']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      watchedAt: serializer.fromJson<DateTime?>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'mediaType': serializer.toJson<String>(
        $LibraryItemsTable.$convertermediaType.toJson(mediaType),
      ),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String>(originalTitle),
      'posterPath': serializer.toJson<String?>(posterPath),
      'overview': serializer.toJson<String>(overview),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'status': serializer.toJson<String>(
        $LibraryItemsTable.$converterstatus.toJson(status),
      ),
      'userRating': serializer.toJson<int?>(userRating),
      'note': serializer.toJson<String?>(note),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'watchedAt': serializer.toJson<DateTime?>(watchedAt),
    };
  }

  LibraryItem copyWith({
    int? id,
    int? tmdbId,
    MediaType? mediaType,
    String? title,
    String? originalTitle,
    Value<String?> posterPath = const Value.absent(),
    String? overview,
    Value<int?> releaseYear = const Value.absent(),
    WatchStatus? status,
    Value<int?> userRating = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? addedAt,
    DateTime? updatedAt,
    Value<DateTime?> watchedAt = const Value.absent(),
  }) => LibraryItem(
    id: id ?? this.id,
    tmdbId: tmdbId ?? this.tmdbId,
    mediaType: mediaType ?? this.mediaType,
    title: title ?? this.title,
    originalTitle: originalTitle ?? this.originalTitle,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    overview: overview ?? this.overview,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    status: status ?? this.status,
    userRating: userRating.present ? userRating.value : this.userRating,
    note: note.present ? note.value : this.note,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    watchedAt: watchedAt.present ? watchedAt.value : this.watchedAt,
  );
  LibraryItem copyWithCompanion(LibraryItemsCompanion data) {
    return LibraryItem(
      id: data.id.present ? data.id.value : this.id,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      overview: data.overview.present ? data.overview.value : this.overview,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      status: data.status.present ? data.status.value : this.status,
      userRating: data.userRating.present
          ? data.userRating.value
          : this.userRating,
      note: data.note.present ? data.note.value : this.note,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItem(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('posterPath: $posterPath, ')
          ..write('overview: $overview, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('note: $note, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tmdbId,
    mediaType,
    title,
    originalTitle,
    posterPath,
    overview,
    releaseYear,
    status,
    userRating,
    note,
    addedAt,
    updatedAt,
    watchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryItem &&
          other.id == this.id &&
          other.tmdbId == this.tmdbId &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.posterPath == this.posterPath &&
          other.overview == this.overview &&
          other.releaseYear == this.releaseYear &&
          other.status == this.status &&
          other.userRating == this.userRating &&
          other.note == this.note &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.watchedAt == this.watchedAt);
}

class LibraryItemsCompanion extends UpdateCompanion<LibraryItem> {
  final Value<int> id;
  final Value<int> tmdbId;
  final Value<MediaType> mediaType;
  final Value<String> title;
  final Value<String> originalTitle;
  final Value<String?> posterPath;
  final Value<String> overview;
  final Value<int?> releaseYear;
  final Value<WatchStatus> status;
  final Value<int?> userRating;
  final Value<String?> note;
  final Value<DateTime> addedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> watchedAt;
  const LibraryItemsCompanion({
    this.id = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.status = const Value.absent(),
    this.userRating = const Value.absent(),
    this.note = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.watchedAt = const Value.absent(),
  });
  LibraryItemsCompanion.insert({
    this.id = const Value.absent(),
    required int tmdbId,
    required MediaType mediaType,
    required String title,
    this.originalTitle = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.releaseYear = const Value.absent(),
    required WatchStatus status,
    this.userRating = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime addedAt,
    required DateTime updatedAt,
    this.watchedAt = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       mediaType = Value(mediaType),
       title = Value(title),
       status = Value(status),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LibraryItem> custom({
    Expression<int>? id,
    Expression<int>? tmdbId,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? posterPath,
    Expression<String>? overview,
    Expression<int>? releaseYear,
    Expression<String>? status,
    Expression<int>? userRating,
    Expression<String>? note,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? watchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (posterPath != null) 'poster_path': posterPath,
      if (overview != null) 'overview': overview,
      if (releaseYear != null) 'release_year': releaseYear,
      if (status != null) 'status': status,
      if (userRating != null) 'user_rating': userRating,
      if (note != null) 'note': note,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (watchedAt != null) 'watched_at': watchedAt,
    });
  }

  LibraryItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? tmdbId,
    Value<MediaType>? mediaType,
    Value<String>? title,
    Value<String>? originalTitle,
    Value<String?>? posterPath,
    Value<String>? overview,
    Value<int?>? releaseYear,
    Value<WatchStatus>? status,
    Value<int?>? userRating,
    Value<String?>? note,
    Value<DateTime>? addedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? watchedAt,
  }) {
    return LibraryItemsCompanion(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      posterPath: posterPath ?? this.posterPath,
      overview: overview ?? this.overview,
      releaseYear: releaseYear ?? this.releaseYear,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      note: note ?? this.note,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $LibraryItemsTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $LibraryItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (userRating.present) {
      map['user_rating'] = Variable<int>(userRating.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItemsCompanion(')
          ..write('id: $id, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('posterPath: $posterPath, ')
          ..write('overview: $overview, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('status: $status, ')
          ..write('userRating: $userRating, ')
          ..write('note: $note, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemGenresTable extends ItemGenres
    with TableInfo<$ItemGenresTable, ItemGenre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemGenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _genreIdMeta = const VerificationMeta(
    'genreId',
  );
  @override
  late final GeneratedColumn<int> genreId = GeneratedColumn<int>(
    'genre_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreNameMeta = const VerificationMeta(
    'genreName',
  );
  @override
  late final GeneratedColumn<String> genreName = GeneratedColumn<String>(
    'genre_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, genreId, genreName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_genres';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemGenre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('genre_id')) {
      context.handle(
        _genreIdMeta,
        genreId.isAcceptableOrUnknown(data['genre_id']!, _genreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_genreIdMeta);
    }
    if (data.containsKey('genre_name')) {
      context.handle(
        _genreNameMeta,
        genreName.isAcceptableOrUnknown(data['genre_name']!, _genreNameMeta),
      );
    } else if (isInserting) {
      context.missing(_genreNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, genreId};
  @override
  ItemGenre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemGenre(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      genreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}genre_id'],
      )!,
      genreName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre_name'],
      )!,
    );
  }

  @override
  $ItemGenresTable createAlias(String alias) {
    return $ItemGenresTable(attachedDatabase, alias);
  }
}

class ItemGenre extends DataClass implements Insertable<ItemGenre> {
  final int itemId;
  final int genreId;
  final String genreName;
  const ItemGenre({
    required this.itemId,
    required this.genreId,
    required this.genreName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['genre_id'] = Variable<int>(genreId);
    map['genre_name'] = Variable<String>(genreName);
    return map;
  }

  ItemGenresCompanion toCompanion(bool nullToAbsent) {
    return ItemGenresCompanion(
      itemId: Value(itemId),
      genreId: Value(genreId),
      genreName: Value(genreName),
    );
  }

  factory ItemGenre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemGenre(
      itemId: serializer.fromJson<int>(json['itemId']),
      genreId: serializer.fromJson<int>(json['genreId']),
      genreName: serializer.fromJson<String>(json['genreName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'genreId': serializer.toJson<int>(genreId),
      'genreName': serializer.toJson<String>(genreName),
    };
  }

  ItemGenre copyWith({int? itemId, int? genreId, String? genreName}) =>
      ItemGenre(
        itemId: itemId ?? this.itemId,
        genreId: genreId ?? this.genreId,
        genreName: genreName ?? this.genreName,
      );
  ItemGenre copyWithCompanion(ItemGenresCompanion data) {
    return ItemGenre(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
      genreName: data.genreName.present ? data.genreName.value : this.genreName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemGenre(')
          ..write('itemId: $itemId, ')
          ..write('genreId: $genreId, ')
          ..write('genreName: $genreName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, genreId, genreName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemGenre &&
          other.itemId == this.itemId &&
          other.genreId == this.genreId &&
          other.genreName == this.genreName);
}

class ItemGenresCompanion extends UpdateCompanion<ItemGenre> {
  final Value<int> itemId;
  final Value<int> genreId;
  final Value<String> genreName;
  final Value<int> rowid;
  const ItemGenresCompanion({
    this.itemId = const Value.absent(),
    this.genreId = const Value.absent(),
    this.genreName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemGenresCompanion.insert({
    required int itemId,
    required int genreId,
    required String genreName,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       genreId = Value(genreId),
       genreName = Value(genreName);
  static Insertable<ItemGenre> custom({
    Expression<int>? itemId,
    Expression<int>? genreId,
    Expression<String>? genreName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (genreId != null) 'genre_id': genreId,
      if (genreName != null) 'genre_name': genreName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemGenresCompanion copyWith({
    Value<int>? itemId,
    Value<int>? genreId,
    Value<String>? genreName,
    Value<int>? rowid,
  }) {
    return ItemGenresCompanion(
      itemId: itemId ?? this.itemId,
      genreId: genreId ?? this.genreId,
      genreName: genreName ?? this.genreName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (genreId.present) {
      map['genre_id'] = Variable<int>(genreId.value);
    }
    if (genreName.present) {
      map['genre_name'] = Variable<String>(genreName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemGenresCompanion(')
          ..write('itemId: $itemId, ')
          ..write('genreId: $genreId, ')
          ..write('genreName: $genreName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TvSeasonsTable extends TvSeasons
    with TableInfo<$TvSeasonsTable, TvSeason> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TvSeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeCountMeta = const VerificationMeta(
    'episodeCount',
  );
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
    'episode_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    seasonNumber,
    episodeCount,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tv_seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<TvSeason> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_count')) {
      context.handle(
        _episodeCountMeta,
        episodeCount.isAcceptableOrUnknown(
          data['episode_count']!,
          _episodeCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeCountMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, seasonNumber};
  @override
  TvSeason map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TvSeason(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      episodeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_count'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TvSeasonsTable createAlias(String alias) {
    return $TvSeasonsTable(attachedDatabase, alias);
  }
}

class TvSeason extends DataClass implements Insertable<TvSeason> {
  final int itemId;
  final int seasonNumber;
  final int episodeCount;
  final String name;
  const TvSeason({
    required this.itemId,
    required this.seasonNumber,
    required this.episodeCount,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_count'] = Variable<int>(episodeCount);
    map['name'] = Variable<String>(name);
    return map;
  }

  TvSeasonsCompanion toCompanion(bool nullToAbsent) {
    return TvSeasonsCompanion(
      itemId: Value(itemId),
      seasonNumber: Value(seasonNumber),
      episodeCount: Value(episodeCount),
      name: Value(name),
    );
  }

  factory TvSeason.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TvSeason(
      itemId: serializer.fromJson<int>(json['itemId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeCount: serializer.fromJson<int>(json['episodeCount']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeCount': serializer.toJson<int>(episodeCount),
      'name': serializer.toJson<String>(name),
    };
  }

  TvSeason copyWith({
    int? itemId,
    int? seasonNumber,
    int? episodeCount,
    String? name,
  }) => TvSeason(
    itemId: itemId ?? this.itemId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    episodeCount: episodeCount ?? this.episodeCount,
    name: name ?? this.name,
  );
  TvSeason copyWithCompanion(TvSeasonsCompanion data) {
    return TvSeason(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TvSeason(')
          ..write('itemId: $itemId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, seasonNumber, episodeCount, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TvSeason &&
          other.itemId == this.itemId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeCount == this.episodeCount &&
          other.name == this.name);
}

class TvSeasonsCompanion extends UpdateCompanion<TvSeason> {
  final Value<int> itemId;
  final Value<int> seasonNumber;
  final Value<int> episodeCount;
  final Value<String> name;
  final Value<int> rowid;
  const TvSeasonsCompanion({
    this.itemId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TvSeasonsCompanion.insert({
    required int itemId,
    required int seasonNumber,
    required int episodeCount,
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       seasonNumber = Value(seasonNumber),
       episodeCount = Value(episodeCount);
  static Insertable<TvSeason> custom({
    Expression<int>? itemId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeCount,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeCount != null) 'episode_count': episodeCount,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TvSeasonsCompanion copyWith({
    Value<int>? itemId,
    Value<int>? seasonNumber,
    Value<int>? episodeCount,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TvSeasonsCompanion(
      itemId: itemId ?? this.itemId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeCount: episodeCount ?? this.episodeCount,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TvSeasonsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchedEpisodesTable extends WatchedEpisodes
    with TableInfo<$WatchedEpisodesTable, WatchedEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchedEpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    seasonNumber,
    episodeNumber,
    watchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watched_episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchedEpisode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_watchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, seasonNumber, episodeNumber};
  @override
  WatchedEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchedEpisode(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $WatchedEpisodesTable createAlias(String alias) {
    return $WatchedEpisodesTable(attachedDatabase, alias);
  }
}

class WatchedEpisode extends DataClass implements Insertable<WatchedEpisode> {
  final int itemId;
  final int seasonNumber;
  final int episodeNumber;
  final DateTime watchedAt;
  const WatchedEpisode({
    required this.itemId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<int>(itemId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  WatchedEpisodesCompanion toCompanion(bool nullToAbsent) {
    return WatchedEpisodesCompanion(
      itemId: Value(itemId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      watchedAt: Value(watchedAt),
    );
  }

  factory WatchedEpisode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchedEpisode(
      itemId: serializer.fromJson<int>(json['itemId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<int>(itemId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  WatchedEpisode copyWith({
    int? itemId,
    int? seasonNumber,
    int? episodeNumber,
    DateTime? watchedAt,
  }) => WatchedEpisode(
    itemId: itemId ?? this.itemId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  WatchedEpisode copyWithCompanion(WatchedEpisodesCompanion data) {
    return WatchedEpisode(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchedEpisode(')
          ..write('itemId: $itemId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemId, seasonNumber, episodeNumber, watchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchedEpisode &&
          other.itemId == this.itemId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.watchedAt == this.watchedAt);
}

class WatchedEpisodesCompanion extends UpdateCompanion<WatchedEpisode> {
  final Value<int> itemId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<DateTime> watchedAt;
  final Value<int> rowid;
  const WatchedEpisodesCompanion({
    this.itemId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchedEpisodesCompanion.insert({
    required int itemId,
    required int seasonNumber,
    required int episodeNumber,
    required DateTime watchedAt,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       seasonNumber = Value(seasonNumber),
       episodeNumber = Value(episodeNumber),
       watchedAt = Value(watchedAt);
  static Insertable<WatchedEpisode> custom({
    Expression<int>? itemId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<DateTime>? watchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchedEpisodesCompanion copyWith({
    Value<int>? itemId,
    Value<int>? seasonNumber,
    Value<int>? episodeNumber,
    Value<DateTime>? watchedAt,
    Value<int>? rowid,
  }) {
    return WatchedEpisodesCompanion(
      itemId: itemId ?? this.itemId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      watchedAt: watchedAt ?? this.watchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchedEpisodesCompanion(')
          ..write('itemId: $itemId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String name;
  final String value;
  const AppSetting({required this.name, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(name: Value(name), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? name, String? value}) =>
      AppSetting(name: name ?? this.name, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('name: $name, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.name == this.name &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> name;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String name,
    required String value,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? name,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? name,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      name: name ?? this.name,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LibraryItemsTable libraryItems = $LibraryItemsTable(this);
  late final $ItemGenresTable itemGenres = $ItemGenresTable(this);
  late final $TvSeasonsTable tvSeasons = $TvSeasonsTable(this);
  late final $WatchedEpisodesTable watchedEpisodes = $WatchedEpisodesTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryItems,
    itemGenres,
    tvSeasons,
    watchedEpisodes,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_genres', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tv_seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('watched_episodes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LibraryItemsTableCreateCompanionBuilder =
    LibraryItemsCompanion Function({
      Value<int> id,
      required int tmdbId,
      required MediaType mediaType,
      required String title,
      Value<String> originalTitle,
      Value<String?> posterPath,
      Value<String> overview,
      Value<int?> releaseYear,
      required WatchStatus status,
      Value<int?> userRating,
      Value<String?> note,
      required DateTime addedAt,
      required DateTime updatedAt,
      Value<DateTime?> watchedAt,
    });
typedef $$LibraryItemsTableUpdateCompanionBuilder =
    LibraryItemsCompanion Function({
      Value<int> id,
      Value<int> tmdbId,
      Value<MediaType> mediaType,
      Value<String> title,
      Value<String> originalTitle,
      Value<String?> posterPath,
      Value<String> overview,
      Value<int?> releaseYear,
      Value<WatchStatus> status,
      Value<int?> userRating,
      Value<String?> note,
      Value<DateTime> addedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> watchedAt,
    });

final class $$LibraryItemsTableReferences
    extends BaseReferences<_$AppDatabase, $LibraryItemsTable, LibraryItem> {
  $$LibraryItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemGenresTable, List<ItemGenre>>
  _itemGenresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemGenres,
    aliasName: 'library_items__id__item_genres__item_id',
  );

  $$ItemGenresTableProcessedTableManager get itemGenresRefs {
    final manager = $$ItemGenresTableTableManager(
      $_db,
      $_db.itemGenres,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemGenresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TvSeasonsTable, List<TvSeason>>
  _tvSeasonsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tvSeasons,
    aliasName: 'library_items__id__tv_seasons__item_id',
  );

  $$TvSeasonsTableProcessedTableManager get tvSeasonsRefs {
    final manager = $$TvSeasonsTableTableManager(
      $_db,
      $_db.tvSeasons,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tvSeasonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WatchedEpisodesTable, List<WatchedEpisode>>
  _watchedEpisodesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchedEpisodes,
    aliasName: 'library_items__id__watched_episodes__item_id',
  );

  $$WatchedEpisodesTableProcessedTableManager get watchedEpisodesRefs {
    final manager = $$WatchedEpisodesTableTableManager(
      $_db,
      $_db.watchedEpisodes,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _watchedEpisodesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryItemsTable> {
  $$LibraryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WatchStatus, WatchStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get userRating => $composableBuilder(
    column: $table.userRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemGenresRefs(
    Expression<bool> Function($$ItemGenresTableFilterComposer f) f,
  ) {
    final $$ItemGenresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemGenres,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemGenresTableFilterComposer(
            $db: $db,
            $table: $db.itemGenres,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tvSeasonsRefs(
    Expression<bool> Function($$TvSeasonsTableFilterComposer f) f,
  ) {
    final $$TvSeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tvSeasons,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvSeasonsTableFilterComposer(
            $db: $db,
            $table: $db.tvSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> watchedEpisodesRefs(
    Expression<bool> Function($$WatchedEpisodesTableFilterComposer f) f,
  ) {
    final $$WatchedEpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchedEpisodes,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchedEpisodesTableFilterComposer(
            $db: $db,
            $table: $db.watchedEpisodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryItemsTable> {
  $$LibraryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userRating => $composableBuilder(
    column: $table.userRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryItemsTable> {
  $$LibraryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WatchStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get userRating => $composableBuilder(
    column: $table.userRating,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  Expression<T> itemGenresRefs<T extends Object>(
    Expression<T> Function($$ItemGenresTableAnnotationComposer a) f,
  ) {
    final $$ItemGenresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemGenres,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemGenresTableAnnotationComposer(
            $db: $db,
            $table: $db.itemGenres,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tvSeasonsRefs<T extends Object>(
    Expression<T> Function($$TvSeasonsTableAnnotationComposer a) f,
  ) {
    final $$TvSeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tvSeasons,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvSeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.tvSeasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> watchedEpisodesRefs<T extends Object>(
    Expression<T> Function($$WatchedEpisodesTableAnnotationComposer a) f,
  ) {
    final $$WatchedEpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchedEpisodes,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchedEpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.watchedEpisodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryItemsTable,
          LibraryItem,
          $$LibraryItemsTableFilterComposer,
          $$LibraryItemsTableOrderingComposer,
          $$LibraryItemsTableAnnotationComposer,
          $$LibraryItemsTableCreateCompanionBuilder,
          $$LibraryItemsTableUpdateCompanionBuilder,
          (LibraryItem, $$LibraryItemsTableReferences),
          LibraryItem,
          PrefetchHooks Function({
            bool itemGenresRefs,
            bool tvSeasonsRefs,
            bool watchedEpisodesRefs,
          })
        > {
  $$LibraryItemsTableTableManager(_$AppDatabase db, $LibraryItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tmdbId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> originalTitle = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String> overview = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<WatchStatus> status = const Value.absent(),
                Value<int?> userRating = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> watchedAt = const Value.absent(),
              }) => LibraryItemsCompanion(
                id: id,
                tmdbId: tmdbId,
                mediaType: mediaType,
                title: title,
                originalTitle: originalTitle,
                posterPath: posterPath,
                overview: overview,
                releaseYear: releaseYear,
                status: status,
                userRating: userRating,
                note: note,
                addedAt: addedAt,
                updatedAt: updatedAt,
                watchedAt: watchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tmdbId,
                required MediaType mediaType,
                required String title,
                Value<String> originalTitle = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String> overview = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                required WatchStatus status,
                Value<int?> userRating = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime addedAt,
                required DateTime updatedAt,
                Value<DateTime?> watchedAt = const Value.absent(),
              }) => LibraryItemsCompanion.insert(
                id: id,
                tmdbId: tmdbId,
                mediaType: mediaType,
                title: title,
                originalTitle: originalTitle,
                posterPath: posterPath,
                overview: overview,
                releaseYear: releaseYear,
                status: status,
                userRating: userRating,
                note: note,
                addedAt: addedAt,
                updatedAt: updatedAt,
                watchedAt: watchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryItemsTable, LibraryItem>(table),
                  $$LibraryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                itemGenresRefs = false,
                tvSeasonsRefs = false,
                watchedEpisodesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemGenresRefs) db.itemGenres,
                    if (tvSeasonsRefs) db.tvSeasons,
                    if (watchedEpisodesRefs) db.watchedEpisodes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemGenresRefs)
                        await $_getPrefetchedData<
                          LibraryItem,
                          $LibraryItemsTable,
                          ItemGenre
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryItemsTableReferences
                              ._itemGenresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemGenresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tvSeasonsRefs)
                        await $_getPrefetchedData<
                          LibraryItem,
                          $LibraryItemsTable,
                          TvSeason
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryItemsTableReferences
                              ._tvSeasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).tvSeasonsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (watchedEpisodesRefs)
                        await $_getPrefetchedData<
                          LibraryItem,
                          $LibraryItemsTable,
                          WatchedEpisode
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryItemsTableReferences
                              ._watchedEpisodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).watchedEpisodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LibraryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryItemsTable,
      LibraryItem,
      $$LibraryItemsTableFilterComposer,
      $$LibraryItemsTableOrderingComposer,
      $$LibraryItemsTableAnnotationComposer,
      $$LibraryItemsTableCreateCompanionBuilder,
      $$LibraryItemsTableUpdateCompanionBuilder,
      (LibraryItem, $$LibraryItemsTableReferences),
      LibraryItem,
      PrefetchHooks Function({
        bool itemGenresRefs,
        bool tvSeasonsRefs,
        bool watchedEpisodesRefs,
      })
    >;
typedef $$ItemGenresTableCreateCompanionBuilder = ItemGenresCompanion Function({
  required int itemId,
  required int genreId,
  required String genreName,
  Value<int> rowid,
});
typedef $$ItemGenresTableUpdateCompanionBuilder = ItemGenresCompanion Function({
  Value<int> itemId,
  Value<int> genreId,
  Value<String> genreName,
  Value<int> rowid,
});

final class $$ItemGenresTableReferences
    extends BaseReferences<_$AppDatabase, $ItemGenresTable, ItemGenre> {
  $$ItemGenresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryItemsTable _itemIdTable(_$AppDatabase db) =>
      db.libraryItems.createAlias('item_genres__item_id__library_items__id');

  $$LibraryItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$LibraryItemsTableTableManager(
      $_db,
      $_db.libraryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemGenresTableFilterComposer
    extends Composer<_$AppDatabase, $ItemGenresTable> {
  $$ItemGenresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genreName => $composableBuilder(
    column: $table.genreName,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryItemsTableFilterComposer get itemId {
    final $$LibraryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableFilterComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemGenresTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemGenresTable> {
  $$ItemGenresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genreName => $composableBuilder(
    column: $table.genreName,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryItemsTableOrderingComposer get itemId {
    final $$LibraryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemGenresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemGenresTable> {
  $$ItemGenresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get genreId =>
      $composableBuilder(column: $table.genreId, builder: (column) => column);

  GeneratedColumn<String> get genreName =>
      $composableBuilder(column: $table.genreName, builder: (column) => column);

  $$LibraryItemsTableAnnotationComposer get itemId {
    final $$LibraryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemGenresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemGenresTable,
          ItemGenre,
          $$ItemGenresTableFilterComposer,
          $$ItemGenresTableOrderingComposer,
          $$ItemGenresTableAnnotationComposer,
          $$ItemGenresTableCreateCompanionBuilder,
          $$ItemGenresTableUpdateCompanionBuilder,
          (ItemGenre, $$ItemGenresTableReferences),
          ItemGenre,
          PrefetchHooks Function({bool itemId})
        > {
  $$ItemGenresTableTableManager(_$AppDatabase db, $ItemGenresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemGenresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemGenresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemGenresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> itemId = const Value.absent(),
                Value<int> genreId = const Value.absent(),
                Value<String> genreName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemGenresCompanion(
                itemId: itemId,
                genreId: genreId,
                genreName: genreName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int itemId,
                required int genreId,
                required String genreName,
                Value<int> rowid = const Value.absent(),
              }) => ItemGenresCompanion.insert(
                itemId: itemId,
                genreId: genreId,
                genreName: genreName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemGenresTable, ItemGenre>(table),
                  $$ItemGenresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ItemGenresTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ItemGenresTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ItemGenresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemGenresTable,
      ItemGenre,
      $$ItemGenresTableFilterComposer,
      $$ItemGenresTableOrderingComposer,
      $$ItemGenresTableAnnotationComposer,
      $$ItemGenresTableCreateCompanionBuilder,
      $$ItemGenresTableUpdateCompanionBuilder,
      (ItemGenre, $$ItemGenresTableReferences),
      ItemGenre,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$TvSeasonsTableCreateCompanionBuilder = TvSeasonsCompanion Function({
  required int itemId,
  required int seasonNumber,
  required int episodeCount,
  Value<String> name,
  Value<int> rowid,
});
typedef $$TvSeasonsTableUpdateCompanionBuilder = TvSeasonsCompanion Function({
  Value<int> itemId,
  Value<int> seasonNumber,
  Value<int> episodeCount,
  Value<String> name,
  Value<int> rowid,
});

final class $$TvSeasonsTableReferences
    extends BaseReferences<_$AppDatabase, $TvSeasonsTable, TvSeason> {
  $$TvSeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryItemsTable _itemIdTable(_$AppDatabase db) =>
      db.libraryItems.createAlias('tv_seasons__item_id__library_items__id');

  $$LibraryItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$LibraryItemsTableTableManager(
      $_db,
      $_db.libraryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TvSeasonsTableFilterComposer
    extends Composer<_$AppDatabase, $TvSeasonsTable> {
  $$TvSeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryItemsTableFilterComposer get itemId {
    final $$LibraryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableFilterComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TvSeasonsTableOrderingComposer
    extends Composer<_$AppDatabase, $TvSeasonsTable> {
  $$TvSeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryItemsTableOrderingComposer get itemId {
    final $$LibraryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TvSeasonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TvSeasonsTable> {
  $$TvSeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeCount => $composableBuilder(
    column: $table.episodeCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$LibraryItemsTableAnnotationComposer get itemId {
    final $$LibraryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TvSeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TvSeasonsTable,
          TvSeason,
          $$TvSeasonsTableFilterComposer,
          $$TvSeasonsTableOrderingComposer,
          $$TvSeasonsTableAnnotationComposer,
          $$TvSeasonsTableCreateCompanionBuilder,
          $$TvSeasonsTableUpdateCompanionBuilder,
          (TvSeason, $$TvSeasonsTableReferences),
          TvSeason,
          PrefetchHooks Function({bool itemId})
        > {
  $$TvSeasonsTableTableManager(_$AppDatabase db, $TvSeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TvSeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TvSeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TvSeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> itemId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeCount = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TvSeasonsCompanion(
                itemId: itemId,
                seasonNumber: seasonNumber,
                episodeCount: episodeCount,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int itemId,
                required int seasonNumber,
                required int episodeCount,
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TvSeasonsCompanion.insert(
                itemId: itemId,
                seasonNumber: seasonNumber,
                episodeCount: episodeCount,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TvSeasonsTable, TvSeason>(table),
                  $$TvSeasonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$TvSeasonsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$TvSeasonsTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TvSeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TvSeasonsTable,
      TvSeason,
      $$TvSeasonsTableFilterComposer,
      $$TvSeasonsTableOrderingComposer,
      $$TvSeasonsTableAnnotationComposer,
      $$TvSeasonsTableCreateCompanionBuilder,
      $$TvSeasonsTableUpdateCompanionBuilder,
      (TvSeason, $$TvSeasonsTableReferences),
      TvSeason,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$WatchedEpisodesTableCreateCompanionBuilder =
    WatchedEpisodesCompanion Function({
      required int itemId,
      required int seasonNumber,
      required int episodeNumber,
      required DateTime watchedAt,
      Value<int> rowid,
    });
typedef $$WatchedEpisodesTableUpdateCompanionBuilder =
    WatchedEpisodesCompanion Function({
      Value<int> itemId,
      Value<int> seasonNumber,
      Value<int> episodeNumber,
      Value<DateTime> watchedAt,
      Value<int> rowid,
    });

final class $$WatchedEpisodesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WatchedEpisodesTable, WatchedEpisode> {
  $$WatchedEpisodesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LibraryItemsTable _itemIdTable(_$AppDatabase db) => db.libraryItems
      .createAlias('watched_episodes__item_id__library_items__id');

  $$LibraryItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$LibraryItemsTableTableManager(
      $_db,
      $_db.libraryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WatchedEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchedEpisodesTable> {
  $$WatchedEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryItemsTableFilterComposer get itemId {
    final $$LibraryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableFilterComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchedEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchedEpisodesTable> {
  $$WatchedEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryItemsTableOrderingComposer get itemId {
    final $$LibraryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchedEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchedEpisodesTable> {
  $$WatchedEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);

  $$LibraryItemsTableAnnotationComposer get itemId {
    final $$LibraryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.libraryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchedEpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchedEpisodesTable,
          WatchedEpisode,
          $$WatchedEpisodesTableFilterComposer,
          $$WatchedEpisodesTableOrderingComposer,
          $$WatchedEpisodesTableAnnotationComposer,
          $$WatchedEpisodesTableCreateCompanionBuilder,
          $$WatchedEpisodesTableUpdateCompanionBuilder,
          (WatchedEpisode, $$WatchedEpisodesTableReferences),
          WatchedEpisode,
          PrefetchHooks Function({bool itemId})
        > {
  $$WatchedEpisodesTableTableManager(
    _$AppDatabase db,
    $WatchedEpisodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchedEpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchedEpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchedEpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> itemId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedEpisodesCompanion(
                itemId: itemId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                watchedAt: watchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int itemId,
                required int seasonNumber,
                required int episodeNumber,
                required DateTime watchedAt,
                Value<int> rowid = const Value.absent(),
              }) => WatchedEpisodesCompanion.insert(
                itemId: itemId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                watchedAt: watchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WatchedEpisodesTable, WatchedEpisode>(table),
                  $$WatchedEpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$WatchedEpisodesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$WatchedEpisodesTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$WatchedEpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchedEpisodesTable,
      WatchedEpisode,
      $$WatchedEpisodesTableFilterComposer,
      $$WatchedEpisodesTableOrderingComposer,
      $$WatchedEpisodesTableAnnotationComposer,
      $$WatchedEpisodesTableCreateCompanionBuilder,
      $$WatchedEpisodesTableUpdateCompanionBuilder,
      (WatchedEpisode, $$WatchedEpisodesTableReferences),
      WatchedEpisode,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String name,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> name,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(name: name, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String name,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                name: name,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LibraryItemsTableTableManager get libraryItems =>
      $$LibraryItemsTableTableManager(_db, _db.libraryItems);
  $$ItemGenresTableTableManager get itemGenres =>
      $$ItemGenresTableTableManager(_db, _db.itemGenres);
  $$TvSeasonsTableTableManager get tvSeasons =>
      $$TvSeasonsTableTableManager(_db, _db.tvSeasons);
  $$WatchedEpisodesTableTableManager get watchedEpisodes =>
      $$WatchedEpisodesTableTableManager(_db, _db.watchedEpisodes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
