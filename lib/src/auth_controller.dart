part of 'auth_handler.dart';

class FirebasePhoneAuthController extends ChangeNotifier {
  /// {@macro auth}
  FirebasePhoneAuthController({
    FirebaseAuth? auth,
  }) : _customAuth = auth;

  /// Default value for [FirebasePhoneAuthHandler.autoRetrievalTimeOutDuration]
  /// and [FirebasePhoneAuthHandler.otpExpirationDuration].
  static const kAutoRetrievalTimeOutDuration = Duration(seconds: 60);

  /// Default value for [sendOTP]'s `codeSendTimeout` parameter.
  static const kCodeSendTimeout = Duration(seconds: 60);

  /// {@macro auth}
  final FirebaseAuth? _customAuth;

  /// The [FirebaseAuth] instance every call in this controller goes through.
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Web confirmation result for OTP.
  ConfirmationResult? _webConfirmationResult;

  /// {@macro recaptchaVerifierForWeb}
  RecaptchaVerifier? _recaptchaVerifierForWeb;

  /// The [_forceResendingToken] obtained from firebase's `codeSent`
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

  /// Guards against firebase never invoking any of the [sendOTP] callbacks.
  Timer? _codeSendTimeoutTimer;

  /// Whether this controller has been disposed.
  ///
  /// Guards against [notifyListeners] being called from a timer callback that
  /// outlives the controller.
  bool _disposed = false;

  /// The state of the current OTP send operation.
  OtpSendStatus _otpSendStatus = OtpSendStatus.idle;

  /// The state of the current OTP send operation.
  OtpSendStatus get otpSendStatus => _otpSendStatus;

  /// Whether OTP to the given phoneNumber is sent or not.
  bool get codeSent => _otpSendStatus == OtpSendStatus.sent;

  /// Whether OTP is being sent to the given phoneNumber.
  bool get isSendingCode => _otpSendStatus == OtpSendStatus.sending;

  /// Sets [_otpSendStatus] and rebuilds listeners.
  void _setOtpSendStatus(OtpSendStatus value) {
    if (_otpSendStatus == value) return;
    _otpSendStatus = value;

    _safeNotifyListeners();
  }

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
    final otpTickDuration = Duration(seconds: (_otpExpirationTimer?.tick ?? 0));
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
  bool get isListeningForOtpAutoRetrieve => _otpAutoRetrievalTimer?.isActive ?? false;

  /// {@macro autoRetrievalTimeOutDuration}
  Duration _autoRetrievalTimeOutDuration = kAutoRetrievalTimeOutDuration;

  /// {@macro otpExpirationDuration}
  Duration _otpExpirationDuration = kAutoRetrievalTimeOutDuration;

  /// Calls [notifyListeners] unless this controller has already been disposed.
  void _safeNotifyListeners() {
    if (_disposed) return;

    try {
      notifyListeners();
    } catch (_) {}
  }

  /// Marks the send-code operation as failed and rebuilds listeners.
  ///
  /// The error itself is reported separately through [_onLoginFailed] or
  /// [_onError] by the caller.
  void _markSendFailed() => _setOtpSendStatus(OtpSendStatus.failed);

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
    if ((!kIsWeb && _verificationId == null) || (kIsWeb && _webConfirmationResult == null)) {
      return false;
    }

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

  /// Sends an OTP to [_phoneNumber].
  ///
  /// Returns true on success. On failure, [_onLoginFailed] is called for a
  /// [FirebaseAuthException], or [_onError] for anything else.
  ///
  /// [shouldAwaitCodeSend] controls whether this completes as soon as
  /// firebase's own request completes (`false`), or only once the code has
  /// actually been sent — the `codeSent` callback has fired (`true`, the
  /// default). Not applicable on web, which has no separate "sent" event.
  ///
  /// [codeSendTimeout] bounds how long this waits for firebase to report the
  /// code as sent or failed. Firebase does not guarantee it calls back at all
  /// — for example on Android with no SHA-1 fingerprint registered, neither
  /// `codeSent` nor `verificationFailed` ever fires, and the controller would
  /// otherwise stay in [OtpSendStatus.sending] forever. On timeout,
  /// [otpSendStatus] becomes [OtpSendStatus.failed] and [_onError] receives a
  /// [TimeoutException]. Defaults to [kCodeSendTimeout] (60 seconds); pass
  /// null to wait indefinitely.
  Future<bool> sendOTP({
    bool shouldAwaitCodeSend = true,
    Duration? codeSendTimeout = kCodeSendTimeout,
  }) async {
    // Throws rather than returning false: reaching here means _setData never
    // ran, so onError/onLoginFailed are unset too — a false return would fail
    // silently.
    if (_phoneNumber == null) {
      throw StateError(
        'sendOTP was called on a FirebasePhoneAuthController that was never '
        'configured with a phone number. If this controller was constructed '
        'directly instead of through FirebasePhoneAuthHandler, set one up '
        'first — the widget does this in its initState before ever calling '
        'sendOTP.',
      );
    }

    Completer<void>? codeSendCompleter;

    _otpSendStatus = OtpSendStatus.sending;
    _codeSendTimeoutTimer?.cancel();
    await Future.delayed(Duration.zero, _safeNotifyListeners);

    void verificationCompletedCallback(AuthCredential authCredential) async {
      _codeSendTimeoutTimer?.cancel();
      _setOtpSendStatus(OtpSendStatus.sent);
      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.complete();
      }

      await _loginUser(authCredential: authCredential, autoVerified: true);
    }

    void verificationFailedCallback(FirebaseAuthException authException) {
      final stackTrace = authException.stackTrace ?? StackTrace.current;

      _codeSendTimeoutTimer?.cancel();
      _markSendFailed();

      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.completeError(authException, stackTrace);
      }
      _onLoginFailed?.call(authException, stackTrace);
    }

    void codeSentCallback(String verificationId, [int? forceResendingToken]) async {
      _codeSendTimeoutTimer?.cancel();
      _verificationId = verificationId;
      _forceResendingToken = forceResendingToken;
      _setOtpSendStatus(OtpSendStatus.sent);
      _onCodeSent?.call();
      if (codeSendCompleter != null && !codeSendCompleter.isCompleted) {
        codeSendCompleter.complete();
      }
      _setTimer();
    }

    void codeAutoRetrievalTimeoutCallback(String verificationId) {
      _verificationId = verificationId;
    }

    try {
      if (kIsWeb) {
        // The web API returns a future rather than firing callbacks, so the
        // timeout applies to that future directly.
        Future<ConfirmationResult> request = _auth.signInWithPhoneNumber(
          _phoneNumber!,
          _recaptchaVerifierForWeb,
        );

        if (codeSendTimeout != null) request = request.timeout(codeSendTimeout);

        _webConfirmationResult = await request;
        _setOtpSendStatus(OtpSendStatus.sent);
        _onCodeSent?.call();
        _setTimer();
      } else {
        codeSendCompleter = Completer<void>();

        // Firebase may never invoke any callback at all (see codeSendTimeout).
        // Nothing below awaits unconditionally, so this timer is what rescues
        // the controller from sitting in `sending` forever.
        if (codeSendTimeout != null) {
          final completer = codeSendCompleter;
          _codeSendTimeoutTimer = Timer(codeSendTimeout, () {
            if (completer.isCompleted) return;

            final error = TimeoutException(
              'Firebase did not report the OTP as sent or failed within '
              '${codeSendTimeout.inSeconds}s. This usually means device '
              'verification could not complete — on Android, check that the '
              "app's SHA-1/SHA-256 fingerprints are registered in the Firebase "
              'console, or use a test phone number.',
              codeSendTimeout,
            );

            final stackTrace = StackTrace.current;
            _markSendFailed();
            completer.completeError(error, stackTrace);
            _onError?.call(error, stackTrace);
          });
        }

        await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumber!,
          verificationCompleted: verificationCompletedCallback,
          verificationFailed: verificationFailedCallback,
          codeSent: codeSentCallback,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeoutCallback,
          timeout: _autoRetrievalTimeOutDuration,
          forceResendingToken: _forceResendingToken,
        );

        if (shouldAwaitCodeSend) {
          try {
            await codeSendCompleter.future;
          } catch (_) {
            // verificationFailedCallback has already reported this error to
            // _onLoginFailed. Rethrowing it here would deliver it twice.
            return false;
          }
        } else {
          codeSendCompleter.future.ignore();
        }
      }

      return true;
    } on FirebaseAuthException catch (e, s) {
      _codeSendTimeoutTimer?.cancel();
      _markSendFailed();
      _onLoginFailed?.call(e, s);
      return false;
    } catch (e, s) {
      _codeSendTimeoutTimer?.cancel();
      _markSendFailed();
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
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw StateError(
            'linkWithExistingUser was true but no user is currently signed in. '
            'Sign a user in before linking a phone credential to it.',
          );
        }

        authResult = await currentUser.linkWithCredential(authCredential!);
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
    _otpExpirationTimer?.cancel();
    _otpExpirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick == _otpExpirationDuration.inSeconds) {
        timer.cancel();
      }

      _safeNotifyListeners();
    });

    _otpAutoRetrievalTimer?.cancel();
    _otpAutoRetrievalTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (timer.tick == _autoRetrievalTimeOutDuration.inSeconds) {
        timer.cancel();
      }

      _safeNotifyListeners();
    });

    _safeNotifyListeners();
  }

  /// {@macro signOut}
  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _disposed = true;

    if (kIsWeb) {
      _recaptchaVerifierForWeb?.clear();
      _recaptchaVerifierForWeb = null;
    }

    _otpSendStatus = OtpSendStatus.idle;
    _webConfirmationResult = null;
    _onLoginSuccess = null;
    _onLoginFailed = null;
    _onError = null;
    _onCodeSent = null;
    _signOutOnSuccessfulVerification = false;
    _forceResendingToken = null;
    _otpExpirationTimer?.cancel();
    _otpExpirationTimer = null;
    _otpAutoRetrievalTimer?.cancel();
    _otpAutoRetrievalTimer = null;
    _codeSendTimeoutTimer?.cancel();
    _codeSendTimeoutTimer = null;
    _phoneNumber = null;
    _linkWithExistingUser = false;
    _autoRetrievalTimeOutDuration = kAutoRetrievalTimeOutDuration;
    _otpExpirationDuration = kAutoRetrievalTimeOutDuration;
    _verificationId = null;

    super.dispose();
  }
}
