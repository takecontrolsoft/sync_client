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
import 'package:get_it/get_it.dart';
import 'package:sync_client/config/config.dart';
import 'package:sync_client/core/core.dart';
import 'screens/cubits.dart';

GetIt getIt = GetIt.instance;

void serviceLocatorInit() {
  getIt.registerLazySingleton(() => RouterExtendedCubit());
  getIt.registerLazySingleton(() => ThemeCubit());
  getIt.registerLazySingleton(() => Configuration());
  getIt.registerLazySingleton(() => FoldersCubit());
}
