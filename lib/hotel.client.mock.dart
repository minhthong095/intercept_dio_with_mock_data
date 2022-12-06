import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

void setupMockClient(Dio dio) {
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      await Future.delayed(const Duration(milliseconds: 1500));
      switch (options.uri.toString().split('?').first) {
        case 'https://hotel.com/api/v1/hotel/hotel-types':
          return await resolveHotelType(options, handler);
        case 'https://hotel.com/api/v1/hotel/hotel-with-types':
          return await resolveHotelWithType(options, handler);
        case 'https://hotel.com/api/v1/filter/facilities':
          return await resolveFacility(options, handler);
        case 'https://hotel.com/api/v1/filter/distance':
          return await resolveDistance(options, handler);
        case 'https://hotel.com/api/v1/hotel/hotel-near-you':
          return await resolveHoteNearYou(options, handler);
        default:
          return handler.resolve404(options);
      }
    },
  ));
}

Future<void> resolveHoteNearYou(
    RequestOptions options, RequestInterceptorHandler handler) async {
  if (options.method == 'GET') {
    try {
      final filterRangePriceStart = options.queryParameters['rangePriceStart'];
      final filterRangePriceEnd = options.queryParameters['rangePriceEnd'];
      final filterDistance = options.queryParameters['distance'];
      final filterFacility = options.queryParameters['facility'];
      final filterRating = options.queryParameters['rating'];

      if ((filterRangePriceEnd == null && filterRangePriceStart != null) ||
          (filterRangePriceEnd != null && filterRangePriceStart == null)) {
        return handler.resolve404(options);
      }

      if (filterRangePriceStart != null &&
          filterRangePriceEnd != null &&
          (filterRangePriceEnd is! double ||
              filterRangePriceStart is! double ||
              filterRangePriceStart < 0 ||
              filterRangePriceEnd < 0 ||
              filterRangePriceStart > filterRangePriceEnd ||
              filterRangePriceEnd > 100)) {
        return handler.resolve404(options);
      }

      if (filterDistance != null && filterDistance > 4) {
        return handler.resolve404(options);
      }

      if ((filterFacility != null && filterFacility is! List) ||
          !checkFacilityParameterFormat(facilitiesParameter: filterFacility)) {
        return handler.resolve404(options);
      }

      if (filterRating != null &&
          filterRating is! double &&
          filterRating < 0 &&
          filterRating > 5) {
        return handler.resolve404(options);
      }

      final response = await mockAsset(path: 'hotel_near_you.mock.json');
      final list = <Map<String, dynamic>>[];
      for (dynamic object in response['data'] as List) {
        if ((filterRangePriceStart == null
                ? true
                : filterRangePriceStart <= object['price'] &&
                    object['price'] <= filterRangePriceEnd) &&
            (filterDistance == null
                ? true
                : object['distance'] <= filterDistance) &&
            (filterFacility == null
                ? true
                : checkFilterAndDataAreaUnion(
                    filter: filterFacility, data: object['facility'])) &&
            (filterRating == null ? true : filterRating == object['rating'])) {
          // print(filterFacility != null &&
          //     checkAnyFilterContainInData(
          //         filter: filterFacility, childList: object['facility']));
          list.add(object);
        }
      }
      response['data'] = list;

      return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response));
    } catch (_) {
      return handler.resolve404(options);
    }
  }

  return handler.resolve404(options);
}

Future<void> resolveDistance(
    RequestOptions options, RequestInterceptorHandler handler) async {
  if (options.method == 'GET') {
    try {
      final response = await mockAsset(path: 'distance_fitler.mock.json');
      return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response));
    } catch (_) {
      return handler.resolve404(options);
    }
  }

  return handler.resolve404(options);
}

Future<void> resolveFacility(
    RequestOptions options, RequestInterceptorHandler handler) async {
  if (options.method == 'GET') {
    try {
      final response = await mockAsset(path: 'facility_filter.mock.json');
      return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response));
    } catch (_) {
      return handler.resolve404(options);
    }
  }

  return handler.resolve404(options);
}

Future<void> resolveHotelWithType(
    RequestOptions options, RequestInterceptorHandler handler) async {
  if (options.method == 'GET' &&
      options.queryParameters['type'] != null &&
      options.queryParameters['type'] is int) {
    try {
      final queryType = options.queryParameters['type'];

      if (queryType == null) return handler.resolve404(options);

      final response = await mockAsset(path: 'hotel_with_type.mock.json');
      final list = <Map<String, dynamic>>[];
      for (dynamic object in response['data'] as List) {
        if (object['type'] == queryType) {
          list.add(object);
        }
      }
      response['data'] = list;

      return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response));
    } catch (_) {
      return handler.resolve404(options);
    }
  }

  return handler.resolve404(options);
}

Future<void> resolveHotelType(
    RequestOptions options, RequestInterceptorHandler handler) async {
  if (options.method == 'GET') {
    try {
      final response = await mockAsset(path: 'hotel_type.mock.json');
      return handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response));
    } catch (_) {
      return handler.resolve404(options);
    }
  }

  return handler.resolve404(options);
}

bool checkFilterAndDataAreaUnion({required List filter, required List data}) {
  late List bigger;
  late List smaller;
  if (filter.length <= data.length) {
    bigger = data;
    smaller = filter;
  } else {
    bigger = filter;
    smaller = data;
  }
  final union = HashSet()
    ..addAll(bigger)
    ..addAll(smaller);
  return bigger.length == union.length;
}

const kFacilities = [
  "ELEVATOR",
  "HOT_EATER",
  "COOKING_PLACE",
  "PARKING",
  "CLEANING_SERVICE",
  "NEARBY_STORES"
];

bool checkFacilityParameterFormat({required List? facilitiesParameter}) {
  final f = facilitiesParameter;

  if (f == null) return true;

  for (dynamic itemParameter in f) {
    if (!kFacilities.contains(itemParameter)) {
      return false;
    }
  }

  return true;
}

Future<Map<String, dynamic>> mockAsset({required String path}) async {
  final string = await rootBundle.loadString('asset/mock_data/$path');
  return await json.decode(string);
}

extension NotHandleResponse on RequestInterceptorHandler {
  void resolve404(RequestOptions options) =>
      resolve(Response(requestOptions: options, statusCode: 404));
}
