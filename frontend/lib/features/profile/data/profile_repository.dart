import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  final Dio _dio = DioClient.instance;

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/profile');
    return UserProfile.fromJson(response.data);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/profile', data: data);
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update profile');
    }
  }

  Future<UserProfile> uploadProfileImage(XFile file) async {
    try {
      final MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: file.name);
      } else {
        multipartFile = await MultipartFile.fromFile(file.path, filename: file.name);
      }
      FormData formData = FormData.fromMap({
        "file": multipartFile,
      });
      final response = await _dio.post('/profile/image', data: formData);
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload image');
    }
  }
}
