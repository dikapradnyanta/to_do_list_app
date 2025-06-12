CREATE TABLE IF NOT EXISTS task (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    note TEXT,
    timestamp INTEGER,
    isComplete INTEGER,
    isDeleted INTEGER,
    category TEXT
);