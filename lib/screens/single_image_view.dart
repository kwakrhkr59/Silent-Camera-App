import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class SingleImageView extends StatelessWidget {
  final File imageFile;

  const SingleImageView({Key? key, required this.imageFile}) : super(key: key);

  // 밝은 테마로 컬러 팔레트 정의
  static const Color _primaryColor = Color(0xFF3498DB);
  static const Color _secondaryColor = Color(0xFF4A90E2);
  static const Color _backgroundColor = Colors.white;
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _iconColor = Color(0xFF4A90E2);
  static const Color _buttonColor = Color(0xFF3498DB);
  static const Color _errorColor = Color(0xFFE74C3C);

  void _shareImage() {
    Share.shareXFiles([XFile(imageFile.path)], text: '내 사진 공유하기');
  }

  void _deleteImage(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
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
            child: Text('취소'),
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
            child: Text('삭제'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await imageFile.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('사진이 삭제되었습니다'),
              backgroundColor: _secondaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pop(); // 이전 화면으로 돌아감
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: _errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 파일 정보 가져오기
    final fileInfo = imageFile.statSync();
    final fileDate = fileInfo.modified;
    final fileSize = (fileInfo.size / 1024).toStringAsFixed(1) + ' KB';

    // 파일 이름 가져오기
    final fileName = imageFile.path.split('/').last;

    // 이미지 로드 시간 측정을 위한 DateTime
    final startTime = DateTime.now();

    // 상태 표시줄 설정
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.95),
        title: Text(
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
            onPressed: () => _deleteImage(context),
          ),
          SizedBox(width: 8),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black12, // 약간의 배경색상 추가
              child: Hero(
                tag: 'gallery_image_${imageFile.path}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(20.0),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 64,
                              color: _errorColor.withOpacity(0.7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '이미지를 불러올 수 없습니다',
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // 안전 영역 확보
          // SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
