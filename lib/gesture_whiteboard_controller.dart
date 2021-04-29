import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:signature/signature_painter.dart';

import 'whiteboard_controller.dart';
import 'whiteboard_draw.dart';

typedef PaintNotifier =void Function(void Function());
// ignore: non_constant_identifier_names
class GestureWhiteboardController extends WhiteboardController {
  final _streamController = StreamController<WhiteboardDraw>.broadcast();
  bool _newLine = true;
  DateTime? lastPan;
  DateTime? lastLine;
  final PaintNotifier paintNotifier = (f) {
    f();
    return;
  };
  double brushSize = 20.0;
  Color brushColor = Colors.blue;
  bool erase = false;
  double eraserSize = 20.0;

  GestureWhiteboardController({WhiteboardDraw? draw}){
    if (draw != null) {
      this.draw = draw.clone();
      refresh();
    }
  }

  @override
  Stream<WhiteboardDraw> onChange() {
    return _streamController.stream;
  }

  bool get isNotEmpty=>(this.draw?.lines?.isNotEmpty??false);

  close() {
    return _streamController.close();
  }

  onPanStart(Offset position) {
    if (this.draw == null) return;
    // if (_newLine){
      onPanUpdate(position);
    // }
  }
  onPanUpdate(Offset position) {
    if (this.draw == null) return;
    if (_newLine) {
      print("_newLine  ${_newLine}");
      this.draw?.lines?.add(new Line(
          points: [],
          color: erase ? Colors.white : brushColor,
          width: erase ? eraserSize : brushSize,
          erase: erase));
      _newLine = false;
      lastLine = DateTime.now();
    }
    if ((this.draw?.lines?.isNotEmpty??false)&&(this.draw?.lines?.last.points?.length??0) > 2 &&
        lastPan != null &&
        (lastPan!.millisecond - DateTime.now().millisecond) < 100) {
      var a1 = position.dx - ((this.draw!.lines!.last.points!.last?.x)??0);
      var a2 = position.dy - ((this.draw!.lines!.last.points!.last?.y)??0);
      var a3 = math.sqrt(math.pow(a1, 2) + math.pow(a2, 2));
      if (a3 < 5) return;
      if (a3 > 80) return;
    }

    if ((this.draw?.lines?.isEmpty??true)||(this.draw?.lines?.last.points?.length??0) == 0 ||
        position != (this.draw!.lines!.last.points!.last)?.toOffset()) {
      this.draw!.lines!.last.points = new List.from(this.draw!.lines!.last.points!)
        ..add(Point.fromOffset(position));
      lastPan = DateTime.now();
    }
    refresh();
  }

  onPanEnd() {
    _newLine = true;
    this.draw?.lines?.last.duration =
    lastLine==null?0:DateTime.now().difference(lastLine!).inMilliseconds;

    if ((this.draw?.lines?.isNotEmpty??false)&&this.draw!.lines!.length > 0 && (this.draw!.lines!.last.points?.length??0) == 1) {
      var secondPoint = new Offset(((this.draw!.lines!.last.points!.last?.x)??0) + 1,
          ((this.draw!.lines!.last.points!.last?.y)??0)+ 1);
      this.draw!.lines!.last.points!.add(Point.fromOffset(secondPoint));
      refresh();
    }
    if ((this.draw?.lines?.length??0) > 0 && (this.draw!.lines!.last.points?.length??0) == 0) {
      this.draw!.lines!.removeLast();
    }
  }

  refresh() {
    if(this.draw!=null){
      _streamController.sink.add(this.draw!);
    }
  }

  undo() {
    if ((this.draw?.lines?.length??0) > 0) this.draw!.lines!.removeLast();
    refresh();
  }

  wipe() {
    this.draw?.lines?.add(new Line(points: [], wipe: true));
    refresh();
  }

  /// convert canvas to dart:ui Image and then to PNG represented in Uint8List
  Future<Uint8List?> toPngBytes() async {
    if (!kIsWeb) {
      final ui.Image? image = await toImage();
      if (image == null) {
        return null;
      }
      final ByteData? bytes = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return bytes?.buffer.asUint8List();
    } else {
      return _toPngBytesForWeb();
    }
  }

  // 'image.toByteData' is not available for web. So we are using the package
  // 'image' to create an image which works on web too
  Uint8List? _toPngBytesForWeb() {
    final linesTemp=this.draw?.lines;
    final nemp=linesTemp?.isNotEmpty??false;
    if (!nemp) {
      return null;
    }
    final lines=linesTemp!;

    final Color backgroundColor = Colors.transparent;
    final int bColor = img.getColor(backgroundColor.red, backgroundColor.green,
        backgroundColor.blue, backgroundColor.alpha.toInt());

    // create the image with the given size
    final img.Image signatureImage = img.Image(getSize().width.toInt(),getSize().height.toInt());
    // set the image background color
    img.fill(signatureImage, bColor);

    // read the drawing points list and draw the image
    // it uses the same logic as the CustomPainter Paint function
    Paint paint = new Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint _eraserPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..strokeWidth = 10
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      paint = paint
        ..color = line.color
        ..strokeWidth = line.width;
      for (int i = 0; i < (line.points?.length??0 - 1); i++) {
        if (line.points?.elementAt(i) != null && line.points?.elementAt(i + 1) != null) {
          if (line.erase) {
            _eraserPaint.strokeWidth = eraserSize;
            img.drawLine(
              signatureImage,
              line.points![i]?.toOffset().dx.toInt()??0,
              line.points![i]?.toOffset().dy.toInt()??0,
              line.points![i + 1]?.toOffset().dx.toInt()??0,
              line.points![i + 1]?.toOffset().dy.toInt()??0,
              img.getColor(_eraserPaint.color.red, _eraserPaint.color.green,
                  _eraserPaint.color.blue, _eraserPaint.color.alpha.toInt()),
              // _eraserPaint,
            );
          } else {
            img.drawLine(
              signatureImage,
              line.points![i]?.toOffset().dx.toInt()??0,
              line.points![i]?.toOffset().dy.toInt()??0,
              line.points![i + 1]?.toOffset().dx.toInt()??0,
              line.points![i + 1]?.toOffset().dy.toInt()??0,
              img.getColor(line.color.red, line.color.green,
                  line.color.blue, line.color.alpha.toInt()),
              // paint
            );
          }
        }
      }
    }
    // encode the image to PNG
    return Uint8List.fromList(img.encodePng(signatureImage));
  }

  /// convert to
  Future<ui.Image?> toImage() async {
    final linesTemp=this.draw?.lines;
    final nemp=linesTemp?.isNotEmpty??false;
    if (!nemp) {
      return null;
    }
    final lines=linesTemp!;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder);
    SignaturePainter(lines:lines,controller: this).paint(canvas, Size.infinite);
    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(getSize().width.toInt(),getSize().height.toInt());
  }

  void turnOnOffErase(){
   setErase(!erase);
  }
  void setErase(bool erase){
    this.erase=erase;
  }
}
