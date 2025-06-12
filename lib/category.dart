import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ChooseActivityPage extends StatefulWidget {
  const ChooseActivityPage({super.key});

  @override
  State<ChooseActivityPage> createState() => _ChooseActivityPageState();
}

class _ChooseActivityPageState extends State<ChooseActivityPage> {
  final List<String> categories = ['Idea', 'Food', 'Work', 'Sport'];
  DateTime currentMonth = DateTime.now();
  late List<DateTime> monthDays;
  int selectedDayIndex = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    monthDays = getMonthDays(currentMonth);
    final now = DateTime.now();
    selectedDayIndex = monthDays.indexWhere(
      (d) => d.day == now.day && d.month == now.month && d.year == now.year,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelectedDate(),
    );
  }

  void _onCategorySelected(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddTaskPage(category: category, date: monthDays[selectedDayIndex]),
      ),
    );
  }

  void _scrollToSelectedDate() {
    // 5 item, index tengah = 2
    double itemWidth = 56; // width + margin (48 + 2*4)
    int centerIndex = 2;
    double targetScroll = (selectedDayIndex - centerIndex) * itemWidth;
    double maxScroll = _scrollController.position.maxScrollExtent;
    double minScroll = _scrollController.position.minScrollExtent;

    // Clamp agar tidak scroll keluar batas
    if (targetScroll < minScroll) targetScroll = minScroll;
    if (targetScroll > maxScroll) targetScroll = maxScroll;

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> getMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final start = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    final end = lastDay.add(Duration(days: 6 - (lastDay.weekday % 7)));
    return List.generate(
      end.difference(start).inDays + 1,
      (i) => start.add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Task'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal date picker
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 32, right: 32),
              child: SizedBox(
                width: 56.0 * 5, // 5 item * (width + margin)
                height: 60,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: monthDays.length,
                  itemBuilder: (context, i) {
                    final d = monthDays[i];
                    final selected = i == selectedDayIndex;
                    final isCurrentMonth = d.month == currentMonth.month;
                    return GestureDetector(
                      onTap: () {
                        if (d.month != currentMonth.month ||
                            d.year != currentMonth.year) {
                          setState(() {
                            currentMonth = DateTime(d.year, d.month);
                            monthDays = getMonthDays(currentMonth);
                            selectedDayIndex = monthDays.indexWhere(
                              (dt) =>
                                  dt.day == d.day &&
                                  dt.month == d.month &&
                                  dt.year == d.year,
                            );
                          });
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollToSelectedDate(),
                          );
                        } else {
                          setState(() {
                            selectedDayIndex = i;
                          });
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollToSelectedDate(),
                          );
                        }
                      },
                      child: Container(
                        width: 48,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: selected ? Colors.indigo : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 18,
                                color: selected
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? Colors.black
                                    : Colors.black26,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('E').format(d),
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? Colors.black54
                                    : Colors.black26,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CategorySelector(
                  categories: categories,
                  onCategorySelected: _onCategorySelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final String category;
  final DateTime date;

  const AddTaskPage({super.key, required this.category, required this.date});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Form(
        key: _formKey,
        child: Center(
          child: Text(
            'Kategori: ${widget.category}\nTanggal: ${DateFormat('yyyy-MM-dd').format(widget.date)}',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  static const Map<String, IconData> categoryIcons = {
    'Idea': Icons.lightbulb_outline,
    'Food': Icons.fastfood,
    'Work': Icons.work_outline,
    'Sport': Icons.fitness_center,
  };

  static const Map<String, String> categorySub = {
    'Idea': '13 on this week',
    'Food': '6 on this week',
    'Work': '15 on this week',
    'Sport': '7 on this week',
  };

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final cat = categories[i];
        return Material(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onCategorySelected(cat),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    categoryIcons[cat] ?? Icons.category,
                    color: Colors.indigo,
                    size: 32,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categorySub[cat] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.indigo.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.indigo,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
