import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_client/services/services.dart';
import 'widgets.dart';

class EditServerForm extends StatefulWidget {
  final String item;
  const EditServerForm(this.item, {super.key});

  @override
  EditServerFormState createState() => EditServerFormState(item);
}

class EditServerFormState extends State<EditServerForm> {
  final _formKey = GlobalKey<FormState>();
  final String item;
  late TextEditingController _serverController;

  EditServerFormState(this.item);

  @override
  void initState() {
    _serverController = TextEditingController(text: item);
    super.initState();
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    return formLayout(
        context,
        Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Text("Enter server address (http://ip:3000)"),
                TextFormField(
                  controller: _serverController,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      cancelButton(context),
                      okButton(context, "Update",
                          onPressed: () async => await update(
                              context, deviceService, _serverController.text)),
                    ],
                  ),
                ),
              ],
            )));
  }

  Future<void> update(BuildContext context, DeviceServicesCubit deviceService,
      String newServer) async {
    if (_formKey.currentState!.validate()) {
      await deviceService.edit((state) {
        if (state.serverUrl != newServer) {
          state.syncedFiles.clear();
        }
        state.serverUrl = newServer;
        state.lastErrorMessage = null;
        state.lastSyncDateTime = null;
      });
      // ignore: use_build_context_synchronously
      context.pop();
    }
  }
}
