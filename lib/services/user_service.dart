import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:massmello/models/user_model.dart';

class UserService {
  static const String _userKey = 'user_data';

  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData == null) return null;
      return UserModel.fromJson(json.decode(userData) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await saveUser(user.copyWith(updatedAt: DateTime.now()));
  }

  Future<bool> isUserRegistered() async {
    final user = await getUser();
    return user != null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
