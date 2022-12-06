import 'dart:collection';

import 'package:dio/dio.dart';

class HotelClient {
  final dio = Dio();

  static final instant = HotelClient._();

  HotelClient._();

  Future<Response> get(
      {required String path,
      HashMap<String, dynamic>? parameters,
      String? accessToken}) {
    return dio.get(
      path,
      queryParameters: parameters,
    );
  }
}
