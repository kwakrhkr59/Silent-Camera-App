import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/single_image_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImagesFromCustomFolder();
  }

  Future<void> _loadImagesFromCustomFolder() async {
    final Directory extDir =
        Directory('/storage/emulated/0/DCIM/Camera/MySilentCam');
    if (!await extDir.exists()) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final List<FileSystemEntity> files = extDir.listSync();
    final List<File> images = files
        .where((f) =>
            f is File &&
            (f.path.endsWith('.jpg') ||
                f.path.endsWith('.jpeg') ||
                f.path.endsWith('.png')))
        .map((f) => File(f.path))
        .toList();

    // 이미지 파일을 최신순(내림차순)으로 정렬
    images.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return bStat.modified.compareTo(aStat.modified); // 내림차순으로 비교
    });

    setState(() {
      _images = images;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 갤러리')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('사진이 없습니다.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // 이미지 선택 시 SingleImageView로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SingleImageView(
                              imageFile: _images[index],
                            ),
                          ),
                        );
                      },
                      child: Image.file(_images[index], fit: BoxFit.cover),
                    );
                  },
                ),
    );
  }
}
