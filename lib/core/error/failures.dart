// lib/core/error/failures.dart

/// Base failure class. All domain-level errors extend this.
abstract class Failure {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure($code): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class TransferFailure extends Failure {
  const TransferFailure(super.message, {super.code});
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message, {super.code});
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.code});
}

class PeerNotFoundFailure extends Failure {
  const PeerNotFoundFailure(super.message, {super.code});
}

class CancelledFailure extends Failure {
  const CancelledFailure(super.message, {super.code});
}

// lib/core/error/exceptions.dart

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic cause;
  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() => 'AppException[$code]: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

class TransferException extends AppException {
  const TransferException(super.message, {super.code, super.cause});
}

class SecurityException extends AppException {
  const SecurityException(super.message, {super.code, super.cause});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.cause});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.cause});
}
