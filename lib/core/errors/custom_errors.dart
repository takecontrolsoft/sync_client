class CustomError extends Error {
  final String message;
  CustomError(this.message);
}

final class InvalidCredentialError extends CustomError {
  InvalidCredentialError() : super("Invalid username or password");
}
