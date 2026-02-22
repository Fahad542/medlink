class AppException implements Exception {
  final _message;
  final _prefix;

  AppException([this._message, this._prefix]);

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
      : super(message, "");
}

class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message, "");
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String? message])
      : super(message, "");
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, "");
}
