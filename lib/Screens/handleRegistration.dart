import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vaarta_app/Config/Constants.dart';

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  ApiException({required this.message, this.fieldErrors});
}

