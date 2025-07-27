import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/storage/storage.dart';

class DeviceServicesCubit extends Cubit<DeviceSettings> {
  DeviceServicesCubit() : super(currentDeviceSettings);

  bool isAuthenticated() {
    if (state.currentUser == null) {
      return false;
    }
    return state.currentUser?.loggedIn ?? false;
  }

  Future<User> logInUserEmailPassword(String email, String password) async {
    if (state.currentUser == null ||
        state.currentUser?.email != email ||
        state.currentUser?.password != password) {
      throw ArgumentError("Invalid user credentials", email);
    }
    await edit(
      (state) {
        state.currentUser!.loggedIn = true;
      },
    );
    emit(state);
    return state.currentUser!;
  }

  Future<User> registerUserEmailPassword(String email, String password) async {
    await edit(
      (state) {
        if (state.currentUser == null) {
          state.currentUser ??= User(email)..password = password;
        } else {
          state.currentUser!.email = email;
          state.currentUser!.password = password;
        }
        state.currentUser!.loggedIn = true;
      },
    );
    return state.currentUser!;
  }

  Future<void> logOut() async {
    if (isAuthenticated()) {
      edit(
        (state) {
          state.currentUser!.loggedIn = false;
        },
      );
      state.currentUser = null;
    }
  }

  Future<T> edit<T>(T Function(DeviceSettings) editCallback) async {
    DeviceSettings newState =
        DeviceSettings.fromJson(json.decode(jsonEncode(state.toJson())));
    T result = editCallback(newState);
    await saveDeviceSettings(newState);
    currentDeviceSettings = newState;
    emit(newState);

    return result;
  }

  Future<void> clearDeviceSettings() async {
    state.currentUser = null;
    await deleteDeviceSettings();
    DeviceSettings newState = currentDeviceSettings;
    emit(newState);
  }
}
