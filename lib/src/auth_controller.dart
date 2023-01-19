part of 'auth_handler.dart';

class FirebasePhoneAuthController extends ChangeNotifier {
  static FirebasePhoneAuthController _of(
    BuildContext context, {
    bool listen = true,
  }) =>
      Provider.of<FirebasePhoneAuthController>(context, listen: listen);

  /// {@macro autoRetrievalTimeOutDuration}
  static const kAutoRetrievalTimeOutDuration = Duration(minutes: 1);

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
  Timer? _otpAutoRetrievalTimer;

  /// Timer object for OTP expiration.
  Timer? _otpExpirationTimer;

  /// Whether OTP to the given phoneNumber is sent or not.
  bool codeSent = false;

  /// Whether OTP is being sent to the given phoneNumber.
  bool get isSendingCode => !codeSent;

  /// Whether the current platform is web or not;
  bool get isWeb => kIsWeb;

  /// {@macro signOutOnSuccessfulVerification}
  late bool _signOutOnSuccessfulVerification;

  /// {@macro onCodeSent}
  VoidCallback? _onCodeSent;

  /// {@macro onLoginSuccess}
  OnLoginSuccess? _onLoginSuccess;

  /// {@macro onLoginFailed}
  OnLoginFailed? _onLoginFailed;

  /// {@macro onError}
  OnError? _onError;

  /// {@macro linkWithExistingUser}
  late bool _linkWithExistingUser;

  /// Set callbacks and other data. (only for internal use)
  void _setData({
    required String phoneNumber,
    required OnLoginSuccess? onLoginSuccess,
    required OnLoginFailed? onLoginFailed,
    required OnError? onError,
    required VoidCallback? onCodeSent,
    required bool signOutOnSuccessfulVerification,
    required RecaptchaVerifier? recaptchaVerifierForWeb,
    required Duration autoRetrievalTimeOutDuration,
    required Duration otpExpirationDuration,
    required bool linkWithExistingUser,
  }) {
    _phoneNumber = phoneNumber;
    _signOutOnSuccessfulVerification = signOutOnSuccessfulVerification;
    _onLoginSuccess = onLoginSuccess;
    _onLoginFailed = onLoginFailed;
    _onError = onError;
    _onCodeSent = onCodeSent;
    _linkWithExistingUser = linkWithExistingUser;
    _autoRetrievalTimeOutDuration = autoRetrievalTimeOutDuration;
    _otpExpirationDuration = otpExpirationDuration;
    if (kIsWeb) _recaptchaVerifierForWeb = recaptchaVerifierForWeb;
  }

  /// [otpExpirationTimeLeft] can be used to display a reverse countdown, starting from
  /// [_otpExpirationDuration.inSeconds]s till 0, and can show the resend
  /// button, to let user request a new OTP.
  Duration get otpExpirationTimeLeft {
    final otpTickDuration = Duration(
      seconds: (_otpExpirationTimer?.tick ?? 0),
    );
    return _otpExpirationDuration - otpTickDuration;
  }

  /// [autoRetrievalTimeLeft] can be used to display a reverse countdown, starting from
  /// [_autoRetrievalTimeOutDuration.inSeconds]s till 0, and can show the
  /// the listening for OTP view, and also the time left.
  ///
  /// After this timer is exhausted, the device no longer tries to auto-fetch
  /// the OTP, and requires user to manually enter it.
  Duration get autoRetrievalTimeLeft {
    final otpTickDuration = Duration(
      seconds: (_otpAutoRetrievalTimer?.tick ?? 0),
    );
    return _autoRetrievalTimeOutDuration - otpTickDuration;
  }

  /// Whether the otp has expired or not.
  bool get isOtpExpired => !(_otpExpirationTimer?.isActive ?? false);

  /// Whether the otp retrieval timer is active or not.
  bool get isListeningForOtpAutoRetrieve =>
      _otpAutoRetrievalTimer?.isActive ?? false;

  /// {@macro autoRetrievalTimeOutDuration}
  static Duration _autoRetrievalTimeOutDuration = kAutoRetrievalTimeOutDuration;

  /// {@macro otpExpirationDuration}
  static Duration _otpExpirationDuration = kAutoRetrievalTimeOutDuration;

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
  Future<bool> verifyOtp(String otp) async {
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
        return await _loginUser(
          authCredential: credential,
          autoVerified: false,
        );
      }
    } on FirebaseAuthException catch (e, s) {
      _onLoginFailed?.call(e, s);
      return false;
    } catch (e, s) {
      _onError?.call(e, s);
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
  ///
  /// [shouldAwaitCodeSend] can be used to await the OTP send.
  /// The firebase method completes early, and if [shouldAwaitCodeSend] is false,
  /// [sendOTP] will complete early, and the OTP will be sent in the background.
  /// Whereas, if [shouldAwaitCodeSend] is true, [sendOTP] will wait for the
  /// code send callback to be fired, and [sendOTP] will complete only after
  /// that callback is fired. Not applicable on web.
  Future<bool> sendOTP({bool shouldAwaitCodeSend = true}) async {
    Completer? codeSendCompleter;

    codeSent = false;
    await Future.delayed(Duration.zero, notifyListeners);

    verificationCompletedCallback(AuthCredential authCredential) async {
      await _loginUser(authCredential: authCredential, autoVerified: true);
    }

    verificationFailedCallback(FirebaseAuthException authException) {
      final stackTrace = authException.stackTrace ?? StackTrace.current;

      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.completeError(authException, stackTrace);
      }
      _onLoginFailed?.call(authException, stackTrace);
    }

    codeSentCallback(
      String verificationId, [
      int? forceResendingToken,
    ]) async {
      _verificationId = verificationId;
      _forceResendingToken = forceResendingToken;
      codeSent = true;
      _onCodeSent?.call();
      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.complete();
      }
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
        _onCodeSent?.call();
        _setTimer();
      } else {
        codeSendCompleter = Completer();

        await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumber!,
          verificationCompleted: verificationCompletedCallback,
          verificationFailed: verificationFailedCallback,
          codeSent: codeSentCallback,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeoutCallback,
          timeout: _autoRetrievalTimeOutDuration,
          forceResendingToken: _forceResendingToken,
        );

        if (shouldAwaitCodeSend) await codeSendCompleter.future;
      }

      return true;
    } on FirebaseAuthException catch (e, s) {
      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.completeError(e, s);
      }
      _onLoginFailed?.call(e, s);
      return false;
    } catch (e, s) {
      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.completeError(e, s);
      }
      _onError?.call(e, s);
      return false;
    }
  }

  /// Called when the otp is verified either automatically (OTP auto fetched)
  /// or [verifyOtp] was called with the correct OTP.
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
        if (_signOutOnSuccessfulVerification) await signOut();
        _onLoginSuccess?.call(userCredential, autoVerified);
        return true;
      } else {
        return false;
      }
    }

    // Not on web.
    try {
      late final UserCredential authResult;

      if (_linkWithExistingUser) {
        authResult = await _auth.currentUser!.linkWithCredential(
          authCredential!,
        );
      } else {
        authResult = await _auth.signInWithCredential(authCredential!);
      }

      if (_signOutOnSuccessfulVerification) await signOut();
      _onLoginSuccess?.call(authResult, autoVerified);
      return true;
    } on FirebaseAuthException catch (e, s) {
      _onLoginFailed?.call(e, s);
      return false;
    } catch (e, s) {
      _onError?.call(e, s);
      return false;
    }
  }

  /// Set timer after code sent.
  void _setTimer() {
    _otpExpirationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (timer.tick == _otpExpirationDuration.inSeconds) {
          _otpExpirationTimer?.cancel();
        }
        try {
          notifyListeners();
        } catch (_) {}
      },
    );
    _otpAutoRetrievalTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (timer.tick == _autoRetrievalTimeOutDuration.inSeconds) {
          _otpAutoRetrievalTimer?.cancel();
        }
        try {
          notifyListeners();
        } catch (_) {}
      },
    );
    notifyListeners();
  }

  /// {@macro signOut}
  Future<void> signOut() async {
    await _auth.signOut();
    // notifyListeners();
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
    _onError = null;
    _onCodeSent = null;
    _signOutOnSuccessfulVerification = false;
    // _forceResendingToken = null;
    _otpExpirationTimer?.cancel();
    _otpExpirationTimer = null;
    _otpAutoRetrievalTimer?.cancel();
    _otpAutoRetrievalTimer = null;
    _phoneNumber = null;
    _linkWithExistingUser = false;
    _autoRetrievalTimeOutDuration = kAutoRetrievalTimeOutDuration;
    _otpExpirationDuration = kAutoRetrievalTimeOutDuration;
    _verificationId = null;
  }
}
