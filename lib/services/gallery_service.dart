import 'package:photo_manager/photo_manager.dart';

// 'mysilentcam_' 접두사를 가진 사진만 필터링해서 불러오는 서비스
Future<List<AssetEntity>> loadFilteredImages(String prefix) async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) return [];

  List<AssetPathEntity> albums =
      await PhotoManager.getAssetPathList(type: RequestType.image);
  List<AssetEntity> allImages = [];

  for (final album in albums) {
    final assets = await album.getAssetListPaged(page: 0, size: 100);
    allImages.addAll(assets);
  }

  // 'mysilentcam_' 접두사를 가진 파일만 필터링
  final filtered = <AssetEntity>[];
  for (final img in allImages) {
    final file = await img.file;
    if (file != null && file.path.contains(prefix)) {
      filtered.add(img);
    }
  }

  return filtered;
}
