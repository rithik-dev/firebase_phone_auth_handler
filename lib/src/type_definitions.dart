import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

typedef OnLoginSuccess = FutureOr<void> Function(UserCredential, bool);

typedef OnLoginFailed = FutureOr<void> Function(
  FirebaseAuthException,
  StackTrace,
);

typedef OnError = FutureOr<void> Function(
  Object,
  StackTrace,
);
