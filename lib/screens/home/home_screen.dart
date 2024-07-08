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
import 'package:go_router/go_router.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/storage/storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar.appBar(context),
      body: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text("Server address"),
              subtitle: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  currentDevice.settings?.changes
                      .listen((changes) => setState(() {}));
                  return Text(
                      "Server set to: ${currentDevice.settings?.serverUrl}");
                },
              ),
              onTap: () {
                context.push("/servers");
              },
            ),
            ListTile(
              title: const Text("Folders to sync"),
              subtitle:
                  const Text("A list of folders to be send to the server"),
              onTap: () {
                context.push("/folders");
              },
            )
          ],
        ),
      ),
      SizedBox(
          width: double.maxFinite,
          child: okButton(context, "Send to server", onPressed: () => _run())),
    ]);
  }

  void _run() async {
    BackgroundAction().execute();
  }
}
