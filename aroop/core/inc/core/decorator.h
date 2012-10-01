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

#ifndef XULTB_DECORATOR_H
#define XULTB_DECORATOR_H

#define XULTB_CORE_UNIMPLEMENTED() assert(!"Unimplemented")

#define XULTB_ASSERT_RETURN(x,y) ({if(!(x)) return y;})


#ifdef __cplusplus
#define C_FUNCTION extern "C"
#define C_CAPSULE_START extern "C" {
#define C_CAPSULE_END }
//#define ST_ASS(x,y) x:y
#else
#define C_FUNCTION
#define C_CAPSULE_START
#define C_CAPSULE_END
//#define ST_ASS(x,y) .x=y
#endif

#define UNUSED_VAR(x)

#endif
