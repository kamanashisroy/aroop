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
 *      Author: Kamanashis Roy
 */

#ifndef OBJ_WATCHDOG_H_
#define OBJ_WATCHDOG_H_

C_CAPSULE_START

enum watchdog_severity {
	WATCHDOG_ALERT = 'A',
	WATCHDOG_NOTICE = 'N',
	WATCHDOG_WARNING = 'W',
	WATCHDOG_ERROR = 'E',
};

#ifdef HAS_WATCHDOG
void opp_watchdog_report(enum watchdog_severity severity, const char *fmt, ...);
int opp_watchdog_walk();
void opp_watchdog_dump(void (*log)(void *log_data, const char*fmt, ...), void*log_data);
int opp_watchdog_init();
int opp_watchdog_deinit();
#else
#define opp_watchdog_report(x, ...)
#define opp_watchdog_walk()
#define opp_watchdog_dump(x, ...)
#define opp_watchdog_init()
#define opp_watchdog_deinit()
#endif

C_CAPSULE_END

#endif /* OBJ_WATCHDOG_H_ */
