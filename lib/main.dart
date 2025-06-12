import 'package:flutter/material.dart';
import 'package:to_do_list_app/ffi/ffi_helper.dart';
import 'widgets/custom_app_bar.dart';
import 'spalsh_screen.dart';
import 'category.dart';
import 'widgets/task_tile.dart';
import 'widgets/task_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
// pastikan path sesuai

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
          accentColor: Colors.indigoAccent,
        ).copyWith(secondary: Colors.indigoAccent),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int todayTimestamp;

  @override
  void initState() {
    super.initState();
    // Timestamp hari ini (dalam detik)
    final now = DateTime.now();
    todayTimestamp =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
  }

  Future<Map<String, int>> getTodayTaskStats() async {
    // Panggil fungsi native
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final done = await getDoneTaskCountHelper(now);
    final total = await getTaskCountHelper(now);
    return {'done': done, 'total': total};
  }

  //int totalTasks = done
  //int completedTasks = getDoneTaskCountHelper(DateTime.now().millisecondsSinceEpoch ~/ 1000);

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FutureBuilder<Map<String, int>>(
                  future: getTodayTaskStats(),
                  builder: (context, snapshot) {
                    int done = snapshot.data?['done'] ?? 0;
                    int total = snapshot.data?['total'] ?? 1;
                    double percent = total == 0 ? 0 : done / total;
                    return Stack(
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: getTaskByDateHelper(todayTimestamp),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gambar SVG ilustrasi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SvgPicture.asset('assets/illustration/kaizen_chinese_girl.svg'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "No tasks today.\nTake a breath and enjoy your moment",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskTile(task: tasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).colorScheme.primary,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Task',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChooseActivityPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
