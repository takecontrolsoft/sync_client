import 'package:json_annotation/json_annotation.dart';
part 'schema.g.dart';

@JsonSerializable()
class User {
  User(this.email);

  String email;
  String? password;

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
  List<FileError> fileErrors = [];

  factory DeviceSettings.fromJson(Map<String, dynamic> json) =>
      _$DeviceSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceSettingsToJson(this);
}

@JsonSerializable()
class FileError {
  FileError(this.filename, this.errorMessage);
  final String errorMessage;
  final String filename;

  factory FileError.fromJson(Map<String, dynamic> json) =>
      _$FileErrorFromJson(json);

  Map<String, dynamic> toJson() => _$FileErrorToJson(this);
}
