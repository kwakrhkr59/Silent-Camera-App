import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _entities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      setState(() => _loading = false);
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );

    final List<AssetEntity> allAssets = [];
    for (final album in albums) {
      final assets = await album.getAssetListPaged(page: 0, size: 1000);
      allAssets.addAll(assets);
    }

    // 파일명에 'mysilentcam_' 이 포함된 이미지만 필터링
    final List<AssetEntity> filtered = [];
    for (final entity in allAssets) {
      final file = await entity.file;
      if (file != null && file.path.contains('mysilentcam_')) {
        filtered.add(entity);
      }
    }

    setState(() {
      _entities = filtered;
      _loading = false;
    });
  }

  Future<Widget> _buildThumbnail(AssetEntity entity) async {
    final thumb =
        await entity.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    if (thumb == null) return Container(color: Colors.grey);
    return Image.memory(thumb, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 갤러리')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entities.isEmpty
              ? const Center(child: Text('사진이 없습니다.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _entities.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    return FutureBuilder<Widget>(
                      future: _buildThumbnail(_entities[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return snapshot.data!;
                        } else {
                          return Container(color: Colors.grey[300]);
                        }
                      },
                    );
                  },
                ),
    );
  }
}
