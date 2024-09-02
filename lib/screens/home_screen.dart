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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: itemsView(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {}),
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  List<String> getChildrenFolders(List<NetFolder>? folders) {
    final List<String> allSubFolders = [];
    if (folders != null) {
      for (var f in folders) {
        allSubFolders.add(f.name);
        if (f.subFolders != null) {
          allSubFolders.addAll(getChildrenFolders(f.subFolders));
        }
      }
    }
    return allSubFolders;
  }

  Future<List<String>> getAllFolders(DeviceServicesCubit deviceService) async {
    if ((deviceService.state.serverUrl ?? "") == "") {
      return [];
    }
    List<NetFolder>? folders = await apiGetFolders(
        deviceService.state.currentUser!.email, deviceService.state.id);

    final List<String> allFolders = getChildrenFolders(folders);
    return allFolders;
  }

  Future<List<String>> getAllFiles(
      DeviceServicesCubit deviceService, String folder) async {
    if ((deviceService.state.serverUrl ?? "") == "") {
      return [];
    }
    List<String>? files = await apiGetFiles(
        deviceService.state.currentUser!.email, deviceService.state.id, folder);

    return files;
  }

  Widget itemsView(BuildContext context) {
    final DeviceServicesCubit deviceService =
        context.read<DeviceServicesCubit>();
    deviceService.state.lastErrorMessage = null;
    if (!deviceService.isAuthenticated()) {
      context.push("/login");
      return Container();
    }

    return Container(
        margin: const EdgeInsets.only(
            left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
        child: ((deviceService.state.serverUrl ?? "") == "")
            ? const Text(
                "There is no files synced to the server or the server is not configured.")
            : FutureBuilder<List<String>>(
                future: getAllFolders(deviceService),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text((snapshot.error as CustomError).message);
                  } else {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return const CircularProgressIndicator();
                      case ConnectionState.active:
                      case ConnectionState.done:
                        if (snapshot.hasData) {
                          final folders = snapshot.data!;
                          return folders.isEmpty
                              ? const Text(
                                  "There is no files synced to the server or the server is not configured.")
                              : ListView(
                                  physics: const PageScrollPhysics(),
                                  children:
                                      photoGridWidgets(folders, deviceService));
                        } else {
                          return const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                Text(
                                  "There is no synced photos/videos from this device and nickname.",
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  "Please go the menu and select 'Sync' to setup configurations.",
                                  textAlign: TextAlign.center,
                                ),
                                Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      "Go to MOBISYNC.EU for help.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ))
                              ]));
                        }
                    }
                  }
                },
              ));
  }

  List<Widget> photoGridWidgets(
      List<String> folders, DeviceServicesCubit deviceService) {
    List<Widget> result = [];
    for (var folder in folders) {
      result.add(Card(
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(folder,
                  style: const TextStyle(fontWeight: FontWeight.bold)))));
      result.add(FutureBuilder<List<String>>(
        future: getAllFiles(deviceService, folder),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasData) {
            final files = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(1.0),
              gridDelegate: CustomGridDelegate(dimension: 100.0),
              shrinkWrap: true,
              itemCount: files.length,
              physics: const PageScrollPhysics(),
              itemBuilder: (context, index) {
                return GridTile(
                    child: Container(
                  margin: const EdgeInsets.all(2.0),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    gradient: const RadialGradient(
                      colors: <Color>[
                        Color.fromARGB(15, 249, 250, 251),
                        Color.fromARGB(44, 120, 121, 122)
                      ],
                    ),
                  ),
                  child: photoWidget(files[index], deviceService),
                ));
              },
            );
          } else {
            return const Text(
              "No photos loaded",
              style: TextStyle(fontSize: 10),
            );
          }
        },
      ));
    }
    return result;
  }

  Widget photoWidget(String file, DeviceServicesCubit deviceService) {
    return FutureBuilder<Uint8List?>(
        future: apiGetImageBytes(deviceService.state.currentUser!.email,
            deviceService.state.id, file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasData) {
            final fileData = snapshot.data!;
            return Image.memory(fileData);
          } else {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      file.split("/").last,
                      style: const TextStyle(fontSize: 9),
                    )));
          }
        });
  }
}
