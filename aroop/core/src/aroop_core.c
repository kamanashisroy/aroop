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
 * Author:
 * 	Kamanashis Roy (kamanashisroy@gmail.com)
 */


#ifndef AROOP_CONCATENATED_FILE
#include "aroop/aroop_core.h"
#include "aroop/core/thread.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_any_obj.h"
#include "aroop/opp/opp_watchdog.h"
#include "aroop/opp/opp_str2.h"
#include "aroop/opp/opp_queue.h"
#include "aroop/core/memory.h"
#include "aroop/aroop_memory_profiler.h"
#endif

OPP_VOLATILE_VAR SYNC_UWORD16_T core_users = 0; // TODO make it thread safe where 

static int aroop_internal_argc;static char**aroop_internal_argv;
int aroop_get_argc() {
	return aroop_internal_argc;
}

char**aroop_get_argv() {
	return aroop_internal_argv;
}

int aroop_init(int argc, char ** argv) {
	aroop_internal_argc = argc;
	aroop_internal_argv = argv;
#ifdef MTRACE
	mtrace();
#endif
#ifdef SYNC_HAS_ATOMIC_OPERATION
	do {
		volatile SYNC_UWORD16_T oldval,newval;
		oldval = core_users;
		newval = oldval+1;
		SYNC_ASSERT(oldval >= 0 && newval <= 255);
		if(sync_do_compare_and_swap(&core_users, oldval, newval)) {
			break;
		}
	} while(1);
#else
	SYNC_UWORD16_T newval = ++core_users;
#endif
	if(newval) {
		SYNC_ASSERT(opp_factory_profiler_init() == 0);
		opp_any_obj_system_init();
		aroop_txt_system_init();
		opp_str2system_init();
		opp_queuesystem_init();
		opp_watchdog_init();
	}
	return 0;
}

int aroop_main0(int argc, char ** argv, int (*cb)()) {
	aroop_init(argc,argv);
	return cb();
}

int aroop_main1(int argc, char ** argv, int (*cb)(char*args)) {
	int i = 0;
	aroop_init(argc,argv);
	char*args = alloca(argc+1);
	for(i=0;i<argc;i++) {
		args[i] = argv[i];
	}
	args[i] = NULL;
	return cb(args);
}

void aroop_core_gc_unsafe() {
	opp_any_obj_gc_unsafe();
}

#define PROFILER_CRASH_DEBUG
#ifdef PROFILER_CRASH_DEBUG
static int profiler_logger_debug(void*log_data, struct aroop_txt*content) {
	aroop_printf("%s\n", aroop_txt_to_vala_string(content));
	return 0;
}
#endif


int aroop_deinit() {
#ifdef SYNC_HAS_ATOMIC_OPERATION
	volatile SYNC_UWORD16_T oldval,newval;
	do {
		oldval = core_users;
		newval = oldval-1;
		SYNC_ASSERT(oldval >= 0 && newval <= 255)
		if(sync_do_compare_and_swap(&core_users, oldval, newval)) {
			break;
		}
	} while(1);
#else
	SYNC_UWORD16_T newval = --core_users;
#endif
	if(newval == 0) {
		opp_watchdog_deinit();
		opp_any_obj_system_deinit();
		aroop_txt_system_deinit();
		opp_str2system_deinit();
		opp_queuesystem_deinit();
#ifdef PROFILER_CRASH_DEBUG
		aroop_write_output_stream_t log = {NULL, profiler_logger_debug};
		aroop_memory_profiler_dump(log);
#endif
		opp_factory_profiler_deinit();
	}
#ifdef MTRACE
	muntrace();
#endif
	return 0;
}

struct aroop_internal_memory_profiler_dumper {
	aroop_write_output_stream_t log;
	long total_memory_used;
	long total_memory;
};

#define PROFILER_DUMP_LINE_SIZE 256
#ifdef AROOP_OPP_PROFILE
static int aroop_memory_profiler_visitor(void*func_data, void*data) {
	struct opp_factory_profiler_info*x = data;
	struct aroop_internal_memory_profiler_dumper*cb_data = func_data;
	cb_data->total_memory_used += x->obuff->slot_use_count*x->obuff->obj_size;
	cb_data->total_memory += (x->obuff->pool_count*x->obuff->memory_chunk_size);
	struct aroop_txt content;
	aroop_txt_embeded_stackbuffer(&content, PROFILER_DUMP_LINE_SIZE);
	aroop_txt_printf(&content, OPP_FACTORY_PROFILER_DUMP_FMT2()" -- "OPP_FACTORY_DUMP_FMT() "\n", OPP_FACTORY_PROFILER_DUMP_ARG2(x), OPP_FACTORY_DUMP_ARG(x->obuff));
	aroop_txt_zero_terminate(&content);
	cb_data->log.cb(cb_data->log.cb_data, &content);
	//aroop_printf(content.str);
	return 0;
}
#endif

static int aroop_string_buffer_dump_helper(const void*func_data, const void*data) {
	aroop_write_output_stream_t*logger = (aroop_write_output_stream_t*)func_data;
	struct aroop_txt content;
	aroop_txt_embeded_stackbuffer(&content, 1024);
	aroop_txt_printf(&content, "[%s]\n", (char*)data);
	logger->cb(logger->cb_data, &content);
	return 0;
}

void aroop_string_buffer_dump(aroop_write_output_stream_t log) {
	opp_str2system_traverse(aroop_string_buffer_dump_helper, &log);
}

int aroop_memory_profiler_dump(aroop_write_output_stream_t log) {
	struct aroop_internal_memory_profiler_dumper cb_data = {log, 0, 0};
	struct aroop_txt content;
	aroop_txt_embeded_stackbuffer(&content, PROFILER_DUMP_LINE_SIZE);
	aroop_txt_printf(&content, OPP_FACTORY_PROFILER_DUMP_HEADER_FMT2()" -- " OPP_FACTORY_DUMP_HEADER_FMT()"\n", OPP_FACTORY_PROFILER_DUMP_HEADER_ARG2(), OPP_FACTORY_DUMP_HEADER_ARG());
	cb_data.log.cb(cb_data.log.cb_data, &content);
	//aroop_printf(content.str);
	opp_factory_profiler_visit(aroop_memory_profiler_visitor, &cb_data);
	aroop_txt_printf(&content, "%ld bytes total, %ld bytes used\n", cb_data.total_memory, cb_data.total_memory_used);
	aroop_txt_zero_terminate(&content);
	cb_data.log.cb(cb_data.log.cb_data, &content);
	//aroop_printf(content.str);
	return 0;
}
