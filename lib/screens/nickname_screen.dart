/*
	Copyright 2024 Take Control - Software & Infrastructure

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
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  NicknameScreenState createState() => NicknameScreenState();
}

class NicknameScreenState extends State<NicknameScreen> {
  bool? _hasName;

  String? _errorMessage;

  late TextEditingController _nicknameController;

  @override
  void initState() {
    _nicknameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceService = context.read<DeviceServicesCubit>();
    _hasName ??= (deviceService.state.currentUser?.email ?? "").isNotEmpty;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.only(top: 30),
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                    _hasName!
                        ? "Your name is: ${deviceService.state.currentUser!.email}"
                        : "Please write your new name or nickname",
                    style: const TextStyle(fontSize: 25)),
                _hasName!
                    ? Container()
                    : loginField(_nicknameController,
                        labelText: "Nickname",
                        hintText: "Enter letters or numbers without spaces"),
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: Text(
                      "You can use this nickname to find your files on Mobi Sync Server.",
                      textAlign: TextAlign.center),
                ),
                loginButton(context,
                    child: const Text("Start"),
                    onPressed: () => _logInOrSignUpUser(
                        context,
                        _hasName!
                            ? deviceService.state.currentUser!.email
                            : _nicknameController.text,
                        "")),
                TextButton(
                    onPressed: () => setState(() => _hasName = !_hasName!),
                    child: Text(
                      (deviceService.state.currentUser?.email ?? "").isNotEmpty
                          ? _hasName!
                              ? "I want to enter a new nickname."
                              : "Go with my existing nickname."
                          : "",
                    )),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Text(_errorMessage ?? "",
                      style: errorTextStyle(context),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _logInOrSignUpUser(
      BuildContext context, String email, String password) async {
    final deviceServices = context.read<DeviceServicesCubit>();
    clearError();
    try {
      if (email.isEmpty) {
        throw RequiredNicknameError();
      }
      await deviceServices.registerUserEmailPassword(email, password);
      setState(() {
        context.push("/");
        if ((deviceServices.state.serverUrl ?? "").trim() == "") {
          context.push("/sync");
        }
      });
    } catch (err) {
      setState(() {
        if (err is CustomError) {
          _errorMessage = err.message;
          return;
        }
        _errorMessage = err.toString();
      });
    }
  }
}
