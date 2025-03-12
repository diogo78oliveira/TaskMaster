import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_master_2_0/models/user_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart'; 

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userKey = 'current_user';

  // Simple password hashing
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign up with email and password
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required int age,
  }) async {
    try {
      // Check if email already exists
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Email already in use');
      }

      // Create new user document
      final hashedPassword = _hashPassword(password);
      
      final docRef = await _firestore.collection('users').add({
        'name': name,
        'email': email,
        'password': hashedPassword,
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get the created user
      final docSnapshot = await docRef.get();
      final userData = docSnapshot.data() as Map<String, dynamic>;
      
      // Create user model (excluding password)
      final userModel = UserModel(
        id: docRef.id,
        name: userData['name'],
        email: userData['email'],
        age: userData['age'],
      );
      
      // Save current user locally
      await _saveCurrentUser(userModel);
      
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final hashedPassword = _hashPassword(password);
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found');
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      
      if (userData['password'] != hashedPassword) {
        throw Exception('Invalid password');
      }

      // Create user model (excluding password)
      final userModel = UserModel(
        id: userDoc.id,
        name: userData['name'],
        email: userData['email'],
        age: userData['age'],
      );
      
      // Save current user locally
      await _saveCurrentUser(userModel);
      
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson == null) return null;
    
    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel(
        id: userMap['id'],
        name: userMap['name'],
        email: userMap['email'],
        age: userMap['age'],
      );
    } catch (e) {
      return null;
    }
  }
  
  // Save current user to local storage
  Future<void> _saveCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'age': user.age,
    });
    
    await prefs.setString(_userKey, userJson);
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await getCurrentUser() != null;
  }
}