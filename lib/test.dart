import 'package:flutter/material.dart';

WidgetBuilder buildTaskCard(String taskName, String taskTime) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      title: Text(taskName),
      subtitle: Text(taskTime),
      trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
    ),
  );
}