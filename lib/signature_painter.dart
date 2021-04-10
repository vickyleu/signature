

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signature/gesture_whiteboard_controller.dart';
import 'package:signature/whiteboard_draw.dart';

class SignaturePainter extends CustomPainter {
  SignaturePainter({required this.lines,required this.controller});

  List<Line> lines;
  GestureWhiteboardController controller;

  final Paint _eraserPaint = Paint()
    ..color = Colors.transparent
    ..blendMode = BlendMode.clear
    ..strokeWidth = 10
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.clipRect(
        Rect.fromPoints(new Offset(0, 0), new Offset(size.width, size.height)));

    Paint paint = new Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      paint = paint
        ..color = line.color
        ..strokeWidth = line.width;
      drawLine(canvas, paint, line);
    }
    canvas.restore();
    canvas.restore();
  }

  drawLine(Canvas canvas, Paint paint, Line line) {
    final pointsCount=line.points?.length??0;
    for (int i = 0; i < (pointsCount- 1); i++) {
      if(pointsCount>(i+1)){
        if (line.points![i] != null && line.points![i + 1] != null) {
          if (line.erase) {
            _eraserPaint.strokeWidth = controller.eraserSize;
            canvas.drawLine(
              line.points![i]?.toOffset()??Offset.zero,
              line.points![i + 1]?.toOffset()??Offset.zero,
              _eraserPaint,
            );
          } else {
            canvas.drawLine(
                line.points![i]?.toOffset()??Offset.zero,
                line.points![i + 1]?.toOffset()??Offset.zero, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.lines.fold(0, (total, l) => ((l.points?.length??0) + ((total as int?)??0))) !=
          lines.fold(0, (total, l) => ((l.points?.length??0)  +  ((total as int?)??0)));
}