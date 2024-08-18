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
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';
import 'components/components.dart';

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
      body: ItemsView(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {}),
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  List<String> GetChildrenFolders(List<NetFolder>? folders) {
    final List<String> allSubFolders = [];
    if (folders != null) {
      folders.forEach((f) {
        allSubFolders.add(f.name);
        if (f.subFolders != null) {
          allSubFolders.addAll(GetChildrenFolders(f.subFolders));
        }
      });
    }
    return allSubFolders;
  }

  Future<List<String>> GetAllFolders(DeviceServicesCubit deviceService) async {
    List<NetFolder>? folders = await GetFolders(
        deviceService.state.currentUser!.email, deviceService.state.id);

    final List<String> allFolders = GetChildrenFolders(folders);
    return allFolders;
  }

  Widget ItemsView(BuildContext context) {
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
        child: FutureBuilder<List<String>>(
          future: GetAllFolders(deviceService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              final folders = snapshot.data!;
              return ListView(children: PhotoWidgets(folders, deviceService));

              //buildPhotos(folders, context);
            } else {
              // if no data, show simple Text
              return const Text("No data available");
            }
          },
        ));
  }

  List<Widget> PhotoWidgets(
      List<String> folders, DeviceServicesCubit deviceService) {
    List<Widget> result = [];
    for (var folder in folders) {
      result.add(Card(
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(folder,
                  style: const TextStyle(fontWeight: FontWeight.bold)))));
      result.add(FutureBuilder<List<String>>(
        future: GetFiles(deviceService.state.currentUser!.email,
            deviceService.state.id, folder),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            final files = snapshot.data!;
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 5.0,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                return GridTile(
                    header: GridTileBar(
                      title: Text('$index',
                          style: const TextStyle(color: Colors.black)),
                    ),
                    child: Container(
                        margin: const EdgeInsets.all(12.0),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          gradient: const RadialGradient(
                            colors: <Color>[
                              Color(0x0F88EEFF),
                              Color(0x2F0099BB)
                            ],
                          ),
                        ),
                        child: Image.network(
                            "http://localhost:3000/Desi/AFA33F68-3E48-5459-B564-20D03E3F6035/${files[index]}")));
              },
            );

            //buildPhotos(folders, context);
          } else {
            // if no data, show simple Text
            return const Text("No data available");
          }
        },
      ));
    }
    return result;
  }
}
