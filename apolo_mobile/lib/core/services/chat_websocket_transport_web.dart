import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'chat_websocket_transport.dart';

class _WebWebSocketTransport implements ChatWebSocketTransport {
  JSObject? _ws;
  final _msgCtrl = StreamController<String>.broadcast();
  final _closeCtrl = StreamController<void>.broadcast();
  bool _open = false;

  @override
  Stream<String> get messages => _msgCtrl.stream;

  @override
  Stream<void> get onClose => _closeCtrl.stream;

  @override
  bool get isOpen {
    final ws = _ws;
    if (!_open || ws == null) return false;
    final state = ws.getProperty<JSNumber?>('readyState'.toJS)?.toDartInt;
    return state == 1;
  }

  @override
  Future<void> connect(String url) async {
    closeSocketOnly();
    final completer = Completer<void>();

    final wsCtor = globalContext.getProperty<JSFunction?>('WebSocket'.toJS);
    if (wsCtor == null) {
      throw StateError('WebSocket API unavailable in browser context');
    }

    final ws = wsCtor.callAsConstructor<JSObject>(url.toJS);
    _ws = ws;

    ws.setProperty(
      'onopen'.toJS,
      (() {
        _open = true;
        if (!completer.isCompleted) completer.complete();
      }).toJS,
    );

    ws.setProperty(
      'onmessage'.toJS,
      ((JSObject evt) {
        final raw = evt.getProperty<JSAny?>('data'.toJS);
        if (raw != null && raw.typeofEquals('string')) {
          final text = (raw as JSString).toDart;
          if (!_msgCtrl.isClosed) _msgCtrl.add(text);
        }
      }).toJS,
    );

    ws.setProperty(
      'onclose'.toJS,
      (() {
        _open = false;
        if (!completer.isCompleted) {
          completer.completeError(StateError('WebSocket closed before open'));
        }
        if (!_closeCtrl.isClosed) _closeCtrl.add(null);
      }).toJS,
    );

    ws.setProperty(
      'onerror'.toJS,
      (() {
        _open = false;
        if (!completer.isCompleted) {
          completer.completeError(StateError('WebSocket connection error'));
        }
      }).toJS,
    );

    return completer.future.timeout(const Duration(seconds: 6));
  }

  @override
  void send(String data) {
    if (!isOpen) return;
    _ws?.callMethod<JSAny?>('send'.toJS, data.toJS);
  }

  void closeSocketOnly() {
    _open = false;
    try {
      _ws?.callMethod<JSAny?>('close'.toJS, 1000.toJS, 'client_close'.toJS);
    } catch (_) {}
    _ws = null;
  }

  @override
  Future<void> close() async {
    closeSocketOnly();
    if (!_msgCtrl.isClosed) await _msgCtrl.close();
    if (!_closeCtrl.isClosed) await _closeCtrl.close();
  }
}

ChatWebSocketTransport createPlatformWebSocketTransport() =>
    _WebWebSocketTransport();
