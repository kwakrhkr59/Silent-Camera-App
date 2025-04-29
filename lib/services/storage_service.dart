import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> saveImageToGallery(Uint8List bytes,
    {String folderName = 'MySilentCam'}) async {
  // Android 10 이상 기준으로 저장소 권한 요청 (Android 13+도 대응)
  final Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    Permission.photos, // Android 13+
  ].request();

  if (statuses[Permission.storage]?.isDenied == true) {
    throw Exception('저장소 권한이 거부되었습니다.');
  }

  try {
    // getExternalStorageDirectory() → /storage/emulated/0/Android/data/패키지명/files
    Directory? directory = await getExternalStorageDirectory();

    if (directory == null) {
      throw Exception('저장소 디렉토리를 찾을 수 없습니다.');
    }

    // 경로 재설정: Android/data/... → /storage/emulated/0/Pictures/folderName
    String basePath = "";
    List<String> paths = directory.path.split("/");
    for (int i = 1; i < paths.length; i++) {
      if (paths[i] == "Android") break;
      basePath += "/${paths[i]}";
    }
    final savePath = "$basePath/Pictures/$folderName";
    final saveDir = Directory(savePath);

    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '$savePath/$fileName';

    final file = await File(filePath).writeAsBytes(bytes);

    // 갤러리에 저장
    await FlutterImageGallerySaver.saveFile(file.path);

    print("✔ 이미지 저장됨: $filePath");

    return filePath;
  } catch (e) {
    print("❌ 이미지 저장 실패: $e");
    throw Exception('이미지 저장 실패: $e');
  }
}
