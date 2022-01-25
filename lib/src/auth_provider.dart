import 'package:firebase_phone_auth_handler/src/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrap the [MaterialApp] with [FirebasePhoneAuthProvider]
/// to enable your application to support phone authentication.
class FirebasePhoneAuthProvider extends StatelessWidget {
  const FirebasePhoneAuthProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child of the widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FirebasePhoneAuthService(),
      child: child,
    );
  }
}
