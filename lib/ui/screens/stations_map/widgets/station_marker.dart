import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> createNumberMarker(int bikeCount) async {
  Color color;
  if (bikeCount == 0) {
    color = Colors.red;
  } else if (bikeCount <= 4) {
    color = Colors.orange;
  } else {
    color = Colors.green;
  }

  const double width = 120;
  const double height = 140;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final fillPaint = Paint()..color = color;

  canvas.drawCircle(const Offset(width / 2, 45), 36, fillPaint);

  final path = Path()
    ..moveTo(width / 2 - 16, 72)
    ..lineTo(width / 2 + 16, 72)
    ..lineTo(width / 2, 110)
    ..close();
  canvas.drawPath(path, fillPaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  canvas.drawCircle(const Offset(width / 2, 45), 36, borderPaint);
  canvas.drawPath(path, borderPaint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: '$bikeCount',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((width - textPainter.width) / 2, 45 - textPainter.height / 2),
  );

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to convert marker to bytes');
  }

  return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
}