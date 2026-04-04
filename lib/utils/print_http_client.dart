import 'dart:convert';

import 'package:http/http.dart' as http;

/// Исправляет опечатку `host:8181:/print` → `host:8181/print` (лишнее `:` перед путём).
String normalizePrintServerUrlTypos(String s) {
  return s.replaceAllMapped(
    RegExp(r'(\d{1,5}):/(?=[^/]|\z)'),
    (Match m) => '${m[1]}/',
  );
}

/// URL печати из конфига: без схемы подставляется **`http://`** (локальная сеть).
Uri? resolvePrintServerUri(String url) {
  final trimmed = normalizePrintServerUrlTypos(url.trim());
  if (trimmed.isEmpty) return null;

  var withScheme = trimmed;
  final lc = trimmed.toLowerCase();
  if (!lc.startsWith('http://') && !lc.startsWith('https://')) {
    withScheme = 'http://$trimmed';
  }

  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasScheme) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}

/// POST JSON на URL из `print_server` — обычно **http://** хост в локальной сети (RFC 1918).
/// На Android/iOS/macOS включён доступ к cleartext HTTP для LAN. Ожидается JSON-ответ с `errorCode` / `errorMessage`.
Future<Map<String, dynamic>> postPrintServerJson({
  required String url,
  required Map<String, dynamic> body,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final trimmed = url.trim();
  final uri = resolvePrintServerUri(trimmed);
  if (uri == null) {
    return <String, dynamic>{
      'errorCode': -10,
      'errorMessage':
          'Invalid print_server URL: $trimmed (use http:// or https://, or host:port/path — then http is assumed)',
    };
  }

  try {
    final resp = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode(body)),
        )
        .timeout(timeout);

    final str = utf8.decode(resp.bodyBytes);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (str.trim().isEmpty) {
        return <String, dynamic>{'errorCode': 0, 'errorMessage': ''};
      }
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
        return <String, dynamic>{'errorCode': 0, 'errorMessage': ''};
      } catch (_) {
        return <String, dynamic>{
          'errorCode': 0,
          'errorMessage': '',
        };
      }
    }
    return <String, dynamic>{
      'errorCode': -10,
      'errorMessage': 'HTTP ${resp.statusCode}: $str',
    };
  } catch (e) {
    return <String, dynamic>{
      'errorCode': -10,
      'errorMessage': e.toString(),
    };
  }
}

/// POST JSON на `print_server`, но в отличие от [postPrintServerJson] не
/// требует схему `errorCode`/`errorMessage`.
///
/// Полезно для эндпоинта `/fiscal`, который возвращает JSON вида:
/// `{ "in": {...}, "out": {...}, "error": "...", "result": 0 }`
/// и может отвечать не-2xx.
Future<Map<String, dynamic>> postPrintServerJsonAny({
  required String url,
  required Map<String, dynamic> body,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final trimmed = url.trim();
  final uri = resolvePrintServerUri(trimmed);
  if (uri == null) {
    return <String, dynamic>{
      'errorCode': -10,
      'errorMessage':
          'Invalid print_server URL: $trimmed (use http:// or https://, or host:port/path — then http is assumed)',
    };
  }

  try {
    final resp = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: utf8.encode(jsonEncode(body)),
        )
        .timeout(timeout);

    final str = utf8.decode(resp.bodyBytes);
    final httpStatus = resp.statusCode;

    if (str.trim().isEmpty) {
      return <String, dynamic>{'_httpStatus': httpStatus};
    }

    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return <String, dynamic>{
          ...decoded,
          '_httpStatus': httpStatus,
        };
      }
      if (decoded is Map) {
        return <String, dynamic>{
          ...Map<String, dynamic>.from(decoded),
          '_httpStatus': httpStatus,
        };
      }
      return <String, dynamic>{'_httpStatus': httpStatus, '_raw': str};
    } catch (_) {
      return <String, dynamic>{'_httpStatus': httpStatus, '_raw': str};
    }
  } catch (e) {
    return <String, dynamic>{
      'errorCode': -10,
      'errorMessage': e.toString(),
    };
  }
}
