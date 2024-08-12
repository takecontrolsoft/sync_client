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
}

Widget ItemsView(BuildContext context) {
  final DeviceServicesCubit deviceService = context.read<DeviceServicesCubit>();
  deviceService.state.lastErrorMessage = null;

  if (!deviceService.isAuthenticated()) {
    context.push("/login");
    return Container();
  }

  return Container(
      margin: const EdgeInsets.only(
          left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
      child: FutureBuilder<List<NetFolder>?>(
        future: GetFolders(
            deviceService.state.currentUser!.email, deviceService.state.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            final folders = snapshot.data!;
            return buildFolders(folders);
          } else {
            // if no data, show simple Text
            return const Text("No data available");
          }
        },
      ));
}

Widget buildFolder(NetFolder folder) {
  return Column(children: [
    Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
        child: Card(
          child: Text(folder.name),
        )),
    folder.subFolders == null
        ? Container()
        : ListView.builder(
            itemCount: folder.subFolders!.length,
            itemBuilder: (context, index) => Card(
                  child: Text(folder.subFolders![index].name),
                ))
    //buildFolders(folder.subFolders),
  ]);
}

Widget buildFolders(List<NetFolder>? folders) {
  return (folders == null)
      ? Container()
      : ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) => buildFolder(folders[index]));
}

Widget buildPhotos(List<NetPhoto>? posts) {
  return Card(
    elevation: 8.0,
    child: GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: CustomGridDelegate(dimension: 140.0),
      // Try uncommenting some of these properties to see the effect on the grid:
      // itemCount: 20, // The default is that the number of grid tiles is infinite.
      // scrollDirection: Axis.horizontal, // The default is vertical.
      // reverse: true, // The default is false, going down (or left to right).
      itemBuilder: (BuildContext context, int index) {
        return GridTile(
          header: GridTileBar(
            title: Text('$index', style: const TextStyle(color: Colors.black)),
          ),
          child: Container(
            margin: const EdgeInsets.all(12.0),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              gradient: const RadialGradient(
                colors: <Color>[Color(0x0F88EEFF), Color(0x2F0099BB)],
              ),
            ),
            child: Image.network(
                "http://mobisyncserver.c4buf4a2b9czf0hc.italynorth.azurecontainer.io:3000/Desi/Mac15,6AFA33F68-3E48/2024/7/Scan%207.jpeg"),
          ),
        );
      },
    ),
  );
}
