// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_participant.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatParticipantCollectionCollection on Isar {
  IsarCollection<ChatParticipantCollection> get chatParticipantCollections =>
      this.collection();
}

const ChatParticipantCollectionSchema = CollectionSchema(
  name: r'ChatParticipantCollection',
  id: -2133540804789575075,
  properties: {
    r'contactPublicId': PropertySchema(
      id: 0,
      name: r'contactPublicId',
      type: IsarType.string,
    )
  },
  estimateSize: _chatParticipantCollectionEstimateSize,
  serialize: _chatParticipantCollectionSerialize,
  deserialize: _chatParticipantCollectionDeserialize,
  deserializeProp: _chatParticipantCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'chat': LinkSchema(
      id: -2648203323717124512,
      name: r'chat',
      target: r'ChatCollection',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _chatParticipantCollectionGetId,
  getLinks: _chatParticipantCollectionGetLinks,
  attach: _chatParticipantCollectionAttach,
  version: '3.1.0+1',
);

int _chatParticipantCollectionEstimateSize(
  ChatParticipantCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contactPublicId.length * 3;
  return bytesCount;
}

void _chatParticipantCollectionSerialize(
  ChatParticipantCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contactPublicId);
}

ChatParticipantCollection _chatParticipantCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ChatParticipantCollection();
  object.contactPublicId = reader.readString(offsets[0]);
  object.id = id;
  return object;
}

P _chatParticipantCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatParticipantCollectionGetId(ChatParticipantCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _chatParticipantCollectionGetLinks(
    ChatParticipantCollection object) {
  return [object.chat];
}

void _chatParticipantCollectionAttach(
    IsarCollection<dynamic> col, Id id, ChatParticipantCollection object) {
  object.id = id;
  object.chat.attach(col, col.isar.collection<ChatCollection>(), r'chat', id);
}

extension ChatParticipantCollectionQueryWhereSort on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QWhere> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatParticipantCollectionQueryWhere on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QWhereClause> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterWhereClause> idBetween(
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

extension ChatParticipantCollectionQueryFilter on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QFilterCondition> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPublicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactPublicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactPublicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactPublicId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactPublicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactPublicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
          QAfterFilterCondition>
      contactPublicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactPublicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
          QAfterFilterCondition>
      contactPublicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactPublicId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactPublicId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> contactPublicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactPublicId',
        value: '',
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> idBetween(
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
}

extension ChatParticipantCollectionQueryObject on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QFilterCondition> {}

extension ChatParticipantCollectionQueryLinks on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QFilterCondition> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> chat(FilterQuery<ChatCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'chat');
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterFilterCondition> chatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'chat', 0, true, 0, true);
    });
  }
}

extension ChatParticipantCollectionQuerySortBy on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QSortBy> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterSortBy> sortByContactPublicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPublicId', Sort.asc);
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterSortBy> sortByContactPublicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPublicId', Sort.desc);
    });
  }
}

extension ChatParticipantCollectionQuerySortThenBy on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QSortThenBy> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterSortBy> thenByContactPublicId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPublicId', Sort.asc);
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterSortBy> thenByContactPublicIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactPublicId', Sort.desc);
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension ChatParticipantCollectionQueryWhereDistinct on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QDistinct> {
  QueryBuilder<ChatParticipantCollection, ChatParticipantCollection, QDistinct>
      distinctByContactPublicId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactPublicId',
          caseSensitive: caseSensitive);
    });
  }
}

extension ChatParticipantCollectionQueryProperty on QueryBuilder<
    ChatParticipantCollection, ChatParticipantCollection, QQueryProperty> {
  QueryBuilder<ChatParticipantCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ChatParticipantCollection, String, QQueryOperations>
      contactPublicIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactPublicId');
    });
  }
}
