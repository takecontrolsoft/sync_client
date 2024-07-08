import 'package:flutter/material.dart';
import 'package:sync_client/storage/realm.dart';
import '../widgets.dart';

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
    return formLayout(
        context,
        Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("Enter server name or IP address"),
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
                          onPressed: () async =>
                              await update(context, _serverController.text)),
                    ],
                  ),
                ),
              ],
            )));
  }

  Future<void> update(BuildContext context, String newServer) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        localRealm.write(() {
          currentDevice.settings?.serverUrl = newServer;
        });
      });
      Navigator.pop(context);
    }
  }
}
