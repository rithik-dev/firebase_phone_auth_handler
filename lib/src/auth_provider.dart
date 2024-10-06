import 'package:firebase_phone_auth_handler/src/auth_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrap the [MaterialApp] with [FirebasePhoneAuthProvider]
/// to enable your application to support phone authentication.
class FirebasePhoneAuthProvider extends StatelessWidget {
  const FirebasePhoneAuthProvider({
    super.key,
    required this.child,
  });

  /// The child of the widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FirebasePhoneAuthController>(
      create: (_) => FirebasePhoneAuthController(),
      child: child,
    );
  }
}
