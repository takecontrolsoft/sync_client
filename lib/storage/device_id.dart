/*
	Copyright 2026 Take Control - Software & Infrastructure

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _storageKeyDeviceId = 'persistent_device_id';

/// Spoofed MAC returned by Android 6+ and iOS (not usable as device ID).
const _spoofedMacPattern = '02:00:00:00:00:00';

/// Returns a stable device identifier so that after app reinstall the same
/// device still maps to the same folder on the server (UserId/DeviceId/...).
/// - Android: Android ID (survives reinstall). Serial/MAC not accessible (OS restriction).
/// - iOS: identifierForVendor (survives reinstall). Serial/MAC not accessible (OS restriction).
/// - Desktop (Windows/Linux/macOS): tries primary ID (deviceId/machineId/systemGUID),
///   then serial number (when available), then MAC address (when available and not randomized).
/// - Fallback: UUID stored in SharedPreferences.
Future<String> getPersistentDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      final id = android.id;
      if (id.isNotEmpty && id != 'unknown') {
        return _sanitizeForPath(id);
      }
    }
    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      final id = ios.identifierForVendor;
      if (id != null && id.isNotEmpty) {
        return _sanitizeForPath(id);
      }
    }
    if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      if (windows.deviceId.isNotEmpty)
        return _sanitizeForPath(windows.deviceId);
      final serial = await _getDesktopSerialNumber();
      if (serial != null && serial.isNotEmpty) return _sanitizeForPath(serial);
      final mac = await _getDesktopMacAddress();
      if (mac != null && mac.isNotEmpty) return _sanitizeForPath(mac);
    }
    if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      if (linux.machineId != null && linux.machineId!.isNotEmpty) {
        return _sanitizeForPath(linux.machineId!);
      }
      final serial = await _getDesktopSerialNumber();
      if (serial != null && serial.isNotEmpty) return _sanitizeForPath(serial);
      final mac = await _getDesktopMacAddress();
      if (mac != null && mac.isNotEmpty) return _sanitizeForPath(mac);
    }
    if (Platform.isMacOS) {
      final macos = await deviceInfo.macOsInfo;
      if (macos.systemGUID != null && macos.systemGUID!.isNotEmpty) {
        return _sanitizeForPath(macos.systemGUID!);
      }
      final serial = await _getDesktopSerialNumber();
      if (serial != null && serial.isNotEmpty) return _sanitizeForPath(serial);
      final mac = await _getDesktopMacAddress();
      if (mac != null && mac.isNotEmpty) return _sanitizeForPath(mac);
    }
  } catch (_) {}
  return _getOrCreateStoredDeviceId();
}

/// Tries to read the machine serial number on desktop (Windows/Linux/macOS).
/// Returns null on mobile, on failure, or when value is placeholder (e.g. "To be filled by O.E.M.").
Future<String?> _getDesktopSerialNumber() async {
  try {
    if (Platform.isWindows) {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          r'(Get-CimInstance Win32_BIOS).SerialNumber'
        ],
        runInShell: false,
      );
      if (result.exitCode == 0 && result.stdout != null) {
        final s = (result.stdout as String).trim();
        if (s.isNotEmpty && !_isPlaceholderSerial(s)) return s;
      }
    }
    if (Platform.isLinux) {
      const path = '/sys/class/dmi/id/product_serial';
      final file = File(path);
      if (await file.exists()) {
        final s = (await file.readAsString()).trim();
        if (s.isNotEmpty && !_isPlaceholderSerial(s)) return s;
      }
    }
    if (Platform.isMacOS) {
      final result = await Process.run(
        'ioreg',
        ['-c', 'IOPlatformExpertDevice', '-d', '2'],
        runInShell: false,
      );
      if (result.exitCode == 0 && result.stdout != null) {
        final out = result.stdout as String;
        final match =
            RegExp(r'"IOPlatformSerialNumber"\s*=\s*"([^"]+)"').firstMatch(out);
        if (match != null) {
          final s = match.group(1)?.trim() ?? '';
          if (s.isNotEmpty && !_isPlaceholderSerial(s)) return s;
        }
      }
    }
  } catch (_) {}
  return null;
}

bool _isPlaceholderSerial(String s) {
  final lower = s.toLowerCase();
  return lower.contains('to be filled') ||
      lower.contains('o.e.m') ||
      lower == 'unknown' ||
      lower == 'none' ||
      s == '0';
}

/// Tries to read the first non-loopback MAC address on desktop.
/// Returns null on mobile, on failure, or when MAC is spoofed (e.g. 02:00:00:00:00:00).
Future<String?> _getDesktopMacAddress() async {
  try {
    if (Platform.isWindows) {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          r'(Get-NetAdapter | Where-Object MacAddress -ne $null | Select-Object -First 1).MacAddress',
        ],
        runInShell: false,
      );
      if (result.exitCode == 0 && result.stdout != null) {
        final s = (result.stdout as String).trim();
        if (s.isNotEmpty && !_isSpoofedMac(s)) return s;
      }
    }
    if (Platform.isLinux) {
      final netDir = Directory('/sys/class/net');
      if (await netDir.exists()) {
        await for (final entity in netDir.list()) {
          if (entity is! Directory || entity.path.endsWith('/lo')) continue;
          final name = entity.path.split('/').last;
          if (name == 'lo') continue;
          final addrFile = File('${entity.path}/address');
          if (await addrFile.exists()) {
            final s = (await addrFile.readAsString()).trim();
            if (s.isNotEmpty && !_isSpoofedMac(s)) return s;
          }
        }
      }
    }
    if (Platform.isMacOS) {
      for (final iface in ['en0', 'en1', 'ether']) {
        final result =
            await Process.run('ifconfig', [iface], runInShell: false);
        if (result.exitCode == 0 && result.stdout != null) {
          final match = RegExp(r'ether\s+([0-9a-fA-F:]+)')
              .firstMatch(result.stdout as String);
          if (match != null) {
            final s = match.group(1)?.trim() ?? '';
            if (s.isNotEmpty && !_isSpoofedMac(s)) return s;
          }
        }
      }
    }
  } catch (_) {}
  return null;
}

bool _isSpoofedMac(String mac) {
  final n = mac.replaceAll(':', '').toLowerCase();
  return n == '020000000000' || mac.trim().toLowerCase() == _spoofedMacPattern;
}

/// Fallback: read stored UUID or create and store one (web, or when platform ID is unavailable).
Future<String> _getOrCreateStoredDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? id = prefs.getString(_storageKeyDeviceId);
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString(_storageKeyDeviceId, id);
  }
  return _sanitizeForPath(id);
}

/// Keep only characters safe for folder names (alphanumeric, hyphen, underscore).
String _sanitizeForPath(String id) {
  return id.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
}
