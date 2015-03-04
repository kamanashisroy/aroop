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

#ifndef OPP_FACTORY_PROFILER_H
#define OPP_FACTORY_PROFILER_H

/**
 *
 * This is an implementation of object based information
 * manipulation system. Please use "opp_" prefix in the
 * variable name. And remember to OPPUNREF()
 * that object.
 */

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#endif

C_CAPSULE_START

#ifdef AROOP_OPP_PROFILE
struct opp_factory_profiler_info {
	char*source_file;
	int source_line;
	char*module_name;
	struct tm birth;
	struct opp_factory*obuff;
};

int opp_factory_create_full_and_profile(struct opp_factory*obuff
		, SYNC_UWORD16_T inc
		, SYNC_UWORD16_T obj_size
		, int token_offset
		, unsigned char property
		, opp_callback_t callback
		, char*source_file, int source_line, char*module_name
	);
int opp_factory_destroy_and_remove_profile(struct opp_factory*src);

int opp_factory_profiler_init();
int opp_factory_profiler_deinit();
void opp_factory_profiler_visit(obj_do_t obj_do, void*func_data);

void opp_factory_profiler_get_total_memory(int*grasped,int*really_allocated);
void*profiler_replace_malloc(size_t size);
void profiler_replace_free(void*ptr, size_t size);

void opp_factory_profiler_checkleak_debug();
#else
#define opp_factory_create_full_and_profile(obuff,inc,obj_size,token_offset,property,callback,source_file,source_line,module_name) opp_factory_create_full(obuff,inc,obj_size,token_offset,property,callback)
#define opp_factory_destroy_and_remove_profile opp_factory_destroy_use_profiler_instead
#define opp_factory_profiler_init() ({0;})
#define opp_factory_profiler_deinit() ({0;})
#define opp_factory_profiler_visit(x, y) ({0;})
#define opp_factory_profiler_get_total_memory(x,y) ({0;})
#define profiler_replace_malloc sync_malloc
#define profiler_replace_free(x,y) sync_free(x)
#define opp_factory_profiler_checkleak_debug()

#endif
//#define opp_factory_profiler_checkleak() opp_factory_profiler_checkleak_debug()
#define opp_factory_profiler_checkleak()

#define OPP_FACTORY_PROFILER_DUMP_HEADER_FMT() "%-20.20s %-5.5s %-10.10s %-10.10s"
#define OPP_FACTORY_PROFILER_DUMP_HEADER_ARG() "Source","Line", "Module","Birth"
#define OPP_FACTORY_PROFILER_DUMP_FMT() "%-20.20s %5d %-10.10s %s"
#define OPP_FACTORY_PROFILER_DUMP_ARG(x) STR_OR((x)->source_file, ""), (x)->source_line, STR_OR((x)->module_name, ""), asctime(&(x)->birth)

#define OPP_FACTORY_PROFILER_DUMP_HEADER_FMT2() "%-20.20s %-5.5s %-10.10s"
#define OPP_FACTORY_PROFILER_DUMP_HEADER_ARG2() "Source","Line", "Module"
#define OPP_FACTORY_PROFILER_DUMP_FMT2() "%-20.20s %5d %-10.10s"
#define OPP_FACTORY_PROFILER_DUMP_ARG2(x) STR_OR((x)->source_file, ""), (x)->source_line, STR_OR((x)->module_name, "")

#define OPP_PFACTORY_CREATE_FULL(obuff, psize, objsize, tokenstart, property, cb) ({opp_factory_create_full_and_profile(obuff, psize, objsize, tokenstart, property, cb, __FILE__, __LINE__, AROOP_MODULE_NAME);})
#define OPP_PFACTORY_CREATE(obuff, x, y, z) ({opp_factory_create_full_and_profile(obuff, x, y, 1, OPPF_HAS_LOCK | OPPF_SWEEP_ON_UNREF, z, __FILE__, __LINE__, AROOP_MODULE_NAME);})
#define OPP_PFACTORY_DESTROY(x) opp_factory_destroy_and_remove_profile(x)


#ifdef AROOP_OPP_DEBUG
void opp_factory_profiler_assert_no_module(char*module_name);
#else
#define opp_factory_profiler_assert_no_module(x) 
#endif

C_CAPSULE_END

#endif // OPP_FACTORY_PROFILER_H
