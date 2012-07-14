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

#ifndef OPP_ANY_OBJ_H_
#define OPP_ANY_OBJ_H_


#include "core/config.h"
#include "opp/opp_factory.h"

C_CAPSULE_START

void*opp_any_obj_alloc(int size, opp_callback_t cb, ...);

void opp_any_obj_system_init();
void opp_any_obj_system_deinit();


C_CAPSULE_END

#endif /* OPP_ANY_OBJ_H_ */
