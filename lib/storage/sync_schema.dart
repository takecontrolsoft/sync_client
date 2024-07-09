import 'package:realm/realm.dart';

part 'sync_schema.realm.dart';

@RealmModel()
class _Role {
  @MapTo('_id')
  @PrimaryKey()
  late ObjectId id;
  bool isAdmin = false;
  @MapTo('owner_id')
  late String ownerId;
}

@RealmModel()
class _RemoteFolder {
  @MapTo('_id')
  @PrimaryKey()
  late ObjectId id;
  late String name;
  @MapTo('owner_id')
  late String ownerId;
}
