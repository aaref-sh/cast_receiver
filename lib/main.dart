import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:typed_data';

import 'package:signalr_client/signalr_client.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

final serverurl = "http://192.168.1.111:5000/CastHub";
HubConnection hubConnection;

class _MyHomePageState extends State<MyHomePage> {
  ui.Image image;
  bool isImageloaded = false;
  void initState() {
    super.initState();
    initSignalR();
    // init();
  }

  Future<Null> init() async {
    final ByteData data = await rootBundle.load('images/lake.jpg');
    image = await loadImage(new Uint8List.view(data.buffer));
  }

  initSignalR() async {
    hubConnection = HubConnectionBuilder().withUrl(serverurl).build();
    hubConnection.onclose((e) => print('connection closed because of: $e'));
    //connect();
    images = [<Image>[]];
    ss = [<void Function(void Function())>[]];
    for (int i = 0; i < 10; i++) {
      images.add(<Image>[]);
      ss.add(<void Function(void Function())>[]);
      for (int j = 0; j < 10; j++) {
        images[i].add(null);
        ss[i].add(null);
      }
    }
    hubConnection.on("UpdateScreen", _updateScreen);
    try {
      await hubConnection.start();
    } catch (_) {}
    await hubConnection.invoke("AddToGroup", args: <Object>["main"]);
    await hubConnection.invoke("getscreen");
  }

  bool encrypted = false;
  _updateScreen(List<Object> args) async {
    String base64 = args[0];

    int r = args[1];
    int c = args[2];

    encrypted = args[3];
    images[r][c] = Image.memory(base64Decode(decoded(base64)));

    ss[c][r](() {});
  }

  String pass = "main";
  String decoded(String s) {
    if (!encrypted) return s;
    var output = [];
    for (var i = 0; i < s.length; i++) {
      var charCode = s.codeUnitAt(i) ^ pass[i % pass.length].codeUnitAt(0);
      output.add(new String.fromCharCode(charCode));
    }

    return output.join("");
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      setState(() {
        isImageloaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }

  List<List<void Function(void Function())>> ss = [
    <void Function(void Function())>[]
  ];
  Widget _buildImage() {
    if (images[9][9] != null) {
      return Container(
          child: Row(children: [
        for (int i = 0; i < 10; i++)
          Column(children: [
            for (int j = 0; j < 10; j++)
              StatefulBuilder(builder: (_context, _setState) {
                ss[i][j] = _setState;
                // put widges here that you want to update using _setState
                return Container(
                    height: MediaQuery.of(context).size.height / 10,
                    constraints: BoxConstraints(
                        maxWidth:
                            (MediaQuery.of(context).size.width - 100) / 10),
                    child: images[j][i]);
              })
          ])
      ]));
    }
    return Center(child: Text('loading'));
  }

  List<List<Image>> images;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildImage(),
    );
  }
}

class ImageEditor extends CustomPainter {
  ImageEditor({this.images});

  List<ui.Image> images;

  @override
  void paint(Canvas canvas, Size size) {
    // ByteData data = image.toByteData();
    for (int i = 0; i < 100; i++)
      canvas.drawImage(
          images[i], Offset(i / 10.toDouble(), i % 10.toDouble()), Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
