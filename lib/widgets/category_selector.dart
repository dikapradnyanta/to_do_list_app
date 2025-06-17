// file: widgets/week_date_selector.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const WeekDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  List<DateTime> _generateWeek(DateTime centerDate) {
    return List.generate(5, (index) {
      return centerDate.add(Duration(days: index - 2)); // 2 hari sebelum dan sesudah
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _generateWeek(selectedDate);
    final dateFormat = DateFormat('d');
    final dayFormat = DateFormat('E');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDates.map((date) {
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Column(
              children: [
                Text(
                  dayFormat.format(date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.indigo : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.indigo : Colors.transparent,
                  ),
                  child: Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
