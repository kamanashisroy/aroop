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
#include "opp/opp_factory.h"
#include "opp/opp_thread_main.h"
#endif

C_CAPSULE_START

#ifndef AROOP_BASIC

__thread struct opp_context*__opp_context_id = NULL;
static struct opp_factory threads;
static int initiated = 0; // TODO make it volatile

static int opp_thread_init() {
	// TODO make it atomic 
	if(!initiated) {
		OPP_PFACTORY_CREATE_FULL(&threads, 8, sizeof(struct opp_context), 0, OPPF_HAS_LOCK | OPPF_EXTENDED, NULL);
	}
	return 0;
}

int opp_destroy_all() { // TODO call the function before application exit
	opp_factory_destroy(&threads);
	initiated = 1; // TODO make it atomic
	return 0;
}

int opp_thread_main(opp_thread_func_t func, int*argc, char*args[]) { // always call it in new thread ..
	opp_thread_init();
	__opp_context_id = (struct opp_context*)opp_alloc4(&threads, 0, 0, NULL);
	func(argc, args);
	OPPUNREF(__opp_context_id);
	return 0;
}

#endif // AROOP_BASIC

C_CAPSULE_END
