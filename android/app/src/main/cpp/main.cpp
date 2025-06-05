#include <iostream>
#include <string>
#include <queue>
#include <vector>
#include <iomanip>
#include <ctime>
#include <sstream>

using namespace std;

// Enum untuk level prioritas
enum Priority {
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    URGENT = 4
};

// Struktur untuk task/tugas
struct Task {
    int id;
    string title;
    string description;
    Priority priority;
    string deadline;
    string createdAt;
    bool isCompleted;
    
    Task(int _id, string _title, string _desc, Priority _priority, string _deadline) 
        : id(_id), title(_title), description(_desc), priority(_priority), 
          deadline(_deadline), isCompleted(false) {
        // Set waktu pembuatan
        time_t now = time(0);
        char* timeStr = ctime(&now);
        createdAt = string(timeStr);
        createdAt.pop_back(); // Hapus newline
    }
};

// Comparator untuk priority queue (prioritas tinggi di depan)
struct TaskComparator {
    bool operator()(const Task& a, const Task& b) {
        if (a.priority != b.priority) {
            return a.priority < b.priority; // Prioritas tinggi di depan
        }
        return a.id > b.id; // Jika prioritas sama, yang lebih dulu dibuat di depan
    }
};

class ToDoListApp {
private:
    priority_queue<Task, vector<Task>, TaskComparator> taskQueue;
    vector<Task> completedTasks;
    int nextId;
    
public:
    ToDoListApp() : nextId(1) {}
    
    // Fungsi untuk menambah tugas baru
    void addTask() {
        string title, description, deadline;
        int priorityChoice;
        
        cout << "\n=== TAMBAH TUGAS BARU ===" << endl;
        cout << "Judul tugas: ";
        cin.ignore();
        getline(cin, title);
        
        cout << "Deskripsi: ";
        getline(cin, description);
        
        cout << "Deadline (DD/MM/YYYY): ";
        getline(cin, deadline);
        
        cout << "\nPilih Prioritas:" << endl;
        cout << "1. Low (Rendah)" << endl;
        cout << "2. Medium (Sedang)" << endl;
        cout << "3. High (Tinggi)" << endl;
        cout << "4. Urgent (Mendesak)" << endl;
        cout << "Pilihan: ";
        cin >> priorityChoice;
        
        Priority priority = static_cast<Priority>(priorityChoice);
        
        Task newTask(nextId++, title, description, priority, deadline);
        taskQueue.push(newTask);
        
        cout << "\nâœ… Tugas berhasil ditambahkan!" << endl;
        cout << "ID Tugas: " << newTask.id << endl;
        cout << "Prioritas: " << getPriorityString(priority) << endl;
    }
    
    // Fungsi untuk menampilkan semua tugas yang belum selesai
    void displayPendingTasks() {
        if (taskQueue.empty()) {
            cout << "\nðŸ“ Tidak ada tugas yang tertunda." << endl;
            return;
        }
        
        cout << "\n=== DAFTAR TUGAS (BERDASARKAN PRIORITAS) ===" << endl;
        
        // Buat copy untuk menampilkan tanpa menghapus dari queue
        priority_queue<Task, vector<Task>, TaskComparator> tempQueue = taskQueue;
        
        int count = 1;
        while (!tempQueue.empty()) {
            Task task = tempQueue.top();
            tempQueue.pop();
            
            cout << "\n" << count++ << ". [ID: " << task.id << "] " << task.title << endl;
            cout << "   ðŸ“‹ Deskripsi: " << task.description << endl;
            cout << "   ðŸš© Prioritas: " << getPriorityString(task.priority) << endl;
            cout << "   ðŸ“… Deadline: " << task.deadline << endl;
            cout << "   ðŸ• Dibuat: " << task.createdAt << endl;
            cout << "   " << string(50, '-') << endl;
        }
    }
    
    // Fungsi untuk mengerjakan tugas dengan prioritas tertinggi
    void processNextTask() {
        if (taskQueue.empty()) {
            cout << "\nâŒ Tidak ada tugas yang tersedia untuk dikerjakan." << endl;
            return;
        }
        
        Task currentTask = taskQueue.top();
        taskQueue.pop();
        
        cout << "\n=== TUGAS BERIKUTNYA (PRIORITAS TERTINGGI) ===" << endl;
        cout << "ðŸ”¥ Tugas: " << currentTask.title << endl;
        cout << "ðŸ“‹ Deskripsi: " << currentTask.description << endl;
        cout << "ðŸš© Prioritas: " << getPriorityString(currentTask.priority) << endl;
        cout << "ðŸ“… Deadline: " << currentTask.deadline << endl;
        
        cout << "\nApakah tugas ini sudah selesai? (y/n): ";
        char choice;
        cin >> choice;
        
        if (choice == 'y' || choice == 'Y') {
            currentTask.isCompleted = true;
            completedTasks.push_back(currentTask);
            cout << "âœ… Tugas berhasil diselesaikan!" << endl;
        } else {
            // Kembalikan ke queue jika belum selesai
            taskQueue.push(currentTask);
            cout << "ðŸ”„ Tugas dikembalikan ke antrian." << endl;
        }
    }
    
    // Fungsi untuk menampilkan tugas yang sudah selesai
    void displayCompletedTasks() {
        if (completedTasks.empty()) {
            cout << "\nðŸ“ Belum ada tugas yang diselesaikan." << endl;
            return;
        }
        
        cout << "\n=== TUGAS YANG SUDAH SELESAI ===" << endl;
        
        for (size_t i = 0; i < completedTasks.size(); i++) {
            Task task = completedTasks[i];
            cout << "\n" << (i+1) << ". âœ… " << task.title << endl;
            cout << "   ðŸ“‹ Deskripsi: " << task.description << endl;
            cout << "   ðŸš© Prioritas: " << getPriorityString(task.priority) << endl;
            cout << "   ðŸ“… Deadline: " << task.deadline << endl;
            cout << "   " << string(50, '-') << endl;
        }
    }
    
    // Fungsi untuk menampilkan statistik
    void displayStatistics() {
        int totalPending = taskQueue.size();
        int totalCompleted = completedTasks.size();
        int totalTasks = totalPending + totalCompleted;
        
        cout << "\n=== STATISTIK APLIKASI ===" << endl;
        cout << "ðŸ“Š Total tugas: " << totalTasks << endl;
        cout << "â³ Tugas tertunda: " << totalPending << endl;
        cout << "âœ… Tugas selesai: " << totalCompleted << endl;
        
        if (totalTasks > 0) {
            double completionRate = (double)totalCompleted / totalTasks * 100;
            cout << "ðŸ“ˆ Tingkat penyelesaian: " << fixed << setprecision(1) 
                 << completionRate << "%" << endl;
        }
        
        // Statistik berdasarkan prioritas
        cout << "\n--- Distribusi Prioritas Tugas Tertunda ---" << endl;
        vector<int> priorityCount(5, 0); // Index 1-4 untuk LOW-URGENT
        
        priority_queue<Task, vector<Task>, TaskComparator> tempQueue = taskQueue;
        while (!tempQueue.empty()) {
            Task task = tempQueue.top();
            tempQueue.pop();
            priorityCount[task.priority]++;
        }
        
        cout << "ðŸ”´ Urgent: " << priorityCount[URGENT] << " tugas" << endl;
        cout << "ðŸŸ  High: " << priorityCount[HIGH] << " tugas" << endl;
        cout << "ðŸŸ¡ Medium: " << priorityCount[MEDIUM] << " tugas" << endl;
        cout << "ðŸŸ¢ Low: " << priorityCount[LOW] << " tugas" << endl;
    }
    
    // Fungsi untuk mencari tugas berdasarkan ID
    void searchTaskById() {
        if (taskQueue.empty()) {
            cout << "\nâŒ Tidak ada tugas yang tersedia." << endl;
            return;
        }
        
        int searchId;
        cout << "\nMasukkan ID tugas yang dicari: ";
        cin >> searchId;
        
        priority_queue<Task, vector<Task>, TaskComparator> tempQueue = taskQueue;
        bool found = false;
        
        while (!tempQueue.empty()) {
            Task task = tempQueue.top();
            tempQueue.pop();
            
            if (task.id == searchId) {
                cout << "\nðŸ” TUGAS DITEMUKAN:" << endl;
                cout << "ID: " << task.id << endl;
                cout << "Judul: " << task.title << endl;
                cout << "Deskripsi: " << task.description << endl;
                cout << "Prioritas: " << getPriorityString(task.priority) << endl;
                cout << "Deadline: " << task.deadline << endl;
                cout << "Dibuat: " << task.createdAt << endl;
                found = true;
                break;
            }
        }
        
        if (!found) {
            cout << "\nâŒ Tugas dengan ID " << searchId << " tidak ditemukan." << endl;
        }
    }
    
    // Helper function untuk mengkonversi prioritas ke string
    string getPriorityString(Priority priority) {
        switch (priority) {
            case LOW: return "ðŸŸ¢ Low (Rendah)";
            case MEDIUM: return "ðŸŸ¡ Medium (Sedang)";
            case HIGH: return "ðŸŸ  High (Tinggi)";
            case URGENT: return "ðŸ”´ Urgent (Mendesak)";
            default: return "â“ Unknown";
        }
    }
    
    // Fungsi untuk menampilkan menu
    void displayMenu() {
        cout << "\n" << string(60, '=') << endl;
        cout << "ðŸ“± TO-DO LIST APP - QUEUE PRIORITY SYSTEM" << endl;
        cout << string(60, '=') << endl;
        cout << "1. âž• Tambah Tugas Baru" << endl;
        cout << "2. ðŸ“‹ Lihat Semua Tugas (Berdasarkan Prioritas)" << endl;
        cout << "3. âš¡ Kerjakan Tugas Berikutnya" << endl;
        cout << "4. âœ… Lihat Tugas yang Selesai" << endl;
        cout << "5. ðŸ“Š Lihat Statistik" << endl;
        cout << "6. ðŸ” Cari Tugas berdasarkan ID" << endl;
        cout << "7. ðŸšª Keluar" << endl;
        cout << string(60, '=') << endl;
        cout << "Pilihan Anda: ";
    }
    
    // Fungsi utama untuk menjalankan aplikasi
    void run() {
        cout << "ðŸŽ‰ Selamat datang di Aplikasi To-Do List!" << endl;
        cout << "ðŸ“ Sistem antrian otomatis berdasarkan prioritas tugas" << endl;
        
        int choice;
        do {
            displayMenu();
            cin >> choice;
            
            switch (choice) {
                case 1:
                    addTask();
                    break;
                case 2:
                    displayPendingTasks();
                    break;
                case 3:
                    processNextTask();
                    break;
                case 4:
                    displayCompletedTasks();
                    break;
                case 5:
                    displayStatistics();
                    break;
                case 6:
                    searchTaskById();
                    break;
                case 7:
                    cout << "\nðŸ‘‹ Terima kasih telah menggunakan To-Do List App!" << endl;
                    cout << "ðŸ“± Semoga produktivitas Anda meningkat!" << endl;
                    break;
                default:
                    cout << "\nâŒ Pilihan tidak valid. Silakan coba lagi." << endl;
            }
            
            if (choice != 7) {
                cout << "\nTekan Enter untuk melanjutkan...";
                cin.ignore();
                cin.get();
            }
            
        } while (choice != 7);
    }
};

// Fungsi utama
int main() {
    // Set locale untuk support emoji dan karakter khusus
    cout << "ðŸš€ Memulai aplikasi..." << endl;
    
    ToDoListApp app;
    app.run();
    
    return 0;
}