import 'package:dio/dio.dart';

abstract class ApiService {
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query});
  Future<Response<dynamic>> post(String path, {Object? data});
  Future<Response<dynamic>> put(String path, {Object? data});
  Future<Response<dynamic>> delete(String path, {Object? data});
}