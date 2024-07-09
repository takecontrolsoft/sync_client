// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_schema.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Role extends _Role with RealmEntity, RealmObjectBase, RealmObject {
  static var _defaultsSet = false;

  Role(
    ObjectId id,
    String ownerId, {
    bool isAdmin = false,
  }) {
    if (!_defaultsSet) {
      _defaultsSet = RealmObjectBase.setDefaults<Role>({
        'isAdmin': false,
      });
    }
    RealmObjectBase.set(this, '_id', id);
    RealmObjectBase.set(this, 'isAdmin', isAdmin);
    RealmObjectBase.set(this, 'owner_id', ownerId);
  }

  Role._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, '_id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, '_id', value);

  @override
  bool get isAdmin => RealmObjectBase.get<bool>(this, 'isAdmin') as bool;
  @override
  set isAdmin(bool value) => RealmObjectBase.set(this, 'isAdmin', value);

  @override
  String get ownerId => RealmObjectBase.get<String>(this, 'owner_id') as String;
  @override
  set ownerId(String value) => RealmObjectBase.set(this, 'owner_id', value);

  @override
  Stream<RealmObjectChanges<Role>> get changes =>
      RealmObjectBase.getChanges<Role>(this);

  @override
  Stream<RealmObjectChanges<Role>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Role>(this, keyPaths);

  @override
  Role freeze() => RealmObjectBase.freezeObject<Role>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      '_id': id.toEJson(),
      'isAdmin': isAdmin.toEJson(),
      'owner_id': ownerId.toEJson(),
    };
  }

  static EJsonValue _toEJson(Role value) => value.toEJson();
  static Role _fromEJson(EJsonValue ejson) {
    return switch (ejson) {
      {
        '_id': EJsonValue id,
        'isAdmin': EJsonValue isAdmin,
        'owner_id': EJsonValue ownerId,
      } =>
        Role(
          fromEJson(id),
          fromEJson(ownerId),
          isAdmin: fromEJson(isAdmin),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Role._);
    register(_toEJson, _fromEJson);
    return SchemaObject(ObjectType.realmObject, Role, 'Role', [
      SchemaProperty('id', RealmPropertyType.objectid,
          mapTo: '_id', primaryKey: true),
      SchemaProperty('isAdmin', RealmPropertyType.bool),
      SchemaProperty('ownerId', RealmPropertyType.string, mapTo: 'owner_id'),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class RemoteFolder extends _RemoteFolder
    with RealmEntity, RealmObjectBase, RealmObject {
  RemoteFolder(
    ObjectId id,
    String name,
    String ownerId,
  ) {
    RealmObjectBase.set(this, '_id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'owner_id', ownerId);
  }

  RemoteFolder._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, '_id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, '_id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get ownerId => RealmObjectBase.get<String>(this, 'owner_id') as String;
  @override
  set ownerId(String value) => RealmObjectBase.set(this, 'owner_id', value);

  @override
  Stream<RealmObjectChanges<RemoteFolder>> get changes =>
      RealmObjectBase.getChanges<RemoteFolder>(this);

  @override
  Stream<RealmObjectChanges<RemoteFolder>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<RemoteFolder>(this, keyPaths);

  @override
  RemoteFolder freeze() => RealmObjectBase.freezeObject<RemoteFolder>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      '_id': id.toEJson(),
      'name': name.toEJson(),
      'owner_id': ownerId.toEJson(),
    };
  }

  static EJsonValue _toEJson(RemoteFolder value) => value.toEJson();
  static RemoteFolder _fromEJson(EJsonValue ejson) {
    return switch (ejson) {
      {
        '_id': EJsonValue id,
        'name': EJsonValue name,
        'owner_id': EJsonValue ownerId,
      } =>
        RemoteFolder(
          fromEJson(id),
          fromEJson(name),
          fromEJson(ownerId),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(RemoteFolder._);
    register(_toEJson, _fromEJson);
    return SchemaObject(ObjectType.realmObject, RemoteFolder, 'RemoteFolder', [
      SchemaProperty('id', RealmPropertyType.objectid,
          mapTo: '_id', primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('ownerId', RealmPropertyType.string, mapTo: 'owner_id'),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
