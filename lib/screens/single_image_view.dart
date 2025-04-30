import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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
            icon: Icon(Icons.share_rounded, color: _iconColor),
            tooltip: '공유하기',
            onPressed: _shareImage,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: _errorColor),
            tooltip: '삭제하기',
            onPressed: _deleteImage,
          ),
          const SizedBox(width: 8),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Expanded(
        // PageView.builder를 Expanded로 감싸줍니다.
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.imageFiles.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imageFile = widget.imageFiles[index];
            return Center(
              child: Hero(
                tag: 'gallery_image_${imageFile.path}',
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
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
