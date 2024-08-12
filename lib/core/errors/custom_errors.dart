class CustomError extends Error {
  final String message;
  CustomError(this.message);
}

final class InvalidCredentialError extends CustomError {
  InvalidCredentialError() : super("Invalid username or password");
}

final class RequiredNicknameError extends CustomError {
  RequiredNicknameError() : super("Nickname is required.");
}

final class SyncCanceledError extends CustomError {
  SyncCanceledError() : super("Canceled operation.");
}

final class SyncError extends CustomError {
  SyncError(String errorText) : super("Synchronization error: $errorText");
}

final class GetFoldersError extends CustomError {
  GetFoldersError() : super("Failed to get folders from server.");
}
