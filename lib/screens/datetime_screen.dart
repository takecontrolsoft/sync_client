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
import 'package:sync_client/config/config.dart';
import 'package:sync_client/storage/realm.dart';
import 'package:sync_client/storage/storage.dart';
import 'package:intl/intl.dart';

enum DateTimeMenuOption { reset }

class DateTimeScreen extends StatelessWidget {
  const DateTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MainAppBar.appBar(context), body: const _DateTimeScreenView());
  }

  void resetDateTime(BuildContext context) async {
    localRealm.write(() {
      currentDevice.lastSyncDateTime = null;
    });
  }
}

class _DateTimeScreenView extends StatelessWidget {
  const _DateTimeScreenView();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          left: 10.0, right: 10.0, top: 30.0, bottom: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const Text(
            'The date time of the last synced file:',
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            currentDevice.changes.listen((changes) => setState(() {}));
            final DateFormat formatter = DateFormat('yyyy-MM-dd hh:ss');
            return ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                    'Date time: ${currentDevice.lastSyncDateTime == null ? "" : formatter.format(currentDevice.lastSyncDateTime!)}'),
                trailing: SizedBox(
                  width: 25,
                  child: PopupMenuButton<DateTimeMenuOption>(
                    onSelected: (menuItem) =>
                        handleMenuClick(context, menuItem),
                    itemBuilder: (context) => [
                      const PopupMenuItem<DateTimeMenuOption>(
                        value: DateTimeMenuOption.reset,
                        child: ListTile(
                            leading: Icon(Icons.reset_tv),
                            title: Text("Reset date")),
                      ),
                    ],
                  ),
                ),
                shape: const Border(bottom: BorderSide()));
          }),
        ],
      ),
    );
  }

  void handleMenuClick(BuildContext context, DateTimeMenuOption menuItem) {
    if (menuItem == DateTimeMenuOption.reset) {
      localRealm.write(() {
        currentDevice.lastSyncDateTime = DateTime(1800, 1, 1);
      });
    }
  }
}
