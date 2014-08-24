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

#ifndef LINUX_LOGGER_H_
#define LINUX_LOGGER_H_

#include <stdio.h>
C_CAPSULE_START
//#define SYNC_LOG_INIT()
//#define SYNC_LOG_DEINIT()
//#define SYNC_DEBUG_VERB(x, ...)
//#define SYNC_LOG(y, ...)
#define SYNC_LOG_INIT()
#define SYNC_LOG_DEINIT()
#define SYNC_DEBUG_VERB(x, ...) do { \
	if(syncsystem_conf.syn_debug) printf("  " __VA_ARGS__); \
}while(0)

#define SYNC_LOG(y, ...) do { \
	if(y==SYNC_DEBUG) \
		printf("--" __VA_ARGS__); \
	else if(y==SYNC_VERB) \
		printf("  ==" __VA_ARGS__); \
	else if(y==SYNC_NOTICE) \
		printf("    Notice: " __VA_ARGS__); \
	else if(y==SYNC_WARNING) \
		printf("    Warning: " __VA_ARGS__); \
	else \
		printf("    Error: " __VA_ARGS__); \
}while(0)

#define SYNC_LOG_OPP(x) opp_factory_verb(x, NULL, NULL, xultb_log_helper, NULL)

void xultb_log_helper(void*fdptr, const char *fmt, ...);

C_CAPSULE_END

#endif /* LINUX_LOGGER_H_ */
