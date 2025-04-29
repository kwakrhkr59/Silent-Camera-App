import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/save_image.dart';
import '../screens/gallery_screen.dart';

enum CameraAspectRatio {
  ratio_1_1,
  ratio_9_16,
  full,
}

extension CameraAspectRatioExtension on CameraAspectRatio {
  String get displayTitle {
    switch (this) {
      case CameraAspectRatio.ratio_1_1:
        return '1:1';
      case CameraAspectRatio.ratio_9_16:
        return '9:16';
      case CameraAspectRatio.full:
        return 'Full';
    }
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  double _currentZoomLevel = 1.0;
  late CameraDescription _currentCamera;
  bool _isRearCamera = true;
  bool _isCapturing = false;
  String? _zoomDisplay;
  Timer? _zoomDisplayTimer;
  FlashMode _flashMode = FlashMode.off;
  CameraAspectRatio _currentAspectRatio = CameraAspectRatio.full;

  // 컬러 팔레트 정의
  final Color _primaryColor = Color(0xFF2C3E50);
  final Color _accentColor = Color(0xFF3498DB);
  final Color _backgroundColor = Colors.black;
  final Color _iconColor = Colors.white;
  final Color _captureButtonColor = Colors.white;
  final Color _sliderColor = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentCamera = widget.camera;
    _initCamera();
    _requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _zoomDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  void _initCamera() {
    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    await Permission.photos.request();
  }

  Future<void> _takePictureAndSave() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;

      await _controller.setFlashMode(_flashMode); // 현재 플래시 모드 적용

      final XFile picture = await _controller.takePicture();
      final Uint8List bytes = await File(picture.path).readAsBytes();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await ImageSaver.saveImageToGallery(bytes, fileName);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("사진이 저장되었습니다"),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(20.0),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("저장에 실패했습니다"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(20.0),
          ),
        );
      }
    } catch (e) {
      print("촬영 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("촬영 중 오류가 발생했습니다"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20.0),
        ),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

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
    });

    await _controller.dispose();
    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  Widget _buildZoomControl() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.18,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove, color: _iconColor),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  activeTrackColor: _sliderColor,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _currentZoomLevel,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  onChanged: (double value) {
                    setState(() {
                      _currentZoomLevel = value;
                      _controller.setZoomLevel(_currentZoomLevel);
                      _displayZoomLevel();
                    });
                  },
                ),
              ),
            ),
            Icon(Icons.add, color: _iconColor),
          ],
        ),
      ),
    );
  }

  void _displayZoomLevel() {
    setState(() {
      _zoomDisplay = '${_currentZoomLevel.toStringAsFixed(1)}x';
    });

    _zoomDisplayTimer?.cancel();
    _zoomDisplayTimer = Timer(Duration(seconds: 2), () {
      setState(() {
        _zoomDisplay = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double aspectRatioValue;
    switch (_currentAspectRatio) {
      case CameraAspectRatio.ratio_1_1:
        aspectRatioValue = 1 / 1;
        break;
      case CameraAspectRatio.ratio_9_16:
        aspectRatioValue = 9 / 16;
        break;
      case CameraAspectRatio.full:
      default:
        aspectRatioValue = screenSize.width / screenSize.height;
        break;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '무음 카메라',
          style: TextStyle(
            color: _iconColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 플래시 버튼
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off
                  ? Icons.flash_off_rounded
                  : Icons.flash_on_rounded,
              color: _iconColor,
            ),
            onPressed: () {
              setState(() {
                _flashMode = _flashMode == FlashMode.off
                    ? FlashMode.auto
                    : FlashMode.off;
              });
            },
          ),
          // 카메라 비율 전환 버튼
          PopupMenuButton<CameraAspectRatio>(
            icon: Icon(Icons.aspect_ratio_rounded, color: _iconColor),
            onSelected: (CameraAspectRatio ratio) {
              setState(() {
                _currentAspectRatio = ratio;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<CameraAspectRatio>>[
              const PopupMenuItem<CameraAspectRatio>(
                value: CameraAspectRatio.ratio_1_1,
                child: Text('1:1'),
              ),
              const PopupMenuItem<CameraAspectRatio>(
                value: CameraAspectRatio.ratio_9_16,
                child: Text('9:16'),
              ),
              const PopupMenuItem<CameraAspectRatio>(
                value: CameraAspectRatio.full,
                child: Text('Full'),
              ),
            ],
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 카메라 미리보기 (화면 비율 조정)
                AspectRatio(
                  aspectRatio: aspectRatioValue,
                  child: GestureDetector(
                    onScaleUpdate: (details) {
                      if (details.scale != 1.0) {
                        final newZoomLevel = _currentZoomLevel * details.scale;
                        setState(() {
                          _currentZoomLevel = newZoomLevel.clamp(1.0, 5.0);
                          _controller.setZoomLevel(_currentZoomLevel);
                          _displayZoomLevel();
                        });
                      }
                    },
                    child: CameraPreview(_controller),
                  ),
                ),

                // 줌 배율 표시 (일시적)
                if (_zoomDisplay != null)
                  Positioned(
                    top: screenSize.height * 0.15,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _zoomDisplay!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 줌 컨트롤
                _buildZoomControl(),

                // 하단 컨트롤 패널
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                        bottom: 40, top: 30, left: 24, right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 갤러리 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GalleryScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: _iconColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),

                        // 촬영 버튼
                        GestureDetector(
                          onTap: _isCapturing ? null : _takePictureAndSave,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _captureButtonColor,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: _isCapturing
                                      ? Colors.grey
                                      : _captureButtonColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: _isCapturing
                                    ? Center(
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    _accentColor),
                                          ),
                                        ),
                                      )
                                    : Container(),
                              ),
                            ),
                          ),
                        ),

                        // 카메라 전환 버튼
                        GestureDetector(
                          onTap: _toggleCamera,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.flip_camera_ios_rounded,
                                color: _iconColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              color: _backgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
