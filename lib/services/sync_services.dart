import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_client/storage/storage.dart';

class SyncServicesCubit extends Cubit<StreamController<SyncedFile>?> {
  SyncServicesCubit() : super(null);

  void reset() {
    emit(StreamController<SyncedFile>.broadcast());
  }
}
