import 'package:edge_detecter/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'firebase/firebase.dart';

class imageList extends StatefulWidget {
  @override
  State<imageList> createState() => _imageListState();
}

class _imageListState extends State<imageList> {
  final Future<ListResult> result =
      FirebaseStorage.instance.ref().child('images').listAll();

  void getFirebaseImageFolder() {
    final Reference storageRef = FirebaseStorage.instance.ref().child('images');
    storageRef.listAll().then((result) {
      print("result is $result");
    });
  }

  Future<List<Map<String, dynamic>>> _loadImages() async {
    List<Map<String, dynamic>> files = [];
    FirebaseStorage storage = FirebaseStorage.instance;
    final ListResult result = await storage.ref().child('images').list();
    final List<Reference> allFiles = result.items;

    await Future.forEach<Reference>(allFiles, (file) async {
      final String fileUrl = await file.getDownloadURL();

      final FullMetadata fileMeta = await file.getMetadata();
      files.add({
        "url": fileUrl,
        "f1": double.parse(fileMeta.customMetadata?['f1'].toString() ?? "0"),
        "f2": double.parse(fileMeta.customMetadata?['f2'].toString() ?? "0"),
        "fileName": fileMeta.customMetadata?['fileName'].toString() ?? "",
      });
    });

    return files;
  }

  Future<void> _delete(String ref) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    await storage.ref(ref).delete();
    // Rebuild the UI
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getFirebaseImageFolder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Images in Server"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.camera,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyHomePage(
                          title: 'Image Selector',
                          check: false,
                          url: '',
                          f1: 0,
                          f2: 0,
                          fileName: '')),
                );
                // do something
              },
            )
          ],
        ),
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder(
                    future: _loadImages(),
                    builder: (context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return ListView.builder(
                          itemCount: snapshot.data?.length ?? 0,
                          itemBuilder: (context, index) {
                            final Map<String, dynamic> image =
                                snapshot.data![index];

                            return InkWell(
                              onTap: () {
                                print(image['url']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyHomePage(
                                          title: 'Image Editor',
                                          check: true,
                                          url: image['url'],
                                          f1: image['f1'],
                                          f2: image['f2'],
                                          fileName: image['fileName'])),
                                );
                              },
                              child: SizedBox(
                                // dense: false,
                                height: 200, width: 200,
                                child: Image.network(image['url']),
                              ),
                            );
                          },
                        );
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }),
              ),
            ],
          ),
        ));
  }
}
