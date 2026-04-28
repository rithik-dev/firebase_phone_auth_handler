import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockConfirmationResult extends Mock implements ConfirmationResult {}

class MockAuthCredential extends Mock implements AuthCredential {}

class MockPhoneAuthCredential extends Mock implements PhoneAuthCredential {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockFirebaseAuthException extends Mock implements FirebaseAuthException {}
