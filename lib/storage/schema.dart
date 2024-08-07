import 'package:json_annotation/json_annotation.dart';
import 'package:sync_client/core/core.dart';
part 'schema.g.dart';

@JsonSerializable()
class User {
  User(this.email);

  String email;
  String? password;
  bool? loggedIn = false;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class DeviceSettings {
  DeviceSettings(this.name);

  String name;
  String? id;
  String? model;
  String? serverUrl;
  User? currentUser;
  Set<String> mediaDirectories = {};
  String? lastErrorMessage;
  DateTime? lastSyncDateTime;

  factory DeviceSettings.fromJson(Map<String, dynamic> json) =>
      _$DeviceSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceSettingsToJson(this);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    bool areEqual = compareJson(toJson(), (other as DeviceSettings).toJson());
    return areEqual;
  }

  @override
  int get hashCode => super.hashCode + 1;
}

class ProcessedFile {
  ProcessedFile(this.filename, {this.errorMessage});
  final String? errorMessage;
  final String filename;
}
