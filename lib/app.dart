import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/camera_screen.dart';

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({required this.camera, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '무음 카메라',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(camera: camera), // 스플래시 먼저 보여줌
    );
  }
}

class SplashScreen extends StatefulWidget {
  final CameraDescription camera;
  const SplashScreen({required this.camera, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 2초 뒤 CameraScreen으로 이동
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(camera: widget.camera),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Image.asset('assets/splash/full_splash.png'),
        ),
      ),
    );
  }
}
