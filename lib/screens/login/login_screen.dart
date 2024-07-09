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
import 'package:sync_client/screens/components/components.dart';
import 'package:sync_client/services/services.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  bool _isLogin = true;
  String? _errorMessage;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    _emailController = TextEditingController()..addListener(clearError);
    _passwordController = TextEditingController()..addListener(clearError);
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.only(top: 30),
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(_isLogin ? 'Log In' : 'Sign Up',
                    style: const TextStyle(fontSize: 25)),
                loginField(_emailController,
                    labelText: "Email",
                    hintText: "Enter valid email like abc@gmail.com"),
                loginField(_passwordController,
                    labelText: "Password",
                    hintText: "Enter secure password",
                    obscure: true),
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: Text(
                      "Please login or register with a Mobi Sync user account.",
                      textAlign: TextAlign.center),
                ),
                loginButton(context,
                    child: Text(_isLogin ? "Log in" : "Sign up"),
                    onPressed: () => _logInOrSignUpUser(context,
                        _emailController.text, _passwordController.text)),
                TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "New to Mobi Sync? Sign up"
                          : 'Already have an account? Log in.',
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
        // Reset error message when user starts typing
        _errorMessage = null;
      });
    }
  }

  void _logInOrSignUpUser(
      BuildContext context, String email, String password) async {
    final appServices = context.read<AppServicesCubit>();
    clearError();
    try {
      if (_isLogin) {
        await appServices.logInUserEmailPassword(email, password);
      } else {
        await appServices.registerUserEmailPassword(email, password);
      }
      setState(() {
        context.push("/");
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString();
      });
    }
  }
}
