import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

void main() => runApp(MyApp());

/// example widget showing how to use signature widget
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GestureWhiteboardController _controller = GestureWhiteboardController();

  @override
  void initState() {
    _controller.brushSize = (5);
    _controller.eraserSize = (25);
    _controller.brushColor = Color(0XFFFF6666);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: ListView(
            children: <Widget>[
              Container(
                height: 300,
                child: const Center(
                  child: Text('Big container to test scrolling issues'),
                ),
              ),
              //SIGNATURE CANVAS
              Signature(
                controller: _controller,
                height: 300,
              ),
              //OK AND CLEAR BUTTONS
              Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    //SHOW EXPORTED IMAGE IN NEW ROUTE
                    IconButton(
                      icon: const Icon(Icons.check),
                      color: Colors.blue,
                      onPressed: () async {
                        if (_controller.isNotEmpty) {
                          final Uint8List? data = await _controller.toPngBytes();
                          if (data != null) {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) {
                                  return Scaffold(
                                    appBar: AppBar(),
                                    body: Center(
                                      child: Container(
                                        color: Colors.grey[300],
                                        child: Image.memory(data),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        }
                      },
                    ),
                    //CLEAR CANVAS
                    IconButton(
                      icon: const Icon(Icons.clear),
                      color: Colors.blue,
                      onPressed: () {
                        setState(() => _controller.turnOnOffErase());
                      },
                    ),
                  ],
                ),
              ),
              Container(
                height: 300,
                child: const Center(
                  child: Text('Big container to test scrolling issues'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
