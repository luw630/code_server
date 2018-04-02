#pragma once

#include <iostream>
class crypto_manager
{
	crypto_manager() = delete;
public:
	static std::string to_hex(const std::string & src);

	static std::string from_hex(const std::string & src);

	static std::string md5(const std::string& src);

	static void rsa_key(std::string& public_key, std::string& private_key);

	static std::string rsa_encrypt(const std::string& public_key, const std::string& src);

	static std::string rsa_decrypt(const std::string& private_key,const std::string &src);
};

