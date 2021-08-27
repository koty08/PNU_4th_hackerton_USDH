import 'package:flutter/material.dart';
import '../const.dart';
import 'package:photo_view/photo_view.dart';

// photo widget 관리
class FullPhoto extends StatelessWidget {
  final String url;

  FullPhoto({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '사진',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        elevation: 0.0,
        backgroundColor: Color(0xFFB4C56C).withOpacity(0.0),
        centerTitle: true,
      ),
      body: FullPhotoScreen(url: url),
    );
  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;

  FullPhotoScreen({Key? key, required this.url}) : super(key: key);

  @override
  State createState() => FullPhotoScreenState(url: url);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;

  FullPhotoScreenState({Key? key, required this.url});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: PhotoView(imageProvider: NetworkImage(url)));
  }
}
