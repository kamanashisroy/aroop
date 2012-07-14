/*
 * opp_list.c
 *
 *  Created on: Feb 9, 2011
 *      Author: root
 */

#include "opp/opp_factory.h"
#include "opp/opp_list.h"
#include "opp/opp_iterator.h"

C_CAPSULE_START

OPP_CB(list_item) {
	struct opp_list_item*item = (struct opp_list_item*)data;

	switch(callback) {
	case OPPN_ACTION_INITIALIZE:
		item->obj_data = (void*)cb_data;
		OPPREF(item->obj_data);
		break;
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(item->obj_data);
		break;
	}


	return 0;
}

struct opp_list_item*opp_list_add_noref(struct opp_factory*olist, void*obj_data) {
	struct opp_list_item*item = (struct opp_list_item*)OPP_ALLOC2(olist, obj_data);
	// link
	if(!item) {
		return NULL;
	}

	OPPUNREF(obj_data);
	return item;
}

int opp_list_create2(struct opp_factory*olist, int pool_size, unsigned int flag) {
	return opp_factory_create_full(olist, pool_size
			, sizeof(struct opp_list_item)
			, 1, flag | OPPF_SWEEP_ON_UNREF
			, OPP_CB_FUNC(list_item));
}

struct opp_find_list_helper {
	int (*compare_func)(const void*data, const void*compare_data);
	const void*compare_data;
	struct opp_factory*olist;
	int count;
};

static int opp_factory_list_compare(void*data, void*func_data) {
	struct opp_find_list_helper*helper = (struct opp_find_list_helper*)func_data;

	if(helper->compare_func(data, helper->compare_data)) {
		return 0;
	}

	OPP_ALLOC2(helper->olist, data);
	return 0;
}

static int opp_list_prune_helper(void*data, void*target) {
	if(((struct opp_list_item*)data)->obj_data == target) {
		OPPUNREF(data);
	}
	return 0;
}

int opp_list_prune(struct opp_factory*olist, void*target, int if_flag, int if_not_flag, int hash) {
	opp_factory_do_full(olist, opp_list_prune_helper, target, if_flag, if_not_flag, hash);
	return 0;
}

int opp_list_find_from_factory(struct opp_factory*obuff, struct opp_factory*olist
		, int (*compare_func)(const void*data, const void*compare_data), const void*compare_data) {
	struct opp_find_list_helper helper = {
#ifdef __cplusplus
			compare_func, compare_data, olist, 0
#else
			.compare_func = compare_func,
			.compare_data = compare_data,
			.olist = olist,
			.count = 0,
#endif
	};

	OPP_FACTORY_DO(obuff, opp_factory_list_compare, &helper);
	return helper.count;
}

C_CAPSULE_END
