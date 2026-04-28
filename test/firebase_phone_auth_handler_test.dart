import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockFirebaseAuth auth;

  setUpAll(() {
    registerFallbackValue(MockAuthCredential());
    registerFallbackValue(MockFirebaseAuthException());
    registerFallbackValue(const Duration(seconds: 30));
  });

  setUp(() {
    auth = MockFirebaseAuth();
    when(() => auth.signOut()).thenAnswer((_) async => {});
  });

  testWidgets('FirebasePhoneAuthHandler triggers onCodeSent when OTP is sent',
      (WidgetTester tester) async {
    bool codeSentCalled = false;

    // Mock verifyPhoneNumber to trigger codeSent callback
    when(() => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeSent: any(named: 'codeSent'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          timeout: any(named: 'timeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        )).thenAnswer((invocation) async {
      final codeSentCallback =
          invocation.namedArguments[#codeSent] as PhoneCodeSent;
      codeSentCallback('test-ver-id', 123);
    });

    await tester.pumpWidget(
      FirebasePhoneAuthProvider(
        auth: auth,
        child: MaterialApp(
          home: Scaffold(
            body: FirebasePhoneAuthHandler(
              phoneNumber: '+1234567890',
              sendOtpOnInitialize: true,
              onCodeSent: () {
                codeSentCalled = true;
              },
              builder: (context, controller) {
                return Text(controller.codeSent ? 'CODE_SENT' : 'SENDING');
              },
            ),
          ),
        ),
      ),
    );

    // Initial pump might not trigger the async callback immediately
    await tester.pumpAndSettle();

    expect(codeSentCalled, isTrue);
    expect(find.text('CODE_SENT'), findsOneWidget);
  });

  testWidgets(
      'FirebasePhoneAuthHandler triggers onLoginSuccess on verification success',
      (WidgetTester tester) async {
    UserCredential? successCredential;
    final mockUserCredential = MockUserCredential();
    final mockUser = MockUser();
    when(() => mockUserCredential.user).thenReturn(mockUser);

    // Mock verifyPhoneNumber to trigger codeSent
    when(() => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeSent: any(named: 'codeSent'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          timeout: any(named: 'timeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        )).thenAnswer((invocation) async {
      final codeSentCallback =
          invocation.namedArguments[#codeSent] as PhoneCodeSent;
      codeSentCallback('test-ver-id', 123);
    });

    // Mock signInWithCredential for manual verification
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => mockUserCredential);

    await tester.pumpWidget(
      FirebasePhoneAuthProvider(
        auth: auth,
        child: MaterialApp(
          home: Scaffold(
            body: FirebasePhoneAuthHandler(
              phoneNumber: '+1234567890',
              sendOtpOnInitialize: true,
              onLoginSuccess: (credential, autoVerified) {
                successCredential = credential;
              },
              builder: (context, controller) {
                return ElevatedButton(
                  onPressed: () => controller.verifyOtp('123456'),
                  child: const Text('VERIFY'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Wait for codeSent
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();

    expect(successCredential, isNotNull);
    verify(() => auth.signInWithCredential(any())).called(1);
  });

  testWidgets(
      'FirebasePhoneAuthHandler triggers onLoginFailed on verification failure',
      (WidgetTester tester) async {
    FirebaseAuthException? loginException;

    // Mock verifyPhoneNumber to trigger codeSent
    when(() => auth.verifyPhoneNumber(
          phoneNumber: any(named: 'phoneNumber'),
          verificationCompleted: any(named: 'verificationCompleted'),
          verificationFailed: any(named: 'verificationFailed'),
          codeSent: any(named: 'codeSent'),
          codeAutoRetrievalTimeout: any(named: 'codeAutoRetrievalTimeout'),
          timeout: any(named: 'timeout'),
          forceResendingToken: any(named: 'forceResendingToken'),
        )).thenAnswer((invocation) async {
      final codeSentCallback =
          invocation.namedArguments[#codeSent] as PhoneCodeSent;
      codeSentCallback('test-ver-id', 123);
    });

    // Mock signInWithCredential to throw FirebaseAuthException
    final mockException = MockFirebaseAuthException();
    when(() => mockException.code).thenReturn('invalid-verification-code');
    when(() => mockException.message).thenReturn('The code is invalid.');
    when(() => auth.signInWithCredential(any())).thenThrow(mockException);

    await tester.pumpWidget(
      FirebasePhoneAuthProvider(
        auth: auth,
        child: MaterialApp(
          home: Scaffold(
            body: FirebasePhoneAuthHandler(
              phoneNumber: '+1234567890',
              sendOtpOnInitialize: true,
              onLoginFailed: (exception, stackTrace) {
                loginException = exception;
              },
              builder: (context, controller) {
                return ElevatedButton(
                  onPressed: () => controller.verifyOtp('000000'),
                  child: const Text('VERIFY_FAIL'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('VERIFY_FAIL'));
    await tester.pumpAndSettle();

    expect(loginException, isNotNull);
    expect(loginException!.code, 'invalid-verification-code');
  });
}
