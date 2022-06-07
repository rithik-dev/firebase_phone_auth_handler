import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

class FirebasePhoneAuthController extends ChangeNotifier {
  static FirebasePhoneAuthController of(
    BuildContext context, {
    bool listen = true,
  }) =>
      Provider.of<FirebasePhoneAuthController>(context, listen: listen);

  /// {@macro timeOutDuration}
  static const kTimeOutDuration = Duration(seconds: 60);

  /// Firebase auth instance using the default [FirebaseApp].
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Web confirmation result for OTP.
  ConfirmationResult? _webConfirmationResult;

  /// {@macro recaptchaVerifierForWeb}
  RecaptchaVerifier? _recaptchaVerifierForWeb;

  /// The [_forceResendingToken] obtained from [codeSent]
  /// callback to force re-sending another verification SMS before the
  /// auto-retrieval timeout.
  int? _forceResendingToken;

  /// {@macro phoneNumber}
  String? _phoneNumber;

  /// The phone auth verification ID.
  String? _verificationId;

  /// Timer object for SMS auto-retrieval.
  Timer? _timer;

  /// Whether OTP to the given phoneNumber is sent or not.
  bool codeSent = false;

  /// Whether the current platform is web or not;
  bool get isWeb => kIsWeb;

  /// {@macro onLoginSuccess}
  FutureOr<void> Function(UserCredential, bool)? _onLoginSuccess;

  /// {@macro onLoginFailed}
  FutureOr<void> Function(FirebaseAuthException)? _onLoginFailed;

  /// Set callbacks and other data. (only for internal use)
  ///
  /// Do not call explicitly.
  void setData(
      {required String phoneNumber,
      required FutureOr<void> Function(UserCredential, bool)? onLoginSuccess,
      required FutureOr<void> Function(FirebaseAuthException)? onLoginFailed,
      RecaptchaVerifier? recaptchaVerifierForWeb,
      Duration timeOutDuration = kTimeOutDuration,
      bool? isUserVerifyOnly}) {
    _phoneNumber = phoneNumber;
    _onLoginSuccess = onLoginSuccess;
    _onLoginFailed = onLoginFailed;
    _timeoutDuration = timeOutDuration;
    if (kIsWeb) _recaptchaVerifierForWeb = recaptchaVerifierForWeb;
  }

  /// After a [Duration] of [timerCount], the library no more waits for SMS auto-retrieval.
  Duration get timerCount =>
      Duration(seconds: _timeoutDuration.inSeconds - (_timer?.tick ?? 0));

  /// Whether the timer is active or not.
  bool get timerIsActive => _timer?.isActive ?? false;

  /// {@macro timeOutDuration}
  static Duration _timeoutDuration = kTimeOutDuration;

  /// Verify the OTP sent to [_phoneNumber] and login user is OTP was correct.
  ///
  /// Returns true if the [otp] passed was correct and the user was logged in successfully.
  /// On login success, [_onLoginSuccess] is called.
  ///
  /// If the [otp] passed is incorrect, or the [otp] is expired or any other
  /// error occurs, the functions returns false.
  ///
  /// Also, [_onLoginFailed] is called with [FirebaseAuthException]
  /// object to handle the error.
  Future<bool> verifyOTP(
      {required String otp, bool isUserVerifyOnly = false}) async {
    if ((!kIsWeb && _verificationId == null) ||
        (kIsWeb && _webConfirmationResult == null)) return false;
    try {
      if (kIsWeb) {
        final userCredential = await _webConfirmationResult!.confirm(otp);
        return await _loginUser(
          userCredential: userCredential,
          autoVerified: false,
        );
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
        if (isUserVerifyOnly) {
          return await _verifyUserPhoneOnly(
            authCredential: credential,
            autoVerified: false,
          );
        }
        return await _loginUser(
          authCredential: credential,
          autoVerified: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (_onLoginFailed != null) _onLoginFailed!(e);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Send OTP to the given [_phoneNumber].
  ///
  /// Returns true if OTP was sent successfully.
  ///
  /// If for any reason, the OTP is not send,
  /// [_onLoginFailed] is called with [FirebaseAuthException]
  /// object to handle the error.
  Future<bool> sendOTP() async {
    codeSent = false;
    await Future.delayed(Duration.zero, notifyListeners);

    verificationCompletedCallback(AuthCredential authCredential) async {
      await _loginUser(authCredential: authCredential, autoVerified: true);
    }

    verificationFailedCallback(FirebaseAuthException authException) {
      if (_onLoginFailed != null) _onLoginFailed!(authException);
    }

    codeSentCallback(
      String verificationId, [
      int? forceResendingToken,
    ]) async {
      _verificationId = verificationId;
      _forceResendingToken = forceResendingToken;
      codeSent = true;
      notifyListeners();
      _setTimer();
    }

    codeAutoRetrievalTimeoutCallback(String verificationId) {
      _verificationId = verificationId;
    }

    try {
      if (kIsWeb) {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(
          _phoneNumber!,
          _recaptchaVerifierForWeb,
        );
        codeSent = true;
        _setTimer();
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumber!,
          verificationCompleted: verificationCompletedCallback,
          verificationFailed: verificationFailedCallback,
          codeSent: codeSentCallback,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeoutCallback,
          timeout: _timeoutDuration,
          forceResendingToken: _forceResendingToken,
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (_onLoginFailed != null) _onLoginFailed!(e);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Called when the otp is verified either automatically (OTP auto fetched)
  /// or [verifyOTP] was called with the correct OTP.
  ///
  /// If true is returned that means the user was logged in successfully.
  ///
  /// If for any reason, the user fails to login,
  /// [_onLoginFailed] is called with [FirebaseAuthException]
  /// object to handle the error and false is returned.
  Future<bool> _loginUser({
    AuthCredential? authCredential,
    UserCredential? userCredential,
    required bool autoVerified,
  }) async {
    if (kIsWeb) {
      if (userCredential != null) {
        if (_onLoginSuccess != null) {
          _onLoginSuccess!(userCredential, autoVerified);
        }
        return true;
      } else {
        return false;
      }
    }

    // Not on web.
    try {
      final authResult = await _auth.signInWithCredential(authCredential!);
      if (_onLoginSuccess != null) _onLoginSuccess!(authResult, autoVerified);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_onLoginFailed != null) _onLoginFailed!(e);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Called when the otp is verified either automatically (OTP auto fetched)
  /// or [verifyOTP] was called with the correct OTP.
  ///
  /// If true is returned that means the user was logged in successfully.
  ///
  /// If for any reason, the user fails to login,
  /// [_onLoginFailed] is called with [FirebaseAuthException]
  /// object to handle the error and false is returned.
  Future<bool> _verifyUserPhoneOnly({
    AuthCredential? authCredential,
    UserCredential? userCredential,
    required bool autoVerified,
  }) async {
    if (kIsWeb) {
      if (userCredential != null) {
        if (_onLoginSuccess != null) {
          _onLoginSuccess!(userCredential, autoVerified);
        }
        return true;
      } else {
        return false;
      }
    }

    // Not on web.
    try {
      // final authResult = await _auth.signInWithCredential(authCredential!);
      final authResult =
          await _auth.currentUser!.linkWithCredential(authCredential!);
      if (_onLoginSuccess != null) _onLoginSuccess!(authResult, autoVerified);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_onLoginFailed != null) _onLoginFailed!(e);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Set timer after code sent.
  void _setTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick == _timeoutDuration.inSeconds) _timer?.cancel();
      notifyListeners();
    });
    notifyListeners();
  }

  /// {@macro signOut}
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    if (kIsWeb) {
      _recaptchaVerifierForWeb?.clear();
      _recaptchaVerifierForWeb = null;
    }
    codeSent = false;
    _webConfirmationResult = null;
    _onLoginSuccess = null;
    _onLoginFailed = null;
    _forceResendingToken = null;
    _timer?.cancel();
    _timer = null;
    _phoneNumber = null;
    _timeoutDuration = kTimeOutDuration;
    _verificationId = null;
  }
}
