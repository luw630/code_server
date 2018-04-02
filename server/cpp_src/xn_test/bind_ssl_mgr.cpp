#include "base_lua_mgr.h"
#include "CryptoManager.h"


static std::string crypto_encrypt_password(const char* public_key, const char* password)
{
	std::string pwd = CryptoManager::rsa_encrypt(CryptoManager::from_hex(public_key), CryptoManager::md5(password));
	return CryptoManager::to_hex(pwd);
}

void bind_lua_crypto_message(lua_State* L)
{
	lua_tinker::def(L, "crypto_encrypt_password", crypto_encrypt_password);
}
