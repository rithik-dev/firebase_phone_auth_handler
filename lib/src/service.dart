import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FirebasePhoneAuthService extends ChangeNotifier {
  /// {@macro timeOutDuration}
  static const TIME_OUT_DURATION = const Duration(seconds: 60);

  /// Firebase Auth instance using the default [FirebaseApp].
  FirebaseAuth? _auth = FirebaseAuth.instance;

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

  FutureOr<void> Function(UserCredential)? _onLoginSuccess;
  FutureOr<void> Function(FirebaseAuthException)? _onLoginFailed;

  /// Set callbacks and other data
  void setData({
    required String phoneNumber,
    required FutureOr<void> Function(UserCredential)? onLoginSuccess,
    required FutureOr<void> Function(FirebaseAuthException)? onLoginFailed,
    Duration timeOutDuration = TIME_OUT_DURATION,
  }) {
    _phoneNumber = phoneNumber;
    _onLoginSuccess = onLoginSuccess;
    _onLoginFailed = onLoginFailed;
    _timeoutDuration = timeOutDuration;
  }

  /// After a [Duration] of [timerCount], the library no more waits for SMS auto-retrieval.
  Duration get timerCount =>
      Duration(seconds: _timeoutDuration.inSeconds - (_timer?.tick ?? 0));

  /// Whether the timer is active or not.
  bool get timerIsActive => _timer?.isActive ?? false;

  /// {@macro timeOutDuration}
  static Duration _timeoutDuration = TIME_OUT_DURATION;

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
  Future<bool> verifyOTP({required String otp}) async {
    if (_verificationId == null) return false;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      return await loginUser(credential);
    } on FirebaseAuthException catch (e) {
      if (_onLoginFailed != null) _onLoginFailed!(e);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear all data
  void clear() {
    _auth = null;
    this.codeSent = false;
    _onLoginSuccess = null;
    _onLoginFailed = null;
    _forceResendingToken = null;
    _timer?.cancel();
    _timer = null;
    _phoneNumber = null;
    _timeoutDuration = TIME_OUT_DURATION;
    _verificationId = null;
  }

  /// Send OTP to the given [_phoneNumber].
  ///
  /// Returns true if OTP was sent successfully.
  ///
  /// If for any reason, the OTP is not send,
  /// [_onLoginFailed] is called with [FirebaseAuthException]
  /// object to handle the error.
  Future<bool> sendOTP() async {
    // this.clear();
    _auth ??= FirebaseAuth.instance;

    this.codeSent = false;
    await Future.delayed(Duration.zero, () {
      notifyListeners();
    });

    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential authCredential) async {
      await loginUser(authCredential);
    };

    final PhoneVerificationFailed verificationFailed = (
      FirebaseAuthException authException,
    ) {
      if (_onLoginFailed != null) _onLoginFailed!(authException);
    };

    final PhoneCodeSent codeSent = (
      String verificationId, [
      int? forceResendingToken,
    ]) async {
      _verificationId = verificationId;
      _forceResendingToken = forceResendingToken;
      this.codeSent = true;
      notifyListeners();

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (timer.tick == _timeoutDuration.inSeconds) _timer?.cancel();
        notifyListeners();
      });
      notifyListeners();
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };

    try {
      _auth ??= FirebaseAuth.instance;
      await _auth!.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: _timeoutDuration,
        forceResendingToken: _forceResendingToken,
      );

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
  Future<bool> loginUser(AuthCredential authCredential) async {
    try {
      _auth ??= FirebaseAuth.instance;
      final authResult = await _auth!.signInWithCredential(authCredential);
      if (_onLoginSuccess != null) _onLoginSuccess!(authResult);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_onLoginFailed != null) _onLoginFailed!(e);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// {@macro signOut}
  Future<void> signOut() async {
    // this.clear();
    _auth ??= FirebaseAuth.instance;
    await _auth!.signOut();
    notifyListeners();
  }
}
