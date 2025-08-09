import 'package:shared_preferences/shared_preferences.dart';

class RecentFilesService {
  static const String _key = 'recent_files';
  static const int maxItems = 10;

  Future<List<String>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key);
    return jsonList ?? [];
  }

  Future<void> addFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> files = prefs.getStringList(_key) ?? [];

    files.remove(path); // 重複排除
    files.insert(0, path); // 先頭に追加

    if (files.length > maxItems) {
      files.removeLast();
    }

    await prefs.setStringList(_key, files);
  }

  Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
