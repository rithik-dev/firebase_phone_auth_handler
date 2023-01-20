## [1.0.8] - 20/01/2023

* Added sendOtpOnInitialize parameter to the handler
* Fixed OTP resend issue if the OTP expiration timer is still active
* Fixed #15
* Added shouldAwaitCodeSend to the sendOTP fn to give more control over the function
* Updated dependencies

## [1.0.7] - 24/10/2022

* Stacktrace in onLoginFailed is now non-nullable
* Updated a dependency to the latest release
* Updated example app

## [1.0.6] - 16/07/2022

* **BREAKING:** Added stack trace to onLoginFailed and onError callbacks
* Added a boolean linkWithExistingUser to link the new credentials with an existing signed-in user, instead of creating a new one.
* Added onError callback for general purpose errors by the library
* Updated example app
* Updated dependencies

## [1.0.5+1] - 11/07/2022

* Fixed files formatting
* Updated example app

## [1.0.5] - 10/07/2022

* **BREAKING:** Renamed flag timeOutDuration to autoRetrievalTimeOutDuration
* **BREAKING:** Renamed verifyOTP to verifyOtp
* **BREAKING:** Updated verifyOtp function signature to not take a named argument, and accept otp as a positional argument
* Added a new otpExpirationDuration flag, as autoRetrievalTimeOutDuration is a completely different parameter.
* Added callback onCodeSent and flag signOutOnSuccessfulVerification
* Added isSendingCode flag to controller
* Optimized code to reduce number of rebuilds
* Updated example app
* Updated dependencies
* Refactored code

## [1.0.4] - 07/06/2022

* Updated example app
* Updated dependencies
* Fixed linter warnings

## [1.0.3] - 03/05/2022

* Updated example app
* Updated README.md

## [1.0.2] - 30/04/2022

* Renamed auth_service to auth_controller
* Updated dependencies
* Minor bug fixes
* Updated example app
* Updated README.md

## [1.0.1] - 26/01/2022

* Updated license
* Updated README.md

## [1.0.0] - 26/01/2022

* Added linter and updated code accordingly
* Updated example app
* Updated dependencies
* Updated README.md

## [0.0.8] - 28/10/2021

* Updated dependencies
* Updated example app

## [0.0.7] - 22/05/2021

* Renamed FirebasePhoneAuthSupporter to FirebasePhoneAuthProvider.
* Supports sending OTP on web out of the box.
* Updated dependencies
* Updated README.md
* Updated package description.

## [0.0.6] - 12/05/2021

* Added key parameter
* Fixed README.md
* Updated dependencies

## [0.0.5] - 23/04/2021

* Added boolean in onLoginSuccess to provide info whether OTP was auto fetched or verified manually
* Updated example app
* Updated README.md

## [0.0.4] - 21/04/2021

* Updated example app
* Updated README.md

## [0.0.3] - 21/04/2021

* Updated screenshots
* Updated package description

## [0.0.2] - 21/04/2021

* Added FirebasePhoneAuthSupporter which has to be wrapped above the MaterialApp in order for the app to support phone authentication.
* Fixed sign out function
* Updated README.md

## [0.0.1] - 21/04/2021

* An easy to use firebase phone authentication library to easily send and verify OTP's.
