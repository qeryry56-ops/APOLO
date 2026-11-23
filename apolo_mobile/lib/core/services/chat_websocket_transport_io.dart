import 'dart:async';
import 'dart:io';
import 'chat_websocket_transport.dart';

class _IoWebSocketTransport implements ChatWebSocketTransport {
  WebSocket? _socket;
  final _msgCtrl = StreamController<String>.broadcast();
  final _closeCtrl = StreamController<void>.broadcast();
  bool _open = false;

  @override
  Stream<String> get messages => _msgCtrl.stream;

  @override
  Stream<void> get onClose => _closeCtrl.stream;

  @override
  bool get isOpen => _open && _socket != null;

  @override
  Future<void> connect(String url) async {
    await closeSocketOnly();
    final socket = await WebSocket.connect(url).timeout(
      const Duration(seconds: 6),
    );
    _socket = socket;
    _open = true;
    socket.listen(
      (event) {
        if (event is String && !_msgCtrl.isClosed) {
          _msgCtrl.add(event);
        }
      },
      onDone: () {
        _open = false;
        if (!_closeCtrl.isClosed) _closeCtrl.add(null);
      },
      onError: (_) {
        _open = false;
        if (!_closeCtrl.isClosed) _closeCtrl.add(null);
      },
      cancelOnError: true,
    );
  }

  @override
  void send(String data) {
    if (!isOpen) return;
    _socket?.add(data);
  }

  Future<void> closeSocketOnly() async {
    _open = false;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  @override
  Future<void> close() async {
    await closeSocketOnly();
    if (!_msgCtrl.isClosed) await _msgCtrl.close();
    if (!_closeCtrl.isClosed) await _closeCtrl.close();
  }
}

ChatWebSocketTransport createPlatformWebSocketTransport() =>
    _IoWebSocketTransport();
