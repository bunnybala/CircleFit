import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/profile_repository.dart';
import '../../domain/user_profile.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() async {
    try {
      return await ref.read(profileRepositoryProvider).getProfile();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        DioClient.clearAuthToken();
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to load profile. Please check your network connection.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final updatedProfile = await ref.read(profileRepositoryProvider).updateProfile(data);
      state = AsyncData(updatedProfile);
      return true;
    } catch (e, st) {
      print('Update error: $e');
      return false;
    }
  }

  Future<bool> uploadImage(XFile file) async {
    try {
      final updatedProfile = await ref.read(profileRepositoryProvider).uploadProfileImage(file);
      state = AsyncData(updatedProfile);
      return true;
    } catch (e) {
      print('Image upload error: $e');
      return false;
    }
  }
}
