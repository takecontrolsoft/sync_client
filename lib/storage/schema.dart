class User {
  late String email;
  late String password;
}

class DeviceSettings {
  late String name;
  late String? id;
  late String? model;
  late String? serverUrl;
  late User? currentUser;
  Set<String> mediaDirectories = {};
  late String? lastErrorMessage;
  late DateTime? lastSyncDateTime;
  late List<FileError> fileErrors = [];
}

class FileError {
  final String errorMessage;
  final String filename;
  FileError(this.filename, this.errorMessage);
}
