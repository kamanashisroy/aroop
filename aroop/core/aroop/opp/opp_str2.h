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
 *  Created on: Mar 2, 2011
 *      Author: Kamanashis Roy
 */

#ifndef OPP_STR2_H_
#define OPP_STR2_H_

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#include "aroop/opp/opp_factory.h"
#endif

C_CAPSULE_START

char*opp_str2_reuse(char*string, int len);
void opp_str2_reuse2(char**dest, char*string, int len);
char*opp_str2_dup(const char*string, int len);
void opp_str2_dup2(char**dest, const char*string, int len);
char*opp_str2_alloc(int size);
void opp_str2_alloc2(char**dest, int size);

void opp_str2system_traverse(void*cb, void*cb_data);
void opp_str2system_init();
void opp_str2system_deinit();

C_CAPSULE_END

#endif /* OPP_STR2_H_ */
