
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockFirebaseAuth auth;
  late FirebasePhoneAuthController controller;

  setUpAll(() {
    registerFallbackValue(MockAuthCredential());
    registerFallbackValue(MockFirebaseAuthException());
    registerFallbackValue(const Duration(seconds: 30));
  });

  setUp(() {
    auth = MockFirebaseAuth();
    when(() => auth.signOut()).thenAnswer((_) async => {});
    controller = FirebasePhoneAuthController(auth: auth);
  });

  group('FirebasePhoneAuthController - Verification Logic', () {
    test('sendOTP fails if phoneNumber is not set', () async {
      // Expect error or false because _phoneNumber is null initially
      final result = await controller.sendOTP();
      expect(result, isFalse);
    });

    test('verifyOtp returns false if verificationId is missing', () async {
      final result = await controller.verifyOtp('123456');
      expect(result, isFalse);
    });
  });

  group('FirebasePhoneAuthController - Basic State', () {
    test('initial state is correct', () {
      expect(controller.codeSent, isFalse);
      expect(controller.isSendingCode, isTrue);
      expect(controller.isOtpExpired, isTrue);
    });

    test('clear() resets state', () {
      controller.clear();
      expect(controller.codeSent, isFalse);
      expect(controller.isOtpExpired, isTrue);
    });

    test('signOut() calls firebase auth signOut', () async {
      await controller.signOut();
      verify(() => auth.signOut()).called(1);
    });
  });
}
