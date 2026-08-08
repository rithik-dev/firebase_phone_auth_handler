import 'package:firebase_phone_auth_handler/firebase_phone_auth_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests deliberately avoid any code path that touches
/// `FirebaseAuth.instance`, so no Firebase app needs to be initialised.
/// `_auth` is a lazily initialised static, so constructing a controller and
/// reading its state never reaches Firebase.
void main() {
  group('FirebasePhoneAuthController defaults', () {
    test('a fresh controller is not sending a code', () {
      final controller = FirebasePhoneAuthController();
      addTearDown(controller.dispose);

      // Regression: isSendingCode used to be defined as `!codeSent`, which
      // reported "sending" for a controller that had never sent anything.
      // `idle` is the state that boolean pair could not express.
      expect(controller.otpSendStatus, OtpSendStatus.idle);
    });

    test('no OTP timer is running before a code is sent', () {
      final controller = FirebasePhoneAuthController();
      addTearDown(controller.dispose);

      expect(controller.isOtpExpired, isTrue);
      expect(controller.isListeningForOtpAutoRetrieve, isFalse);
    });

    test('time-left getters fall back to the default duration', () {
      final controller = FirebasePhoneAuthController();
      addTearDown(controller.dispose);

      const fallback = FirebasePhoneAuthController.kAutoRetrievalTimeOutDuration;
      expect(controller.otpExpirationTimeLeft, fallback);
      expect(controller.autoRetrievalTimeLeft, fallback);
    });

    test('verifyOtp returns false when no code has been sent', () async {
      final controller = FirebasePhoneAuthController();
      addTearDown(controller.dispose);

      await expectLater(controller.verifyOtp('123456'), completion(isFalse));
    });

    test('constructing never touches FirebaseAuth.instance', () {
      // No Firebase app is initialised in this suite. Resolving the auth
      // instance eagerly in the constructor — `auth ?? FirebaseAuth.instance`
      // — would throw here and make the controller untestable without Firebase.
      expect(FirebasePhoneAuthController.new, returnsNormally);
      expect(() => FirebasePhoneAuthController(auth: null), returnsNormally);
    });

    test('dispose() releases state', () {
      final controller = FirebasePhoneAuthController();

      controller.dispose();

      // Reading is still safe after disposal; listening is not.
      expect(controller.otpSendStatus, OtpSendStatus.idle);
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    test('dispose() does not throw with no timers running', () {
      final controller = FirebasePhoneAuthController();
      expect(controller.dispose, returnsNormally);
    });

    test('sendOTP resolves to a terminal state instead of hanging', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final controller = FirebasePhoneAuthController();
      addTearDown(controller.dispose);

      // No Firebase app is initialised here, so reaching FirebaseAuth.instance
      // throws. What matters is that the failure is caught and turned into a
      // terminal status rather than leaving the controller in `sending` — the
      // state that shows a loader forever.
      final result = await controller
          .sendOTP(codeSendTimeout: const Duration(milliseconds: 50))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => fail('sendOTP hung instead of failing'),
          );

      expect(result, isFalse);
      expect(controller.otpSendStatus, OtpSendStatus.failed);
    });

    test('kCodeSendTimeout is the documented default', () {
      expect(
        FirebasePhoneAuthController.kCodeSendTimeout,
        const Duration(seconds: 60),
      );
    });

    test('boolean shorthands derive from otpSendStatus', () {
      final controller = FirebasePhoneAuthController();
      addTearDown(controller.dispose);

      // `idle` must report neither sent nor sending — the exact case the old
      // `isSendingCode = !codeSent` definition got wrong.
      expect(controller.otpSendStatus, OtpSendStatus.idle);
      expect(controller.codeSent, isFalse);
      expect(controller.isSendingCode, isFalse);
    });
  });

  group('FirebasePhoneAuthHandler wiring', () {
    Widget wrap({
      required Duration autoRetrievalTimeOutDuration,
      required Duration otpExpirationDuration,
      required void Function(FirebasePhoneAuthController) onBuild,
    }) {
      // No provider wrapper: the handler creates and owns its own controller.
      return FirebasePhoneAuthHandler(
        phoneNumber: '+911234567890',
        sendOtpOnInitialize: false,
        autoRetrievalTimeOutDuration: autoRetrievalTimeOutDuration,
        otpExpirationDuration: otpExpirationDuration,
        builder: (context, controller) {
          onBuild(controller);
          return const SizedBox.shrink();
        },
      );
    }

    testWidgets('durations passed to the widget reach the controller', (
      tester,
    ) async {
      late FirebasePhoneAuthController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: wrap(
            autoRetrievalTimeOutDuration: const Duration(seconds: 30),
            otpExpirationDuration: const Duration(seconds: 45),
            onBuild: (c) => controller = c,
          ),
        ),
      );

      expect(controller.autoRetrievalTimeLeft, const Duration(seconds: 30));
      expect(controller.otpExpirationTimeLeft, const Duration(seconds: 45));
    });

    testWidgets('sendOtpOnInitialize: false leaves otpSendStatus idle', (
      tester,
    ) async {
      late FirebasePhoneAuthController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: wrap(
            autoRetrievalTimeOutDuration: const Duration(seconds: 30),
            otpExpirationDuration: const Duration(seconds: 30),
            onBuild: (c) => controller = c,
          ),
        ),
      );

      // Regression: this used to report true forever, so a UI gated on
      // isSendingCode would show a "sending OTP" spinner that never cleared.
      expect(controller.otpSendStatus, OtpSendStatus.idle);
    });

    testWidgets('each mount gets a fresh controller, disposed on unmount', (
      tester,
    ) async {
      final controllers = <FirebasePhoneAuthController>[];
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);

      Widget app(Duration autoRetrieval) => MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, showHandler, _) {
            if (!showHandler) return const SizedBox.shrink();
            return FirebasePhoneAuthHandler(
              phoneNumber: '+911234567890',
              sendOtpOnInitialize: false,
              autoRetrievalTimeOutDuration: autoRetrieval,
              otpExpirationDuration: const Duration(seconds: 30),
              builder: (context, controller) {
                if (!controllers.contains(controller)) {
                  controllers.add(controller);
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      );

      await tester.pumpWidget(app(const Duration(seconds: 30)));
      expect(controllers, hasLength(1));

      // Unmount. The handler owns the controller, so it is disposed outright —
      // no leftover session can reach the next screen.
      visible.value = false;
      await tester.pumpAndSettle();
      expect(
        () => controllers.first.addListener(() {}),
        throwsFlutterError,
        reason: 'the first controller should have been disposed on unmount',
      );

      // Remounting builds a brand new controller rather than reviving the old
      // one, so nothing carries over between verification sessions.
      await tester.pumpWidget(app(const Duration(seconds: 90)));
      visible.value = true;
      await tester.pumpAndSettle();

      expect(controllers, hasLength(2));
      expect(controllers[1], isNot(same(controllers[0])));
      expect(controllers[1].otpSendStatus, OtpSendStatus.idle);
      expect(controllers[1].autoRetrievalTimeLeft, const Duration(seconds: 90));
      expect(tester.takeException(), isNull);
    });

    testWidgets('two handlers keep independent durations', (tester) async {
      late FirebasePhoneAuthController first;
      late FirebasePhoneAuthController second;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              wrap(
                autoRetrievalTimeOutDuration: const Duration(seconds: 30),
                otpExpirationDuration: const Duration(seconds: 30),
                onBuild: (c) => first = c,
              ),
              wrap(
                autoRetrievalTimeOutDuration: const Duration(seconds: 90),
                otpExpirationDuration: const Duration(seconds: 90),
                onBuild: (c) => second = c,
              ),
            ],
          ),
        ),
      );

      // Regression: these durations used to be stored in static fields, so the
      // second handler's configuration overwrote the first one's.
      expect(first.autoRetrievalTimeLeft, const Duration(seconds: 30));
      expect(second.autoRetrievalTimeLeft, const Duration(seconds: 90));
    });
  });
}
