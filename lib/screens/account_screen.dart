// ignore_for_file: must_be_immutable

/*
	Copyright 2023 Take Control - Software & Infrastructure

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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/device_services.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

Future<void> _confirmDeleteCachedImages(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Delete cached images'),
      content: const Text(
        'This will clear all cached thumbnails and images from this device. '
        'Images will be re-downloaded when you browse again.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  try {
    await ThumbnailCacheService.clear();
    await CacheService.clearCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cached images deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Asks the server to clean orphan thumbnails (delete thumbnails with no source file), then prunes local cache to match.
Future<void> _confirmCleanOrphanThumbnails(
    BuildContext context, DeviceServicesCubit deviceService) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Clean orphan thumbnails'),
      content: const Text(
        'This will ask the server to delete thumbnail files that have no '
        'corresponding photo/video (orphans). Local cache will be pruned to match.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clean'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  final user = deviceService.state.currentUser?.email;
  final deviceId = deviceService.state.id;
  if (user == null || user.isEmpty || (deviceId ?? '').isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
    }
    return;
  }
  try {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cleaning on server…')),
      );
    }
    final ok = await apiCleanOrphanThumbnails(user, deviceId!);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server did not accept clean request or endpoint not implemented')),
      );
      return;
    }
    final serverPaths = await apiGetAllFilePaths(user, deviceId);
    final validSet = serverPaths.map((s) => s.replaceAll(r'\', '/')).toSet();
    final cached = await ThumbnailCacheService.listCachedPaths();
    int removed = 0;
    for (final path in cached) {
      final normalized = path.replaceAll(r'\', '/');
      if (!validSet.contains(normalized)) {
        await ThumbnailCacheService.delete(path);
        removed++;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Server cleaned orphan thumbnails. Local cache pruned.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

/// Asks the server to regenerate thumbnails for media files, then clears local cache so they re-download.
Future<void> _confirmRegenerateThumbnails(
    BuildContext context, DeviceServicesCubit deviceService) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Regenerate thumbnails'),
      content: const Text(
        'This will ask the server to regenerate thumbnails for your media. '
        'Local cache will be cleared so thumbnails re-download when you browse.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Regenerate'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  final user = deviceService.state.currentUser?.email;
  final deviceId = deviceService.state.id;
  if (user == null || user.isEmpty || (deviceId ?? '').isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
    }
    return;
  }
  try {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regenerating on server…')),
      );
    }
    final ok = await apiRegenerateThumbnails(user, deviceId!);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server did not accept request or endpoint not implemented')),
      );
      return;
    }
    await ThumbnailCacheService.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Server regenerating thumbnails. Local cache cleared.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

Future<void> _confirmDeleteSyncMetadata(
    BuildContext context, DeviceServicesCubit deviceService) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Delete Sync Metadata'),
      content: const Text(
        'This will clear sync metadata (synced file list, last sync time) from '
        'device settings (deviceSettings.json). Your account and selected folders '
        'to sync are kept.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  try {
    await deviceService.clearSyncMetadata();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync metadata deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      deviceService.edit((state) {
        state.lastErrorMessage = 'Failed to delete sync metadata: $e';
        state.successMessage = null;
      });
    }
  }
}

Widget _accountActionRow({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonLabel,
  required ColorScheme colorScheme,
  required VoidCallback onPressed,
}) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120,
                child: FilledButton.tonal(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const AccountScreenView(),
    );
  }
}

class AccountScreenView extends StatelessWidget {
  const AccountScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    deviceService.state.lastErrorMessage = null;
    deviceService.state.successMessage = "";

    if (!deviceService.isAuthenticated()) {
      context.push("/login");
      return Container();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 24.0, bottom: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "${deviceService.state.currentUser?.email ?? ""}",
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              "Data & cache",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _accountActionRow(
              context: context,
              title: "Delete cached images",
              description:
                  "Clear thumbnails from this device. They will re-download when you browse.",
              buttonLabel: "Delete",
              colorScheme: colorScheme,
              onPressed: () => _confirmDeleteCachedImages(context),
            ),
            _accountActionRow(
              context: context,
              title: "Delete Sync Metadata",
              description:
                  "Clear synced file list and last sync time. Account and folders are kept.",
              buttonLabel: "Delete",
              colorScheme: colorScheme,
              onPressed: () => _confirmDeleteSyncMetadata(context, deviceService),
            ),
            _accountActionRow(
              context: context,
              title: "Clean orphan thumbnails",
              description:
                  "Server deletes thumbnails with no source file. Local cache is pruned to match.",
              buttonLabel: "Clean",
              colorScheme: colorScheme,
              onPressed: () => _confirmCleanOrphanThumbnails(context, deviceService),
            ),
            _accountActionRow(
              context: context,
              title: "Regenerate thumbnails",
              description:
                  "Server regenerates thumbnails for your media. Local cache is cleared.",
              buttonLabel: "Regenerate",
              colorScheme: colorScheme,
              onPressed: () => _confirmRegenerateThumbnails(context, deviceService),
            ),
            const SizedBox(height: 24),
            Text(
              "Account",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _accountActionRow(
              context: context,
              title: "Delete my local settings",
              description:
                  "Remove account from this device. Photos stay on the server. Use same nickname to sign in again.",
              buttonLabel: "Delete",
              colorScheme: colorScheme,
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Delete my local settings'),
                  content: const Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: <Widget>[
                      Text(
                        'WARNING: This operation will delete your settings for this application.',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'After this operation your account will be removed from this device, but your photos/videos will still exist on the server.',
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Use the same nickname next time to access your synced files from the server.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    okButton(context, "Confirm", onPressed: () async {
                      deleteDeviceSettings(context, deviceService);
                      if (context.mounted) Navigator.pop(context);
                    }),
                    cancelButton(context),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
              buildWhen: (previous, current) =>
                  current.lastErrorMessage == null ||
                  previous.lastErrorMessage != current.lastErrorMessage,
              child: (context, state) => Text(
                deviceService.state.lastErrorMessage ??
                    deviceService.state.successMessage ??
                    "",
                style: deviceService.state.lastErrorMessage == null
                    ? successTextStyle(context)
                    : errorTextStyle(context),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> deleteDeviceSettings(
      BuildContext context, DeviceServicesCubit deviceService) async {
    try {
      await deviceService.logOut();
      await deviceService.clearDeviceSettings();
      // ignore: use_build_context_synchronously
      if (context.canPop()) {
        // ignore: use_build_context_synchronously
        context.pop();
      }
      // ignore: use_build_context_synchronously
      context.push('/login');
    } catch (err) {
      await deviceService.edit((state) {
        state.lastErrorMessage =
            "An error ocurred while deleting local file with your settings.";
        state.successMessage = null;
      });
    }
  }
}
