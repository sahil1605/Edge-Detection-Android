import 'dart:io';

import 'package:path/path.dart';

import 'package:edge_detecter/image_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:starflut/starflut.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase/firebase.dart';
// import 'storage_service.dart';
import 'package:opencv/opencv.dart';
import 'package:opencv/core/core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(
          title: 'Image Selector', check: false, url: '', f1: 0, f2: 0),
      // ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key? key,
      required this.title,
      required this.url,
      required bool this.check,
      required this.f1,
      required this.f2})
      : super(key: key);
  final String url;
  final bool check;
  final String title;
  final double f1;
  final double f2;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
// widget.check ?image = Image.network(url):null;0
  final imagePicker = ImagePicker();

  double _value1 = 200;

  double _value2 = 200;
  dynamic res;
  Image imageNew = Image.asset('assets/temp.png');
  late File file;
  bool preloaded = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
  }

  Future pickCamera() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return;
      final imageTemp = File(image.path);

      setState(() {
        this.image = this.image = imageTemp;
        preloaded = true;
      });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> runAFunction(
      {bool check = true,
      String path = '',
      double f1 = 50,
      double f2 = 200}) async {
    try {
      if (check) {
        File file1;
        file1 = await DefaultCacheManager().getSingleFile(path);

        res = await ImgProc.canny(await file1.readAsBytes(), f1, f2);
      } else {
        res = await ImgProc.canny(await (image as File).readAsBytes(), f1, f2);
      }

      setState(() {
        imageNew = Image.memory(res);
        loaded = true;
      });
      // ignore: empty_catches
    } on PlatformException {}
  }

  final storage = FirebaseStorage.instance;

  Future<void> uploadFile(String filePath, String fileName) async {
    File file = File(filePath);

    try {
      await storage.ref('test/$fileName').putFile(file);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print(e.message);
    }
  }

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);

      setState(() {
        this.image = this.image = imageTemp;
        preloaded = true;
      });
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  String imageUrl = '';
  uploadImage() async {
    final firebaseStorage = FirebaseStorage.instance;

    var file = File(image!.path);

    String fileName = file.path.split('/').last;
    if (image != null) {
      final newMetadata = SettableMetadata(
        cacheControl: "public,max-age=300",
        contentType: "image/jpeg",
        customMetadata: {'f1': _value1.toString(), 'f2': _value2.toString()},
      );
      var snapshot = firebaseStorage
          .ref()
          .child('images/$fileName')
          .putFile(file, newMetadata)
          .snapshot;

// Update metadata properties
      final metadata = await firebaseStorage
          .ref()
          .child('images/$fileName')
          .updateMetadata(newMetadata);

      var downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        imageUrl = downloadUrl;
      });
    } else {
      // ignore: avoid_print
      print('No Image Path Received');
    }
  }

  bool ticker = true;
  void checker(bool check, double f1, double f2) {
    if (ticker) {
      if (check) {
        _value1 = f1;
        _value2 = f2;
      }
      ticker = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final Storage storage = Storage();
    checker(widget.check, widget.f1, widget.f2);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.get_app,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => imageList()),
              );
              // do something
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              (preloaded | widget.check)
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            MaterialButton(
                              color: Colors.blue,
                              child: const Text("Use Edge Detection",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () {
                                runAFunction(
                                    check: widget.check,
                                    path: widget.url,
                                    f1: _value1,
                                    f2: _value2);
                              },
                            ),
                            (loaded)
                                ? MaterialButton(
                                    color: Colors.blue,
                                    child: Text(
                                        widget.check
                                            ? 'Change Threshold'
                                            : "Upload Image",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      uploadImage();
                                    },
                                  )
                                : Container(),
                          ],
                        ),
                        Row(
                          children: [
                            Slider(
                              min: 0,
                              max: 511,
                              divisions: 511,
                              label: '${_value1.round()}',
                              value: _value1,
                              onChanged: (value) {
                                setState(() {
                                  _value1 = value;
                                });
                              },
                            ),
                            Slider(
                              label: '${_value2.round()}',
                              min: 0,
                              max: 511,
                              divisions: 511,
                              value: _value2,
                              onChanged: (value) {
                                setState(() {
                                  _value2 = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(),
              SizedBox(
                width: 400,
                height: 300,
                child: widget.check
                    ? Image.network(widget.url)
                    : image != null
                        ? Image.file(image!)
                        : const Text("No image Selected"),
              ),
              SizedBox(
                  width: 300,
                  height: 300,
                  child: loaded ? imageNew : Container()),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            onPressed: () {
              pickImage();
            },
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
              onPressed: pickCamera, child: const Icon(Icons.camera)),
        ],
      ),
    );
  }
}
