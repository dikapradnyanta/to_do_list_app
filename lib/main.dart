import 'package:flutter/material.dart';
import 'add_task.dart';
import 'widgets/custom_app_bar.dart';
import 'spalsh_screen.dart';
import 'ffi/ffi_bindings.dart'; // pastikan path sesuai

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
    final done = getDoneTaskCountNative(todayTimestamp);
    final total = getTaskByDateNative(todayTimestamp);
    return {'done': done, 'total': total};
  }

  int totalTasks = 10;
  int completedTasks = 9;

  int getTaskByDateHelper(int dateTimestamp) {
    // Ganti dengan logika real untuk hitung task berdasarkan date
    return totalTasks;
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        getTaskByDateHelper: getTaskByDateHelper,
        // Hapus baris berikut karena tidak ada di konstruktor CustomAppBar:
        // getDoneTaskCountHelper: getDoneTaskCountHelper,
      ),
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
          const Expanded(child: Center(child: Text("List of Tasks Goes Here"))),
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
            MaterialPageRoute(builder: (context) => const AddTaskPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
