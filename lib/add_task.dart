import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ffi/ffi_helper.dart';

class AddTaskPage extends StatefulWidget {
  final String category;
  final DateTime date;

  const AddTaskPage({super.key, required this.category, required this.date});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedCategory;
  final List<String> _categories = ['Idea', 'Food', 'Work', 'Sport', 'Music'];
  late DateTime selectedDate;
  bool _titleFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    selectedDate = widget.date;
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final note = _noteController.text.trim();
      final category = _selectedCategory;
      final date = selectedDate;
      final timestamp = date.millisecondsSinceEpoch;

      debugPrint('Before addTaskHelper');
      await addTaskHelper(
        title: title,
        description: note,
        timestamp: timestamp,
        kategori: category,
      );
      debugPrint('After addTaskHelper');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final borderRadius = BorderRadius.circular(14);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Title Field
              Focus(
                onFocusChange: (hasFocus) =>
                    setState(() => _titleFieldFocused = hasFocus),
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: null,
                    hintText:
                        _titleFieldFocused || _titleController.text.isNotEmpty
                        ? 'Give this task a name'
                        : 'Title',
                    hintStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: borderRadius,
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Title can't be empty";
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (!_formKey.currentState!.validate()) {
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Calendar Field
              Text(
                "Date",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: borderRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Field
              Text(
                "Category",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: borderRadius,
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black54,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategory = val!);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Note Field
              Text(
                "Note",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Add a note...",
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saveTask,
          child: const Text(
            "Create task",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
