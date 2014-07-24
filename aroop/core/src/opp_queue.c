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
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_factory_profiler.h"
#include "aroop/opp/opp_queue.h"
#include "aroop/core/logger.h"
#endif

C_CAPSULE_START

enum {
	OPP_QUEUE_INITIALIZED = 14,
#ifdef SYNC_LOW_MEMORY
	OPP_QUEUE_REDUNDENCY = 1,
	OPP_QUEUE_BUFFER_INC = 32,
	OPP_QUEUE_FACTORY_COUNT = COMPONENT_SCALABILITY*OPP_QUEUE_REDUNDENCY,
#else
	OPP_QUEUE_REDUNDENCY = 8,
	OPP_QUEUE_BUFFER_INC = 1024,
	OPP_QUEUE_FACTORY_COUNT = COMPONENT_SCALABILITY*OPP_QUEUE_REDUNDENCY,
#endif
};

//#define USLEEP_BEFORE_RETRYING() sync_usleep(1)
#ifndef SYMBIAN
#define USLEEP_BEFORE_RETRYING()
#endif

static struct opp_factory queue_factorys[OPP_QUEUE_FACTORY_COUNT];


#if 0
#define OBJ_QUEUE_INTEGRITY_TEST(x) do { \
	int count = 0; \
	struct obj_queue_item*test_item = NULL; \
	for(test_item = x->opp_internal_first; test_item; test_item = test_item->opp_internal_next) { \
		if(!test_item->opp_internal_next) { \
			SYNC_ASSERT(test_item == x->opp_internal_tail); \
		} \
		count++; \
	} \
	SYNC_ASSERT(count == queue->opp_internal_usec); \
} while(0)
#else
#define OBJ_QUEUE_INTEGRITY_TEST(x)
#endif


//#define USE_MALLOCED_QUEUE_ITEM
// note that both malloc and freelist are not recommended .. but freelist is totally lockfree

#ifdef SYNC_USE_LOCKFREE_QUEUE
#ifdef USE_MALLOCED_QUEUE_ITEM
static struct opp_queue_item*opp_queue_item_getfree(struct opp_queue*queue, void*obj_data) {
	struct opp_queue_item*node = malloc(sizeof(struct opp_queue_item));
	if(!node) {
		return NULL;
	}
	node->obj_data = obj_data?OPPREF(obj_data):NULL;
	return node;
}


static int opp_queue_item_setfree(struct opp_queue*queue, struct opp_queue_item*node) {
	free(node);
	return 0;
}
#else
static volatile int cycles = 0;
static struct opp_factory*opp_queue_factory_resulve(struct opp_queue*queue) {
	struct opp_factory*fac = NULL;
#ifdef SYNC_HAS_ATOMIC_OPERATION
	do {

		int oldval = cycles;
		int newval = (oldval+1)%OPP_QUEUE_REDUNDENCY;
		if(sync_do_compare_and_swap(&(cycles), oldval, newval)) {
			break;
		}
		usleep(1);
	}while(1);
#else
	cycles = (cycles+1)%OPP_QUEUE_REDUNDENCY;
#endif

	fac = queue_factorys+queue->opp_internal_factory_idx+(COMPONENT_SCALABILITY*cycles);
	if(queue->opp_internal_factory_idx == OBJ_QUEUE_STACK_ALLOC) {
		fac = (struct opp_factory*)(queue+1);
	}
	return fac;
}
static struct opp_queue_item*opp_queue_item_getfree(struct opp_queue*queue, void*obj_data, struct opp_factory*pool) {
	volatile struct opp_queue_item*node = NULL;
#ifdef USE_FREELIST
	do {
		node = queue->opp_internal_free_list;
		if(!node) {
			break;
		}
		if(node == &queue->opp_internal_free_node) {
			USLEEP_BEFORE_RETRYING();
			continue;
		}
		// we are placing a itermediate node so that none changes this
		if(!sync_do_compare_and_swap(&(queue->opp_internal_free_list), node, &queue->opp_internal_free_node)) {
			USLEEP_BEFORE_RETRYING();
			continue;
		}
		volatile struct opp_queue_item*next = node->opp_internal_next;
		SYNC_ASSERT(sync_do_compare_and_swap(&(queue->opp_internal_free_list), &queue->opp_internal_free_node, next));
		break;
	} while(1);
#endif

	if(!node) {
		if(!(node = OPP_ALLOC2(pool, NULL))) {
			return NULL;
		}
	}
	node->opp_internal_next = NULL;
	if(obj_data) {
		node->obj_data = OPPREF(obj_data);
	} else {
		node->obj_data = NULL;
	}
	return (struct opp_queue_item*)node;
}

static int opp_queue_item_setfree(struct opp_queue*queue, struct opp_queue_item*node) {
	node->opp_internal_next = NULL;
	node->obj_data = NULL;
#ifdef USE_FREELIST
	do {
		SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*free_node;
		free_node = queue->opp_internal_free_list;
		if(free_node == &queue->opp_internal_free_node) {
			USLEEP_BEFORE_RETRYING();
			continue;
		}
		node->opp_internal_next = free_node;
		if(sync_do_compare_and_swap(&(queue->opp_internal_free_list), free_node, node)) {
			break;
		}
		USLEEP_BEFORE_RETRYING();
	} while(1);
#else
	OPPUNREF(node);
#endif
	return 0;
}
#endif
#endif

#if 0
#define OBJ_QUEUE_ASSERT_RETURN(x,y) ({int loop_breaker = 0; \
while(x->opp_internal_sign != OPP_QUEUE_INITIALIZED) { \
	usleep(1); \
	loop_breaker++; \
	if(loop_breaker > 500) { \
		x->opp_internal_errorc++; \
		if(x->opp_internal_errorc > 50) { \
			x->opp_internal_errorc = 0; \
			SYNC_LOG(SYNC_ERROR, "%d line failed\n", __LINE__); \
		} \
		return y; \
	} \
}})
#else
//#define OBJ_QUEUE_ASSERT_RETURN(x,y) SYNC_ASSERT(x->opp_internal_sign == OPP_QUEUE_INITIALIZED)
// NOTE The following code may introduce memory leak ..
#define OBJ_QUEUE_ASSERT_RETURN(x,y) ({if(x->opp_internal_sign != OPP_QUEUE_INITIALIZED)return y;})
#endif

int opp_enqueue(struct opp_queue*queue, void*obj_data) {
	/* sanity check */
	if(!obj_data) {
		return 0;
	}
	OBJ_QUEUE_ASSERT_RETURN(queue,-1);
#ifdef SYNC_USE_LOCKFREE_QUEUE
	struct opp_factory*pool = opp_queue_factory_resulve(queue);
#ifndef USE_FREELIST
	opp_factory_lock_donot_use(pool);
#endif
	struct opp_queue_item*node = NULL, *interm = NULL;
	do {
		node = opp_queue_item_getfree(queue, obj_data, pool);
		if(!node) {
			break;
		}
		interm = opp_queue_item_getfree(queue, NULL, pool);
		if(!interm) {
			opp_queue_item_setfree(queue, node);
			break;
		}
	} while(0);
#ifndef USE_FREELIST
	opp_factory_unlock_donot_use(pool);
#endif
	if(!node || !interm) {
		return -1;
	}
	node->opp_internal_next = interm;
	interm->opp_internal_next = NULL;
	SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*queuelast = NULL;
	do {
		queuelast = queue->opp_internal_tail;
		SYNC_ASSERT(queuelast);
		if(sync_do_compare_and_swap(&(queue->opp_internal_tail), queuelast, interm)) {
			break;
		}
		USLEEP_BEFORE_RETRYING();
	} while(1);
	while(!sync_do_compare_and_swap(&(queuelast->opp_internal_next), NULL, node)) {
		USLEEP_BEFORE_RETRYING();
	}
	SYNC_QUEUE_VOLATILE_VAR int oldval,newval;
	do {
		oldval = queue->opp_internal_usec;
		newval = oldval+1;
		if(sync_do_compare_and_swap(&(queue->opp_internal_usec), oldval, newval)) {
			break;
		}
		USLEEP_BEFORE_RETRYING();
	}while(1);
	return 0;
#else
	opp_factory_lock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	OBJ_QUEUE_INTEGRITY_TEST(queue);
	struct opp_queue_item*node = (struct opp_queue_item*)OPP_ALLOC2(queue_factorys+queue->opp_internal_factory_idx, NULL);
	if(node) {
		node->obj_data = OPPREF(obj_data);
		node->opp_internal_next = NULL;
		if (queue->opp_internal_first == NULL) {
			queue->opp_internal_first = queue->opp_internal_tail = node;
		} else {
			queue->opp_internal_tail->opp_internal_next = node;
			queue->opp_internal_tail = node;
		}
		queue->opp_internal_usec++;
	}
	OBJ_QUEUE_INTEGRITY_TEST(queue);
	opp_factory_unlock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	return node?0:-1;
#endif
}

void*opp_dequeue(struct opp_queue*queue) {
	void*ret = NULL;
	OBJ_QUEUE_ASSERT_RETURN(queue,NULL);
#ifdef SYNC_USE_LOCKFREE_QUEUE
#define REMOVE_INTERMEDIATE_NODE() if(swap){SYNC_ASSERT(sync_do_compare_and_swap(&(node->opp_internal_next), &queue->opp_internal_free_node, next));swap = 0;}
#define REMOVE_INTERMEDIATE_NODE2() if(swap2){SYNC_ASSERT(sync_do_compare_and_swap(&(queue->opp_internal_head_node.opp_internal_next), &queue->opp_internal_free_node, node));swap2 = 0;}
	do {
		SYNC_QUEUE_VOLATILE_VAR int swap = 0, swap2 = 0;
		do {
			SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*node = queue->opp_internal_head_node.opp_internal_next;
			if(!node) {
				return NULL;
			}

			if(node == &queue->opp_internal_free_node || !(swap2 = sync_do_compare_and_swap(&(queue->opp_internal_head_node.opp_internal_next), node, &queue->opp_internal_free_node))) {
				USLEEP_BEFORE_RETRYING();
				continue;
			}
			SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*next = node->opp_internal_next;
			if(!node->obj_data && !next) {
				REMOVE_INTERMEDIATE_NODE2();
				return NULL;
			}
			if(next == &queue->opp_internal_free_node) {
				REMOVE_INTERMEDIATE_NODE2();
				USLEEP_BEFORE_RETRYING();
				continue;
			}
			// we are placing a itermediate node so that none changes this
			if(!(swap = sync_do_compare_and_swap(&(node->opp_internal_next), next, &queue->opp_internal_free_node))) {
				REMOVE_INTERMEDIATE_NODE2();
				USLEEP_BEFORE_RETRYING();
				continue;
			}
			if(!sync_do_compare_and_swap(&(queue->opp_internal_head_node.opp_internal_next), &queue->opp_internal_free_node, next)) {
				REMOVE_INTERMEDIATE_NODE();
				REMOVE_INTERMEDIATE_NODE2();
				USLEEP_BEFORE_RETRYING();
				continue;
			}
			ret = node->obj_data;
			node->obj_data = NULL;
			opp_queue_item_setfree(queue, (struct opp_queue_item*)node);
			break;
		} while(1);
	}while(!ret);
	if(ret) {
		SYNC_QUEUE_VOLATILE_VAR int oldval,newval;
		do {
			oldval = queue->opp_internal_usec;
			newval = oldval-1;
		}while(!sync_do_compare_and_swap(&(queue->opp_internal_usec), oldval, newval));
	}
	return ret;
#else
	struct opp_queue_item*item = NULL;
	if(!queue->opp_internal_first) {
		return NULL;
	}

	opp_factory_lock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	OBJ_QUEUE_INTEGRITY_TEST(queue);
	item = queue->opp_internal_first;
	if(item) {
		ret = item->obj_data;
		OPPREF(ret);
		if(queue->opp_internal_tail == item) {
			queue->opp_internal_tail = item->opp_internal_next;
		}
		queue->opp_internal_first = item->opp_internal_next;
		OPPUNREF_UNLOCKED(item);
		queue->opp_internal_usec--;
	}
	OBJ_QUEUE_INTEGRITY_TEST(queue);
	opp_factory_unlock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	return ret;
#endif
}

int opp_queue_init2(struct opp_queue*queue, int scindex) {
	if(scindex != OBJ_QUEUE_STACK_ALLOC)SYNC_ASSERT(scindex < COMPONENT_SCALABILITY);
	queue->opp_internal_usec = 0;
#ifdef SYNC_USE_LOCKFREE_QUEUE
	queue->opp_internal_tail = &queue->opp_internal_head_node;
#ifdef USE_FREELIST
	queue->opp_internal_free_list = NULL;
#endif
	queue->opp_internal_head_node.opp_internal_next = NULL;
	queue->opp_internal_free_node.opp_internal_next = NULL;
#else
	queue->opp_internal_tail = NULL;
	queue->opp_internal_first = NULL;
#endif
	queue->opp_internal_sign = OPP_QUEUE_INITIALIZED;
	queue->opp_internal_factory_idx = (scindex%COMPONENT_SCALABILITY);
	return 0;
}

int opp_queue_deinit(struct opp_queue*queue) {
	if(queue->opp_internal_sign != OPP_QUEUE_INITIALIZED) {
		return 0;
	}
	queue->opp_internal_sign = 89;
#ifdef SYNC_USE_LOCKFREE_QUEUE
	SYNC_QUEUE_VOLATILE_VAR struct opp_queue_item*node,*next;
	for(node = queue->opp_internal_head_node.opp_internal_next;node;node = next) {
		next = node->opp_internal_next;
		if(node != &queue->opp_internal_head_node && node != &queue->opp_internal_free_node) {
#ifdef USE_MALLOCED_QUEUE_ITEM
			OPPUNREF(node->obj_data);
			free((void*)node);
#else
			OPPUNREF(node);
#endif
		}
	}
#ifdef USE_FREELIST
	for(node = queue->opp_internal_free_list;node;node = next) {
		next = node->opp_internal_next;
		if(node != &queue->opp_internal_head_node && node != &queue->opp_internal_free_node) {
#ifdef USE_MALLOCED_QUEUE_ITEM
			OPPUNREF(node->obj_data);
			free((void*)node);
#else
			OPPUNREF(node);
#endif
		}
	}
#endif
#else
	struct opp_queue_item*node,*next;
	opp_factory_lock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	OBJ_QUEUE_INTEGRITY_TEST(queue);
	for(node = queue->opp_internal_first;node;node = next) {
		next = node->opp_internal_next;
		if(!next) {
			SYNC_ASSERT(node == queue->opp_internal_tail);
		}
		OPPUNREF_UNLOCKED(node);
	}
	opp_factory_unlock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	queue->opp_internal_first = NULL;
#endif
	queue->opp_internal_tail = NULL;
#ifdef SYNC_USE_LOCKFREE_QUEUE
#ifdef USE_FREELIST
	queue->opp_internal_free_list = NULL;
#endif
	queue->opp_internal_head_node.opp_internal_next = NULL;
#endif
	return 0;
}

int opp_queue_do_full_unsafe(struct opp_queue*queue, int (*func)(void*data, void*func_data), void*func_data) {
#ifdef SYNC_USE_LOCKFREE_QUEUE
  struct opp_queue_item*node,*prev;
  for(prev = (struct opp_queue_item*)&queue->opp_internal_head_node,node = (struct opp_queue_item*)queue->opp_internal_head_node.opp_internal_next
		  ;(node && node != &queue->opp_internal_free_node);prev = node,node = (struct opp_queue_item*)node->opp_internal_next) {
    if(!node->obj_data) {
      continue;
    }
    if(func && func(node->obj_data, func_data) == OBJ_QUEUE_RETRUN_UNLINK) {
      // Destroy ..
      if(prev) {
        prev->opp_internal_next = node->opp_internal_next;
        if(node == queue->opp_internal_tail) {
          queue->opp_internal_tail = prev;
        }
      }
      queue->opp_internal_usec--;
#if 0
      OPPUNREF(node);
#else
      // two step destruction is done to avoid deadlock
      OPPUNREF(node->obj_data);
      OPPUNREF(node);
#endif
      node = prev;
    }
  }
  return 0;
#else
  return opp_queue_do_full_on_stack(queue, func, func_data);
#endif
}

int opp_queue_do_full(struct opp_queue*queue, int (*func)(void*data, void*func_data), void*func_data) {
#ifdef SYNC_USE_LOCKFREE_QUEUE
	void*data;
	if(queue->opp_internal_sign != OPP_QUEUE_INITIALIZED || !queue->opp_internal_usec) {
		return 0;
	}
	struct opp_queue tmpqueue;
	opp_queue_init2(&tmpqueue, queue->opp_internal_factory_idx);

	while((data = opp_dequeue(queue))) {
		if(func && func(data, func_data) == OBJ_QUEUE_RETRUN_UNLINK) {
			// nothing to do
		} else {
			opp_enqueue(&tmpqueue, data);
		}
		OPPUNREF(data);
	}

	while((data = opp_dequeue(&tmpqueue))) {
		opp_enqueue(queue, data);
		OPPUNREF(data);
	}
	opp_queue_deinit(&tmpqueue);
	//no need to destroy may be ... obj_queue_destroy(&tmpqueue);
#else
	struct opp_queue_item*item, *prev;
	if(queue->opp_internal_sign != OPP_QUEUE_INITIALIZED || !queue->opp_internal_first) {
		return 0;
	}
	opp_factory_lock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
	OBJ_QUEUE_INTEGRITY_TEST(queue);
	for(item = queue->opp_internal_first, prev = NULL;item;) {
		if(func && func(item->obj_data, func_data) == OBJ_QUEUE_RETRUN_UNLINK) {
			if(prev) {
				prev->opp_internal_next = item->opp_internal_next;
			} else {
				queue->opp_internal_first = item->opp_internal_next;
			}
			if(queue->opp_internal_tail == item) {
				queue->opp_internal_tail = item->opp_internal_next?item->opp_internal_next:(prev?prev:queue->opp_internal_first);
			}
			OPPUNREF_UNLOCKED(item);
			queue->opp_internal_usec--;
			item = prev?prev->opp_internal_next:queue->opp_internal_first;
		} else {
			prev = item;
			item = item->opp_internal_next;
		}
		OBJ_QUEUE_INTEGRITY_TEST(queue);
	}
	opp_factory_unlock_donot_use(queue_factorys+queue->opp_internal_factory_idx);
#endif
	return 0;
}


int opp_queue_do_full_on_stack(struct opp_queue*queue, int (*func)(void*data, void*func_data), void*func_data) {
#ifdef SYNC_USE_LOCKFREE_QUEUE
	// XXX this code is buggy it destroyes the object sequence ..
	void*data;
	if(queue->opp_internal_sign != OPP_QUEUE_INITIALIZED || !queue->opp_internal_usec) {
		return 0;
	}
#if 1
	int incsize = ((queue->opp_internal_usec+1)*3);
	OPP_QUEUE_DECLARE_STACK(tmpqueue, incsize);
#else
	OPP_QUEUE_DECLARE_STACK(tmpqueue, 100);
#endif
	while((data = opp_dequeue(queue))) {
		if(func && func(data, func_data) == OBJ_QUEUE_RETRUN_UNLINK) {
			// nothing to do
		} else {
			opp_enqueue(tmpqueue, data);
		}
		OPPUNREF(data);
	}

	while((data = opp_dequeue(tmpqueue))) {
		opp_enqueue(queue, data);
		OPPUNREF(data);
	}
	OPP_QUEUE_DESTROY_STACK(tmpqueue);
	return 0;
#else
	return opp_queue_do_full(queue, func, func_data);
#endif
}

OPP_CB(opp_queue_item) {
	struct opp_queue_item*node = (struct opp_queue_item*)data;
	switch(callback) {
	case OPPN_ACTION_FINALIZE:
		OPPUNREF(node->obj_data);
		node->opp_internal_next = NULL;
		break;
	}
	return 0;
}

#if 0
int opp_queue_init(struct opp_queue*queue) {
	opp_queue_init2(queue, (queue_count++)%OPP_QUEUE_FACTORY_COUNT);
	return 0;
}
#endif

static int opp_queue_verb_helper(const void*data, const void*func_data) {
	// do nothing
	return 0;
}
void opp_queuesystem_verb(void (*log)(void *log_data, const char*fmt, ...), void*log_data) {
	int i;
	for(i=0;i<OPP_QUEUE_FACTORY_COUNT;i++) {
		opp_factory_verb(queue_factorys+i, opp_queue_verb_helper, NULL, log, log_data);
	}
}

int opp_queuesystem_init() {
	int i,res = 0;
	for(i=0;!res && i<OPP_QUEUE_FACTORY_COUNT;i++) {
		res = OPP_PFACTORY_CREATE_FULL(queue_factorys+i, OPP_QUEUE_BUFFER_INC
			, sizeof(struct opp_queue_item)
			, 1/*token offset*/, OPPF_HAS_LOCK | OPPF_SWEEP_ON_UNREF | OPPF_FAST_INITIALIZE
			, OPP_CB_FUNC(opp_queue_item));
	}
	return res;
}

void opp_queuesystem_deinit() {
	int i;
	for(i=0;i<OPP_QUEUE_FACTORY_COUNT;i++) {
		opp_factory_destroy(queue_factorys+i);
	}
}


#ifdef TEST_OBJ_FACTORY_UTILS
struct pen {
	int color;
	int depth;
};

static struct opp_queue test_queue;
static struct opp_factory test_factory;
void*opp_queue_test_thread_run(void*notused) {
	int i=20000;
	while(i--) {
		struct pen*p = OPP_ALLOC2(&test_factory, NULL);
		opp_enqueue(&test_queue, p);
		void*data = opp_dequeue(&test_queue);
		if(data) {
			OPPUNREF(data);
		}
	}
	return 0;
}

int opp_queue_test_init() {
	OPP_PFACTORY_CREATE_FULL(&test_factory, 256, sizeof(struct pen), 1, OPPF_HAS_LOCK, NULL);
	opp_queue_init2(&test_queue, 0);
	return 0;
}

int opp_queue_test_deinit() {
	opp_queue_deinit(&test_queue);
	opp_factory_destroy(&test_factory);
	return 0;
}
#endif // TEST_OBJ_FACTORY_UTILS

C_CAPSULE_END


