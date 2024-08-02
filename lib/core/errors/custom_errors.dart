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
