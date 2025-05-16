import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class SingleImageView extends StatefulWidget {
  final List<File> imageFiles;
  final int initialIndex;

  const SingleImageView({
    Key? key,
    required this.imageFiles,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<SingleImageView> createState() => _SingleImageViewState();
}

class _SingleImageViewState extends State<SingleImageView> {
  late PageController _pageController;
  late int _currentIndex;
  double _rotationAngle = 0;

  static const Color _primaryColor = Color(0xFF3498DB);
  static const Color _secondaryColor = Color(0xFF4A90E2);
  static const Color _backgroundColor = Colors.white;
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _iconColor = Color(0xFF4A90E2);
  static const Color _buttonColor = Color(0xFF3498DB);
  static const Color _errorColor = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareImage() {
    Share.shareXFiles([XFile(widget.imageFiles[_currentIndex].path)],
        text: '내 사진 공유하기');
  }

  void _rotateImage() {
    setState(() {
      _rotationAngle += math.pi / 2; // 90도 회전
    });
  }

  void _showImageInfo() {
    final file = widget.imageFiles[_currentIndex];
    final fileStat = file.statSync();
    final fileSize = _formatFileSize(fileStat.size);
    final fileName = path.basename(file.path);
    final lastModified =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(fileStat.modified);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '이미지 정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 20),
            _infoRow('파일명', fileName),
            _infoRow('크기', fileSize),
            _infoRow('수정일', lastModified),
            _infoRow('경로', file.path),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _textColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int size) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double formattedSize = size.toDouble();

    while (formattedSize > 1024 && i < suffixes.length - 1) {
      formattedSize /= 1024;
      i++;
    }

    return '${formattedSize.toStringAsFixed(2)} ${suffixes[i]}';
  }

  void _deleteImage() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '삭제 확인',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '이 사진을 삭제할까요?',
          style: TextStyle(
            color: _textColor.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('삭제'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final file = widget.imageFiles[_currentIndex];
        await file.delete();
        setState(() {
          widget.imageFiles.removeAt(_currentIndex);
          if (_currentIndex >= widget.imageFiles.length && _currentIndex > 0) {
            _currentIndex--;
          }
        });
        if (widget.imageFiles.isEmpty) {
          Navigator.of(context).pop();
        } else {
          _pageController.jumpToPage(_currentIndex);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('사진이 삭제되었습니다'),
            backgroundColor: _secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionItem(
                icon: Icons.info_outline,
                label: '이미지 정보',
                color: _iconColor,
                onTap: () {
                  Navigator.pop(context);
                  _showImageInfo();
                },
              ),
              _buildOptionItem(
                icon: Icons.share_rounded,
                label: '공유하기',
                color: _iconColor,
                onTap: () {
                  Navigator.pop(context);
                  _shareImage();
                },
              ),
              _buildOptionItem(
                icon: Icons.delete_outline_rounded,
                label: '삭제하기',
                color: _errorColor,
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 32),
            Text(
              label,
              style: const TextStyle(
                color: _textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.95),
        title: const Text(
          '이미지 보기',
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
        actions: [
          IconButton(
            icon: Icon(Icons.rotate_right, color: _iconColor),
            tooltip: '회전하기',
            onPressed: _rotateImage,
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: _iconColor),
            tooltip: '더보기',
            onPressed: _showMoreOptions,
          ),
          const SizedBox(width: 8),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageFiles.length,
          padEnds: false,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              _rotationAngle = 0; // 페이지가 변경될 때 회전 각도 초기화
            });
          },
          itemBuilder: (context, index) {
            final imageFile = widget.imageFiles[index];
            return Hero(
              tag: 'gallery_image_${imageFile.path}',
              child: Transform.rotate(
                angle: _rotationAngle,
                child: PhotoView(
                  imageProvider: FileImage(imageFile),
                  minScale: PhotoViewComputedScale.contained * 1.0,
                  maxScale: PhotoViewComputedScale.covered * 5.0,
                  gestureDetectorBehavior: HitTestBehavior.translucent,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 64,
                          color: _errorColor.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
