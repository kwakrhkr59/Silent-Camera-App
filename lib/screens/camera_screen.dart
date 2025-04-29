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
  double _currentZoomLevel = 1.0;
  late CameraDescription _currentCamera;
  bool _isRearCamera = true;

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.camera;
    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.high, // 기본 해상도 설정 (비율 조정)
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

  // 카메라 전환 기능
  Future<void> _toggleCamera() async {
    final cameras = await availableCameras();
    CameraDescription newCamera;

    if (_isRearCamera) {
      newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);
    } else {
      newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back);
    }

    setState(() {
      _isRearCamera = !_isRearCamera;
      _currentCamera = newCamera;
      _controller = CameraController(
        _currentCamera,
        ResolutionPreset.high, // 비율 설정
        enableAudio: false,
      );
      _initializeControllerFuture = _controller.initialize();
    });
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
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _toggleCamera, // 카메라 전환
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                GestureDetector(
                  onScaleUpdate: (details) {
                    if (details.scale != 1.0) {
                      // 핀치 제스처로 줌인/아웃 처리
                      setState(() {
                        _currentZoomLevel *= details.scale;
                        if (_currentZoomLevel < 1.0) _currentZoomLevel = 1.0;
                        if (_currentZoomLevel > 10.0) _currentZoomLevel = 10.0;
                        _controller.setZoomLevel(_currentZoomLevel);
                      });
                    }
                  },
                  child: CameraPreview(_controller),
                ),
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Text(
                        'Zoom Level: ${_currentZoomLevel.toStringAsFixed(1)}',
                        style: TextStyle(color: Colors.white),
                      ),
                      Slider(
                        value: _currentZoomLevel,
                        min: 1.0,
                        max: 10.0,
                        divisions: 18,
                        onChanged: (double value) {
                          setState(() {
                            _currentZoomLevel = value;
                            _controller.setZoomLevel(_currentZoomLevel);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _takePictureAndSave,
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
