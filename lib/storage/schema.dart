import 'package:realm/realm.dart';
part 'schema.realm.dart';

@RealmModel()
class _Settings {
  late String? serverUrl;
  late _DeviceInfo? device;
  Set<String> mediaDirectories = {};
}

@RealmModel()
class _DeviceInfo {
  late String name;
  late String? id;
  late String? model;
  late _Settings? settings;
}
