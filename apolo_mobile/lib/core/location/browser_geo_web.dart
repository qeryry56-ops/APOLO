import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Requests browser HTML5 geolocation when running on Flutter Web.
Future<({double lat, double lng})?> tryBrowserGeolocation({
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    final nav = globalContext.getProperty<JSObject?>('navigator'.toJS);
    if (nav == null) return null;
    final geo = nav.getProperty<JSObject?>('geolocation'.toJS);
    if (geo == null) return null;

    final completer = Completer<({double lat, double lng})?>();

    void onSuccess(JSObject pos) {
      if (completer.isCompleted) return;
      final coords = pos.getProperty<JSObject?>('coords'.toJS);
      final latNum = coords?.getProperty<JSNumber?>('latitude'.toJS);
      final lngNum = coords?.getProperty<JSNumber?>('longitude'.toJS);
      final lat = latNum?.toDartDouble;
      final lng = lngNum?.toDartDouble;
      if (lat != null && lng != null && !lat.isNaN && !lng.isNaN) {
        completer.complete((lat: lat, lng: lng));
      } else {
        completer.complete(null);
      }
    }

    void onError(JSObject _) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }

    final options = JSObject()
      ..setProperty('enableHighAccuracy'.toJS, false.toJS)
      ..setProperty('timeout'.toJS, timeout.inMilliseconds.toJS)
      ..setProperty('maximumAge'.toJS, 300000.toJS);

    geo.callMethodVarArgs<JSAny?>(
      'getCurrentPosition'.toJS,
      <JSAny?>[onSuccess.toJS, onError.toJS, options],
    );

    return await completer.future.timeout(
      timeout + const Duration(milliseconds: 500),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
}
