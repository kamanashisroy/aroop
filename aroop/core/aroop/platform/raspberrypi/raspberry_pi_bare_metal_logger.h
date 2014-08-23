
#ifndef AROOP_CORE_METAL_PI_LOGGER_H_
#define AROOP_CORE_METAL_PI_LOGGER_H_

#include <stdio.h>
C_CAPSULE_START
//#define SYNC_LOG_INIT()
//#define SYNC_LOG_DEINIT()
//#define SYNC_DEBUG_VERB(x, ...)
//#define SYNC_LOG(y, ...)
#define SYNC_LOG_INIT()
#define SYNC_LOG_DEINIT()
#define SYNC_DEBUG_VERB(x, ...) do { \
	if(syncsystem_conf.syn_debug) raspberry_serial_printf("  " __VA_ARGS__); \
}while(0)

#define SYNC_LOG(y, ...) do { \
	if(y==SYNC_DEBUG) \
		raspberry_serial_printf("--" __VA_ARGS__); \
	else if(y==SYNC_VERB) \
		raspberry_serial_printf("  ==" __VA_ARGS__); \
	else if(y==SYNC_NOTICE) \
		raspberry_serial_printf("    Notice: " __VA_ARGS__); \
	else if(y==SYNC_WARNING) \
		raspberry_serial_printf("    Warning: " __VA_ARGS__); \
	else \
		raspberry_serial_printf("    Error: " __VA_ARGS__); \
}while(0)

#define SYNC_LOG_OPP(x) opp_factory_verb(x, NULL, NULL, xultb_log_helper, NULL)

void xultb_log_helper(void*fdptr, const char *fmt, ...);

C_CAPSULE_END

#endif /* AROOP_CORE_METAL_PI_LOGGER_H_ */
