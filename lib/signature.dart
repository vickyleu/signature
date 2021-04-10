
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:signature/OnlyOnePointerRecognizer.dart';
import 'package:signature/gesture_whiteboard_controller.dart';
import 'package:signature/signature_painter.dart';
import 'package:signature/whiteboard_draw.dart';

export 'package:signature/gesture_whiteboard_controller.dart';
/// signature canvas. Controller is required, other parameters are optional.
/// widget/canvas expands to maximum by default.
/// this behaviour can be overridden using width and/or height parameters.
class Signature extends StatefulWidget {
  /// constructor
  const Signature({
    required this.controller,
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  /// signature widget controller
  final GestureWhiteboardController controller;

  /// signature widget width
  final double? width;

  /// signature widget height
  final double? height;

  @override
  State createState() => SignatureState();
}

/// signature widget state
class SignatureState extends State<Signature> {
  bool initialized = false;
  //drawing tools
  Size boardSize=Size.zero;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = widget.width ?? double.infinity;
    final double maxHeight = widget.height ?? double.infinity;
    final GestureDetector signatureCanvas = GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        //NO-OP
      },
      child: Container(
          decoration: BoxDecoration(color: Colors.white),
          constraints: BoxConstraints(
              minWidth: maxWidth,
              minHeight: maxHeight,
              maxWidth: maxWidth,
              maxHeight: maxHeight),
          child:LayoutBuilder(builder: (context, constraints) {
            if (!initialized) {
              widget.controller
                  .initializeSize(constraints.maxHeight, constraints.maxWidth);
              initialized = true;
            }
            boardSize = widget.controller.getSize();
            return StreamBuilder<WhiteboardDraw>(
                stream: widget.controller.onChange(),
                builder: (context, snapshot) {
                  List<Line> lines = [];
                  if (snapshot.data?.lines != null) {
                    snapshot.data!.lines!.forEach((l) => l.wipe ? lines = [] : lines.add(l.clone()));
                    lines = scaleLines(lines, snapshot.data!.width,snapshot.data!.height, boardSize.width, boardSize.height);
                  }
                  var painter = new SignaturePainter(lines: lines, controller: widget.controller);
                  if(initialized){
                    print("widget.controller.paintNotifier==>>${widget.controller.paintNotifier}");
                    painter.addListener((){
                      widget.controller.paintNotifier(() {
                        if(mounted){
                          setState(() {});
                        }
                      });
                    });
                  }
                  return OnlyOnePointerRecognizerWidget(
                    child: GestureDetector(
                      onPanUpdate: (DragUpdateDetails details) {
                        RenderBox? object = context.findRenderObject() as RenderBox?;
                        Offset? _localPosition = object?.globalToLocal(details.globalPosition);
                        if(_localPosition==null)return;
                        widget.controller.onPanUpdate(_localPosition);
                        setState(() {});
                      },
                      onVerticalDragUpdate: (DragUpdateDetails details){
                        RenderBox? object = context.findRenderObject() as RenderBox?;
                        Offset? _localPosition = object?.globalToLocal(details.globalPosition);
                        if(_localPosition==null)return;
                        widget.controller.onPanUpdate(_localPosition);
                        setState(() {});
                      },
                      onPanEnd: (DragEndDetails details) {
                        widget.controller.onPanEnd();
                        setState(() {});
                      },
                      child: Container(
                        child: CustomPaint(
                          foregroundPainter: painter,
                          size: Size.infinite,
                          child: Container(
                            color: Colors.yellow,
                          ),
                        ),
                        color: Colors.red,
                      ),
                    ),
                  );
                });
          })
      ),
    );

    if (widget.width != null || widget.height != null) {
      //IF DOUNDARIES ARE DEFINED, USE LIMITED BOX
      return Center(
        child: LimitedBox(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          child: signatureCanvas,
        ),
      );
    } else {
      //IF NO BOUNDARIES ARE DEFINED, USE EXPANDED
      return Expanded(child: signatureCanvas);
    }
  }

  List<Line> scaleLines(List<Line> lines, double width, double height,
      double boardWidth, double boardHeight) {
    var scaleX = boardWidth / width; // 0.5
    var scaleY = boardHeight / height; // 1

    var scale = 0.0;

    if (scaleX < scaleY) {
      scale = scaleX;
    } else {
      scale = scaleY;
    }

    return lines
        .map((line) => line.clone()
      ..points = line.points?.map((point) => point==null?null:Point(point.x * scale, point.y * scale))
          .toList()
      ..width = line.width * scale)
        .toList();
  }

}


