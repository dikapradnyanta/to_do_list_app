#include <sqlite3.h>
#include <stdio.h>
#include <iostream>

using namespace std;

static int createDB(const char* s);
static int createTable(const char* s);
static int callback(void* NotUsed, int argc, char** argv, char** azColName);

int main()
{
	const char* dir = R"(c:Database.db)";

	createDB(dir);
	createTable(dir);

	return 0;
}

static int createDB(const char* s)
{
	sqlite3* DB;
	
	int exit = 0;
	exit = sqlite3_open(s, &DB);

	sqlite3_close(DB);

	return 0;
}

static int createTable(const char* s)
{
	sqlite3 *DB;
	char* messageError;

	string sql = "CREATE TABLE To_Do_List("
		"Id INTEGER PRIMARY KEY AUTOINCREMENT, "
		"Status    char(10), "
		"Headline  TEXT NOT NULL, "
		"Deskrpisi TEXT NOT NULL;";

	try
	{
		int exit = 0;
		exit = sqlite3_open(s, &DB);
		/* An open database, SQL to be evaluated, Callback function, 1st argument to callback, Error msg written here */
		exit = sqlite3_exec(DB, sql.c_str(), NULL, 0, &messageError);
		if (exit != SQLITE_OK) {
			cerr << "Error in createTable function." << endl;
			sqlite3_free(messageError);
		}
		else
			cout << "Table created Successfully" << endl;
		sqlite3_close(DB);
	}
	catch (const exception& e)
	{
		cerr << e.what();
	}

	return 0;
}