#ifndef AROOP_CORE_METAL_PI_CONFIG_H
#define AROOP_CORE_METAL_PI_CONFIG_H

#include <stdint.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint8_t SYNC_UWORD8_T;
typedef uint16_t SYNC_UWORD16_T;
typedef uint32_t SYNC_UWORD32_T;

typedef int16_t SYNC_SWORD16_T;
typedef int32_t SYNC_SWORD32_T;

typedef __SIZE_TYPE__ size_t;
//typedef int32_t size_t;

#define NULL 0
#define aroop_printf(...) ({raspberry_serial_printf(__VA_ARGS__);})
int raspberry_serial_printf(char*format, ...);
#define aroop_snprintf(...) ({raspberry_snprintf(__VA_ARGS__);})
int raspberry_snprintf(char*format, ...);

#ifdef __GNUC__
#define alloca(size) __builtin_alloca(size)
#else
#error("You need to define alloca\n")
#endif

#ifdef AROOP_OPP_DEBUG
#define SYNC_ASSERT(x) assert(x)
#else
#define SYNC_ASSERT(x) ({(x) && 1;})
#endif

#ifdef __cplusplus
}
#endif

#endif //AROOP_CORE_METAL_PI_CONFIG_H

