// file: task_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'ffi/ffi_helper.dart';
import 'widgets/task_tile.dart';
import 'widgets/task_model.dart';
import 'add_task.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final ScrollController _weekScrollController = ScrollController();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _showCalendar = false;
  bool _useWeekSelector = true;
  bool _isSelecting = false;
  final Set<int> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      // PERBAIKAN: Sama seperti di HomePage - reload database dulu
      await updateDBhelper();
      await loadDBHelper();

      final loaded = await getAllTasksHelper();
      debugPrint('Loaded ${loaded.length} tasks from native');

      // Sort by timestamp
      loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _tasks = loaded;
          _isLoading = false;
        });
      }

      debugPrint('Tasks updated in Flutter state, count: ${_tasks.length}');
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshTasks() async {
    // PERBAIKAN: Sama seperti di HomePage
    try {
      await updateDBhelper();
      await loadDBHelper();
    } catch (e) {
      debugPrint('Error reloading database: $e');
    }
    await _loadTasks();
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks.where((task) {
      final d = DateTime.fromMillisecondsSinceEpoch(task.timestamp * 1000);
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  Map<DateTime, List<Task>> _getTaskMap() {
    final map = <DateTime, List<Task>>{};
    for (var task in _tasks) {
      final d = DateTime.fromMillisecondsSinceEpoch(task.timestamp * 1000);
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(task);
    }
    return map;
  }

  // PERBAIKAN: Sederhanakan update task - sama seperti di HomePage
  void _updateTaskInList(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      setState(() {
        _tasks[index] = updatedTask;
      });
    }
  }

  void _removeTaskFromList(int taskId) {
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
      _selectedTaskIds.remove(taskId);
    });
  }

  // Selection management
  void _toggleSelectMode(bool value) {
    setState(() {
      _isSelecting = value;
      if (!value) {
        _selectedTaskIds.clear();
        _showCalendar = false;
      }
    });
  }

  void _onTaskSelected(bool selected, int taskId) {
    setState(() {
      if (selected) {
        _selectedTaskIds.add(taskId);
        if (!_isSelecting) {
          _isSelecting = true;
          _showCalendar = false;
        }
      } else {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isSelecting = false;
        }
      }
    });
  }

  Future<void> _deleteSelectedTasks() async {
    final tasksToDelete = _selectedTaskIds.toList();

    try {
      for (var id in tasksToDelete) {
        await deleteTaskHelper(id);
      }
      _toggleSelectMode(false);
      await _refreshTasks();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tasksToDelete.length} task${tasksToDelete.length > 1 ? 's' : ''} deleted successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete tasks'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _delaySelectedTasks() async {
    final tasksToDelay = _selectedTaskIds.toList();

    try {
      for (var id in tasksToDelay) {
        await delayTaskHelper(id);
      }
      _toggleSelectMode(false);
      await _refreshTasks();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tasksToDelay.length} task${tasksToDelay.length > 1 ? 's' : ''} delayed successfully',
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error delaying tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delay tasks'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method: Toggle completion status for selected tasks
  Future<void> _toggleSelectedTasks() async {
    final tasksToToggle = _selectedTaskIds.toList();

    try {
      for (var id in tasksToToggle) {
        await changeStatusCompleteHelper(id);
      }
      _toggleSelectMode(false);
      await _refreshTasks();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${tasksToToggle.length} task${tasksToToggle.length > 1 ? 's' : ''} updated successfully',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update tasks'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if most selected tasks are complete
  bool _areSelectedTasksComplete() {
    if (_selectedTaskIds.isEmpty) return false;

    final selectedTasks = _tasks.where(
      (task) => _selectedTaskIds.contains(task.id),
    );
    final completedCount = selectedTasks
        .where((task) => task.isComplete)
        .length;

    // Return true if more than half are complete
    return completedCount > (selectedTasks.length / 2);
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Tasks'),
              content: Text(
                'Are you sure you want to delete ${_selectedTaskIds.length} task${_selectedTaskIds.length > 1 ? 's' : ''}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  List<DateTime> _getStableDateRange() {
    final now = DateTime.now();
    final List<DateTime> days = [];

    final startDate = now.subtract(const Duration(days: 60));
    for (int i = 0; i < 121; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  void _scrollToSelectedDate() {
    if (!_weekScrollController.hasClients) return;

    final days = _getStableDateRange();
    final selectedIndex = days.indexWhere(
      (day) =>
          day.year == _selectedDay.year &&
          day.month == _selectedDay.month &&
          day.day == _selectedDay.day,
    );

    if (selectedIndex == -1) return;

    const itemWidth = 70.0;
    const itemMargin = 16.0;
    const totalItemWidth = itemWidth + itemMargin;

    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = (screenWidth / 2) - (itemWidth / 2);
    final targetOffset = (selectedIndex * totalItemWidth) - centerOffset;

    _weekScrollController.animateTo(
      targetOffset.clamp(0.0, _weekScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _selectTasksByCategory(String category) {
    final tasksToday = _getTasksForDay(_selectedDay);
    final categoryTasks = tasksToday
        .where((task) => task.category.toLowerCase() == category.toLowerCase())
        .map((task) => task.id);

    setState(() {
      _selectedTaskIds.addAll(categoryTasks);
      if (_selectedTaskIds.isNotEmpty && !_isSelecting) {
        _isSelecting = true;
        _showCalendar = false;
      }
    });
  }

  void _selectCompletedTasks() {
    final tasksToday = _getTasksForDay(_selectedDay);
    final completedTasks = tasksToday
        .where((task) => task.isComplete)
        .map((task) => task.id);

    setState(() {
      _selectedTaskIds.addAll(completedTasks);
      if (_selectedTaskIds.isNotEmpty && !_isSelecting) {
        _isSelecting = true;
        _showCalendar = false;
      }
    });
  }

  void _selectIncompleteTasks() {
    final tasksToday = _getTasksForDay(_selectedDay);
    final incompleteTasks = tasksToday
        .where((task) => !task.isComplete)
        .map((task) => task.id);

    setState(() {
      _selectedTaskIds.addAll(incompleteTasks);
      if (_selectedTaskIds.isNotEmpty && !_isSelecting) {
        _isSelecting = true;
        _showCalendar = false;
      }
    });
  }

  Widget _buildWeekSelector() {
    final days = _getStableDateRange();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _weekScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = isSameDay(day, _selectedDay);
          final isCurrentMonth = day.month == _selectedDay.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
                _focusedDay = day;
              });
              _scrollToSelectedDate();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.indigo
                          : isCurrentMonth
                          ? Colors.black54
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.indigo
                          : isCurrentMonth
                          ? Colors.grey[200]
                          : Colors.grey[100],
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isCurrentMonth
                            ? Colors.black
                            : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickSelectionChips(List<Task> tasksToday) {
    if (tasksToday.isEmpty || !_isSelecting) return const SizedBox.shrink();

    final categories = tasksToday.map((t) => t.category).toSet().toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Select:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // Category chips
              ...categories.map((category) {
                final categoryTasks = tasksToday.where(
                  (t) => t.category == category,
                );
                final selectedInCategory = categoryTasks
                    .where((t) => _selectedTaskIds.contains(t.id))
                    .length;

                return FilterChip(
                  label: Text(
                    '$category ($selectedInCategory/${categoryTasks.length})',
                  ),
                  selected: selectedInCategory == categoryTasks.length,
                  onSelected: (selected) {
                    if (selected) {
                      _selectTasksByCategory(category);
                    } else {
                      setState(() {
                        final categoryTaskIds = categoryTasks.map((t) => t.id);
                        _selectedTaskIds.removeWhere(
                          (id) => categoryTaskIds.contains(id),
                        );
                      });
                    }
                  },
                  selectedColor: Colors.indigo[100],
                  checkmarkColor: Colors.indigo,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final formattedMonth = DateFormat.MMMM().format(_selectedDay);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

    if (_isSelecting) {
      return AppBar(
        backgroundColor: Colors.indigo[700],
        title: Text(
          '${_selectedTaskIds.length} Selected',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _toggleSelectMode(false),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'select_all':
                  final tasksToday = _getTasksForDay(_selectedDay);
                  setState(() {
                    _selectedTaskIds.clear();
                    _selectedTaskIds.addAll(tasksToday.map((t) => t.id));
                  });
                  break;
                case 'select_completed':
                  _selectCompletedTasks();
                  break;
                case 'select_incomplete':
                  _selectIncompleteTasks();
                  break;
                case 'invert_selection':
                  final tasksToday = _getTasksForDay(_selectedDay);
                  final allIds = tasksToday.map((t) => t.id).toSet();
                  final newSelection = allIds.difference(_selectedTaskIds);
                  setState(() {
                    _selectedTaskIds.clear();
                    _selectedTaskIds.addAll(newSelection);
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select_all',
                child: Row(
                  children: [
                    Icon(Icons.select_all),
                    SizedBox(width: 12),
                    Text('Select All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'select_completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 12),
                    Text('Select Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'select_incomplete',
                child: Row(
                  children: [
                    Icon(Icons.radio_button_unchecked),
                    SizedBox(width: 12),
                    Text('Select Incomplete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'invert_selection',
                child: Row(
                  children: [
                    Icon(Icons.flip_to_back),
                    SizedBox(width: 12),
                    Text('Invert Selection'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return AppBar(
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : null,
      backgroundColor: Colors.indigo,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedMonth, style: const TextStyle(color: Colors.white)),
          Text(
            formattedDate,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          onPressed: () {
            setState(() {
              _showCalendar = !_showCalendar;
              _useWeekSelector = !_useWeekSelector;
            });

            Future.delayed(const Duration(milliseconds: 300), () {
              if (_useWeekSelector) {
                _scrollToSelectedDate();
                // tambahkan function lain juga di sini jika perlu
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'select_mode':
                _toggleSelectMode(true);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select_mode',
              child: Row(
                children: [
                  Icon(Icons.checklist),
                  SizedBox(width: 12),
                  Text('Select Tasks'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTasksList(List<Task> tasksToday) {
    return Column(
      children: [
        // Selection toolbar - Enhanced with more options
        if (_isSelecting)
          Container(
            color: Colors.indigo[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.indigo, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedTaskIds.length} task${_selectedTaskIds.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[800],
                      ),
                    ),
                    const Spacer(),
                    // Select All / Deselect All
                    TextButton(
                      onPressed: () {
                        if (_selectedTaskIds.length == tasksToday.length) {
                          // Deselect all
                          setState(() => _selectedTaskIds.clear());
                        } else {
                          // Select all
                          setState(() {
                            _selectedTaskIds.clear();
                            _selectedTaskIds.addAll(
                              tasksToday.map((t) => t.id),
                            );
                          });
                        }
                      },
                      child: Text(
                        _selectedTaskIds.length == tasksToday.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: TextStyle(color: Colors.indigo[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Delete button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed: _selectedTaskIds.isEmpty
                              ? null
                              : () async {
                                  final confirmed =
                                      await _showDeleteConfirmation();
                                  if (confirmed) await _deleteSelectedTasks();
                                },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.red[800],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    // Delay button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: _selectedTaskIds.isEmpty
                              ? null
                              : _delaySelectedTasks,
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('Delay'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[800],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    // Complete/Incomplete button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: _selectedTaskIds.isEmpty
                              ? null
                              : _toggleSelectedTasks,
                          icon: Icon(
                            _areSelectedTasksComplete()
                                ? Icons.undo
                                : Icons.check,
                            size: 18,
                          ),
                          label: Text(
                            _areSelectedTasksComplete() ? 'Undo' : 'Complete',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[100],
                            foregroundColor: Colors.green[800],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    // Close button
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        onPressed: () => _toggleSelectMode(false),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        // Tasks list
        Expanded(
          child: tasksToday.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tasks for this day',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: tasksToday.length,
                    itemBuilder: (context, index) {
                      final task = tasksToday[index];
                      final isSelected = _selectedTaskIds.contains(task.id);

                      return GestureDetector(
                        onLongPress: () {
                          if (!_isSelecting) {
                            _onTaskSelected(true, task.id);
                            HapticFeedback.mediumImpact(); // Haptic feedback
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TaskTile(
                            key: ValueKey(task.id),
                            task: task,
                            isSelecting: _isSelecting,
                            isSelected: isSelected,
                            onSelected: (selected) =>
                                _onTaskSelected(selected, task.id),
                            onToggleComplete: _updateTaskInList,
                            onDelete: () => _removeTaskFromList(task.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksToday = _getTasksForDay(_selectedDay);
    final taskMap = _getTaskMap();
    final formattedMonth = DateFormat.MMMM().format(_selectedDay);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 8),

          AnimatedSwitcher(
            transitionBuilder: (child, animation) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.0, 0.2),
                end: Offset.zero,
              );
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: child,
              );
            },
            duration: const Duration(milliseconds: 300),

            child: (!_isSelecting && _useWeekSelector)
                ? _buildWeekSelector()
                : const SizedBox.shrink(),
          ),

          // calendar
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            child: (_showCalendar && !_isSelecting)
                ? TableCalendar(
                    key: const ValueKey('calendar'),
                    firstDay: DateTime.utc(2020),
                    lastDay: DateTime.utc(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                      _scrollToSelectedDate();
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.indigo[200],
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left),
                      rightChevronIcon: Icon(Icons.chevron_right),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, _) {
                        final key = DateTime(date.year, date.month, date.day);
                        if (taskMap.containsKey(key)) {
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: taskMap[key]!
                                  .take(3)
                                  .map(
                                    (task) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    onPageChanged: (newFocusedDay) =>
                        _focusedDay = newFocusedDay,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTasksList(tasksToday),
          ),
        ],
      ),

      floatingActionButton: Transform.translate(
        offset: const Offset(0, -40),
        child: FloatingActionButton(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddTaskPage(category: "Music", date: _selectedDay),
              ),
            );
            if (result == true) {
              _refreshTasks();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
