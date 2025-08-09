import 'dart:io';

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../viewer/viewer_screen.dart';
import '../../services/recent_files_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecentFilesService _recentFilesService = RecentFilesService();
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final files = await _recentFilesService.getRecentFiles();
    if (!mounted) return;
    setState(() {
      _recentFiles = files;
    });
  }

  Future<void> _openFile(String path) async {
    await _recentFilesService.addFile(path);
    await _loadRecentFiles();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewerScreen(filePath: path),
      ),
    );
  }

  Future<String?> _openFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // ← これ大事（pathがnullでもbytesで読める）
      allowMultiple: false,
    );
    final file = result?.files.single;
    if (file == null) return null;

    // 1) bytes優先（SAFやiCloudでpathがnullになるケースがある）
    Uint8List? bytes = file.bytes;
    String? srcPath = file.path;

    // 2) bytesが無ければ、pathから読み込み（Windows/macOS等でpathが来る）
    if (bytes == null && srcPath != null) {
      bytes = await File(srcPath).readAsBytes();
    }
    if (bytes == null) return null; // それでも無ければ諦める

    // 3) 一時ディレクトリへ保存（ビューアはローカルパスが安定）
    final tmpDir = await getTemporaryDirectory();
    final safeName = (file.name.isNotEmpty ? file.name : 'picked.pdf')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'); // Windows用に念のため
    final cachedPath = '${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final out = File(cachedPath);
    await out.writeAsBytes(bytes, flush: true);

    return cachedPath;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('かくしーと'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.insert_drive_file),
              label: const Text('ローカルファイルを開く'),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                  withData: true,
                );
                final f = result?.files.single;
                if (f != null) {
                  String path;
                  if (f.bytes != null) {
                    final tmp = await getTemporaryDirectory();
                    final safeName = (f.name.isNotEmpty ? f.name : 'local.pdf')
                        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
                    final cached = '${tmp.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
                    await File(cached).writeAsBytes(f.bytes!, flush: true);
                    path = cached;
                  } else if (f.path != null) {
                    path = f.path!;
                  } else {
                    return; // 取れなかった
                  }
                  if (context.mounted) _openFile(path);
                }

              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud),
              label: const Text('クラウドストレージから開く'),
              onPressed: () async {
                final String? cachedPath = await _openFromCloud();
                if (cachedPath == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ファイルを選択できませんでした')),
                  );
                  return;
                }
                if (!mounted) return;
                await _openFile(cachedPath);
              },

            ),
            const SizedBox(height: 32),
            const Text(
              '最近開いたファイル',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _recentFiles.isEmpty
                  ? const Center(child: Text('履歴はまだありません'))
                  : ListView.builder(
                itemCount: _recentFiles.length,
                itemBuilder: (context, index) {
                  final path = _recentFiles[index];
                  return ListTile(
                    title: Text(p.basename(path)),
                    subtitle: Text(path),
                    onTap: () => _openFile(path),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
