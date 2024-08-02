// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      json['email'] as String,
    )
      ..password = json['password'] as String?
      ..loggedIn = json['loggedIn'] as bool?;

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'loggedIn': instance.loggedIn,
    };

DeviceSettings _$DeviceSettingsFromJson(Map<String, dynamic> json) =>
    DeviceSettings(
      json['name'] as String,
    )
      ..id = json['id'] as String?
      ..model = json['model'] as String?
      ..serverUrl = json['serverUrl'] as String?
      ..currentUser = json['currentUser'] == null
          ? null
          : User.fromJson(json['currentUser'] as Map<String, dynamic>)
      ..mediaDirectories = (json['mediaDirectories'] as List<dynamic>)
          .map((e) => e as String)
          .toSet()
      ..lastErrorMessage = json['lastErrorMessage'] as String?
      ..lastSyncDateTime = json['lastSyncDateTime'] == null
          ? null
          : DateTime.parse(json['lastSyncDateTime'] as String)
      ..fileErrors = (json['fileErrors'] as List<dynamic>)
          .map((e) => FileError.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$DeviceSettingsToJson(DeviceSettings instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
      'model': instance.model,
      'serverUrl': instance.serverUrl,
      'currentUser': instance.currentUser,
      'mediaDirectories': instance.mediaDirectories.toList(),
      'lastErrorMessage': instance.lastErrorMessage,
      'lastSyncDateTime': instance.lastSyncDateTime?.toIso8601String(),
      'fileErrors': instance.fileErrors,
    };

FileError _$FileErrorFromJson(Map<String, dynamic> json) => FileError(
      json['filename'] as String,
      json['errorMessage'] as String,
    );

Map<String, dynamic> _$FileErrorToJson(FileError instance) => <String, dynamic>{
      'errorMessage': instance.errorMessage,
      'filename': instance.filename,
    };
