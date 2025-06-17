import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do_list_app/ffi/ffi_helper.dart';
import 'widgets/custom_app_bar.dart';
import 'splash_screen.dart';
import 'category.dart';
import 'widgets/task_tile.dart';
import 'widgets/task_model.dart';
import 'task_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = '${dir.path}/tasks.db';

  try {
    //
    await initDBWithPathHelper(dbPath);
    debugPrint('Database initialized at: $dbPath');
    await updateDBhelper();
    await loadDBHelper();
    debugPrint('Database loaded successfully');
  } catch (e) {
    debugPrint('DB initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To Do List App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  late int todayTimestamp;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    todayTimestamp =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;

    sendLogPathToNative();
    _loadTasks();
    _updateStats();
  }

  // PERBAIKAN: Tambahkan listener untuk mendeteksi ketika kembali dari halaman lain
  @override
  void didPopNext() {
    super.didPopNext();
    // Refresh ketika kembali dari halaman lain
    _refreshTasks();
  }

  Future<void> _updateStats() async {
    try {
      final result = await getTaskStatsHelper(todayTimestamp);
      if (mounted) {
        setState(() {
          _done = result['done'] ?? 0;
          _total = result['total'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error updating stats: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // PERBAIKAN: Selalu reload database sebelum mengambil data
      await updateDBhelper();
      await loadDBHelper();

      final tasks = await getTaskByDateHelper(todayTimestamp);

      // Debug: Print task status untuk memastikan data benar
      for (var task in tasks) {
        debugPrint('Task: ${task.title}, isComplete: ${task.isComplete}');
      }

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshTasks() async {
    // PERBAIKAN: Reload database sebelum mengambil tasks untuk memastikan sinkronisasi
    try {
      await updateDBhelper();
      await loadDBHelper();
    } catch (e) {
      debugPrint('Error reloading database: $e');
    }

    await _loadTasks();
    await _updateStats();
  }

  void _updateTaskInList(Task updatedTask) {
    // Update task di list dan refresh stats
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      setState(() {
        _tasks[index] = updatedTask;
      });
    }
    // Selalu update stats setelah perubahan
    _updateStats();
  }

  void _removeTaskFromList(int taskId) {
    // Hapus task dari list dan refresh stats
    setState(() {
      _tasks.removeWhere((task) => task.id == taskId);
    });
    _updateStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(date: todayTimestamp, done: _done, total: _total, onRefresh: _refreshTasks,),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading tasks: $_error',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshTasks,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _tasks.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('asset/img/kaisen.png', height: 300),
                              const Text(
                                "No tasks today.\nTake a breath and enjoy your moment",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TaskTile(
                              key: ValueKey(
                                _tasks[index].id,
                              ), // PERBAIKAN: Tambahkan key untuk tracking yang lebih baik
                              task: _tasks[index],
                              onToggleComplete: (updatedTask) {
                                _updateTaskInList(updatedTask);
                              },
                              onDelete: () {
                                _removeTaskFromList(_tasks[index].id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) async {
          if (index == 1) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskPage()),
            );
            // PERBAIKAN: Selalu refresh ketika kembali dari TaskPage
            _refreshTasks();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'All Tasks',
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChooseActivityPage()),
          );

          if (result == true) {
            _refreshTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}