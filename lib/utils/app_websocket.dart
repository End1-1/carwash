import 'dart:async';
import 'dart:convert';

import 'package:carwash/utils/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStateType { connected, disconnected, connecting, error }

class AppWebSocket {
  static int _counter = 1;
  static ConnectionStateType connectionState = ConnectionStateType.disconnected;
  WebSocketChannel? _channel;
  final StreamController<ConnectionStateType> _connectionStateController =
      StreamController.broadcast();
  final StreamController<String> messageBroadcast =
      StreamController.broadcast();

  Stream<ConnectionStateType> get connectionStream =>
      _connectionStateController.stream;
  var _host = '';
  Function(Map<String, dynamic>)? _callerHandleMessage;

  AppWebSocket() {
    _connect();
  }

  void _connect() {
    if (connectionState == ConnectionStateType.connected ||
        connectionState == ConnectionStateType.connecting) {
      return;
    }
    _host = prefs.string('websocket');
    if (kDebugMode) {
      print('Connecting to: $_host');
    }
    _setConnectionState(ConnectionStateType.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_host));
      _channel?.stream.listen(_handleMessage, onError: (e) {
        if (kDebugMode) {
          print('Error on $_host: $e');
        }
        _replyMessage({'errorCode':-10, 'errorMessage': e.toString()});
        _closeChannel();
        _setConnectionState(ConnectionStateType.error);
        _socketDisconnected();
      }, onDone: _socketDisconnected);
      if (kDebugMode) {
        print('Connected to: $_host');
      }
      _replyMessage({'errorCode':-12, 'errorMessage': 'Reconnected'});
      _setConnectionState(ConnectionStateType.connected);
    } catch (e) {
      _replyMessage({'errorCode':-10, 'errorMessage': e.toString()});
      _closeChannel();
      _setConnectionState(ConnectionStateType.error);
      _reconnect();
    }
  }

  void _setConnectionState(ConnectionStateType t) {
    connectionState = t;
    _connectionStateController.add(t);
  }

  void _socketDisconnected() {
    if (kDebugMode) {
      print('Websocket disconnected');
    }
    _closeChannel();
    _connectionStateController.add(ConnectionStateType.disconnected);
    _reconnect();
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5)).then((_) {
      _connect();
    });
  }

  void _closeChannel() {
    _channel?.sink.close();
    _channel = null;
    connectionState = ConnectionStateType.disconnected;
  }

  void _replyMessage(Map<String, dynamic> reply) {
    if (_callerHandleMessage != null) {
      _callerHandleMessage!(reply);
      _callerHandleMessage = null;
    }
  }

  void _handleMessage(dynamic msg) {
    if (kDebugMode) {
      print('Websocket message: $msg');
    }
    _replyMessage(jsonDecode(msg));
  }

  int messageId() {
    return _counter++;
  }

  Map<String, dynamic> _makeErrorMsg(String error) {
    return {"errorCode": -10, "errorMessage": error};
  }

  void sendMessage(String msg, Function(Map<String, dynamic>)? handle) {
    if (kDebugMode) {
      print('send message to websocket:');
      print(msg);
    }
    _callerHandleMessage = handle;
    if (connectionState != ConnectionStateType.connected || _channel == null) {
      if (kDebugMode) {
        print(
            'send message failed. ConnectionState: $connectionState, channel: $_channel');
      }
      _replyMessage(_makeErrorMsg('Service unavailable: -10'));
      _socketDisconnected();
      return;
    }
    try {
      _channel?.sink.add(msg);
    } catch (e) {
      _setConnectionState(ConnectionStateType.error);
      _socketDisconnected();
      _replyMessage(_makeErrorMsg(e.toString()));
    }
  }
}
