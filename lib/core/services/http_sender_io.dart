import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

String _guessImageMime(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'application/octet-stream';
}

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

/// `multipart/form-data` with string fields plus one file (e.g. `event_name` + `image`).
Future<HttpApiResponse> sendMultipartFormData({
  required Uri uri,
  required Map<String, String> headers,
  required Map<String, String> textFields,
  required String fileFieldName,
  required File file,
  Duration timeout = const Duration(seconds: 120),
}) async {
  final fileBytes = await file.readAsBytes();
  final path = file.path;
  final filename = path.isEmpty
      ? 'card.jpg'
      : path.replaceAll('\\', '/').split('/').last;
  final mime = _guessImageMime(filename);

  final boundary = 'dart-${DateTime.now().microsecondsSinceEpoch}';
  const crlf = '\r\n';
  final builder = BytesBuilder();

  void write(String s) => builder.add(utf8.encode(s));

  for (final e in textFields.entries) {
    write('--$boundary$crlf');
    write('Content-Disposition: form-data; name="${e.key}"$crlf$crlf');
    write('${e.value}$crlf');
  }

  write('--$boundary$crlf');
  write(
    'Content-Disposition: form-data; name="$fileFieldName"; filename="${filename.replaceAll('"', '')}"$crlf',
  );
  write('Content-Type: $mime$crlf$crlf');
  builder.add(fileBytes);
  write('$crlf--$boundary--$crlf');

  final body = builder.toBytes();
  final contentType = 'multipart/form-data; boundary=$boundary';

  final HttpClient httpClient = HttpClient();
  try {
    final HttpClientRequest request =
        await httpClient.postUrl(uri).timeout(timeout);

    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    request.headers
        .set(HttpHeaders.contentLengthHeader, body.length.toString());

    for (final entry in headers.entries) {
      final k = entry.key;
      if (k.toLowerCase() == 'content-type') continue;
      request.headers.set(k, entry.value);
    }

    request.add(body);
    final HttpClientResponse response =
        await request.close().timeout(timeout);

    final responseBytes = await response
        .fold<List<int>>(<int>[], (previous, data) => previous..addAll(data))
        .timeout(timeout);
    final bodyText = utf8.decode(responseBytes, allowMalformed: true);

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

