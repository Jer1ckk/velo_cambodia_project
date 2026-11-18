import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../theme/theme.dart';

Future<BitmapDescriptor> createNumberMarker(
  int bikeCount, {
  bool selected = false,
}) async {
  // Render at 2x, then supply logical dimensions for consistent map sizing.
  const width = 96.0;
  const height = 112.0;
  final color = selected
      ? VeloColors.neutralDark
      : bikeCount == 0
      ? VeloColors.backgroundAccent
      : VeloColors.primary;
  final foreground = selected ? VeloColors.white : VeloColors.neutralDark;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final shape = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 4, 88, 80),
        const Radius.circular(32),
      ),
    )
    ..moveTo(34, 82)
    ..lineTo(48, 104)
    ..lineTo(62, 82)
    ..close();
  canvas.drawPath(shape, Paint()..color = color);
  canvas.drawPath(
    shape,
    Paint()
      ..color = VeloColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );
  final painter = TextPainter(
    text: TextSpan(
      text: '$bikeCount',
      style: TextStyle(
        color: foreground,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset((width - painter.width) / 2, (88 - painter.height) / 2),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Unable to render station marker');
    return BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      width: 48,
      height: 56,
    );
  } finally {
    image.dispose();
    picture.dispose();
    painter.dispose();
  }
}
