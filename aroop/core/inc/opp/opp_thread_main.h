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

#ifndef OPP_THREAD_MAIN_H_
#define OPP_THREAD_MAIN_H_


#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#endif

C_CAPSULE_START

#ifndef AROOP_BASIC
struct opp_context {
	OPP_OBJECT_EXT_TINY();
	struct opp_factory objs;
};

typedef int (*opp_thread_func_t) (int*argc, char*args[]);
int opp_thread_main(opp_thread_func_t func, int*argc, char*args[]);
#endif

C_CAPSULE_END

#endif /* OPP_THREAD_MAIN_H_ */
