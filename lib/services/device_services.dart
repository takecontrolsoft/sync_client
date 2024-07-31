import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/storage/storage.dart';

class DeviceServicesCubit extends Cubit<DeviceSettings> {
  User? currentUser;
  DeviceServicesCubit() : super(currentDeviceSettings) {
    _initCurrentDevice();
  }

  Future<User> logInUserEmailPassword(String email, String password) async {
    if (state.currentUser == null ||
        state.currentUser?.email != email ||
        state.currentUser?.password != password) {
      throw ArgumentError("Invalid user credentials", email);
    }

    currentUser = state.currentUser;
    emit(state);
    return currentUser!;
  }

  Future<User> registerUserEmailPassword(String email, String password) async {
    state.currentUser ??= User()
      ..email = email
      ..password = password;
    currentUser = state.currentUser;
    emit(state);
    return currentUser!;
  }

  Future<void> logOut() async {
    if (currentUser != null) {
      currentUser = null;
    }
  }

  static Future<void> _initCurrentDevice() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final deviceInfo = await deviceInfoPlugin.deviceInfo;

    String? deviceName = deviceInfo.data["deviceId"];
    deviceName ??= deviceInfo.data["id"];
    deviceName ??= (deviceInfo.data["model"] ?? "") +
        (deviceInfo.data["systemGUID"] ?? "");
    deviceName ??= "unknown";
    currentDeviceSettings.name = deviceName;
    currentDeviceSettings.id = deviceInfo.data["id"];
    currentDeviceSettings.model = deviceInfo.data["model"];
  }
}
