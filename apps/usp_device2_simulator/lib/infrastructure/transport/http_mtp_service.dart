import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:usp_device2_simulator/infrastructure/adapter/usp_message_adapter.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

class HttpMtpService {
  final UspMessageAdapter _adapter;
  final UspProtobufConverter _uspProtobufConverter;
  HttpServer? _server;

  // Simple token storage for POC
  final Map<String, bool> _validTokens = {};

  HttpMtpService({required UspMessageAdapter adapter})
    : _adapter = adapter,
      _uspProtobufConverter = UspProtobufConverter();

  Future<void> start({int port = 8081}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('✅ HTTP MTP Service listening on http://0.0.0.0:$port');

    _server!.listen((HttpRequest request) {
      _handleRequest(request).catchError((e) {
        print('❌ Error handling HTTP request: $e');
        try {
          if (request.response.connectionInfo != null) {
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.close();
          }
        } catch (_) {}
      });
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    print('🛑 HTTP MTP Service stopped.');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // CORS headers
    final response = request.response;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    response.headers.add(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization, Cookie',
    );
    response.headers.add('Access-Control-Allow-Credentials', 'true');

    if (request.method == 'OPTIONS') {
      await response.close();
      return;
    }

    if (request.uri.path == '/api/v1/auth/login' && request.method == 'POST') {
      await _handleLogin(request);
    } else if (request.uri.path == '/api/v1/usp' && request.method == 'POST') {
      await _handleUsp(request);
    } else if (request.uri.path == '/api/v1/auth/logout' &&
        request.method == 'POST') {
      await _handleLogout(request);
    } else if (request.uri.path == '/api/v1/auth/refresh' &&
        request.method == 'POST') {
      await _handleRefresh(request);
    } else if (request.uri.path == '/api/v1/health' &&
        request.method == 'GET') {
      await _handleHealth(request);
    } else {
      response.statusCode = HttpStatus.notFound;
      await response.close();
    }
  }

  Future<void> _handleLogin(HttpRequest request) async {
    // In a real implementation this would verify a password from the request body.
    // For the simulator, we accept anything and generate a token.
    final token = 'usp_token_${DateTime.now().millisecondsSinceEpoch}';
    _validTokens[token] = true;

    // Provide AuthResponse compatible with usp-client
    final authResponse = {
      'success': true,
      'token': token,
      'endpoints': {
        'controller': '/api/v1/usp',
        'turbo': '/api/v1/turbo/start',
      },
    };

    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.json;
    // Set cookie for auth
    response.headers.add('Set-Cookie', 'access_token=$token; Path=/; HttpOnly');

    response.write(jsonEncode(authResponse));
    await response.close();
  }

  Future<void> _handleHealth(HttpRequest request) async {
    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'status': 'ok'}));
    await response.close();
  }

  Future<void> _handleRefresh(HttpRequest request) async {
    final oldToken = _extractToken(request);
    final response = request.response;

    if (oldToken == null || _validTokens[oldToken] != true) {
      response.statusCode = HttpStatus.unauthorized;
      await response.close();
      return;
    }

    _validTokens.remove(oldToken);
    final newToken = 'usp_token_${DateTime.now().millisecondsSinceEpoch}';
    _validTokens[newToken] = true;

    final authResponse = {
      'success': true,
      'token': newToken,
      'endpoints': {
        'controller': '/api/v1/usp',
        'turbo': '/api/v1/turbo/start',
      },
    };

    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.json;
    response.headers.add(
      'Set-Cookie',
      'access_token=$newToken; Path=/; HttpOnly',
    );
    response.write(jsonEncode(authResponse));
    await response.close();
  }

  Future<void> _handleLogout(HttpRequest request) async {
    final token = _extractToken(request);
    if (token != null) {
      _validTokens.remove(token);
    }

    final response = request.response;
    response.statusCode = HttpStatus.ok;
    response.headers.add(
      'Set-Cookie',
      'access_token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT',
    );
    response.write(jsonEncode({'success': true}));
    await response.close();
  }

  Future<void> _handleUsp(HttpRequest request) async {
    final response = request.response;

    // Auth Check
    final token = _extractToken(request);
    if (token == null || _validTokens[token] != true) {
      print('⚠️ HTTP MTP: Unauthorized request');
      response.statusCode = HttpStatus.unauthorized;
      await response.close();
      return;
    }

    // Verify Content-Type
    final contentType = request.headers.contentType?.value;
    final validContentTypes = [
      'application/vnd.bbf.usp.msg',
      'application/x-protobuf',
      'application/octet-stream',
    ];

    if (contentType == null || !validContentTypes.contains(contentType)) {
      print('⚠️ HTTP MTP: Unsupported Media Type ($contentType)');
      response.statusCode = HttpStatus.unsupportedMediaType;
      response.write('Unsupported Media Type');
      await response.close();
      return;
    }

    try {
      // Read body
      final builder = BytesBuilder();
      await request.forEach(builder.add);
      final payload = builder.takeBytes();

      if (payload.isEmpty) {
        response.statusCode = HttpStatus.badRequest;
        await response.close();
        return;
      }

      // Parse bare Msg directly
      final Msg uspMsg = Msg.fromBuffer(payload);
      final requestDto = _uspProtobufConverter.fromProto(uspMsg);

      // Handle Request
      final responseDto = await _adapter.handleRequest(requestDto);

      // Build bare Msg for Response
      final responseMsg = _uspProtobufConverter.toProto(
        responseDto,
        msgId: uspMsg.header.msgId,
      );

      final responseBytes = responseMsg.writeToBuffer();

      // Return Response
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType(
        'application',
        'vnd.bbf.usp.msg',
      );
      response.add(responseBytes);
      await response.close();
    } catch (e) {
      print('❌ HTTP MTP Error: $e');
      try {
        response.statusCode = HttpStatus.internalServerError;
      } catch (_) {}
      try {
        await response.close();
      } catch (_) {}
    }
  }

  String? _extractToken(HttpRequest request) {
    // 1. Check Authorization header
    final authHeader = request.headers.value('authorization');
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    // 2. Check Cookie
    final cookies = request.cookies;
    for (final cookie in cookies) {
      if (cookie.name == 'access_token') {
        return cookie.value;
      }
    }

    return null;
  }
}
