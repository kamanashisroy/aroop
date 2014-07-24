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
#include "aroop/aroop_factory.h"
#endif

struct aroop_factory_action_data_internal {
	int action;
	unsigned int flag;
};

static int opp_factory_do_all_helper(void*func_data, void*target) {
	struct aroop_factory_action_data_internal*adata = (struct aroop_factory_action_data_internal*)func_data;
	switch(adata->action) {
	case 0:
		opp_unset_flag(target, adata->flag);
		break;
	case 1:
		opp_set_flag(target, adata->flag);
		break;
	case -1:
		OPPUNREF(target);
		break;
	default:
		SYNC_ASSERT(0);
		break;
	}
	return 0;
}

int aroop_factory_action_all_internal(struct opp_factory*fac, int action, unsigned int flag) {
	struct aroop_factory_action_data_internal data = {action, flag};
	opp_factory_do_full(fac, opp_factory_do_all_helper, &data, action == 1?OPPN_ALL:flag, 0, 0);
}

