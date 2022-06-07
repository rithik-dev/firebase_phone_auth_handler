import 'package:easy_container/easy_container.dart';
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter/material.dart';
import 'package:phone_auth_handler_demo/screens/authentication_screen.dart';
import 'package:phone_auth_handler_demo/utils/globals.dart';
import 'package:phone_auth_handler_demo/utils/helpers.dart';

class HomeScreen extends StatelessWidget {
  static const id = 'HomeScreen';

  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    child: Text('Logged in user UID'),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  child: Text(Globals.firebaseUser!.uid),
                ),
              ),
              EasyContainer(
                onTap: () async {
                  await FirebasePhoneAuthHandler.signOut(context);
                  showSnackBar('Logged out successfully!');

                  // ignore: use_build_context_synchronously
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AuthenticationScreen.id,
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
