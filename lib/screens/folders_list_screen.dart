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
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

class FoldersListScreen extends StatelessWidget {
  const FoldersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const _FoldersListScreenView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => selectSourceDir(context, deviceService),
        tooltip: 'Select folder',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> selectSourceDir(
      BuildContext context, DeviceServicesCubit deviceService) async {
    try {
      // Show loading while picker opens
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Card(
              child: Padding(
                padding: FolderListStyles.loadingDialogPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Opening folder picker...'),
                  ],
                ),
              ),
            ),
          );
        },
      );

      String? selectedDirectory;

      try {
        // This works on all platforms with proper configuration:
        // - Android: Uses Storage Access Framework (no manifest permissions needed)
        // - iOS: Uses document picker (add NSDocumentsFolderUsageDescription to Info.plist)
        // - macOS: Uses native dialog (needs entitlements as configured)
        // - Windows/Linux: Works out of the box
        selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select folder to sync',
          lockParentWindow: true,
        );
      } catch (e) {
        // Close loading dialog
        if (context.mounted) Navigator.of(context).pop();

        debugPrint('FilePicker error: $e');

        // Show error with helpful message
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unable to open folder picker'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Error: ${e.toString()}'),
                  const SizedBox(height: 16),
                  if (Platform.isMacOS && e.toString().contains('ENTITLEMENT'))
                    const Text(
                      'This appears to be a development configuration issue. '
                      'Please ensure the macOS entitlements are properly set.',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    )
                  else
                    const Text(
                      'Would you like to enter a folder path manually instead?',
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                if (!e.toString().contains('ENTITLEMENT'))
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final manualPath = await _showManualPathDialog(context);
                      if (manualPath != null) {
                        selectedDirectory = manualPath;
                      }
                    },
                    child: const Text('Enter Manually'),
                  ),
              ],
            ),
          );
        }

        // Don't process further if there was an error
        if (selectedDirectory == null) return;
      }

      // Close loading dialog
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Process the selected directory
      if (selectedDirectory != null) {
        // Verify the directory exists and is accessible
        final directory = Directory(selectedDirectory!);
        bool canAccess = false;

        try {
          canAccess = await directory.exists();
        } catch (e) {
          canAccess = false;
          debugPrint('Cannot access directory: $e');
        }

        if (!canAccess && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot access folder: ${directory.path}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Try Again',
                onPressed: () => selectSourceDir(context, deviceService),
              ),
            ),
          );
          return;
        }

        // Add the directory to the list
        await deviceService.edit((state) {
          if (!state.mediaDirectories.contains(selectedDirectory)) {
            state.mediaDirectories.add(selectedDirectory!);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackbarStyles.successSnackbar(
                  message:
                      'Added: ${selectedDirectory!.split(Platform.pathSeparator).last}',
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackbarStyles.warningSnackbar(
                  message: 'This folder is already in your sync list',
                ),
              );
            }
          }
          state.lastErrorMessage = null;
        });
      }
    } catch (e) {
      // Close any open dialogs
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      debugPrint('Error in selectSourceDir: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackbarStyles.errorSnackbar(
            message: 'Unexpected error: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<String?> _showManualPathDialog(BuildContext context) async {
    final controller = TextEditingController();
    String hintText;
    String helperText;

    if (Platform.isAndroid) {
      hintText = '/storage/emulated/0/DCIM';
      helperText = 'Example: /storage/emulated/0/Pictures';
    } else if (Platform.isIOS) {
      hintText = 'Documents/Photos';
      helperText = 'Relative to app container';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ??
          '/Users/${Platform.environment['USER']}';
      hintText = '$home/Pictures';
      helperText = 'Example: $home/Documents';
    } else if (Platform.isWindows) {
      final username = Platform.environment['USERNAME'] ?? 'User';
      hintText = 'C:\\Users\\$username\\Pictures';
      helperText = 'Example: C:\\Users\\$username\\Documents';
    } else {
      final home = Platform.environment['HOME'] ?? '/home/user';
      hintText = '$home/Pictures';
      helperText = 'Example: $home/Documents';
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Folder Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the full path to the folder you want to sync:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                helperText: helperText,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.folder),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the path exists and is accessible',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                Navigator.of(context).pop(path);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _FoldersListScreenView extends StatelessWidget {
  const _FoldersListScreenView();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: FolderListStyles.containerMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Folders to Sync',
            style: FolderListStyles.titleTextStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            'These folders will be synchronized with your server',
            style: FolderListStyles.subtitleTextStyle(context),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: reactiveBuilder<DeviceServicesCubit, DeviceSettings>(
              buildWhen: (previous, current) =>
                  previous.mediaDirectories.length !=
                  current.mediaDirectories.length,
              child: (context, state) {
                if (state.mediaDirectories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: FolderListStyles.emptyStateIconSize,
                          color: FolderListStyles.emptyStateIconColor,
                        ),
                        const SizedBox(
                            height: FolderListStyles.emptyStateSpacing),
                        Text(
                          'No folders selected',
                          style: FolderListStyles.emptyStateTitleStyle(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add a folder',
                          style:
                              FolderListStyles.emptyStateSubtitleStyle(context),
                        ),
                        const SizedBox(height: 32),
                        // Platform-specific help
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration:
                              FolderListStyles.infoContainerDecoration(context),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                FolderListStyles.getPlatformHelpText(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.mediaDirectories.length,
                  itemBuilder: (context, index) {
                    final directory = state.mediaDirectories.toList()[index];
                    if (directory.isEmpty) return const SizedBox.shrink();

                    return Dismissible(
                      key: Key(directory),
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Folder?'),
                            content: Text(
                              'Stop syncing "${directory.split(Platform.pathSeparator).last}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        final folderName =
                            directory.split(Platform.pathSeparator).last;
                        context.read<DeviceServicesCubit>().edit((state) {
                          state.mediaDirectories.remove(directory);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed: $folderName'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                context
                                    .read<DeviceServicesCubit>()
                                    .edit((state) {
                                  state.mediaDirectories.add(directory);
                                });
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: FolderListStyles.cardMargin,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration:
                                FolderListStyles.folderIconDecoration(context),
                            child: Icon(
                              Icons.folder,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            directory.split(Platform.pathSeparator).last,
                            style: FolderListStyles.folderNameStyle(),
                          ),
                          subtitle: Text(
                            directory,
                            style: FolderListStyles.folderPathStyle(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () =>
                                _showFolderOptions(context, directory),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (context
              .watch<DeviceServicesCubit>()
              .state
              .mediaDirectories
              .isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Swipe left to remove • Tap folder for options',
                style: FolderListStyles.helperTextStyle(context),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _getPlatformHelpText() {
    return FolderListStyles.getPlatformHelpText();
  }

  void _showFolderOptions(BuildContext context, String directory) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Open in File Manager'),
              onTap: () {
                Navigator.pop(context);
                // Could implement opening folder in system file manager
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening folder in file manager...'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Folder Info'),
              onTap: () async {
                Navigator.pop(context);
                final dir = Directory(directory);
                int fileCount = 0;
                if (await dir.exists()) {
                  try {
                    fileCount = await dir
                        .list(recursive: true)
                        .where((entity) => entity is File)
                        .length;
                  } catch (e) {
                    debugPrint('Error counting files: $e');
                  }
                }

                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Folder Information'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Path: $directory'),
                          const SizedBox(height: 8),
                          Text('Files: $fileCount'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove from Sync',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Trigger the dismiss action
                context.read<DeviceServicesCubit>().edit((state) {
                  state.mediaDirectories.remove(directory);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
