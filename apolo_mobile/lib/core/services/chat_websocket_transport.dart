import 'chat_websocket_transport_stub.dart'
    if (dart.library.io) 'chat_websocket_transport_io.dart'
    if (dart.library.js_interop) 'chat_websocket_transport_web.dart';

/// Platform-agnostic persistent WebSocket transport (IO & Web).
abstract class ChatWebSocketTransport {
  Stream<String> get messages;
  Stream<void> get onClose;
  bool get isOpen;

  Future<void> connect(String url);
  void send(String data);
  Future<void> close();

  factory ChatWebSocketTransport() => createPlatformWebSocketTransport();
}
