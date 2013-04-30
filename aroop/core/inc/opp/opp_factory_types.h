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
 *  Created on: Jun 17, 2011
 *      Author: kamanashisroy@gmail.com
 */

#ifndef OPP_FACTORY_TYPES_H
#define OPP_FACTORY_TYPES_H

/**
 *
 * This is an implementation of object based information
 * manipulation system. Please use "opp_" prefix in the
 * variable name. And remember to OPPUNREF()
 * that object.
 */

#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#include "core/thread.h"
#endif

#ifdef SYNC_HAS_ATOMIC_OPERATION
#define OPP_VOLATILE_VAR volatile
#else
#define OPP_VOLATILE_VAR
#endif

#ifndef C_CAPSULE_START
#ifdef __cplusplus
#define C_CAPSULE_START extern "C" {
#define C_CAPSULE_END }
#else
#define C_CAPSULE_START
#define C_CAPSULE_END
#endif
#endif

C_CAPSULE_START

typedef SYNC_UWORD32_T opp_hash_t;
#define OPP_OBJECT_EXT_TINY() opp_hash_t hash;OPP_VOLATILE_VAR SYNC_UWORD16_T flag,token;
#define OPP_RBTREE
#ifndef OBJ_COMP_T
#define OBJ_COMP_T
typedef int (*obj_do_t)(void*func_data, void*data);
typedef int (*obj_comp_t)(const void*func_data, const void*data);
#endif


C_CAPSULE_END

#endif // OPP_FACTORY_TYPES_H
