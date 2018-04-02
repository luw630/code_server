#include "base_http_request.h"

#include <algorithm>
#include <boost/asio.hpp>
#include <boost/bind.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/filesystem.hpp>
#include <boost/function.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/algorithm/string/case_conv.hpp>
#include <boost/algorithm/string/replace.hpp>
#include <boost/algorithm/string/trim.hpp>
#include <boost/algorithm/string/find.hpp>
#include <boost/algorithm/string/erase.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/range.hpp>


#include <boost/algorithm/string.hpp>
#include <boost/range.hpp>
#include <boost/foreach.hpp>
#include <boost/lexical_cast.hpp>


using boost::asio::ip::tcp;
using namespace std;



struct header {
	std::string name;
	std::string value;

	header(const std::string &_name = "", const std::string &_value = "")
		: name(_name), value(_value)
	{}
};

template<typename SequenceSequenceT, typename RangeT, typename FinderT>
SequenceSequenceT& find_split(SequenceSequenceT& Result, RangeT& Input, FinderT Finder,
	boost::algorithm::token_compress_mode_type eCompress = boost::algorithm::token_compress_off)
{
	typedef typename boost::range_iterator<RangeT>::type input_iter_type;
	typedef typename SequenceSequenceT::value_type seq_value_type;

	for (boost::split_iterator<input_iter_type> iter = boost::make_split_iterator(Input, Finder);
		iter != boost::split_iterator<input_iter_type>();
		++iter) {

			if (eCompress == boost::algorithm::token_compress_on) {
				if ((*iter)) {
					Result.push_back(boost::copy_range<seq_value_type>(*iter));
				}
			}
			else {
				Result.push_back(boost::copy_range<seq_value_type>(*iter));
			}
	}

	return Result;
}

struct request {
	std::string method;
	std::string uri;
	int http_version_major;
	int http_version_minor;
	std::vector<header> headers;

	template<typename SequenceT>
	typename boost::range_const_iterator<SequenceT>::type from_string(const SequenceT &buffer)
	{
		typename boost::range_const_iterator<SequenceT>::type _begin, _end;

		_begin = boost::begin(boost::as_literal(buffer));
		_end = boost::end(boost::as_literal(buffer));

		return from_string(_begin, _end);
	}

	template<typename Iterator>
	Iterator from_string(Iterator _begin, Iterator _end)
	{
		unsigned int i;
		const char *methods[] = { "OPTIONS", "GET", "HEAD", "POST", "PUT", "DELETE", "TRACE", "CONNECT" };
		typename boost::iterator_range<Iterator> _input = boost::make_iterator_range(_begin, _end);

		typename boost::iterator_range<Iterator> end_found = boost::find_first(_input, "\r\n\r\n");
		if (!end_found)
			return _begin;

		typename boost::iterator_range<Iterator> found = boost::find_first(_input, "\r\n");
		if (!found)
			return _begin;

		std::vector<typename boost::iterator_range<Iterator> > split_vec;
		typename boost::iterator_range<Iterator> _req_line = boost::make_iterator_range(_begin, found.begin());
		boost::split(split_vec, _req_line, boost::is_space(), boost::algorithm::token_compress_on);
		if (split_vec.size() != 3)
			return _begin;
		if (!boost::starts_with(split_vec[2], "HTTP/", boost::is_iequal()))
			return _begin;

		method = boost::copy_range<std::string>(split_vec[0]);
		for (i = 0; i < sizeof(methods) / sizeof(const char *); i++) {
			if (boost::equals(method, std::string(methods[i]), boost::is_iequal()))
				break;
		}
		if (i == sizeof(methods) / sizeof(const char *)) {
			method = "";
			return _begin;
		}

		uri = boost::copy_range<std::string>(split_vec[1]);

		typename boost::iterator_range<Iterator> ver_range = split_vec[2];
		ver_range.advance_begin(5);
		std::istringstream ss(boost::copy_range<std::string>(ver_range));
		char dot;
		ss >> http_version_major >> dot >> http_version_minor;

		split_vec.clear();
		typename boost::iterator_range<Iterator> _headers = boost::make_iterator_range(found.end(), end_found.end());
		find_split(split_vec, _headers, boost::first_finder("\r\n"), boost::algorithm::token_compress_on);

		headers.clear();
		BOOST_FOREACH(typename boost::iterator_range<Iterator> &aheader, split_vec) {
			found = boost::find_first(aheader, ":");
			if (found) {
				header _h;
				_h.name = boost::copy_range<std::string>(boost::make_iterator_range(aheader.begin(), found.begin()));
				_h.value = boost::copy_range<std::string>(boost::make_iterator_range(found.end(), aheader.end()));
				boost::trim(_h.name);
				boost::trim(_h.value);
				headers.push_back(_h);
			}
		}

		return end_found.end();
	}

	std::size_t to_string_length() const
	{
		std::size_t len = 0;
		std::ostringstream ss;
		std::string http_ver;
		std::vector<header>::const_iterator iter;

		ss << http_version_major << "." << http_version_minor;
		http_ver = ss.str();

		len += method.end() - method.begin();
		len++;
		len += uri.end() - uri.begin();
		len++;
		len += 5; // "HTTP/"
		len += http_ver.end() - http_ver.begin();
		len += 2; // "\r\n"

		for (iter = headers.begin(); iter != headers.end(); ++iter) {
			len += iter->name.end() - iter->name.begin();
			len += 2; // ": "
			len += iter->value.end() - iter->value.begin();
			len += 2; // "\r\n"
		}

		len += 2; // "\r\n"
		return len;
	}

	std::string to_string() const
	{
		std::ostringstream ss;
		std::vector<header>::const_iterator iter;

		ss << method << " " << uri << " " << "HTTP/"
			<< http_version_major << "." << http_version_minor << "\r\n";

		for (iter = headers.begin(); iter != headers.end(); ++iter) {
			ss << iter->name << ": " << iter->value << "\r\n";
		}

		ss << "\r\n";
		return ss.str();
	}

	template<typename Iterator>
	Iterator to_string(Iterator _output) const
	{
		const char *http = "HTTP/";
		const char *crlf = "\r\n";
		const char *sep = ": ";
		std::ostringstream ss;
		std::string http_ver;
		std::vector<header>::const_iterator iter;

		ss << http_version_major << "." << http_version_minor;
		http_ver = ss.str();

		_output = std::copy(method.begin(), method.end(), _output);
		*_output++ = ' ';
		_output = std::copy(uri.begin(), uri.end(), _output);
		*_output++ = ' ';
		_output = std::copy(http, http + 5, _output);
		_output = std::copy(http_ver.begin(), http_ver.end(), _output);
		_output = std::copy(crlf, crlf + 2, _output);

		for (iter = headers.begin(); iter != headers.end(); ++iter) {
			_output = std::copy(iter->name.begin(), iter->name.end(), _output);
			_output = std::copy(sep, sep + 2, _output);
			_output = std::copy(iter->value.begin(), iter->value.end(), _output);
			_output = std::copy(crlf, crlf + 2, _output);
		}

		_output = std::copy(crlf, crlf + 2, _output);
		return _output;
	}
};

struct reply {
	int http_version_major;
	int http_version_minor;
	int reply_code;
	std::string reply_description;
	std::vector<header> headers;

	template<typename SequenceT>
	typename boost::range_const_iterator<SequenceT>::type from_string(const SequenceT &buffer)
	{
		typename boost::range_const_iterator<SequenceT>::type _begin, _end;

		_begin = boost::begin(boost::as_literal(buffer));
		_end = boost::end(boost::as_literal(buffer));

		return from_string(_begin, _end);
	}

	template<typename Iterator>
	Iterator from_string(Iterator _begin, Iterator _end)
	{
		typename boost::iterator_range<Iterator> _input = boost::make_iterator_range(_begin, _end);

		typename boost::iterator_range<Iterator> end_found = boost::find_first(_input, "\r\n\r\n");
		if (!end_found)
			return _begin;

		typename boost::iterator_range<Iterator> found = boost::find_first(_input, "\r\n");
		if (!found)
			return _begin;

		std::vector<typename boost::iterator_range<Iterator> > split_vec;
		typename boost::iterator_range<Iterator> _reply_line = boost::make_iterator_range(_begin, found.begin());
		boost::split(split_vec, _reply_line, boost::is_space());
		if (split_vec.size() < 3)
			return _begin;
		if (!boost::starts_with(split_vec[0], "HTTP/", boost::is_iequal()))
			return _begin;

		typename boost::iterator_range<Iterator> ver_range = split_vec[0];
		ver_range.advance_begin(5);
		std::istringstream ss(boost::copy_range<std::string>(ver_range));
		char dot;
		ss >> http_version_major >> dot >> http_version_minor;

		try {
			reply_code = boost::lexical_cast<int>(boost::copy_range<std::string>(split_vec[1]));
		}
		catch (boost::bad_lexical_cast &) {
			http_version_major = http_version_minor = 0;
			return _begin;
		}

		reply_description = "";
		for (std::size_t i = 2; i < split_vec.size(); i++) {
			reply_description += boost::copy_range<std::string>(split_vec[i]);
			if (i < split_vec.size() - 1)
				reply_description += " ";
		}

		split_vec.clear();
		typename boost::iterator_range<Iterator> _headers = boost::make_iterator_range(found.end(), end_found.end());
		find_split(split_vec, _headers, boost::first_finder("\r\n"), boost::algorithm::token_compress_on);

		headers.clear();
		BOOST_FOREACH(typename boost::iterator_range<Iterator> &aheader, split_vec) {
			found = boost::find_first(aheader, ":");
			if (found) {
				header _h;
				_h.name = boost::copy_range<std::string>(boost::make_iterator_range(aheader.begin(), found.begin()));
				_h.value = boost::copy_range<std::string>(boost::make_iterator_range(found.end(), aheader.end()));
				boost::trim(_h.name);
				boost::trim(_h.value);
				headers.push_back(_h);
			}
		}

		return end_found.end();
	}

	std::size_t to_string_length() const
	{
		std::size_t len = 0;
		std::ostringstream ss;
		std::string http_ver;
		std::string code_str = boost::lexical_cast<std::string>(reply_code);
		std::vector<header>::const_iterator iter;

		ss << http_version_major << "." << http_version_minor;
		http_ver = ss.str();

		len += 5; // "HTTP/"
		len += http_ver.end() - http_ver.begin();
		len++;
		len += code_str.end() - code_str.begin();
		len++;
		len += reply_description.end() - reply_description.begin();
		len += 2; // "\r\n"

		for (iter = headers.begin(); iter != headers.end(); ++iter) {
			len += iter->name.end() - iter->name.begin();
			len += 2; // ": "
			len += iter->value.end() - iter->value.begin();
			len += 2; // "\r\n"
		}

		len += 2; // "\r\n"
		return len;
	}

	std::string to_string() const
	{
		std::stringstream ss;
		std::vector<header>::const_iterator iter;

		ss << "HTTP/" << http_version_major << "." << http_version_minor << " "
			<< reply_code << " " << reply_description << "\r\n";

		for (iter = headers.begin(); iter != headers.end(); ++iter) {
			ss << iter->name << ": " << iter->value << "\r\n";
		}

		ss << "\r\n";
		return ss.str();
	}

	template<typename Iterator>
	Iterator to_string(Iterator _output) const
	{
		const char *http = "HTTP/";
		const char *crlf = "\r\n";
		const char *sep = ": ";
		std::ostringstream ss;
		std::string http_ver;
		std::string code_str = boost::lexical_cast<std::string>(reply_code);
		std::vector<header>::const_iterator iter;

		ss << http_version_major << "." << http_version_minor;
		http_ver = ss.str();

		_output = std::copy(http, http + 5, _output);
		_output = std::copy(http_ver.begin(), http_ver.end(), _output);
		*_output++ = ' ';
		_output = std::copy(code_str.begin(), code_str.end(), _output);
		*_output++ = ' ';
		_output = std::copy(reply_description.begin(), reply_description.end(), _output);
		_output = std::copy(crlf, crlf + 2, _output);

		for (iter = headers.begin(); iter != headers.end(); ++iter) {
			_output = std::copy(iter->name.begin(), iter->name.end(), _output);
			_output = std::copy(sep, sep + 2, _output);
			_output = std::copy(iter->value.begin(), iter->value.end(), _output);
			_output = std::copy(crlf, crlf + 2, _output);
		}

		_output = std::copy(crlf, crlf + 2, _output);
		return _output;
	}
};





std::string findehost(std::string url)
{
	boost::algorithm::to_lower(url);
	boost::algorithm::replace_first(url, "http://", "");
	boost::algorithm::trim(url);
	std::string::iterator iter = boost::algorithm::find_first(url, ":").begin();
	if (std::string(iter._Ptr).length() != 0)
	{
		boost::erase_range(url, boost::make_iterator_range(iter, url.end()));
	}

	std::string::iterator iter_begin = boost::algorithm::find_first(url, "/").begin();
	boost::erase_range(url, boost::make_iterator_range(iter_begin, url.end()));
	return url;
}


std::string IntoString(int i_change)
{
	char s_change[512];
	_itoa_s(i_change, s_change, 10);
	return std::string(s_change);
}

std::string findport(std::string url)
{
	std::string port;
	boost::algorithm::to_lower(url);
	boost::algorithm::replace_first(url, "http://", "");
	boost::algorithm::trim(url);
	std::string::iterator iter = boost::algorithm::find_first(url, ":").begin();
	if (std::string(iter._Ptr).length() != 0)
	{
		std::string::iterator iter_begin = boost::algorithm::find_first(url, "/").begin();
		port.append(iter + 1, iter_begin);
	}
	else
	{
		port = "http";
	}
	return port;
}
std::string findsuburl(std::string url)
{
	std::string sub = "/";
	boost::algorithm::to_lower(url);
	boost::algorithm::replace_first(url, "http://", "");
	boost::algorithm::trim(url);
	std::string::iterator iter = boost::algorithm::find_first(url, "/").begin();
	if (std::string(iter._Ptr).length() != 0)
	{
		sub.append(iter + 1, url.end());
	}
	else
	{
		sub = "";
	}
	return sub;
}

std::string findfile(std::string url)
{
	std::string s_file = "null";
	std::string::iterator iter_end = boost::algorithm::find_last(url, "/").begin();
	std::string s_temp = iter_end._Ptr;
	if (s_temp.length() > 0)
	{
		boost::erase_range(url, boost::make_iterator_range(url.begin(), iter_end + 1));
		s_file = url;
	}
	return s_file;
}



bool AsioHttpPost(boost::asio::io_service& io_service,std::string url_, std::string s_message, std::string & code_ret, std::string & _code_err)
{
	try
	{
		
		tcp::resolver resolver(io_service);
		tcp::resolver::query query(findehost(url_), findport(url_));
		tcp::resolver::iterator endpoint_iterator = resolver.resolve(query);
		tcp::resolver::iterator end;
		tcp::socket socket_(io_service);
		boost::system::error_code error = boost::asio::error::host_not_found;

		while (error && endpoint_iterator != end)
		{
			socket_.close();
			socket_.connect(*endpoint_iterator++, error);
		}

		if (error)
		{
			_code_err = error.message();
			throw boost::system::system_error(error);
			return false;
		}

		boost::asio::streambuf request;
		std::ostream request_stream(&request);
		std::string method = "POST ";
		std::string url_end = " HTTP/1.1\r\n";
		std::string accapet = "Accept: */*\r\n";
		std::string language = "Accept-Language: zh-cn\r\n";
		std::string host = "Host: ";
		std::string s_end = "\r\n";
		std::string content_type = "Content-Type: application/x-www-form-urlencoded";
		std::string content_length = "Content-Length:" + IntoString(s_message.length());
		std::string conn = "Connection: close\r\n";


		std::string request_s = method + findsuburl(url_) + url_end + accapet + language +
			host + findehost(url_) + s_end + content_type + s_end + content_length + s_end + conn + s_end + s_message + s_end;

		request_stream << request_s;
		boost::asio::write(socket_, request);

		boost::asio::streambuf response;

		//boost::asio::read_some(socket_, response, "\r\n");
		boost::system::error_code ec;
		std::string header_infor;
		header_infor.resize(1024 * 10);
		socket_.read_some(boost::asio::buffer(&header_infor[0], 1024 * 10), ec);
		reply reply_;
		const char *addtion = reply_.from_string(header_infor)._Ptr;
		int ir_code = reply_.reply_code;
		if (ir_code != 200)
		{
			_code_err = "?????????????:" + IntoString(ir_code);
			return false;
		}
		if (addtion)
		{
			code_ret.assign(addtion);
			return true;
		}
	}
	catch (std::exception& e)
	{
		code_ret = e.what();
	}
	catch (...)
	{

	}
	return false;
}
bool AsioHttpPost_AllMsg(boost::asio::io_service& io_service, std::string url_, std::string s_message, std::string & code_ret, std::string & _code_err, std::string & split)
{
	try 
	{
		tcp::resolver resolver(io_service);
		tcp::resolver::query query(findehost(url_), findport(url_));
		tcp::resolver::iterator endpoint_iterator = resolver.resolve(query);
		tcp::resolver::iterator end;
		tcp::socket socket_(io_service);
		boost::system::error_code error = boost::asio::error::host_not_found;

		while (error && endpoint_iterator !=end)
		{
			socket_.close();
			socket_.connect(*endpoint_iterator++, error);
		}

		if (error)
		{
			_code_err = error.message();
			throw boost::system::system_error(error);
			return false;
		}

		boost::asio::streambuf request;
		std::ostream request_stream(&request);
		std::string method = "POST " ;
		std::string url_end = " HTTP/1.1\r\n" ;
		std::string accapet = "Accept: */*\r\n" ;
		//std::string boundary = "boundary=----------------------------675526169953038878040223\r\n";
		std::string language = "Accept-Language: zh-cn\r\n";
		std::string accept_type = "Accept-Encoding: deflate\r\n";
		std::string host = "Host: ";
		std::string s_end = "\r\n";
		std::string content_type = "Content-Type: multipart/form-data;";
		if (!split.empty())
		{
			content_type.append(" boundary=").append(split);
		}
		std::string content_length = "Content-Length:"+ IntoString(s_message.length());
		std::string conn = "Connection: close\r\n";

		//+ boundary 
		std::string request_s = method + findsuburl(url_) + url_end + accapet + language + accept_type +
			host + findehost(url_) + s_end + content_type + s_end + content_length + s_end + conn + s_end + s_message;

		request_stream<<request_s;

		boost::asio::write(socket_, request);

		boost::asio::streambuf response;
		//read???????????????????,????????while???,?????????,????????????
		// transfer_at_least ????????transfer_at_least_t????,
		//???????????????,?????????????????????????????,
		//????????????????????,????????1???????????????????
		while (boost::asio::read(socket_, response,boost::asio::transfer_at_least(1), error));
		if (error != boost::asio::error::eof)
			throw boost::system::system_error(error);

		boost::asio::streambuf::const_buffers_type input_buf = response.data();
		std::string header_infor(boost::asio::buffers_begin(input_buf), boost::asio::buffers_end(input_buf));
		reply reply_;
		const char *addtion = reply_.from_string(header_infor)._Ptr;
		int ir_code = reply_.reply_code;
		if (ir_code!=200)
		{
			_code_err = "?????????????:"+ IntoString(ir_code);
			return false;
		}
		if (addtion)
		{
			code_ret.assign(addtion);
			for (auto it=reply_.headers.begin(); it<reply_.headers.end(); it++)
			{
				if (strcmp(it->name.c_str(),"Transfer-Encoding") == 0
					&&
					strcmp(it->value.c_str(),"chunked") == 0)
				{
					while (true)
					{
						if (code_ret.size() > 2)
						{
							if (code_ret.at(0) == 13 && code_ret.at(1) == 10)
							{
								code_ret.erase(0,1);
								code_ret.erase(0,1);
								break;
							}
							code_ret.erase(0,1);
						}
						else
						{
							break;
						}
					}
					//"\r\n0\r\n\r\n"
					int len = strlen("\r\n0\r\n\r\n");
					while (len--)
					{
						if (code_ret.size() > 0)
						{
							code_ret.erase(code_ret.size()-1,1);
						}
					}

					break;
				}
			}
			return true;
		}
	}
	catch (std::exception& e)
	{
		code_ret = e.what();
	}
	return false;
}






bool AsioHttpGet(boost::asio::io_service& io_service, std::string url_, std::string pms, std::string & code_ret, std::string & _code_err)
{
	try
	{

		
		tcp::resolver resolver(io_service);
		tcp::resolver::query query(findehost(url_), findport(url_));
		tcp::resolver::iterator endpoint_iterator = resolver.resolve(query);
		tcp::resolver::iterator end;
		tcp::socket socket_(io_service);
		boost::system::error_code error = boost::asio::error::host_not_found;

		while (error && endpoint_iterator != end)
		{
			socket_.close();
			socket_.connect(*endpoint_iterator++, error);
		}

		if (error)
		{
			_code_err = error.message();
			throw boost::system::system_error(error);
			return false;
		}

		boost::asio::streambuf request;
		std::ostream request_stream(&request);
		std::string method = "GET /";
		std::string url_end = " HTTP/1.1\r\n";
		std::string accapet = "Accept: */*\r\n";
		std::string language = "Accept-Language: zh-cn\r\n";
		std::string host = "Host: ";
		std::string s_end = "\r\n";
		std::string content_type = "Content-Type: application/x-www-form-urlencoded";
		std::string content_length = "Content-Length:0";
		std::string conn = "Connection: close\r\n";


		std::string request_s = method + pms + url_end + accapet + language +
			host + findehost(url_) + s_end + content_type + s_end + content_length + s_end + conn + s_end + "" + s_end;

		request_stream << request_s;
		boost::asio::write(socket_, request);

		boost::asio::streambuf response;

		//boost::asio::read_some(socket_, response, "\r\n");
		boost::system::error_code ec;
		std::string header_infor;
		header_infor.resize(1024 * 10);
		socket_.read_some(boost::asio::buffer(&header_infor[0], 1024 * 10), ec);
		reply reply_;
		const char *addtion = reply_.from_string(header_infor)._Ptr;
		int ir_code = reply_.reply_code;
		if (ir_code != 200)
		{
			_code_err = "?????????????:" + IntoString(ir_code);
			return false;
		}
		if (addtion)
		{
			code_ret.assign(addtion);
			return true;
		}
	}
	catch (std::exception& e)
	{
		code_ret = e.what();
	}
	return false;
}
bool AsioHttpGet_AllMsg(boost::asio::io_service& io_service, std::string url_, std::string & code_ret, std::string & _code_err)
{
	try 
	{
		tcp::resolver resolver(io_service);
		tcp::resolver::query query(findehost(url_), findport(url_));
		tcp::resolver::iterator endpoint_iterator = resolver.resolve(query);
		tcp::resolver::iterator end;
		tcp::socket socket_(io_service);
		boost::system::error_code error = boost::asio::error::host_not_found;

		while (error && endpoint_iterator !=end)
		{
			socket_.close();
			socket_.connect(*endpoint_iterator++, error);
		}

		if (error)
		{
			_code_err = error.message();
			throw boost::system::system_error(error);
			return false;
		}

		boost::asio::streambuf request;
		std::ostream request_stream(&request);
		std::string method = "GET " ;
		std::string url_end = " HTTP/1.1\r\n" ;
		std::string accapet = "Accept: */*\r\n" ;
		std::string language = "Accept-Language: zh-cn\r\n";
		std::string host = "Host: ";
		std::string s_end = "\r\n";
		std::string conn = "Connection: close\r\n";
		std::string request_s = method+url_+ url_end+ accapet + host+findehost(url_) + s_end+ language + conn+ s_end;


		request_stream<<request_s;
		boost::asio::write(socket_, request);


		boost::asio::streambuf response;
		//read???????????????????,????????while???,?????????,????????????
		// transfer_at_least ????????transfer_at_least_t????,
		//???????????????,?????????????????????????????,
		//????????????????????,????????1???????????????????
		while (boost::asio::read(socket_, response,boost::asio::transfer_at_least(1), error));
		if (error != boost::asio::error::eof)
			throw boost::system::system_error(error);

		// 		boost::asio::streambuf response;
		// 		boost::asio::read_until(socket_, response, "\r\n");


		boost::asio::streambuf::const_buffers_type input_buf = response.data();
		std::string header_infor(boost::asio::buffers_begin(input_buf), boost::asio::buffers_end(input_buf));


		reply reply_;
		const char *addtion = reply_.from_string(header_infor)._Ptr;
		int ir_code = reply_.reply_code;
		if (ir_code!=200)
		{
			_code_err = "?????????????:"+ IntoString(ir_code);
			return false;
		}
		if (addtion)
		{
			code_ret.assign(addtion);
			return true;
		}
	}
	catch (std::exception& e)
	{
		code_ret = e.what();
	}
	return false;
}
