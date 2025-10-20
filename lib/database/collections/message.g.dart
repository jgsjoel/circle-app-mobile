// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageCollectionCollection on Isar {
  IsarCollection<MessageCollection> get messageCollections => this.collection();
}

const MessageCollectionSchema = CollectionSchema(
  name: r'MessageCollection',
  id: -7394621338610000233,
  properties: {
    r'fromMe': PropertySchema(
      id: 0,
      name: r'fromMe',
      type: IsarType.bool,
    ),
    r'message': PropertySchema(
      id: 1,
      name: r'message',
      type: IsarType.string,
    ),
    r'msgPubId': PropertySchema(
      id: 2,
      name: r'msgPubId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 3,
      name: r'status',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 4,
      name: r'timestamp',
      type: IsarType.long,
    )
  },
  estimateSize: _messageCollectionEstimateSize,
  serialize: _messageCollectionSerialize,
  deserialize: _messageCollectionDeserialize,
  deserializeProp: _messageCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'chat': LinkSchema(
      id: 5998315199696215740,
      name: r'chat',
      target: r'ChatCollection',
      single: true,
    ),
    r'mediaFiles': LinkSchema(
      id: 2338330675270120693,
      name: r'mediaFiles',
      target: r'MediaFileCollection',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _messageCollectionGetId,
  getLinks: _messageCollectionGetLinks,
  attach: _messageCollectionAttach,
  version: '3.1.0+1',
);

int _messageCollectionEstimateSize(
  MessageCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.message.length * 3;
  {
    final value = object.msgPubId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.status;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _messageCollectionSerialize(
  MessageCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.fromMe);
  writer.writeString(offsets[1], object.message);
  writer.writeString(offsets[2], object.msgPubId);
  writer.writeString(offsets[3], object.status);
  writer.writeLong(offsets[4], object.timestamp);
}

MessageCollection _messageCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MessageCollection();
  object.fromMe = reader.readBool(offsets[0]);
  object.id = id;
  object.message = reader.readString(offsets[1]);
  object.msgPubId = reader.readStringOrNull(offsets[2]);
  object.status = reader.readStringOrNull(offsets[3]);
  object.timestamp = reader.readLong(offsets[4]);
  return object;
}

P _messageCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _messageCollectionGetId(MessageCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messageCollectionGetLinks(
    MessageCollection object) {
  return [object.chat, object.mediaFiles];
}

void _messageCollectionAttach(
    IsarCollection<dynamic> col, Id id, MessageCollection object) {
  object.id = id;
  object.chat.attach(col, col.isar.collection<ChatCollection>(), r'chat', id);
  object.mediaFiles.attach(
      col, col.isar.collection<MediaFileCollection>(), r'mediaFiles', id);
}

extension MessageCollectionQueryWhereSort
    on QueryBuilder<MessageCollection, MessageCollection, QWhere> {
  QueryBuilder<MessageCollection, MessageCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MessageCollectionQueryWhere
    on QueryBuilder<MessageCollection, MessageCollection, QWhereClause> {
  QueryBuilder<MessageCollection, MessageCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MessageCollectionQueryFilter
    on QueryBuilder<MessageCollection, MessageCollection, QFilterCondition> {
  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      fromMeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fromMe',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'msgPubId',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'msgPubId',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'msgPubId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'msgPubId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'msgPubId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'msgPubId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'msgPubId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'msgPubId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'msgPubId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'msgPubId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'msgPubId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      msgPubIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'msgPubId',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'status',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      timestampEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      timestampGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      timestampLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      timestampBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MessageCollectionQueryObject
    on QueryBuilder<MessageCollection, MessageCollection, QFilterCondition> {}

extension MessageCollectionQueryLinks
    on QueryBuilder<MessageCollection, MessageCollection, QFilterCondition> {
  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      chat(FilterQuery<ChatCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'chat');
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      chatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chat', 0, true, 0, true);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFiles(FilterQuery<MediaFileCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'mediaFiles');
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFilesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'mediaFiles', length, true, length, true);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFilesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'mediaFiles', 0, true, 0, true);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFilesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'mediaFiles', 0, false, 999999, true);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFilesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'mediaFiles', 0, true, length, include);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFilesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'mediaFiles', length, include, 999999, true);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterFilterCondition>
      mediaFilesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'mediaFiles', lower, includeLower, upper, includeUpper);
    });
  }
}

extension MessageCollectionQuerySortBy
    on QueryBuilder<MessageCollection, MessageCollection, QSortBy> {
  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByFromMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromMe', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByFromMeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromMe', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByMsgPubId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgPubId', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByMsgPubIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgPubId', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension MessageCollectionQuerySortThenBy
    on QueryBuilder<MessageCollection, MessageCollection, QSortThenBy> {
  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByFromMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromMe', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByFromMeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromMe', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByMsgPubId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgPubId', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByMsgPubIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'msgPubId', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension MessageCollectionQueryWhereDistinct
    on QueryBuilder<MessageCollection, MessageCollection, QDistinct> {
  QueryBuilder<MessageCollection, MessageCollection, QDistinct>
      distinctByFromMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromMe');
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QDistinct>
      distinctByMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QDistinct>
      distinctByMsgPubId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'msgPubId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QDistinct>
      distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MessageCollection, MessageCollection, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension MessageCollectionQueryProperty
    on QueryBuilder<MessageCollection, MessageCollection, QQueryProperty> {
  QueryBuilder<MessageCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MessageCollection, bool, QQueryOperations> fromMeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromMe');
    });
  }

  QueryBuilder<MessageCollection, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<MessageCollection, String?, QQueryOperations>
      msgPubIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'msgPubId');
    });
  }

  QueryBuilder<MessageCollection, String?, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<MessageCollection, int, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
