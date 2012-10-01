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
 *  Created on: Dec 29, 2010
 *      Author: Kamanashis Roy
 */

#ifndef SYNC_MEMORY_H
#define SYNC_MEMORY_H

#include "core/config.h"

#ifdef __EPOC32___CLIENT
#if 0
#define USE_SYMBIAN_ALLOC
void*symb_malloc(size_t size);
void symb_free(void*memory);
#define sync_malloc symb_malloc
#define sync_free symb_free
#else
#define sync_malloc malloc
#define sync_free free
#endif
#else
#define sync_malloc malloc
#define sync_free free
#endif


#define SYNC_EMPTY_STRING(x) ({(!x||*x == '\0');})

#define SYNC_ARRAY_LEN(a) (sizeof(a) / sizeof(0[a]))

#define STR_OR(x,y) (x?x:y)

#endif // SYNC_MEMORY_H
