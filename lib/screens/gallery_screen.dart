import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/single_image_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _images = [];
  bool _loading = true;

  // 밝은 컬러 팔레트 정의
  final Color _primaryColor = Color(0xFF3498DB); // 더 밝은 파란색
  final Color _accentColor = Color(0xFF4A90E2); // 보조 색상
  final Color _backgroundColor = Colors.white;
  final Color _iconColor = Color(0xFF4A90E2);
  final Color _textColor = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    // 시스템 UI 설정
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
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

  // 날짜별 섹션 헤더 생성 함수
  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final fileDate = DateTime(date.year, date.month, date.day);

    if (fileDate == today) {
      return '오늘';
    } else if (fileDate == yesterday) {
      return '어제';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  // 빈 갤러리를 위한 위젯
  Widget _buildEmptyGallery() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 60,
                color: _accentColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '사진이 없습니다',
              style: TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '카메라로 돌아가서 첫 사진을 찍어보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.camera_alt_rounded),
              label: Text('카메라로 돌아가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로딩 인디케이터 위젯
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            '갤러리 불러오는 중...',
            style: TextStyle(
              color: _textColor.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _backgroundColor,
        title: Text(
          '내 갤러리',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _loading
          ? _buildLoadingIndicator()
          : _images.isEmpty
              ? _buildEmptyGallery()
              : RefreshIndicator(
                  onRefresh: _loadImagesFromCustomFolder,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 80),
                    physics:
                        const AlwaysScrollableScrollPhysics(), // 스크롤이 없을 때도 새로고침 가능
                    itemCount: _images.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SingleImageView(
                                imageFiles: _images,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'gallery_image_${_images[index].path}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _images[index],
                                fit: BoxFit.cover,
                                cacheHeight: 300,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        color: _accentColor,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

      // 하단 정보 표시줄
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, -1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_rounded,
              color: _accentColor,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              '총 ${_images.length}장의 사진',
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
