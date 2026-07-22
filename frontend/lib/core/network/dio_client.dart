import 'package:dio/dio.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      // baseUrl: 'http://172.20.10.3:8081/api',
      baseUrl: 'http://192.168.1.12:8081/api', // Uses ADB reverse (adb reverse tcp:8081 tcp:8081) for physical devices
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json', //Json
      },
    ),
  );

  static Dio get instance => _dio;

  static String get baseUrl => _dio.options.baseUrl;
  
  static void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
