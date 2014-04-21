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
 *  Created on: Jun 29, 2011
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_ANDROID_CONFIG_H
#define AROOP_ANDROID_CONFIG_H

#include <inttypes.h>
#include "unistd.h"
#include "string.h"
#include "stdlib.h"
#include <assert.h>
#include <stdarg.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint8_t SYNC_UWORD8_T;
typedef uint16_t SYNC_UWORD16_T;
typedef uint32_t SYNC_UWORD32_T;

typedef int8_t SYNC_SWORD8_T;
typedef int16_t SYNC_SWORD16_T;
typedef int32_t SYNC_SWORD32_T;

#define SYNC_ASSERT(x) assert(x)

#ifdef __cplusplus
}
#endif

#endif //AROOP_ANDROID_CONFIG_H

