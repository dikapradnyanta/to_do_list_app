import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../restore_page.dart';
import 'package:to_do_list_app/widgets/task_tile.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int date;
  final int done;
  final int total;
  final VoidCallback? onRefresh;

  const CustomAppBar({
    super.key,
    required this.date,
    required this.done,
    required this.total,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (total == 0) ? 0.0 : done / total;
    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM').format(now);

    return SafeArea(
      bottom: false,
      top: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        decoration: const BoxDecoration(
          color: Color(0xFF3F51B5),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.menu_open_sharp, color: Colors.white),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.white,), // ✅ this can stay const
                  onPressed: () async {
                    final restored = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RestoreTaskPage(),
                      ),
                    );

                    if (restored == true && onRefresh != null) {
                      onRefresh!(); // ✅ call parent's refresh method if provided
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Bottom Row: Today + Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$total tasks",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Progress Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$done/$total",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          "Done",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.square(160);
}
