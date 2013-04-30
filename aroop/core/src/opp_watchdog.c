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
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_CONCATENATED_FILE
#include "opp/opp_queue.h"
#include "opp/opp_str2.h"
#include "opp/opp_watchdog.h"
//#include "core/net.h"
#include "core/logger.h"
#endif

#ifdef HAS_WATCHDOG
struct watchdog {
	int len;
	int off;
	SYNC_UWORD8_T severity;
	char message[0];
};

static int dogpipe[2];
static struct opp_queue dogqueue;
#include <stdarg.h>
#include <execinfo.h>
void opp_watchdog_report(enum watchdog_severity severity, const char *fmt, ...) {
	va_list ap;
#define WATCHDOG_INT_SIZE 5
#define WATCHDOG_BUFFER_SIZE 1024
	char buffer[WATCHDOG_BUFFER_SIZE];
#define BT_SIZE 4
	void*bt[BT_SIZE];
	int nptrs, i, len = 0;
	char**symbols;

	buffer[0] = severity;
	len++;
	len+=WATCHDOG_INT_SIZE;
	va_start(ap, fmt);
	len += vsnprintf(buffer+len, WATCHDOG_BUFFER_SIZE - len, fmt, ap);
	va_end(ap);

	nptrs = backtrace(bt, BT_SIZE);
	symbols = backtrace_symbols(bt, nptrs);
	if(!symbols) {
		return;
	}
	for(i=1;i<nptrs;i++) {
		len += snprintf(buffer+len, WATCHDOG_BUFFER_SIZE - len, "%s\n", symbols[i]);
	}

	free(symbols);
	snprintf(buffer+1, WATCHDOG_INT_SIZE, "%04d", len);
	write(dogpipe[1], buffer, len);
	fsync(dogpipe[1]);
}

struct opp_watchdog_dumper_data {
	void (*log)(void *log_data, const char*fmt, ...);
	void*log_data;
};

static int opp_watchdog_dumper(void*data, void*func_data) {
	struct opp_watchdog_dumper_data*dumper = func_data;
	struct watchdog*event = data;
	dumper->log(dumper->log_data, "[-%s-]:%s\n"
			, event->severity == 'A'? "Alert":(event->severity == 'N'?"Notice":(event->severity == 'W'?"Warning":"Error"))
			, event->message);
	dumper->log(dumper->log_data, "================================\n");
	return 0;
}

void opp_watchdog_dump(void (*log)(void *log_data, const char*fmt, ...), void*log_data) {
	struct opp_watchdog_dumper_data dumper = {.log = log, .log_data = log_data};
	opp_queue_do_full_on_stack(&dogqueue, opp_watchdog_dumper, &dumper);
}


static struct watchdog*native_event = NULL;
static int opp_watchdog_walk_internal() {
	int recvsize = 0,len = 0;
	sync_recvsize(dogpipe[0], &recvsize, 1024);
	if(recvsize <= 0) {
		return -1;
	}
	if(!native_event && recvsize < 11) {
		return 0;
	}
	if(!native_event) {
		char buffer[WATCHDOG_INT_SIZE+2];
		if((WATCHDOG_INT_SIZE+1) != read(dogpipe[0], buffer, WATCHDOG_INT_SIZE+1)) {
			SYNC_LOG(SYNC_ERROR, "Watchdog pipe has invalid data:------------\n");
			return -1;
		}
		recvsize -= WATCHDOG_INT_SIZE+1;
		buffer[WATCHDOG_INT_SIZE+1] = '\0';
//		SYNC_LOG(SYNC_ERROR, "<<%s\n", buffer+1);
		len = atoi(buffer+1);
//		SYNC_LOG(SYNC_ERROR, "%d,%d\n", len, recvsize);
		native_event = (struct watchdog*)opp_str2_alloc(sizeof(struct watchdog)+len);
		if(!native_event) {
			return -1;
		}
		native_event->off = 0;
		native_event->len = len - WATCHDOG_INT_SIZE - 1;
		native_event->severity = *buffer;
	}


	native_event->off+= read(dogpipe[0], native_event->message+native_event->off, native_event->len - native_event->off);
	if(native_event->off < native_event->len-1) {
		return 0;
	}
	native_event->message[native_event->off] = '\0';
	opp_enqueue(&dogqueue, native_event);
	OPPUNREF(native_event);
	while(OPP_QUEUE_SIZE(&dogqueue) > 32) {
		native_event = opp_dequeue(&dogqueue);
		OPPUNREF(native_event);
	}
	return 0;
}

int opp_watchdog_walk() {
	int i;
	for(i=0;i<10 && !opp_watchdog_walk_internal();i++);
	return 0;
}

int opp_watchdog_init() {
	native_event = NULL;
	return (opp_queue_init2(&dogqueue, COMPONENT_SCALABILITY+1) || pipe(dogpipe));
}

int opp_watchdog_deinit() {
	native_event = NULL;
	return (opp_queue_deinit(&dogqueue) || close(dogpipe[0]) || close(dogpipe[1]));
}
#endif
