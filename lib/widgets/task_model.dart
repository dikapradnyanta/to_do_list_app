class Task {
  final int id;
  final String title;
  final String description;
  final int timestamp;
  final bool isComplete;
  final bool isDeleted;
  final String category;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isComplete = false,
    this.isDeleted = false,
    required this.category,
  });
}
