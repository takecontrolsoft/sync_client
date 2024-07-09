import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realm/realm.dart';
import 'package:sync_client/storage/storage.dart';

class AppServicesCubit extends Cubit<App> {
  String id;
  User? currentUser;
  AppServicesCubit(this.id) : super(App(AppConfiguration(id)));

  Future<User> logInUserEmailPassword(String email, String password) async {
    User loggedInUser =
        await state.logIn(Credentials.emailPassword(email, password));
    currentUser = loggedInUser;
    emit(state);
    return loggedInUser;
  }

  Future<User> registerUserEmailPassword(String email, String password) async {
    EmailPasswordAuthProvider authProvider = EmailPasswordAuthProvider(state);
    await authProvider.registerUser(email, password);
    User loggedInUser =
        await state.logIn(Credentials.emailPassword(email, password));
    await setRole(loggedInUser);
    await loggedInUser.refreshCustomData();
    currentUser = loggedInUser;
    emit(state);
    return loggedInUser;
  }

  Future<void> setRole(User loggedInUser) async {
    final realm = Realm(Configuration.flexibleSync(
        loggedInUser, [Role.schema, RemoteFolder.schema]));
    String subscriptionName = "rolesSubscription";
    realm.subscriptions.update((mutableSubscriptions) =>
        mutableSubscriptions.add(realm.all<Role>(), name: subscriptionName));
    await realm.subscriptions.waitForSynchronization();
    realm.write(
        () => realm.add(Role(ObjectId(), loggedInUser.id, isAdmin: false)));
    await realm.syncSession.waitForUpload();
    realm.subscriptions.update((mutableSubscriptions) =>
        mutableSubscriptions.removeByName(subscriptionName));
    await realm.subscriptions.waitForSynchronization();
    await realm.syncSession.waitForDownload();
    realm.close();
  }

  Future<void> logOut() async {
    await currentUser?.logOut();
    currentUser = null;
  }
}
