//
// TODO: Switch to CBC block cipher
//

// #define PASS_DEBUG 1

#define AES128 1
#define ECB 1

extern "C" {
#include "tiny-AES-c/aes.h"
}
#include <cstring>
#include <cstdio>
#include "password_encrypt.h"

static bool require_init = true;
static uint8_t encryption_key[] = {0x2b, 0x7e, 0x16, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab,
		0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c};
static uint8_t iv[] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a,
		0x0b, 0x0c, 0x0d, 0x0e, 0x0f};
static struct AES_ctx ctx;
static const char *password_file_path = "pass.bin";

constexpr std::size_t buffer_len = AES_BLOCKLEN;

static_assert(64 % AES_BLOCKLEN == 0);

bool setUserPassword(const char *password)
{
	if (password == nullptr || password[0] == '\0') {
		clearUserPassword();
		return true;
	}

#ifdef PASS_DEBUG
	printf("Setting pass: %s\n", password);
#endif

	const std::size_t password_len = std::strlen(password);
	if (require_init) {
#ifdef PASS_DEBUG
		printf("Doing init\n");
#endif
		AES_init_ctx_iv(&ctx, encryption_key, iv);
		require_init = false;
	}

	char buffer[buffer_len];
	memset(buffer, 0, buffer_len);
	memcpy(buffer, password, password_len);

#ifdef PASS_DEBUG
	printf("Encrypting pass: %s\n", buffer);
#endif
	// AES_CBC_encrypt_buffer(&ctx, reinterpret_cast<uint8_t*>(buffer), 64);
	AES_ECB_encrypt(&ctx, reinterpret_cast<uint8_t *>(buffer));

	FILE *password_fp = fopen(password_file_path, "w+b");
	if (!password_fp) {
#ifdef PASS_DEBUG
		printf("Failed to open pass file\n");
#endif
		return false;
	}
#ifdef PASS_DEBUG
	printf("Writing encrypted pass to file: %s\n", buffer);
#endif

	const std::size_t bytes_written = fwrite(buffer, buffer_len, 1, password_fp);
	fclose(password_fp);

	if (bytes_written != 1) {
		return false;
	}

#ifdef PASS_DEBUG
	printf("Decrypt test..\n");
	// AES_CBC_decrypt_buffer(&ctx, reinterpret_cast<uint8_t*>(buffer), 64);
	AES_ECB_decrypt(&ctx, reinterpret_cast<uint8_t *>(buffer));
	printf("Decrypted pass: %s\n", buffer);
#endif

	return true;
}

const char *getUserPassword()
{
#ifdef PASS_DEBUG
	printf("Getting pass\n");
#endif

	if (require_init) {
#ifdef PASS_DEBUG
		printf("Doing init\n");
#endif
		AES_init_ctx_iv(&ctx, encryption_key, iv);
		require_init = false;
	}
#ifdef PASS_DEBUG
	printf("Opening password file\n");
#endif
	FILE *password_fp = fopen(password_file_path, "rb");
	if (!password_fp) {
#ifdef PASS_DEBUG
		printf("Failed to open file\n");
#endif
		return nullptr;
	}

	static char buffer[buffer_len];
	memset(buffer, 0, buffer_len);

	const std::size_t bytes_read = fread(buffer, buffer_len, 1, password_fp);
	fclose(password_fp);

	if (bytes_read != 1) {
#ifdef PASS_DEBUG
		printf("Error: Only read %llu bytes\n", bytes_read);
#endif
		return nullptr;
	}

#ifdef PASS_DEBUG
	printf("Decrypting: %s\n", buffer);
#endif
	// AES_CBC_decrypt_buffer(&ctx, reinterpret_cast<uint8_t*>(buffer), 64);
	AES_ECB_decrypt(&ctx, reinterpret_cast<uint8_t *>(buffer));

#ifdef PASS_DEBUG
	printf("Returning user password: %s\n", buffer);
#endif

	return buffer;
}

void clearUserPassword()
{
#ifdef PASS_DEBUG
	printf("Clearing password\n");
#endif
	remove(password_file_path);
}