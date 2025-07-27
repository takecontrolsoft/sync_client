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
      json['id'] as String,
    )
      ..model = json['model'] as String?
      ..serverUrl = json['serverUrl'] as String?
      ..currentUser = json['currentUser'] == null
          ? null
          : User.fromJson(json['currentUser'] as Map<String, dynamic>)
      ..mediaDirectories = json['mediaDirectories'] == null
          ? {}
          : DeviceSettings._listToSet(json['mediaDirectories'])
      ..lastErrorMessage = json['lastErrorMessage'] as String?
      ..successMessage = json['successMessage'] as String?
      ..lastSyncDateTime = json['lastSyncDateTime'] == null
          ? null
          : DateTime.parse(json['lastSyncDateTime'] as String)
      ..syncedFiles = (json['syncedFiles'] as List<dynamic>?)
              ?.map((e) => SyncedFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          []
      ..isSyncing = json['isSyncing'] as bool?;

Map<String, dynamic> _$DeviceSettingsToJson(DeviceSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'model': instance.model,
      'serverUrl': instance.serverUrl,
      'currentUser': instance.currentUser,
      'mediaDirectories': DeviceSettings._setToList(instance.mediaDirectories),
      'lastErrorMessage': instance.lastErrorMessage,
      'successMessage': instance.successMessage,
      'lastSyncDateTime': instance.lastSyncDateTime?.toIso8601String(),
      'syncedFiles': instance.syncedFiles,
      'isSyncing': instance.isSyncing,
    };

SyncedFile _$SyncedFileFromJson(Map<String, dynamic> json) => SyncedFile(
      json['filename'] as String,
      errorMessage: json['errorMessage'] as String?,
    )..failedAttempts = (json['failedAttempts'] as num).toInt();

Map<String, dynamic> _$SyncedFileToJson(SyncedFile instance) =>
    <String, dynamic>{
      'errorMessage': instance.errorMessage,
      'filename': instance.filename,
      'failedAttempts': instance.failedAttempts,
    };

NetFolder _$NetFolderFromJson(Map<String, dynamic> json) => NetFolder(
      json['name'] as String,
      subFolders: (json['subFolders'] as List<dynamic>?)
          ?.map((e) => NetFolder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NetFolderToJson(NetFolder instance) => <String, dynamic>{
      'name': instance.name,
      'subFolders': instance.subFolders,
    };
