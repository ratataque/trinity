import 'package:dio/dio.dart';
import 'package:trinity/type/user.dart';
import 'package:trinity/utils/http.dart';
import 'dart:convert';

class UserApi {
  Future<User> getUser() async {
    try {
      final response = await ApiClient.auth.get('/user/self');

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception("User information retrival failed: ${e.response?.data}");
    }
  }

  Future<User> getUserDetails() async {
    try {
      final response = await ApiClient.auth.get('/user/details/self');

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception("User information retrival failed: ${e.response?.data}");
    }
  }


  Future<void> updateUser(Map<String, dynamic> userData) async {
    if (userData.isEmpty) {
      throw Exception("Les données utilisateur ne peuvent pas être vides.");
    }

    try {
      await ApiClient.auth.put(
        '/user/self',
        data: jsonEncode(userData),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
    } on DioException catch (e) {
      throw Exception("Échec de la mise à jour de l'utilisateur : ${e.response?.data}");
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw Exception("Les mots de passe ne peuvent pas être vides.");
    }

    final Map<String, dynamic> data = {
      "current_password": currentPassword,
      "new_password": newPassword
    };

    try {
      await ApiClient.auth.put(
        '/user/self/password',
        data: jsonEncode(data),
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
    } on DioException catch (e) {
      throw Exception("Échec de la mise à jour du mot de passe: ${e.response?.data}");
    }
  }
}
