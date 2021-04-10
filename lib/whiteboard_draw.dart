import 'package:flutter/material.dart';

part 'whiteboard_draw.g.dart';

class WhiteboardDraw {
  final String? id;
  final List<Line>? lines;
  final double width;
  final double height;

  WhiteboardDraw({this.id, this.lines, this.width=0, this.height=0});

  factory WhiteboardDraw.fromJson(Map<String, dynamic> json) =>
      _$DrawFromJson(json);

  Map<String, dynamic> toJson() => _$DrawToJson(this);

  WhiteboardDraw clone() {
    return new WhiteboardDraw(
        id: id,
        lines: lines?.map((line) => line.clone()).toList(),
        width: width,
        height: height);
  }

  WhiteboardDraw copyWith(
      {String? id, List<Line>? lines, double? width, double? height}) {
    return WhiteboardDraw(
      id: id ?? this.id,
      lines: lines ?? this.lines?.map((line) => line.clone()).toList(),
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Duration get drawingDuration {
    var duration = new Duration();

    if (lines != null)
      lines?.forEach((line) {
        duration += Duration(milliseconds: line.duration);
      });
    return duration;
  }
}

class Line {
//  @JsonKey(fromJson: _offsetsFromList, toJson: _offsetsToList)
//  List<Offset> points;

  List<Point?>? points;

  Color color;

  double width;
  int duration;

  bool wipe;
  bool erase;

  Line(
      {this.points,
      this.color = Colors.blue,
      this.width = 10.0,
      this.wipe = false,
      this.erase = false,
      this.duration = 0});

  factory Line.fromJson(Map<String, dynamic> json) => _$LineFromJson(json);

  Map<String, dynamic> toJson() => _$LineToJson(this);

  Line clone() {
    return new Line(
        points: points?.map((point) =>  point==null?null:Point(point.x, point.y)).toList(),
        color: color,
        width: width,
        wipe: wipe,
        erase: this.erase,
        duration: duration);
  }

  Line copyWith(
      {List<Point>? points,
      Color? color,
      double? width,
      bool? wipe,
      int? duration}) {
    return Line(
      points: points ?? this.points?.map((p) =>  p==null?null:Point(p.x, p.y)).toList(),
      color: color ?? this.color,
      width: width ?? this.width,
      wipe: wipe ?? this.wipe,
      erase: this.erase,
      duration: duration ?? this.duration,
    );
  }
}

List<Offset> _offsetsFromList(List<List<double>> points) =>
    points.map((point) => new Offset(point[0], point[1])).toList();

List<List<double>> _offsetsToList(List<Offset> points) =>
    points.map((point) => <double>[point.dx, point.dy]).toList();

Color _colorFromString(String colorStr) {
  var color = new Color(int.parse(colorStr));
  return color;
} //Colors.blue;

String _colorToString(Color color) {
  var string = color.value.toString();
  return string;
}

//Color _colorFromString(String color) => new HexColor(color);
//
//String _colorToString(Color color) => color.value.toString();

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
  Map<String, dynamic> toJson() => _$PointToJson(this);

  factory Point.fromOffset(Offset offset) => new Point(offset.dx, offset.dy);
  Offset toOffset() => Offset(x, y);
}
