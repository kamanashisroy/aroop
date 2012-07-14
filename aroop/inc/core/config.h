#ifndef XULTB_CORE_CONFIG_H
#define XULTB_CORE_CONFIG_H

#define COMPONENT_SCALABILITY 2

#define XULTB_PLATFORM_ENTER(x) x
#define XULTB_PLATFORM_WALK(x) x

#ifdef  QTGUI_LIBRARY
#include "qt_config.h"
#else
#ifdef __EPOC32__
#include "symb_config.h"
#else
#ifdef WIN
#include "win_config.h"
#else
#ifdef ANDROID_XULTB
#include "android_config.h"
#else
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <inttypes.h>
#include <stdarg.h>

typedef uint8_t SYNC_UWORD8_T;
typedef uint16_t SYNC_UWORD16_T;
typedef uint32_t SYNC_UWORD32_T;

typedef int8_t SYNC_SWORD8_T;
typedef int16_t SYNC_SWORD16_T;
typedef int32_t SYNC_SWORD32_T;

#define SYNC_ASSERT(x) assert(x)
#endif // ifdef ANDROID else
#endif // ifdef WIN else
#endif // ifdef __EPOC32__ else
#endif

#include "core/decorator.h"

#endif //XULTB_CONFIG_H
