import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/services/services.dart';

enum FolderMenuOption { edit, delete }

class FolderItem extends StatelessWidget {
  final String folder;

  const FolderItem(this.folder, {super.key});

  @override
  Widget build(BuildContext context) {
    final deviceService = context.watch<DeviceServicesCubit>();
    return folder.isNotEmpty
        ? ListTile(
            leading: const Icon(Icons.folder),
            title: Text('Directory: $folder'),
            trailing: SizedBox(
              width: 25,
              child: PopupMenuButton<FolderMenuOption>(
                onSelected: (menuItem) =>
                    handleMenuClick(context, deviceService, menuItem, folder),
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

  void handleMenuClick(BuildContext context, DeviceServicesCubit deviceService,
      FolderMenuOption menuItem, String folder) {
    if (menuItem == FolderMenuOption.delete) {
      deviceService.state.mediaDirectories.remove(folder);
    }
  }
}
