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

import 'package:go_router/go_router.dart';
import 'package:sync_client/screens/screens.dart';

GoRouter getAppRouter() {
  return GoRouter(initialLocation: '/', routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/sync',
      builder: (context, state) => const SyncScreen(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/servers',
      builder: (context, state) => const ServersListScreen(),
    ),
    GoRoute(
      path: '/folders',
      builder: (context, state) => const FoldersListScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const NicknameScreen(), // const LogInScreen(),
    ),
  ]);
}
