#pragma once

#include "god_include.h"
#include "base_game_log.h"


#pragma pack(1)

struct MsgHeader
{
	unsigned short							len;		
	unsigned short							id;			
};

struct GateMsgHeader : public MsgHeader
{
	int										guid;		// player
};

#pragma pack()


#define MSG_SEND_BUFFER_SIZE (128 * 1024)
#define MSG_RECV_BUFFER_SIZE (128 * 1024)
#define MSG_WRITE_BUFFER_SIZE (256 * 1024)
#define MSG_READ_BUFFER_SIZE (256 * 1024)
#define MSG_ONE_BUFFER_SIZE 65535


class virtual_session : public std::enable_shared_from_this < virtual_session >
{
protected:
	boost::asio::ip::tcp::socket			socket_;
	int										id_;
	bool									sending_;
	bool									close_after_send_ = false;
public:
	template<size_t N>
	class MsgBuffer
	{
	public:

		MsgBuffer()
			: size_(0)
		{

		}

		char* data() {
			return buf_;
		}
		size_t size() {
			return size_;
		}
		size_t remain() {
			return N - size_;
		}
		bool empty() {
			return 0 == size_;
		}
		bool add(size_t pos)
		{
			if (pos > N - size_)
				return false;
			size_ += pos;
			return true;
		}
		bool push(void* data, size_t len)
		{
			if (len > N - size_)
				return false;
			memcpy(buf_ + size_, data, len);
			size_ += len;
			return true;
		}
		bool push(MsgHeader* msg)
		{
			return push(msg, msg->len);
		}
		void clear() {
			size_ = 0;
		}
		void move(size_t pos)
		{
			if (pos < size_)
			{
				memmove(buf_, buf_ + pos, size_ - pos);
				size_ -= pos;
			}
			else
			{
				size_ = 0;
			}
		}
	private:
		char								buf_[N];
		size_t								size_;
	};
	typedef MsgBuffer<MSG_SEND_BUFFER_SIZE>	MsgSendBuffer;
	typedef MsgBuffer<MSG_RECV_BUFFER_SIZE>	MsgRecvBuffer;
	typedef MsgBuffer<MSG_WRITE_BUFFER_SIZE> MsgWirteBuffer;
	typedef MsgBuffer<MSG_READ_BUFFER_SIZE>	MsgReadBuffer;

protected:
	MsgSendBuffer							send_buf_;
	MsgRecvBuffer							recv_buf_;
	MsgWirteBuffer							write_buf_;
	MsgReadBuffer							read_buf_;
	std::deque<MsgWirteBuffer*>				buf2_write_;
	std::deque<MsgReadBuffer*>				buf2_read_;
	std::recursive_mutex					mutex_;
	time_t									last_msg_time_;
public:
	virtual_session(boost::asio::io_service& ioservice);
	virtual_session(boost::asio::ip::tcp::socket& sock);
	virtual ~virtual_session();
	boost::asio::ip::tcp::socket& socket()
	{
		return socket_;
	}
	int get_id() { return id_; }
	void set_id(int id) { id_ = id; }
	void start();
	virtual bool connect(const char* ip, unsigned short port);
	virtual bool is_connect(){ return socket_.is_open(); };
	virtual bool tick();
	bool send(MsgHeader* msg);
	bool send(void* data, size_t len);
	bool send_spb(unsigned short id, const std::string& pb);
	bool send_c_spb(int guid, unsigned short id, const std::string& pb);
	void set_close_after_send(bool b_val) {
		close_after_send_ = b_val;
	};
	template<typename T> bool send_pb(T* pb)
	{
		try
		{
			std::string str = pb->SerializeAsString();
			return send_spb(T::ID, str);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
		}
		return false;
	}
	bool send_cx(int guid, MsgHeader* header);
	bool send_xc(GateMsgHeader* header);
	template<typename T> bool send_xc_pb(int guid, T* pb)
	{
		try
		{
			std::string str = pb->SerializeAsString();
			return send_c_spb(guid, T::ID, str);
		}
		catch (const std::exception& e)
		{
			LOG_ERR("pb error:%s", e.what());
		}
		return false;
	}
	void post();
	virtual bool dispatch();
	void close();
	virtual bool handler_msg_dispatch(MsgHeader* header);
	virtual bool handler_accept() { return true; };
	virtual bool handler_connect() { return true; };
	virtual void handler_connect_failed() {};
	virtual void on_closed() {}
	unsigned short get_local_ip_port(std::string& ip);
	unsigned short get_remote_ip_port(std::string& ip);
	virtual int get_server_id() { return 0; }
	void start_read();

	void move__buf2_write__to__write_buf_();
	void move__buf2_read__to__read_buf_();
protected:
	void handle_read(const boost::system::error_code& error, size_t bytes_transferred);
	void do_write();
	void handle_write(const boost::system::error_code& error, size_t bytes_transferred);
    virtual void initiative_close_session();
	void reset();
};
