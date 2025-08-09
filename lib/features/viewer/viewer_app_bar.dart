import 'package:flutter/material.dart';

class ViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onJumpToPage;
  final VoidCallback onShowBookmarks;
  final VoidCallback onToggleBookmark;
  final bool isErasing;
  final bool maskEnabled;
  final bool isBookmarked;
  final VoidCallback onToggleEraser;
  final VoidCallback onToggleMask;

  const ViewerAppBar({
    super.key,
    required this.title,
    required this.onUndo,
    required this.onClear,
    required this.onJumpToPage,
    required this.onShowBookmarks,
    required this.onToggleBookmark,
    required this.isErasing,
    required this.maskEnabled,
    required this.isBookmarked,
    required this.onToggleEraser,
    required this.onToggleMask,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
          onPressed: onUndo,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Clear',
          onPressed: onClear,
        ),
        IconButton(
          icon: const Icon(Icons.menu_book),
          tooltip: 'ページジャンプ',
          onPressed: onJumpToPage,
        ),
        IconButton(
          icon: const Icon(Icons.bookmarks),
          tooltip: 'しおり一覧',
          onPressed: onShowBookmarks,
        ),
        IconButton(
          icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border),
          tooltip: isBookmarked ? 'しおりを削除' : 'しおりを追加',
          onPressed: onToggleBookmark,
        ),
        IconButton(
          icon: Icon(Icons.cleaning_services,
              color: isErasing ? Colors.orange : null),
          tooltip: '消しゴム',
          onPressed: onToggleEraser,
        ),
        IconButton(
          icon: Icon(maskEnabled ? Icons.visibility_off : Icons.visibility),
          tooltip: maskEnabled ? 'シート非表示' : 'シート表示',
          onPressed: onToggleMask,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
