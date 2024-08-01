import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/storage/storage.dart';

class DeviceServicesCubit extends Cubit<DeviceSettings> {
  User? currentUser;
  DeviceServicesCubit() : super(currentDeviceSettings);

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
    state.currentUser ??= User(email)..password = password;
    currentUser = state.currentUser;
    emit(state);
    return currentUser!;
  }

  Future<void> logOut() async {
    if (currentUser != null) {
      currentUser = null;
    }
  }

  T edit<T>(T Function(DeviceSettings) editCallback) {
    T result = editCallback(state);
    saveDeviceSettings(state);
    emit(state);
    return result;
  }
}
