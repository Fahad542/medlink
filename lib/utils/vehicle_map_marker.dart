import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders a small vehicle-style bitmap for the driver on Google Maps (no default pin).
class VehicleMapMarker {
  VehicleMapMarker._();

  static BitmapDescriptor? _cached;
  static double? _cachedDpr;

  /// Builds once per device pixel ratio; safe to call from [initState] post-frame.
  static Future<BitmapDescriptor> forContext(BuildContext context) async {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (_cached != null && _cachedDpr == dpr) {
      return _cached!;
    }
    _cachedDpr = dpr;
    _cached = await _build(dpr);
    return _cached!;
  }

  static Future<BitmapDescriptor> _build(double devicePixelRatio) async {
    const logicalSide = 56.0;
    final side = (logicalSide * devicePixelRatio).roundToDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(side / 2, side / 2 + 1.5 * devicePixelRatio);
    final r = 22 * devicePixelRatio;

    final shadowPaint = Paint()
      ..color = const Color(0x59000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * devicePixelRatio);
    canvas.drawCircle(center.translate(0, 1.2 * devicePixelRatio), r, shadowPaint);

    canvas.drawCircle(center, r, Paint()..color = Colors.white);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * devicePixelRatio,
    );

    final icon = Icons.local_shipping_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24 * devicePixelRatio,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFF1D4ED8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(side.toInt(), side.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
