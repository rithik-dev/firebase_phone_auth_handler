import 'package:firebase_phone_auth_handler/src/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrap the [MaterialApp] with [FirebasePhoneAuthSupporter]
/// to enable your application to support phone authentication.
class FirebasePhoneAuthSupporter extends StatelessWidget {
  /// The child of the widget.
  final Widget child;

  const FirebasePhoneAuthSupporter({required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebasePhoneAuthService()),
      ],
      child: this.child,
    );
  }
}
