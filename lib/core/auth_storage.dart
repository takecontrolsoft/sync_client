/*
	Copyright 2024 Take Control - Software & Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
*/
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyToken = 'auth_token';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Reads the auth token from secure storage (null if none).
Future<String?> getAuthToken() => _storage.read(key: _keyToken);

/// Saves the auth token to secure storage.
Future<void> setAuthToken(String token) =>
    _storage.write(key: _keyToken, value: token);

/// Removes the auth token (e.g. on logout).
Future<void> clearAuthToken() => _storage.delete(key: _keyToken);
