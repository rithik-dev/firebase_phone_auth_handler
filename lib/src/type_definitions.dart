import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

typedef OnLoginSuccess = FutureOr<void> Function(UserCredential, bool);

typedef OnLoginFailed = FutureOr<void> Function(FirebaseAuthException, StackTrace);

typedef OnError = FutureOr<void> Function(Object, StackTrace);

/// The state of the current OTP send operation.
enum OtpSendStatus {
  /// No OTP has been requested yet, or the controller has been cleared.
  ///
  /// This is the state a handler sits in when `sendOtpOnInitialize` is false
  /// and [FirebasePhoneAuthController.sendOTP] has not been called yet.
  idle,

  /// An OTP is currently being sent.
  sending,

  /// The OTP was sent successfully and is awaiting verification.
  sent,

  /// The last send attempt failed.
  ///
  /// The failure has already been reported through `onLoginFailed` or
  /// `onError`. Calling [FirebasePhoneAuthController.sendOTP] again retries.
  failed,
}
