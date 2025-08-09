import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/color_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _maskColorKey = 'maskColor';
  Color _maskColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadMaskColor();
  }

  Future<void> _loadMaskColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_maskColorKey);
    if (value != null && mounted) {
      setState(() => _maskColor = Color(value));
    }
  }

  Future<void> _saveMaskColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maskColorKey, color.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'マスク対象の色',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _maskColor,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    showColorSelectorDialog(
                      context: context,
                      colors: [
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                        Colors.black,
                        Colors.purple,
                        Colors.grey
                      ],
                      selectedColor: _maskColor,
                      onColorSelected: (color) {
                        setState(() => _maskColor = color);
                        _saveMaskColor(color);
                      },
                    );
                  },
                  child: const Text('色を選ぶ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
