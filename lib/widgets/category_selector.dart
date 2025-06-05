import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories = const [
    'Idea',
    'Food',
    'Work',
    'Sport',
    'Music',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: categories.map((category) {
        final bool isSelected = category == selectedCategory;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => onCategorySelected(category),
          selectedColor: Colors.blue,
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
    );
  }
}
