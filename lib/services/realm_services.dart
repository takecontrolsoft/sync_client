import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realm/realm.dart';
import 'package:sync_client/storage/storage.dart';

class RealmServicesCubit extends Cubit<Realm> {
  bool isWaiting = false;
  App app;

  RealmServicesCubit(this.app)
      : super(Realm(Configuration.flexibleSync(
            app.currentUser!, [RemoteFolder.schema]))) {
    if (state.subscriptions.isEmpty) {
      updateSubscriptions();
    }
    print(state.config.path);
  }

  Future<void> updateSubscriptions() async {
    state.subscriptions.update((mutableSubscriptions) {
      mutableSubscriptions.clear();
      mutableSubscriptions.add(state.all<RemoteFolder>());
    });
    await state.subscriptions.waitForSynchronization();
  }

  @override
  Future<void> close() async {
    if (app.currentUser != null) {
      await app.currentUser?.logOut();
    }
    state.close();
    super.close();
  }
}

extension UserPermisisons on User {
  bool get isAdmin => customData?["isAdmin"] ?? false;
}
