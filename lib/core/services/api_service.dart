import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'api.dart';
import '../../routes/app_routes.dart';
import 'auth_session_service.dart';
import 'http_sender_io.dart';
import 'toast_service.dart';

class ApiService extends GetxService {
  final AuthSessionService _session = Get.find<AuthSessionService>();


  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[API][$method] ${uri.toString()}');
    debugPrint('[API][headers] $headers');
    final auth = headers['Authorization'];
    if (auth != null && auth.isNotEmpty) {
      log('[API][auth-full] $auth');
    }
    if (body != null && body.isNotEmpty) {
      debugPrint('[API][body] $body');
    }
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required dynamic decodedBody,
  }) {
    if (!kDebugMode) return;
    debugPrint('[API][$method][status] $statusCode ${uri.toString()}');
    debugPrint('[API][response] $decodedBody');
  }

  void _logError({
    required String method,
    required String endpoint,
    required String message,
  }) {
    if (!kDebugMode) return;
    debugPrint('[API][$method][error] $endpoint -> $message');
  }

  Uri _resolveUri(String url, Map<String, dynamic>? queryParameters) {
    final trimmed = url.trim();
    final String resolvedUrl;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      resolvedUrl = trimmed;
    } else {
      if (ApiUrl.baseUrl.isEmpty) {
        throw StateError(
          'ApiUrl.baseUrl is not configured. Call ApiUrl.configure(baseUrl: ...) before requests.',
        );
      }
      resolvedUrl = '${ApiUrl.baseUrl}${trimmed.startsWith('/') ? '' : '/'}$trimmed';
    }

    final uri = Uri.parse(resolvedUrl);
    if (queryParameters == null || queryParameters.isEmpty) return uri;

    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  dynamic _tryDecode(String bodyText) {
    final trimmed = bodyText.trim();
    if (trimmed.isEmpty) return null;
    if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) return bodyText;
    try {
      return json.decode(trimmed);
    } catch (_) {
      return bodyText;
    }
  }

  String _extractErrorMessage(dynamic decodedBody) {
    if (decodedBody is Map) {
      final dynamic message = decodedBody['message'] ?? decodedBody['error'];
      return (message?.toString().isNotEmpty ?? false)
          ? message.toString()
          : 'Request failed';
    }
    return decodedBody?.toString() ?? 'Request failed';
  }

  String _extractSuccessMessage(dynamic decodedBody) {
    if (decodedBody is Map) {
      final dynamic message = decodedBody['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return 'Success';
  }

  void _handleUnauthorized() {
    _session.clear();
    Get.offAllNamed(Routes.login);
  }

  Future<void> postRequest({
    required String url,
    dynamic params,
    dynamic header,
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool showSuccessToast = false,
    String? successToastMessage,
    bool showErrorToast = false,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final uri = _resolveUri(url, queryParameters);

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };
      final token = _session.accessToken.value;
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      if (header is Map) {
        headers.addAll(
          header.map((key, value) => MapEntry(key.toString(), value.toString())),
        );
      }

      final Object? payload = data ?? params;
      final String? body = payload == null
          ? null
          : payload is String
              ? payload
              : json.encode(payload);
      _logRequest(method: 'POST', uri: uri, headers: headers, body: body);

      final response = await sendHttpRequest(
        method: 'POST',
        uri: uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      final decodedBody = _tryDecode(response.bodyText);
      _logResponse(
        method: 'POST',
        uri: uri,
        statusCode: response.statusCode,
        decodedBody: decodedBody,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = _extractErrorMessage(decodedBody);
        _logError(method: 'POST', endpoint: uri.toString(), message: message);
        if (showErrorToast) {
          await ToastService.error(message);
        }
        onError(message);
        return;
      }

      if (decodedBody is Map) {
        final dynamic statusCode = decodedBody['statusCode'];
        if (statusCode != null && statusCode.toString() != '200') {
          final message = decodedBody['message']?.toString() ??
              decodedBody['error']?.toString() ??
              'Request failed';
          _logError(method: 'POST', endpoint: uri.toString(), message: message);
          if (showErrorToast) {
            await ToastService.error(message);
          }
          onError(message);
          return;
        }
        final dynamic success = decodedBody['success'];
        if (success is bool && success == false) {
          final message = decodedBody['error']?.toString() ??
              decodedBody['message']?.toString() ??
              'Request failed';
          _logError(method: 'POST', endpoint: uri.toString(), message: message);
          if (showErrorToast) {
            await ToastService.error(message);
          }
          onError(message);
          return;
        }
      }

      if (showSuccessToast) {
        await ToastService.success(
          successToastMessage ?? _extractSuccessMessage(decodedBody),
        );
      }
      onSuccess(<String, dynamic>{'response': decodedBody});
    } catch (e) {
      final message = e.toString();
      _logError(method: 'POST', endpoint: url, message: message);
      if (showErrorToast) {
        await ToastService.error(message);
      }
      onError(message);
    }
  }

  Future<void> getRequest({
    required String url,
    Map<String, dynamic>? header,
    Map<String, dynamic>? queryParameters,
    bool showSuccessToast = false,
    String? successToastMessage,
    bool showErrorToast = false,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String?) onError,
  }) async {
    try {
      final uri = _resolveUri(url, queryParameters);

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'X-Requested-With': 'XMLHttpRequest',
      };
      final token = _session.accessToken.value;
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      if (header != null) {
        headers.addAll(
          header.map((key, value) => MapEntry(key.toString(), value.toString())),
        );
      }
      _logRequest(method: 'GET', uri: uri, headers: headers);

      final response = await sendHttpRequest(
        method: 'GET',
        uri: uri,
        headers: headers,
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      final decodedBody = _tryDecode(response.bodyText);
      _logResponse(
        method: 'GET',
        uri: uri,
        statusCode: response.statusCode,
        decodedBody: decodedBody,
      );

      if (response.statusCode != 200) {
        final message = _extractErrorMessage(decodedBody);
        _logError(method: 'GET', endpoint: uri.toString(), message: message);
        if (showErrorToast) {
          await ToastService.error(message);
        }
        onError(message);
        return;
      }

      if (showSuccessToast) {
        await ToastService.success(
          successToastMessage ?? _extractSuccessMessage(decodedBody),
        );
      }
      onSuccess(<String, dynamic>{'response': decodedBody});
    } catch (e) {
      final message = e.toString();
      _logError(method: 'GET', endpoint: url, message: message);
      if (showErrorToast) {
        await ToastService.error(message);
      }
      onError(message);
    }
  }

  Future<void> putRequest({
    required String url,
    dynamic params,
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool showSuccessToast = false,
    String? successToastMessage,
    bool showErrorToast = false,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String?) onError,
  }) async {
    try {
      final uri = _resolveUri(url, queryParameters);

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'X-Requested-With': 'XMLHttpRequest',
      };
      final token = _session.accessToken.value;
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      final Object? payload = data ?? params;
      final String? body = payload == null
          ? null
          : payload is String
              ? payload
              : json.encode(payload);
      _logRequest(method: 'PUT', uri: uri, headers: headers, body: body);

      final response = await sendHttpRequest(
        method: 'PUT',
        uri: uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      final decodedBody = _tryDecode(response.bodyText);
      _logResponse(
        method: 'PUT',
        uri: uri,
        statusCode: response.statusCode,
        decodedBody: decodedBody,
      );

      if (response.statusCode != 200) {
        final message = _extractErrorMessage(decodedBody);
        _logError(method: 'PUT', endpoint: uri.toString(), message: message);
        if (showErrorToast) {
          await ToastService.error(message);
        }
        onError(message);
        return;
      }

      if (showSuccessToast) {
        await ToastService.success(
          successToastMessage ?? _extractSuccessMessage(decodedBody),
        );
      }
      onSuccess(<String, dynamic>{'response': decodedBody});
    } catch (e) {
      final message = e.toString();
      _logError(method: 'PUT', endpoint: url, message: message);
      if (showErrorToast) {
        await ToastService.error(message);
      }
      onError(message);
    }
  }

  Future<void> patchRequest({
    required String url,
    dynamic params,
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool showSuccessToast = false,
    String? successToastMessage,
    bool showErrorToast = false,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String?) onError,
  }) async {
    try {
      final uri = _resolveUri(url, queryParameters);

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'X-Requested-With': 'XMLHttpRequest',
      };
      final token = _session.accessToken.value;
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      final Object? payload = data ?? params;
      final String? body = payload == null
          ? null
          : payload is String
              ? payload
              : json.encode(payload);
      _logRequest(method: 'PATCH', uri: uri, headers: headers, body: body);

      final response = await sendHttpRequest(
        method: 'PATCH',
        uri: uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      final decodedBody = _tryDecode(response.bodyText);
      _logResponse(
        method: 'PATCH',
        uri: uri,
        statusCode: response.statusCode,
        decodedBody: decodedBody,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = _extractErrorMessage(decodedBody);
        _logError(method: 'PATCH', endpoint: uri.toString(), message: message);
        if (showErrorToast) {
          await ToastService.error(message);
        }
        onError(message);
        return;
      }

      if (decodedBody is Map) {
        final dynamic statusCode = decodedBody['statusCode'];
        if (statusCode != null && statusCode.toString() != '200') {
          final message = decodedBody['message']?.toString() ??
              decodedBody['error']?.toString() ??
              'Request failed';
          _logError(method: 'PATCH', endpoint: uri.toString(), message: message);
          if (showErrorToast) {
            await ToastService.error(message);
          }
          onError(message);
          return;
        }

        final dynamic success = decodedBody['success'];
        if (success is bool && success == false) {
          final message = decodedBody['error']?.toString() ??
              decodedBody['message']?.toString() ??
              'Request failed';
          _logError(method: 'PATCH', endpoint: uri.toString(), message: message);
          if (showErrorToast) {
            await ToastService.error(message);
          }
          onError(message);
          return;
        }
      }

      if (showSuccessToast) {
        await ToastService.success(
          successToastMessage ?? _extractSuccessMessage(decodedBody),
        );
      }

      onSuccess(<String, dynamic>{'response': decodedBody});
    } catch (e) {
      final message = e.toString();
      _logError(method: 'PATCH', endpoint: url, message: message);
      if (showErrorToast) {
        await ToastService.error(message);
      }
      onError(message);
    }
  }

  Future<void> deleteRequest({
    required String url,
    dynamic header,
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool showSuccessToast = false,
    String? successToastMessage,
    bool showErrorToast = false,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String?) onError,
  }) async {
    try {
      final uri = _resolveUri(url, queryParameters);

      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'X-Requested-With': 'XMLHttpRequest',
      };
      final token = _session.accessToken.value;
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

      if (header is Map) {
        headers.addAll(
          header.map((key, value) => MapEntry(key.toString(), value.toString())),
        );
      }

      final String? body = data == null
          ? null
          : data is String
              ? data
              : json.encode(data);
      _logRequest(method: 'DELETE', uri: uri, headers: headers, body: body);

      final response = await sendHttpRequest(
        method: 'DELETE',
        uri: uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      final decodedBody = _tryDecode(response.bodyText);
      _logResponse(
        method: 'DELETE',
        uri: uri,
        statusCode: response.statusCode,
        decodedBody: decodedBody,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final message = _extractErrorMessage(decodedBody);
        _logError(method: 'DELETE', endpoint: uri.toString(), message: message);
        if (showErrorToast) {
          await ToastService.error(message);
        }
        onError(message);
        return;
      }

      if (showSuccessToast) {
        await ToastService.success(
          successToastMessage ?? _extractSuccessMessage(decodedBody),
        );
      }
      onSuccess(<String, dynamic>{'response': decodedBody});
    } catch (e) {
      final message = e.toString();
      _logError(method: 'DELETE', endpoint: url, message: message);
      if (showErrorToast) {
        await ToastService.error(message);
      }
      onError(message);
    }
  }
}

