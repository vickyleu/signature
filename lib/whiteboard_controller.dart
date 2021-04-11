import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'whiteboard_draw.dart';

abstract class WhiteboardController {
  final _streamController = StreamController<WhiteboardDraw>.broadcast();

  double width=0;
  double height=0;

  WhiteboardDraw? draw;
  bool initialized=false;
  void initializeSize(double height, double width) {
    initialized = true;
    this.width = width;
    this.height = height;

    if (draw == null){
      draw = new WhiteboardDraw(height: height, width: width, lines: []);
    }
      print("draw===>>>${draw}  hashCode::${this.hashCode}");
  }


  Size getSize() => new Size(width,height);

  WhiteboardDraw? getDraw() => draw;

  Stream<WhiteboardDraw> onChange() {
    return _streamController.stream;
  }

  close() {
    return _streamController.close();
  }

  onPanUpdate(Offset position);

  onPanEnd();
}
