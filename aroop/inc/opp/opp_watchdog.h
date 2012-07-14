/*
 * obj_watchdog.h
 *
 *  Created on: Jun 17, 2011
 *      Author: ayaskanti
 */

#ifndef OBJ_WATCHDOG_H_
#define OBJ_WATCHDOG_H_

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

#endif /* OBJ_WATCHDOG_H_ */
