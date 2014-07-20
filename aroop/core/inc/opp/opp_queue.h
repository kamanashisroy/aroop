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
 *  Created on: Feb 9, 2011
 *      Author: Kamanashis Roy
 */

#ifndef OPP_QUEUE_H
#define OPP_QUEUE_H
#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#include "core/thread.h"
#endif

C_CAPSULE_START

enum {
	OBJ_QUEUE_RETRUN_UNLINK = -99,
	OBJ_QUEUE_STACK_ALLOC = 255,
};

#ifdef SYNC_HAS_ATOMIC_OPERATION
#define SYNC_USE_LOCKFREE_QUEUE
#endif

#ifdef SYNC_USE_LOCKFREE_QUEUE
#define SYNC_QUEUE_VOLATILE_VAR volatile
#else
#define SYNC_QUEUE_VOLATILE_VAR
#endif

struct opp_queue_item {
	void*obj_data;
	SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*opp_internal_next;
};

/* using freelist solves the repeatative memory allocation and locking problem .. anyway it creates fragmentation */
//#define USE_FREELIST

struct opp_queue {
	SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*opp_internal_tail;
#ifdef SYNC_USE_LOCKFREE_QUEUE
#ifdef USE_FREELIST
	SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*opp_internal_freelist;
#endif
	struct opp_queue_item opp_internal_head_node,opp_internal_free_node;
#else
	struct opp_queue_item*opp_internal_first;
#endif
	SYNC_UWORD16_T opp_internal_usec;
	SYNC_UWORD8_T opp_internal_sign;
	SYNC_UWORD8_T opp_internal_factory_idx;
};

typedef struct opp_queue opp_queue_t;

#define OPP_QUEUE_SIZE(q) ({(q)->opp_internal_usec;})

int opp_enqueue(struct opp_queue*queue, void*obj_data);
void*opp_dequeue(struct opp_queue*queue);
#if 0
int opp_queue_init(struct opp_queue*queue);
#endif
int opp_queue_init2(struct opp_queue*queue, int scindex);
int opp_queue_deinit(struct opp_queue*queue);
int opp_queue_do_full_on_stack(struct opp_queue*queue, int (*func)(void*data, void*func_data), void*func_data);
int opp_queue_do_full(struct opp_queue*queue, int (*func)(void*data, void*func_data), void*func_data);
int opp_queue_do_full_unsafe(struct opp_queue*queue, int (*func)(void*data, void*func_data), void*func_data);

void opp_queuesystem_verb(void (*log)(void *log_data, const char*fmt, ...), void*log_data);
int opp_queuesystem_init();
void opp_queuesystem_deinit();

#define OPP_QUEUE_DECLARE_STACK(x,y) char opp_internal_x##buf[sizeof(struct opp_queue)+sizeof(struct opp_factory)];struct opp_queue*x = (struct opp_queue*)opp_internal_x##buf;struct opp_factory*opp_internal_x##fac = (struct opp_factory*)(x+1);do { \
	opp_internal_x##fac->sign = 0; \
	SYNC_ASSERT(!opp_factory_create_full(opp_internal_x##fac, y, sizeof(struct opp_queue_item), 1, OPPF_SWEEP_ON_UNREF, NULL)); \
	opp_factory_create_pool_donot_use(_x##fac, NULL, alloca(opp_internal_x##fac->memory_chunk_size)); \
	opp_queue_init2(x, OBJ_QUEUE_STACK_ALLOC); \
}while(0);

#define OPP_QUEUE_DESTROY_STACK(x) ({opp_queue_deinit(x);opp_factory_destroy(opp_internal_x##fac);})

#ifdef TEST_OBJ_FACTORY_UTILS
void*opp_queue_test_thread_run(void*notused);
int opp_queue_test_init();
int opp_queue_test_deinit();
/*
  	const int threadcount = 10;
	int i;
	pthread_t ths[100];
	pthread_attr_t att[100];
	opp_queue_test_init();
	SYNC_ASSERT(threadcount <= 100);
	printf("Starting threads\n");
	for(i = 0; i < threadcount; i++) {
		pthread_attr_init(att+i);
		pthread_attr_setdetachstate(att+i, PTHREAD_CREATE_JOINABLE);
		pthread_create(ths+i, att+i, opp_queue_test_thread_run, NULL);
	}
	opp_queue_test_thread_run(NULL);
	for(i = 0; i < threadcount; i++) {
		SYNC_ASSERT(!pthread_join(ths[i], NULL));
		pthread_attr_destroy(att+i);
	}
	printf("If you see this then the error is fixed\n");
	opp_queue_test_deinit();

 * */
#endif


C_CAPSULE_END

#endif /* OPP_QUEUE_H */
