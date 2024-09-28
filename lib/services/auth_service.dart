import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? _user;
  bool get isAuth => _user != null;
  User? get currentUser => _user;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    _user = _auth.currentUser;
    notifyListeners();
    return true;
  }

  Future<void> signUp(String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      
      await _user?.updateDisplayName(fullName);
      await _user?.sendEmailVerification();

      await _firestore.collection('users').doc(_user!.uid).set({
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = result.user;
      if (!_user!.emailVerified) {
        _user = null;
        throw CustomAuthException('Please verify your email before signing in.');
      }
      await _storeUserData();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      prefs.clear();
      notifyListeners();
    } catch (e) {
      print(e.toString());
      throw CustomAuthException('Failed to sign out. Please try again.');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> _storeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'userId': _user!.uid,
      'email': _user!.email,
    });
    prefs.setString('userData', userData);
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return CustomAuthException('The password provided is too weak.');
      case 'email-already-in-use':
        return CustomAuthException('An account already exists for that email.');
      case 'user-not-found':
        return CustomAuthException('No user found for that email.');
      case 'wrong-password':
        return CustomAuthException('Wrong password provided.');
      case 'user-disabled':
        return CustomAuthException('This user account has been disabled.');
      case 'too-many-requests':
        return CustomAuthException('Too many unsuccessful login attempts. Please try again later.');
      case 'operation-not-allowed':
        return CustomAuthException('This operation is not allowed. Please contact support.');
      default:
        return CustomAuthException('An error occurred. Please try again.');
    }
  }
}

class CustomAuthException implements Exception {
  final String message;
  CustomAuthException(this.message);

  @override
  String toString() => message;
}