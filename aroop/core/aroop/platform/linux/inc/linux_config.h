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

#ifndef XULTB_LINUX_CONFIG_H
#define XULTB_LINUX_CONFIG_H

#include <inttypes.h>
#include "unistd.h"
#include "string.h"
#include "stdlib.h"
#include <assert.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef quint8 SYNC_UWORD8_T;
typedef quint16 SYNC_UWORD16_T;
typedef quint32 SYNC_UWORD32_T;

typedef qint16 SYNC_SWORD16_T;
typedef qint32 SYNC_SWORD32_T;

#ifdef AROOP_OPP_DEBUG
#define SYNC_ASSERT(x) assert(x)
#endif

#ifdef __cplusplus
}
#endif

#endif //XULTB_LINUX_CONFIG_H

