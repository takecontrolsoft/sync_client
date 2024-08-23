import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';
import 'package:sync_client/storage/storage.dart';

Widget syncFilesStatusWidget(BuildContext context,
    DeviceServicesCubit deviceService, SyncServicesCubit syncService) {
  if (deviceService.state.lastErrorMessage != null) {
    return Text(deviceService.state.lastErrorMessage ?? "",
        style: errorTextStyle(context), textAlign: TextAlign.center);
  } else {
    return StreamBuilder<SyncedFile>(
        stream: syncService.state?.stream,
        builder: (BuildContext context, AsyncSnapshot<SyncedFile> snapshot) =>
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getStateWidgets(
                    context, syncService, deviceService, snapshot)));
  }
}

List<Widget> getStateWidgets(
    BuildContext context,
    SyncServicesCubit syncService,
    DeviceServicesCubit deviceService,
    AsyncSnapshot<SyncedFile> snapshot) {
  List<Widget> children;

  if (snapshot.hasError) {
    children = _errorState(context, syncService, snapshot.error as CustomError);
  } else {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        children = [closeButton(context)];
      case ConnectionState.waiting:
        children = [];
      case ConnectionState.active:
        children = _infoProgress(context, syncService, deviceService, snapshot);
      case ConnectionState.done:
        children = _doneState(context, syncService, deviceService);
    }
  }
  return children;
}

List<Widget> _errorState(
    BuildContext context, SyncServicesCubit syncService, CustomError error) {
  return <Widget>[
    const Icon(Icons.error_outline, color: Colors.red, size: 30),
    Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
          '${error is SyncCanceledError ? "" : "Error: "}${error.message}'),
    ),
  ];
}

List<Widget> _infoProgress(BuildContext context, SyncServicesCubit syncService,
    DeviceServicesCubit deviceService, AsyncSnapshot<SyncedFile> snapshot) {
  return <Widget>[
    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
    Center(
        child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${snapshot.data?.filename}',
              textAlign: TextAlign.center,
            ))),
    okButton(context, "Stop", onPressed: () {
      if (syncService.state != null) {
        if (!syncService.state!.isClosed) {
          syncService.state!.addError(SyncCanceledError());
          syncService.state!.close();
          syncService.reset();
        }
      }
      deviceService.edit((state) {
        state.isSyncing = false;
      });
    }),
  ];
}

List<Widget> _doneState(BuildContext context, SyncServicesCubit syncService,
    DeviceServicesCubit deviceService) {
  deviceService.edit((state) {
    state.isSyncing = false;
  });
  syncService.reset();
  return <Widget>[
    const Icon(Icons.check_circle_outline, color: Colors.green, size: 30),
    const Padding(padding: EdgeInsets.only(top: 2), child: Text('Completed'))
  ];
}
