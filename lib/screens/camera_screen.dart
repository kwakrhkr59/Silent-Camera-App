import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/save_image.dart';
import '../screens/gallery_screen.dart';
import '../main.dart';

enum CameraAspectRatio {
  ratio_1_1,
  ratio_3_4,
  ratio_9_16,
  full,
}

extension CameraAspectRatioExtension on CameraAspectRatio {
  String get displayTitle {
    switch (this) {
      case CameraAspectRatio.ratio_1_1:
        return '1:1';
      case CameraAspectRatio.ratio_3_4:
        return '3:4';
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
    with WidgetsBindingObserver, RouteAware {
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

  // 미리 정의된 줌 레벨 단계
  final List<double> _zoomLevels = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0];
  int _currentZoomIndex = 0;

  // 핀치 줌 관련 변수
  double _baseScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 5.0;

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _currentCamera = widget.camera;
    _initCamera();
    _requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    routeObserver.unsubscribe(this);
    _controller.dispose();
    _zoomDisplayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _initCamera();
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
    _initializeControllerFuture = _controller.initialize().then((_) async {
      try {
        await _controller.setFlashMode(_flashMode);
        // 카메라 초기화 후 최대/최소 줌 레벨 얻기
        _minAvailableZoom = await _controller.getMinZoomLevel();
        _maxAvailableZoom = await _controller.getMaxZoomLevel();
      } catch (e) {
        print("초기 카메라 설정 실패: $e");
      }
      // 현재 줌 레벨 초기화
      _currentZoomLevel = _minAvailableZoom;
      _currentZoomIndex = 0;

      if (mounted) setState(() {});
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
    await Permission.photos.request();
  }

  // 터치로 줌 레벨 변경하는 함수
  void _toggleZoomLevel() {
    _currentZoomIndex = (_currentZoomIndex + 1) % _zoomLevels.length;
    _setZoomLevel(_zoomLevels[_currentZoomIndex]);
  }

  // 줌 레벨 설정 함수
  Future<void> _setZoomLevel(double zoomLevel) async {
    // 최대/최소 범위 내로 조정
    double safeZoom = zoomLevel.clamp(_minAvailableZoom, _maxAvailableZoom);

    try {
      await _controller.setZoomLevel(safeZoom);
      setState(() {
        _currentZoomLevel = safeZoom;
        _displayZoomLevel();
      });
    } catch (e) {
      print('줌 레벨 설정 실패: $e');
    }
  }

  Future<void> _takePictureAndSave() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      await _controller.setFlashMode(_flashMode);

      final XFile picture = await _controller.takePicture();
      final Uint8List bytes = await File(picture.path).readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) throw Exception("이미지 디코딩 실패");

      final previewSize = _controller.value.previewSize;
      img.Image image = originalImage;

      final int width = image.width;
      final int height = image.height;
      img.Image croppedImage = image;

      switch (_currentAspectRatio) {
        case CameraAspectRatio.ratio_1_1:
          final int size = width < height ? width : height;
          croppedImage = img.copyCrop(
            image,
            x: (width - size) ~/ 2,
            y: (height - size) ~/ 2,
            width: size,
            height: size,
          );
          break;

        case CameraAspectRatio.ratio_3_4:
          final targetHeight = (width * 4 / 3).toInt();
          if (targetHeight <= height) {
            croppedImage = img.copyCrop(
              image,
              x: 0,
              y: (height - targetHeight) ~/ 2,
              width: width,
              height: targetHeight,
            );
          }
          break;

        case CameraAspectRatio.ratio_9_16:
          final targetHeight = (width * 16 / 9).toInt();
          if (targetHeight <= height) {
            croppedImage = img.copyCrop(
              image,
              x: 0,
              y: (height - targetHeight) ~/ 2,
              width: width,
              height: targetHeight,
            );
          }
          break;

        case CameraAspectRatio.full:
          break;
      }

      final Uint8List croppedBytes =
          Uint8List.fromList(img.encodeJpg(croppedImage));
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result =
          await ImageSaver.saveImageToGallery(croppedBytes, fileName);

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
    });

    try {
      // 기존 컨트롤러 safely dispose
      if (_controller.value.isInitialized) {
        await _controller.dispose();
      }

      _currentCamera = newCamera;
      _controller = CameraController(
        _currentCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller.initialize().then((_) async {
        try {
          await _controller.setFlashMode(_flashMode);
          _minAvailableZoom = await _controller.getMinZoomLevel();
          _maxAvailableZoom = await _controller.getMaxZoomLevel();

          // 줌 레벨 초기화
          _currentZoomLevel = _minAvailableZoom;
          _currentZoomIndex = 0;
        } catch (e) {
          print("카메라 전환 후 설정 실패: $e");
        }
        if (mounted) setState(() {});
      });
    } catch (e) {
      print("카메라 전환 실패: $e");
    }
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
                  min: _minAvailableZoom,
                  max: _maxAvailableZoom,
                  divisions: 8,
                  onChanged: (double value) {
                    _setZoomLevel(value);
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
      if (mounted) {
        setState(() {
          _zoomDisplay = null;
        });
      }
    });
  }

  Widget _buildAspectRatioMask(Size screenSize) {
    double previewHeight;
    switch (_currentAspectRatio) {
      case CameraAspectRatio.ratio_1_1:
        previewHeight = screenSize.width; // 정사각형
        break;
      case CameraAspectRatio.ratio_3_4:
        previewHeight = screenSize.width * 4 / 3;
        break;
      case CameraAspectRatio.ratio_9_16:
        previewHeight = screenSize.width * 16 / 9;
        break;
      case CameraAspectRatio.full:
      default:
        return SizedBox.shrink(); // full일 땐 마스크 없음
    }

    double topMaskHeight = (screenSize.height - previewHeight) / 2;
    return Column(
      children: [
        Container(height: topMaskHeight, color: Colors.black.withOpacity(0.5)),
        Expanded(child: Container(color: Colors.transparent)),
        Container(height: topMaskHeight, color: Colors.black.withOpacity(0.5)),
      ],
    );
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
        aspectRatioValue = _controller.value.isInitialized &&
                _controller.value.previewSize != null
            ? _controller.value.previewSize!.height /
                _controller.value.previewSize!.width
            : screenSize.width / screenSize.height;
        // aspectRatioValue = screenSize.width / screenSize.height;
        break;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 플래시 버튼
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off
                  ? Icons.flash_off_rounded
                  : _flashMode == FlashMode.auto
                      ? Icons.flash_auto_rounded
                      : Icons.flash_on_rounded,
              color: _iconColor,
            ),
            onPressed: _controller.description.lensDirection ==
                    CameraLensDirection.front
                ? null // 전면 카메라는 비활성화
                : () async {
                    setState(() {
                      _flashMode = _flashMode == FlashMode.off
                          ? FlashMode.auto
                          : _flashMode == FlashMode.auto
                              ? FlashMode.always
                              : FlashMode.off;
                    });

                    try {
                      await _controller.setFlashMode(_flashMode);
                    } catch (e) {
                      print("플래시 설정 실패: $e");
                    }
                  },
          ),

          // 카메라 비율 순환 버튼
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            // decoration: BoxDecoration(
            //   color: Colors.black45,
            //   borderRadius: BorderRadius.circular(12),
            // ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentAspectRatio.displayTitle,
                  style: TextStyle(
                    color: _iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.aspect_ratio_rounded, color: _iconColor),
                  onPressed: () {
                    setState(() {
                      // 비율 리스트와 현재 인덱스
                      final allRatios = CameraAspectRatio.values;
                      final currentIndex =
                          allRatios.indexOf(_currentAspectRatio);
                      final nextIndex = (currentIndex + 1) % allRatios.length;
                      _currentAspectRatio = allRatios[nextIndex];
                    });

                    // 화면에 비율 변경 정보 표시
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "비율이 ${_currentAspectRatio.displayTitle}로 변경되었습니다"),
                        backgroundColor: _accentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.all(20.0),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
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
                // 카메라 프리뷰에 제스처 감지 추가
                GestureDetector(
                  // onTap: () {
                  //   // 화면 탭했을 때 줌 레벨 토글
                  //   _toggleZoomLevel();
                  // },
                  // onDoubleTap: () {
                  //   // 더블 탭시 줌 초기화
                  //   _setZoomLevel(_minAvailableZoom);
                  //   _currentZoomIndex = 0;
                  // },
                  // 핀치 줌 구현
                  onScaleStart: (ScaleStartDetails details) {
                    _baseScale = _currentZoomLevel;
                  },
                  onScaleUpdate: (ScaleUpdateDetails details) {
                    // 핀치 줌 처리
                    if (details.scale != 1.0) {
                      double newZoom = (_baseScale * details.scale)
                          .clamp(_minAvailableZoom, _maxAvailableZoom);
                      _setZoomLevel(newZoom);
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: aspectRatioValue,
                    // aspectRatio: _controller.value.previewSize!.height /
                    //     _controller.value.previewSize!.width,
                    child: CameraPreview(_controller),
                  ),
                ),

                // 촬영 영역 외 마스크 추가
                _buildAspectRatioMask(screenSize),

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
