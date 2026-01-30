import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/core/core.dart';
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
    if (state.serverUrl == null || state.serverUrl!.trim().isEmpty) {
      throw ServerUrlNotSetError();
    }
    final result = await apiLogin(email, password);
    await setAuthToken(result.token);
    await edit(
      (state) {
        if (state.currentUser == null) {
          state.currentUser = User(email)
            ..password = password
            ..userId = result.userId
            ..loggedIn = true;
        } else {
          state.currentUser!.email = email;
          state.currentUser!.password = password;
          state.currentUser!.userId = result.userId;
          state.currentUser!.loggedIn = true;
        }
      },
    );
    emit(state);
    return state.currentUser!;
  }

  Future<User> registerUserEmailPassword(String email, String password) async {
    if (state.serverUrl == null || state.serverUrl!.trim().isEmpty) {
      throw ServerUrlNotSetError();
    }
    final result = await apiRegister(email, password);
    await setAuthToken(result.token);
    await edit(
      (state) {
        if (state.currentUser == null) {
          state.currentUser = User(email)
            ..password = password
            ..userId = result.userId
            ..loggedIn = true;
        } else {
          state.currentUser!.email = email;
          state.currentUser!.password = password;
          state.currentUser!.userId = result.userId;
          state.currentUser!.loggedIn = true;
        }
      },
    );
    return state.currentUser!;
  }

  Future<void> logOut() async {
    await clearAuthToken();
    await edit((state) {
      state.currentUser = null;
    });
    emit(state);
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

  /// Updates the device ID (e.g. after user confirms or changes it on registration).
  Future<void> updateDeviceId(String newId) async {
    final trimmed = newId.trim();
    if (trimmed.isEmpty) return;
    await edit((state) {
      state.id = trimmed;
    });
  }

  /// Clears sync metadata only: syncedFiles, lastSyncDateTime, isSyncing.
  /// Keeps account (currentUser, serverUrl, id) and selected folders (mediaDirectories).
  /// Persists to deviceSettings.json.
  Future<void> clearSyncMetadata() async {
    await edit((state) {
      state.syncedFiles = [];
      state.lastSyncDateTime = null;
      state.isSyncing = null;
    });
  }
}
