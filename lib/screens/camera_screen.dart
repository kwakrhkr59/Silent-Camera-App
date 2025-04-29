import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/save_image.dart';
import '../screens/gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    await Permission.photos.request();
  }

  Future<void> _takePictureAndSave() async {
    try {
      await _initializeControllerFuture;
      final XFile picture = await _controller.takePicture();

      final Uint8List bytes = await File(picture.path).readAsBytes();

      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await ImageSaver.saveImageToGallery(bytes, fileName);

      if (result != null) {
        print("Saved to MediaStore: $result");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("사진이 $result 에 저장되었습니다.")),
        );
      } else {
        print("저장 실패");
      }
    } catch (e) {
      print("촬영 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('무음 카메라'),
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GalleryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePictureAndSave,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
