import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mask_overlay.dart';
import 'viewer_app_bar.dart';
import 'viewer_page_controls.dart';

class ViewerScreen extends StatefulWidget {
  final String filePath;

  const ViewerScreen({super.key, required this.filePath});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PdfController _pdfController;
  bool _maskEnabled = true;
  Map<int, List<MaskStroke>> _strokesByPage = {};
  List<Offset> _currentStrokePoints = [];
  int _pageCount = 1;
  int _currentPage = 1;
  bool _isErasing = false;
  Set<int> _bookmarkedPages = {};
  String get _prefsKey =>
      'lastPage_'
      '${base64Url.encode(utf8.encode(widget.filePath))}';
  String get _bookmarkKey =>
      'bookmarks_'
      '${base64Url.encode(utf8.encode(widget.filePath))}';

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openFile(widget.filePath),
      initialPage: _currentPage,
    );
    _loadPageInfo();
    _loadMaskData();
    _loadLastPage();
    _loadBookmarks();
  }

  Future<void> _loadPageInfo() async {
    final doc = await _pdfController.document;
    if (!mounted) return;
    setState(() {
      _pageCount = doc.pagesCount;
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    unawaited(_saveMaskData().catchError((e, _) {
      debugPrint('Failed to save mask data: $e');
    }));
    unawaited(_saveLastPage().catchError((e, _) {
      debugPrint('Failed to save last page: $e');
    }));
    super.dispose();
  }

  Future<void> _loadMaskData() async {
    final file = File('${widget.filePath}.mask.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final loaded = <int, List<MaskStroke>>{};
        jsonMap.forEach((key, value) {
          final page = int.tryParse(key);
          if (page != null) {
            final strokes = (value as List)
                .map<MaskStroke>((strokePoints) {
              final points = (strokePoints as List)
                  .map<Offset>((p) => Offset((p['dx'] as num).toDouble(),
                      (p['dy'] as num).toDouble()))
                  .toList();
              return MaskStroke(points: points, page: page);
            }).toList();
            loaded[page] = strokes;
          }
        });
        if (!mounted) return;
        setState(() {
          _strokesByPage = loaded;
        });
      } catch (_) {
        // ignore malformed files
      }
    }
  }

  Future<void> _saveMaskData() async {
    final file = File('${widget.filePath}.mask.json');
    final data = _strokesByPage.map((page, strokes) => MapEntry(
        page.toString(),
        strokes
            .map((s) =>
                s.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList())
            .toList()));
    await file.writeAsString(jsonEncode(data));
  }

  void _undoLastStroke() {
    final strokes = _strokesByPage[_currentPage];
    if (strokes != null && strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
      unawaited(_saveMaskData());
    }
  }

  void _clearAllStrokes() {
    setState(() {
      _strokesByPage[_currentPage]?.clear();
    });
    unawaited(_saveMaskData());
  }

  Future<void> _jumpToPageDialog() async {
    final doc = await _pdfController.document;
    final pageCount = doc.pagesCount;
    if (!mounted) return;
    int? selected = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('ページジャンプ'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: ListView.builder(
          itemCount: pageCount,
          itemBuilder: (context, index) => ListTile(
            title: Text('ページ ${index + 1}'),
            onTap: () => Navigator.of(context).pop(index + 1),
          ),
        ),
      ),
    ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _currentPage = selected;
    });
    _pdfController.jumpToPage(selected);
    unawaited(_saveLastPage());
  }

  void _eraseStrokeAt(Offset point) {
    final strokes = _strokesByPage[_currentPage];
    if (strokes == null) return;
    setState(() {
      strokes.removeWhere(
          (stroke) => stroke.points.any((p) => (p - point).distance < 20));
    });
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarkKey) ?? [];
    if (!mounted) return;
    setState(() {
      _bookmarkedPages = list.map(int.parse).toSet();
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _bookmarkKey, _bookmarkedPages.map((e) => e.toString()).toList());
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarkedPages.contains(_currentPage)) {
        _bookmarkedPages.remove(_currentPage);
      } else {
        _bookmarkedPages.add(_currentPage);
      }
    });
    unawaited(_saveBookmarks());
  }

  Future<void> _showBookmarksDialog() async {
    if (_bookmarkedPages.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => const AlertDialog(
          content: Text('しおりはありません'),
        ),
      );
      return;
    }
    final pages = _bookmarkedPages.toList()..sort();
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('しおり'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView(
            children: [
              for (final page in pages)
                ListTile(
                  title: Text('ページ $page'),
                  onTap: () => Navigator.of(context).pop(page),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _currentPage = selected;
      });
      _pdfController.jumpToPage(selected);
      unawaited(_saveLastPage());
    }
  }

  Future<void> _loadLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefsKey);
    if (saved != null && saved >= 1 && mounted) {
      setState(() {
        _currentPage = saved;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pdfController.jumpToPage(saved);
        }
      });
    }
  }

  Future<void> _saveLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _currentPage);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: ViewerAppBar(
      title: widget.filePath.split('/').last,
      onUndo: _undoLastStroke,
      onClear: _clearAllStrokes,
      onJumpToPage: _jumpToPageDialog,
      onShowBookmarks: _showBookmarksDialog,
      onToggleBookmark: _toggleBookmark,
      isErasing: _isErasing,
      maskEnabled: _maskEnabled,
      isBookmarked: _bookmarkedPages.contains(_currentPage),
      onToggleEraser: () {
        setState(() {
          _isErasing = !_isErasing;
        });
      },
      onToggleMask: () {
        setState(() {
          _maskEnabled = !_maskEnabled;
        });
      },
    ),
    body: Column(
      children: [
        ViewerPageControls(
          currentPage: _currentPage,
          pageCount: _pageCount,
          onPrev: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _pdfController.jumpToPage(_currentPage);
                  unawaited(_saveLastPage());
                }
              : null,
          onNext: _currentPage < _pageCount
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _pdfController.jumpToPage(_currentPage);
                  unawaited(_saveLastPage());
                }
              : null,
        ),
        Expanded(
          child: GestureDetector(
            onPanStart: (details) {
              if (_isErasing) {
                _eraseStrokeAt(details.localPosition);
              } else {
                setState(() {
                  _currentStrokePoints = [details.localPosition];
                });
              }
            },
            onPanUpdate: (details) {
              if (_isErasing) {
                _eraseStrokeAt(details.localPosition);
              } else {
                setState(() {
                  _currentStrokePoints.add(details.localPosition);
                });
              }
            },
            onPanEnd: (details) {
              if (_isErasing) {
                unawaited(_saveMaskData());
              } else {
                setState(() {
                  _strokesByPage.putIfAbsent(_currentPage, () => []).add(
                    MaskStroke(points: List.from(_currentStrokePoints), page: _currentPage),
                  );
                  _currentStrokePoints.clear();
                });
                unawaited(_saveMaskData());
              }
            },
            child: Stack(
              children: [
                PdfView(
                  controller: _pdfController,
                ),
                MaskOverlay(
                  strokes: _strokesByPage[_currentPage] ?? [],
                  maskEnabled: _maskEnabled,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
