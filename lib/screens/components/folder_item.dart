import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/services/services.dart';

enum FolderMenuOption { edit, delete }

class FolderItem extends StatelessWidget {
  final String folder;

  const FolderItem(this.folder, {super.key});

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    return folder.isNotEmpty
        ? ListTile(
            leading: const Icon(Icons.folder),
            title: Text('Directory: $folder'),
            trailing: SizedBox(
              width: 25,
              child: PopupMenuButton<FolderMenuOption>(
                onSelected: (menuItem) async => await handleMenuClick(
                    context, deviceService, menuItem, folder),
                itemBuilder: (context) => [
                  const PopupMenuItem<FolderMenuOption>(
                    value: FolderMenuOption.delete,
                    child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text("Delete item")),
                  ),
                ],
              ),
            ),
            shape: const Border(bottom: BorderSide()),
          )
        : Container();
  }

  Future<void> handleMenuClick(
      BuildContext context,
      DeviceServicesCubit deviceService,
      FolderMenuOption menuItem,
      String folder) async {
    if (menuItem == FolderMenuOption.delete) {
      await deviceService.edit((state) {
        state.mediaDirectories.remove(folder);
        state.lastSyncDateTime = null;
      });
    }
  }
}
