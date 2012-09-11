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


#include "aroop_core.h"
#include "core/thread.h"
#include "opp/opp_factory.h"
#include "opp/opp_any_obj.h"

OPP_VOLATILE_VAR SYNC_UWORD16_T core_users = 0; // TODO make it thread safe where 

int aroop_init(int argc, char ** argv) {
#ifdef SYNC_HAS_ATOMIC_OPERATION
	do {
		volatile SYNC_UWORD16_T oldval,newval;
		oldval = core_users;
		newval = oldval+1;
		SYNC_ASSERT(oldval >= 0 && newval <= 255)
		if(sync_do_compare_and_swap(&core_users, oldval, newval)) {
			break;
		}
	} while(1);
#else
	core_users++;
#endif
	opp_any_obj_system_init();
	aroop_txt_system_init();
}

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
	SYNC_UWORD16_T newval = core_users--;
#endif
	if(newval == 0) {
		opp_any_obj_system_deinit();
		aroop_txt_system_deinit();
	}
}
