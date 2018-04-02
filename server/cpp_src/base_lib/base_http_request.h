#pragma once

#include <string>
#include "boost/asio.hpp"

bool AsioHttpGet(boost::asio::io_service& io_service,std::string url_, std::string pms, std::string & code_ret, std::string & _code_err);
bool AsioHttpGet_AllMsg(boost::asio::io_service& io_service, std::string url_, std::string & code_ret, std::string & _code_err);

bool AsioHttpPost(boost::asio::io_service& io_service, std::string url_, std::string s_message, std::string & code_ret, std::string & _code_err);
bool AsioHttpPost_AllMsg(boost::asio::io_service& io_service, std::string url_, std::string sMsg, std::string & code_ret, std::string & _code_err, std::string & split);
