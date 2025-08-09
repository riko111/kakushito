import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final List<Color> colors;
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorSelector({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : Border.all(color: Colors.grey.shade300),
            ),
          ),
        );
      }).toList(),
    );
  }
}

void showColorSelectorDialog({
  required BuildContext context,
  required List<Color> colors,
  required Color? selectedColor,
  required ValueChanged<Color> onColorSelected,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('マスク対象の色を選択'),
      content: SingleChildScrollView(
        child: ColorSelector(
          colors: colors,
          selectedColor: selectedColor,
          onColorSelected: (color) {
            Navigator.pop(context);
            onColorSelected(color);
          },
        ),
      ),
    ),
  );
}
