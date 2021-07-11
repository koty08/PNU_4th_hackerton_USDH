import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:login_test/firebase_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

late WriteBoardState pageState;

class WriteBoard extends StatefulWidget {
  @override
  WriteBoardState createState() {
    pageState = WriteBoardState();
    return pageState;
  }
}

class WriteBoardState extends State<WriteBoard> {
  late File img;
  late FirebaseProvider fp;
  TextEditingController member = TextEditingController();
  TextEditingController input = TextEditingController();
  String imageurl = "";
  final _picker = ImagePicker();
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore fs = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);
    fp.setInfo();

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text("게시판 글쓰기")),
        body: Center(
          child: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 50),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: member,
                          decoration: InputDecoration(hintText: "제한 인원"),
                        ),
                      ],
                    )),
                Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 50),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: input,
                          decoration: InputDecoration(hintText: "내용을 입력하세요."),
                        ),
                      ],
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                        child: Text("카메라로 촬영하기"),
                        onPressed: () {
                          uploadImage(ImageSource.camera);
                        }),
                    ElevatedButton(
                        child: Text("갤러리에서 불러오기"),
                        onPressed: () {
                          uploadImage(ImageSource.gallery);
                        }),
                  ],
                ),
                Divider(
                  color: Colors.black,
                ),
                Container(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text("test"),
                        ],
                      ),
                      SizedBox(
                        height: 250,
                        width: 250,
                        child: Image.network(imageurl),
                      ),
                    ],
                  ),
                ),
                Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueAccent[200],
                      ),
                      child: Text(
                        "게시글 쓰기",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        FocusScope.of(context).requestFocus(new FocusNode());
                        uploadOnFS(member.text, input.text);
                        Navigator.pop(context);
                      },
                    ))
              ],
            ),
          ),
        ));
  }

  void uploadImage(ImageSource src) async {
    PickedFile? pickimg = await _picker.getImage(source: src);

    if (pickimg == null) return;
    setState(() {
      img = File(pickimg.path);
    });

    Reference ref = storage.ref().child('board/${fp.getUser()!.uid}');
    await ref.putFile(img);

    String URL = await ref.getDownloadURL();

    setState(() {
      imageurl = URL;
    });
  }

  void uploadOnFS(String member, String txt) async {
    var tmp = fp.getInfo();
    await fs
        .collection('posts')
        .doc(tmp['name'] + tmp['postcount'].toString())
        .set({
      'writer': tmp['name'],
      'contents': txt,
      'current member': '1',
      'limited member': member,
      'pic': imageurl
    });
    fp.updateIntInfo('postcount', 1);
  }
}
