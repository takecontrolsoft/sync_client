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
import 'package:sync_client/configuration.dart';
import 'package:sync_client/background.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photos Sync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _config = Configuration();
  bool _proccessed = false;

  void _selectFolders() {
    _config.selectSourceDir();
    setState(() {
      _config.dirs;
    });
  }

  void _run() {
    setState(() {
      _proccessed = false;
    });
    BackgroundAction().execute().whenComplete(() => setState(() {
          _proccessed = true;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Selected directories to sync:',
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _config.dirs.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text('Directory: ${_config.dirs.elementAt(index)}'),
                );
              },
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: _run,
              child: const Text('Sync'),
            ),
            Text('Sync completed: ${_proccessed ? "Yes" : "No"}')
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectFolders,
        tooltip: 'Select folder',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
