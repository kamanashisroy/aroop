/*
 * This file part of aroop.
 *
 * Copyright (C) 2012  Kamanashis Roy
 *
 * Aroop is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MiniIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Aroop.  If not, see <http://www.gnu.org/licenses/>.
 *
 *      Author: Kamanashis Roy
 */

#ifndef XULTB_CORE_CONFIG_H
#define XULTB_CORE_CONFIG_H

#define COMPONENT_SCALABILITY 2

//#define XULTB_PLATFORM_ENTER(x) x
//#define XULTB_PLATFORM_WALK(x) x

#ifdef ASTERISK_CHANNEL
#ifndef AROOP_CONCATENATED_FILE
#include "ast_config.h"
#endif
#elif defined(QTGUI_LIBRARY)
#ifndef AROOP_CONCATENATED_FILE
#include "qt_config.h"
#endif
#elif defined(__EPOC32__)
#ifndef AROOP_CONCATENATED_FILE
#include "symb_config.h"
#endif
#elif defined(WIN)
#ifndef AROOP_CONCATENATED_FILE
#include "win_config.h"
#endif
#elif defined(AROOP_ANDROID)
#ifndef AROOP_CONCATENATED_FILE
#include "android_config.h"
#endif
#elif defined(RASPBERRY_PI_BARE_METAL)
#ifndef AROOP_CONCATENATED_FILE
#include "raspberry_pi_bare_metal_config.h"
#endif
#else // ANDROID_XULTB
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <inttypes.h>
#include <stdarg.h>
#include <time.h>

typedef uint8_t SYNC_UWORD8_T;
typedef uint16_t SYNC_UWORD16_T;
typedef uint32_t SYNC_UWORD32_T;

typedef int8_t SYNC_SWORD8_T;
typedef int16_t SYNC_SWORD16_T;
typedef int32_t SYNC_SWORD32_T;

#ifdef AROOP_OPP_DEBUG
#define SYNC_ASSERT(x) assert(x)
#else
#define SYNC_ASSERT(x) (x)
#endif
#endif // ifdef ANDROID else

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/decorator.h"
#endif

#define pointer_arith_add_byte(x,y) ({((SYNC_UWORD8_T*)(x))+y;})
#define pointer_arith_sub_byte(x,y) ({((SYNC_UWORD8_T*)(x))-y;})

#ifndef AROOP_MODULE_NAME
#define AROOP_MODULE_NAME "aroop"
#endif

#endif //XULTB_CONFIG_H
