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
import 'package:path/path.dart';
import 'package:sync_client/core/core.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo Live"),
      ),
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
              title: const Text("Server list"),
              subtitle:
                  const Text("Detect all photo sync servers in the network"),
              onTap: () {
                context.go("/servers");
              },
            ),
            ListTile(
              title: const Text("Select Folder"),
              subtitle:
                  const Text("Detect all photo sync servers in the network"),
              onTap: () {
                context.go("/folders");
              },
            )
          ],
        ),
      ),
      SizedBox(
        width: double.maxFinite,
        child: TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
          ),
          onPressed: _run,
          child: const Text('Sync'),
        ),
      ),
    ]);
  }

  void _run() {
    BackgroundAction().execute();
  }
}
