import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

Widget syncFilesStatusWidget(
  BuildContext context,
  DeviceServicesCubit deviceService,
  StreamController<SyncedFile> syncedFileController,
) {
  if (deviceService.state.lastErrorMessage != null) {
    return Text(deviceService.state.lastErrorMessage ?? "",
        style: errorTextStyle(context), textAlign: TextAlign.center);
  } else {
    return StreamBuilder<SyncedFile>(
        stream: syncedFileController.stream,
        builder: (BuildContext context, AsyncSnapshot<SyncedFile> snapshot) =>
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    getStateWidgets(context, syncedFileController, snapshot)));
  }
}

List<Widget> getStateWidgets(
    BuildContext context,
    StreamController<SyncedFile> syncedFileController,
    AsyncSnapshot<SyncedFile> snapshot) {
  List<Widget> children;

  if (snapshot.hasError) {
    children = _errorState(snapshot.error as CustomError);
  } else {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
        children = const <Widget>[];
      case ConnectionState.active:
        children = _infoProgress(context, syncedFileController, snapshot);
      case ConnectionState.done:
        children = _doneState();
    }
  }
  return children;
}

List<Widget> _errorState(CustomError error) {
  return <Widget>[
    const Icon(Icons.error_outline, color: Colors.red, size: 30),
    Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
          '${error is SyncCanceledError ? "" : "Error: "}${error.message}'),
    ),
  ];
}

List<Widget> _infoProgress(
    BuildContext context,
    StreamController<SyncedFile> syncedFileController,
    AsyncSnapshot<SyncedFile> snapshot) {
  return <Widget>[
    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
    Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text('\$${snapshot.data?.filename}')),
    okButton(context, "Stop", onPressed: () async {
      syncedFileController.addError(SyncCanceledError());
      syncedFileController.close();
      await Future<void>.delayed(Duration(seconds: 1));
      Navigator.pop(context);
    }),
  ];
}

List<Widget> _doneState() {
  return <Widget>[
    const Icon(Icons.check_circle_outline, color: Colors.green, size: 30),
    const Padding(padding: EdgeInsets.only(top: 2), child: Text('Completed')),
  ];
}
