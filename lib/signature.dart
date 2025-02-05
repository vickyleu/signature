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
    this.disableNotifier,
  }) : super(key: key);

  /// signature widget controller
  final GestureWhiteboardController controller;

  /// signature widget width
  final double? width;

  /// signature widget height
  final double? height;

  final ValueNotifier<bool>? disableNotifier;

  @override
  State createState() => SignatureState();
}

/// signature widget state
class SignatureState extends State<Signature> {
  //drawing tools
  Size boardSize = Size.zero;

  @override
  void initState() {
    if (!widget.controller.initialized) {
      widget.controller.initializeSize(widget.height ?? 0, widget.width ?? 0);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = widget.width ?? double.infinity;
    final double maxHeight = widget.height ?? double.infinity;
    final GestureDetector signatureCanvas = GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        //NO-OP
      },
      child: Container(
          decoration: BoxDecoration(color: Colors.transparent),
          constraints: BoxConstraints(
              minWidth: maxWidth,
              minHeight: maxHeight,
              maxWidth: maxWidth,
              maxHeight: maxHeight),
          child: LayoutBuilder(builder: (context, constraints) {
            boardSize = widget.controller.getSize();
            return StreamBuilder<WhiteboardDraw>(
                stream: widget.controller.onChange(),
                builder: (context, snapshot) {
                  List<Line> lines = [];
                  if (snapshot.data?.lines != null) {
                    snapshot.data!.lines!.forEach((l) =>
                    l.wipe
                        ? lines = []
                        : lines.add(l.clone()));
                    lines = scaleLines(
                        lines, snapshot.data!.width, snapshot.data!.height,
                        boardSize.width, boardSize.height);
                  }
                  var painter = new SignaturePainter(
                      lines: lines, controller: widget.controller);
                  painter.addListener(() {
                    widget.controller.paintNotifier(() {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                  });
                  return SignatureOnlyOnePointerRecognizerWidget(
                      child: Listener(
                        child: CustomPaint(
                          foregroundPainter: painter,
                          size: Size.infinite,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                        onPointerCancel: (PointerCancelEvent details){
                          print("onPointerCancel${details.toStringShort()}");
                          if(widget.disableNotifier!=null&&widget.disableNotifier!.value){
                            // widget.controller.onPanEnd();
                            widget.controller.releaseLine();
                            return;
                          }
                          widget.controller.onPanEnd();
                          setState(() {});
                        },
                        onPointerUp: (details){
                          print("onPointerUp${details.toStringShort()}");
                          if(widget.disableNotifier!=null&&widget.disableNotifier!.value){
                            // widget.controller.onPanEnd();
                            widget.controller.releaseLine();
                            return;
                          }
                          widget.controller.onPanEnd();
                          setState(() {});
                        },
                        onPointerMove: (PointerMoveEvent details){
                          print("onPointerMove${details.toStringShort()}");
                          if(widget.disableNotifier!=null&&widget.disableNotifier!.value){
                            // widget.controller.onPanEnd();
                            widget.controller.releaseLine();
                            return;
                          }
                          RenderBox? object = context
                              .findRenderObject() as RenderBox?;
                          Offset? _localPosition = object?.globalToLocal(
                              details.position);
                          if (_localPosition == null) return;
                          print("widget.disableNotifier!.value:::${widget.disableNotifier!.value}");
                          widget.controller.onPanUpdate(_localPosition);
                          setState(() {});
                        },

                        onPointerDown: (details){
                          print("onPointerDown${details.toStringShort()}");
                          if(widget.disableNotifier!=null&&widget.disableNotifier!.value){
                            // widget.controller.onPanEnd();
                            widget.controller.releaseLine();
                            return;
                          }
                          RenderBox? object = context
                              .findRenderObject() as RenderBox?;
                          Offset? _localPosition = object?.globalToLocal(
                              details.position);
                          if (_localPosition == null) return;
                          widget.controller.onPanStart(_localPosition);
                          setState(() {});
                        },
                      )
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
        .map((line) =>
    line.clone()
      ..points = line.points?.map((point) =>
      point == null ? null : Point(point.x * scale, point.y * scale))
          .toList()
      ..width = line.width * scale)
        .toList();
  }

}


