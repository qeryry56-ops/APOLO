import 'dart:async';
import 'chat_websocket_transport.dart';

class _StubWebSocketTransport implements ChatWebSocketTransport {
  final _msgCtrl = StreamController<String>.broadcast();
  final _closeCtrl = StreamController<void>.broadcast();

  @override
  Stream<String> get messages => _msgCtrl.stream;

  @override
  Stream<void> get onClose => _closeCtrl.stream;

  @override
  bool get isOpen => false;

  @override
  Future<void> connect(String url) async {}

  @override
  void send(String data) {}

  @override
  Future<void> close() async {
    await _msgCtrl.close();
    await _closeCtrl.close();
  }
}

ChatWebSocketTransport createPlatformWebSocketTransport() =>
    _StubWebSocketTransport();
