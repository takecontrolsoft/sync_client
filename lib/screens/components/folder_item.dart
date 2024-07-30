import 'package:flutter/material.dart';
import 'package:sync_client/storage/realm.dart';

enum FolderMenuOption { edit, delete }

class FolderItem extends StatelessWidget {
  final String folder;

  const FolderItem(this.folder, {super.key});

  @override
  Widget build(BuildContext context) {
    return folder.isNotEmpty
        ? ListTile(
            leading: const Icon(Icons.folder),
            title: Text('Directory: $folder'),
            trailing: SizedBox(
              width: 25,
              child: PopupMenuButton<FolderMenuOption>(
                onSelected: (menuItem) =>
                    handleMenuClick(context, menuItem, folder),
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

  void handleMenuClick(
      BuildContext context, FolderMenuOption menuItem, String folder) {
    if (menuItem == FolderMenuOption.delete) {
      localRealm.write(() {
        currentDevice.settings?.mediaDirectories.remove(folder);
      });
    }
  }
}
