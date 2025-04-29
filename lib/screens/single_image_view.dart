import 'dart:io';
import 'package:flutter/material.dart';

class SingleImageView extends StatelessWidget {
  final File imageFile;

  const SingleImageView({Key? key, required this.imageFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 보기'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(imageFile, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
