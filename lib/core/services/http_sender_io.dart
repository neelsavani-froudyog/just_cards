import 'dart:convert';
import 'dart:io';

class HttpApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String bodyText;

  HttpApiResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyText,
  });
}

Future<HttpApiResponse> sendHttpRequest({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
  String? body,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final HttpClient httpClient = HttpClient();
  try {
    final HttpClientRequest request =
        await httpClient.openUrl(method, uri).timeout(timeout);

    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    if (body != null) {
      request.write(body);
    }

    final HttpClientResponse response = await request.close().timeout(timeout);

    final bytes = await response
        .fold<List<int>>(<int>[], (previous, data) => previous..addAll(data))
        .timeout(timeout);
    final bodyText = utf8.decode(bytes, allowMalformed: true);

    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) {
      responseHeaders[name] = values.join(', ');
    });

    return HttpApiResponse(
      statusCode: response.statusCode,
      headers: responseHeaders,
      bodyText: bodyText,
    );
  } finally {
    httpClient.close(force: true);
  }
}

