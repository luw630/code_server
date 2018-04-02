#pragma once

#include "god_include.h"
#include <mysqld_error.h>
#include <mysql_driver.h>
#include <mysql_connection.h>
#include <cppconn/driver.h>
#include <cppconn/statement.h>
#include <cppconn/prepared_statement.h>
#include <cppconn/metadata.h>
#include <cppconn/exception.h>


class base_db_connection
{
private:
	sql::Connection*							con_;
	sql::Statement*								stmt_;
	bool										save_sql_to_log_;
public:

	
	base_db_connection();

	
	~base_db_connection();

	
	void connect(const std::string& host, const std::string& user, const std::string& password, const std::string& database);

	
	void close();

	
	void execute(const std::string& sql);

	
	int execute_update(const std::string& sql);

	
	int execute_try(const std::string& sql);

	int execute_update_try(const std::string& sql, int& ret);

	bool execute_query_string(std::vector<std::string>& output, const std::string& sql);

	
	bool execute_query_vstring(std::vector<std::vector<std::string>>& output, const std::string& sql);

	
	bool execute_query(std::string& output, const std::string& sql, const std::string& name);

	
	bool execute_query_filter(std::string& output, const std::string& sql, const std::string& name, 
		const std::function<bool(const std::string&)>& filter_func);

	bool execute_query_lua(std::string& output, bool b_more, const std::string& sql);

	void set_save_sql_to_log(bool b_val);
	void save_sql_to_log(const std::string& sql);

};
