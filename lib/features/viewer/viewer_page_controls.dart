import 'package:flutter/material.dart';

class ViewerPageControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const ViewerPageControls({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onPrev,
          ),
          Text('ページ $currentPage / $pageCount'),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
