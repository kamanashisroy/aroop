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
#include "aroop/core/config.h"
#include "aroop/core/memory.h"
#include "aroop/opp/opp_factory.h"
#include "aroop/opp/opp_list.h"
#include "aroop/opp/opp_queue.h"
#include "aroop/core/logger.h"
#include "aroop/opp/opp_watchdog.h"
#include "aroop/opp/opp_iterator.h"
#include "aroop/opp/opp_factory_profiler.h"
#endif

C_CAPSULE_START
#ifdef SYNC_BIT64
#warning "Building 64 bit binary"
#else
#define SYNC_BIT32
#endif

#ifdef SYNC_BIT32
enum {
	BITSTRING_MASK = 0xFFFFFFFF
};
#define BITSTRING_TYPE SYNC_UWORD32_T
#define OPP_NORMALIZE_SIZE(x) ({(x+3)&~3;}) // multiple of 4
#define BIT_PER_STRING 32
#define OPP_INDEX_TO_BITSTRING_INDEX(x) (x>>5)
#define BITSTRING_IDX_TO_BITS(x) (x<<5)
#else
#ifdef SYNC_BIT64
//enum {
//	BITSTRING_MASK = 0xFFFFFFFFFFFFFFFF
//};

typedef uint64_t SYNC_UWORD64_T;
static const uint64_t BITSTRING_MASK = 0xFFFFFFFFFFFFFFFF;

#define BITSTRING_TYPE SYNC_UWORD64_T
#define OPP_NORMALIZE_SIZE(x) ({(x+7)&~7;})
#define BIT_PER_STRING 64
#define OPP_INDEX_TO_BITSTRING_INDEX(x) (x>>6)
#define BITSTRING_IDX_TO_BITS(x) (x<<6)
#endif
#endif

#ifndef SYNC_ASSERT
#define SYNC_ASSERT(x) assert(x)
#endif

#define AUTO_GC	// recommended
#define OPTIMIZE_OBJ_LOOP // recommended
#define OPP_HAS_TOKEN // recommended
#ifdef TEST_OBJ_FACTORY_UTILS
#define OPP_DEBUG
#endif

#ifdef OPP_DEBUG
#define OPP_DEBUG_REFCOUNT // only for testing
enum {
	OPP_TRACE_SIZE = 32,
};
#endif

#ifdef OPP_DEBUG
#define FACTORY_OBJ_SIGN 0x24
#else
#undef FACTORY_OBJ_SIGN
#endif

#ifdef OPP_BUFFER_HAS_LOCK

#ifdef TEST_OBJ_FACTORY_UTILS
#define OPP_LOCK(x) do { \
	if((x)->property & OPPF_HAS_LOCK) while(sync_mutex_trylock(&(x)->lock)) { \
		sync_usleep(1); \
	} \
}while(0)
#else
#define OPP_LOCK(x) do { \
	int lock_alert = 0; \
	if((x)->property & OPPF_HAS_LOCK) while(sync_mutex_trylock(&(x)->lock)) { \
		lock_alert++; \
		if(lock_alert > 20) { \
			/*abort();*/ \
			opp_watchdog_report(WATCHDOG_ALERT, "lock failed 20 times ..\n"); \
		} \
		sync_usleep(1); \
	} \
}while(0)
#endif // TEST_OBJ_FACTORY_UTILS

#ifdef SYNC_HAS_ATOMIC_OPERATION
#define BINARY_AND_HELPER(xtype,x,y) ({volatile xtype old,new;do{old=*x;new=old&y;}while(!sync_do_compare_and_swap(x,old,new));})
#define BINARY_OR_HELPER(xtype,x,y) ({volatile xtype old,new;do{old=*x;new=old|y;}while(!sync_do_compare_and_swap(x,old,new));})
#else
#define BINARY_AND_HELPER(xtype,x,y) ({*x &= y;})
#define BINARY_OR_HELPER(xtype,x,y) ({*x |= y;})
#endif // SYNC_HAS_ATOMIC_OPERATION


#define OPP_UNLOCK(x) do { \
	if((x)->property & OPPF_HAS_LOCK) { \
		SYNC_ASSERT(!sync_mutex_unlock(&(x)->lock)); \
	} \
}while(0)
#else
#define OPP_LOCK(x)
#define OPP_UNLOCK(x)
#define BINARY_AND_HELPER(xtype,x,y) ({*x &= y;})
#define BINARY_OR_HELPER(xtype,x,y) ({*x |= y;})
#endif

#ifdef OPP_DEBUG
#ifdef OPP_HAS_RECYCLING
#define CHECK_POOL(x) ({SYNC_ASSERT((x)->end > (x)->head \
	&& (x)->head > ((SYNC_UWORD8_T*)(x)->bitstring) \
	&& ((SYNC_UWORD8_T*)(x)->bitstring) > ((SYNC_UWORD8_T*)(x)) \
	&& (!(x)->recycled || ((SYNC_UWORD8_T*)(x)->recycled) < (x)->end) \
	&& (((BITSTRING_TYPE*)((x)+1)) == (x)->bitstring));})
#else
#define CHECK_POOL(x) ({SYNC_ASSERT((x)->end > (x)->head \
	&& (x)->head > ((SYNC_UWORD8_T*)(x)->bitstring) \
	&& ((SYNC_UWORD8_T*)(x)->bitstring) > ((SYNC_UWORD8_T*)(x)) \
	&& (((BITSTRING_TYPE*)((x)+1)) == (x)->bitstring));})
#endif
#else
#define CHECK_POOL(x)
#endif

#ifdef OPP_DEBUG
#define CHECK_OBJ(x) ({SYNC_ASSERT((x)->signature == FACTORY_OBJ_SIGN);})
#else
#define CHECK_OBJ(x)
#endif

#ifdef AUTO_GC
#define DO_AUTO_GC_CHECK(x) do{\
	if((x)->pool_count*(x)->pool_size - (x)->slot_use_count > ((x)->pool_size << 1)) { \
		opp_factory_gc_nolock(x); \
	} \
}while(0);
#else
#define DO_AUTO_GC_CHECK(x)
#endif

#define OPP_FINALIZE_NOW(x,y) ({\
	if((x->property & OPPF_SEARCHABLE) && (((struct opp_object_ext*)(y+1))->flag & OPPN_INTERNAL_1))\
		opp_lookup_table_delete(&x->tree, (struct opp_object_ext*)(y+1));\
	if(x->callback){static va_list va;x->callback(y+1, OPPN_ACTION_FINALIZE, NULL, va, y->slots*x->obj_size - sizeof(struct opp_object));}*(y->bitstring+BITFIELD_FINALIZE) &= ~( 1 << y->bit_idx);UNSET_PAIRED_BITS(y);\
})

enum {
	OPP_POOL_FREEABLE = 1,
};
struct opp_pool {
	SYNC_UWORD16_T idx;
	SYNC_UWORD16_T flags;
#ifdef OPP_HAS_RECYCLING
	struct opp_object*recycled;
#endif
	BITSTRING_TYPE*bitstring; // each word(doublebyte) pair contains the usage and finalization flag respectively.
	SYNC_UWORD8_T*head;
	SYNC_UWORD8_T*end;
	struct opp_pool*next;
};

// bit hacks http://graphics.stanford.edu/~seander/bithacks.html

enum {
	BITFIELD_FINALIZE = 1,
	BITFIELD_PAIRED = 2,
#ifndef OPP_NO_FLAG_OPTIMIZATION
	BITFIELD_PERFORMANCE = 3,
	BITFIELD_PERFORMANCE1 = 4,
	BITFIELD_PERFORMANCE2 = 5,
	BITFIELD_PERFORMANCE3 = 6,
	BITFIELD_SIZE = 7,
#else
	BITFIELD_SIZE = 3,
#endif
};

#ifndef OPP_NO_FLAG_OPTIMIZATION
enum {
	OPPN_PERFORMANCE = 1,
	OPPN_PERFORMANCE1 = 1<<1,
	OPPN_PERFORMANCE2 = 1<<2,
	OPPN_PERFORMANCE3 = 1<<3,
};
#endif

enum {
	OPPF_INITIALIZED_INTERNAL = 0x3428,
};

#ifdef LOW_MEMORY
#define refcount_t OPP_VOLATILE_VAR SYNC_UWORD16_T
#else
#define refcount_t OPP_VOLATILE_VAR SYNC_UWORD32_T
#endif

struct opp_object {
	SYNC_UWORD8_T bit_idx;
	SYNC_UWORD8_T slots;
	refcount_t refcount;
#ifdef FACTORY_OBJ_SIGN
	SYNC_UWORD32_T signature;
#endif
	BITSTRING_TYPE*bitstring;
#ifdef OPP_HAS_RECYCLING
	struct opp_object*recycled;
#endif
#ifdef OPP_DEBUG_REFCOUNT
	struct {
		const char *filename;
		SYNC_UWORD16_T lineno;
		refcount_t refcount;
		char op;
		char flags[3];
	}ref_trace[OPP_TRACE_SIZE];
	SYNC_UWORD32_T rt_idx;
#endif
	struct opp_factory*obuff;
};

#define SET_PAIRED_BITS(x) do{\
	SYNC_ASSERT((x)->slots <= BIT_PER_STRING); \
	if((x)->slots>1) { \
		*((x)->bitstring+BITFIELD_PAIRED) |= ((1<<((x)->slots-1))-1)<<((x)->bit_idx+1); \
	} \
	SYNC_ASSERT(!(*((x)->bitstring) & *((x)->bitstring+BITFIELD_PAIRED))); \
	(x)->obuff->slot_use_count += (x)->slots; \
}while(0);

#define UNSET_PAIRED_BITS(x) do{\
	SYNC_ASSERT((x)->slots <= BIT_PER_STRING); \
	/*SYNC_ASSERT(bitfield == (bitfield & *((x)->bitstring+BITFIELD_PAIRED)));*/ \
	if((x)->slots>1) { \
		*((x)->bitstring+BITFIELD_PAIRED) &= ~(((1<<((x)->slots-1))-1)<<((x)->bit_idx+1)); \
	} \
	(x)->obuff->slot_use_count -= (x)->slots; \
	(x)->slots = 0; \
}while(0);

static void opp_factory_gc_nolock(struct opp_factory*obuff);

int opp_factory_create_full(struct opp_factory*obuff
		, SYNC_UWORD16_T inc
		, SYNC_UWORD16_T obj_size
		, int token_offset
		, unsigned char property
		, opp_callback_t callback
	) {
	SYNC_ASSERT(obj_size < (1024<<1));
	SYNC_ASSERT(inc);
#ifdef SYNC_LOW_MEMORY
	SYNC_ASSERT(inc < 1024);
#else
	SYNC_ASSERT(inc < (1024<<3));
#endif

	if(obuff->sign == OPPF_INITIALIZED_INTERNAL) {
		SYNC_LOG(SYNC_ERROR, "obj is already initiated\n");
		SYNC_ASSERT(!"obj is already initiated\n");
		return 0;
	}
	obuff->sign = OPPF_INITIALIZED_INTERNAL;
#ifdef OPP_BUFFER_HAS_LOCK
	if(property & OPPF_HAS_LOCK) {
		sync_mutex_init(&obuff->lock);
	}
#endif
	obuff->property = property | OPPF_SWEEP_ON_UNREF; // force sweep
	obuff->pool_size = inc;
	obj_size = OPP_NORMALIZE_SIZE(obj_size);
	obuff->obj_size = obj_size + sizeof(struct opp_object);
//	obuff->initialize = initialize;
//	obuff->finalize = finalize;
	obuff->callback = callback;
	obuff->bitstring_size = (inc+7) >> 3;
	obuff->bitstring_size = OPP_NORMALIZE_SIZE(obuff->bitstring_size);
	obuff->bitstring_size = obuff->bitstring_size*BITFIELD_SIZE;
	obuff->memory_chunk_size = sizeof(struct opp_pool) + obuff->obj_size*inc + obuff->bitstring_size;
	obuff->token_offset = token_offset;

	obuff->pool_count = 0;
	obuff->use_count = 0;
	obuff->slot_use_count = 0;
	obuff->pools = NULL;

#ifndef OBJ_MAX_BUFFER_SIZE
#define OBJ_MAX_BUFFER_SIZE (4096<<10)
#endif
	SYNC_ASSERT(obuff->memory_chunk_size < OBJ_MAX_BUFFER_SIZE);

	if(property & OPPF_SEARCHABLE) {
		SYNC_ASSERT(property & OPPF_EXTENDED);
		opp_lookup_table_init(&obuff->tree, 0);
	}
	return 0;
}

#if 0
#define SYNC_OBJ_CTZ(x) 
#else
#ifdef __EPOC32__ // todo add symbian version
#define SYNC_OBJ_POPCOUNT(a) ({ \
    unsigned int opp_internal_pop_count = (unsigned int)a; \
    opp_internal_pop_count = opp_internal_pop_count - ((opp_internal_pop_count >> 1) & 0x55555555); \
    /* Every 2 bits holds the sum of every pair of bits */ \
    opp_internal_pop_count = ((opp_internal_pop_count >> 2) & 0x33333333) + (opp_internal_pop_count & 0x33333333); \
    /* Every 4 bits holds the sum of every 4-set of bits (3 significant bits) */ \
    opp_internal_pop_count = (opp_internal_pop_count + (opp_internal_pop_count >> 4)) & 0x0F0F0F0F; \
    /* Every 8 bits holds the sum of every 8-set of bits (4 significant bits) */ \
    opp_internal_pop_count = (opp_internal_pop_count + (opp_internal_pop_count >> 16)); \
    /* The lower 16 bits hold two 8 bit sums (5 significant bits).*/ \
    /*    Upper 16 bits are garbage */ \
    (opp_internal_pop_count + (opp_internal_pop_count >> 8)) & 0x0000003F;  /* (6 significant bits) */ \
})
#else
#define SYNC_OBJ_POPCOUNT(x) __builtin_popcount(x)
#endif
#define SYNC_OBJ_CTZ(x) __builtin_ctz(x)
#endif

struct opp_pool*opp_factory_create_pool_donot_use(struct opp_factory*obuff, struct opp_pool*addpoint, void*nofreememory) {
	// allocate a block of memory
	struct opp_pool*pool = (struct opp_pool*)nofreememory;
	opp_factory_profiler_checkleak();
	if(!pool && !(pool = (struct opp_pool*)profiler_replace_malloc(obuff->memory_chunk_size))) {
		SYNC_LOG(SYNC_ERROR, "Out of memory\n");
		return NULL;
	}

	if(!obuff->pools) {
		obuff->pools = pool;
		pool->idx = 0;
		pool->next = NULL;
	} else {
		SYNC_ASSERT(addpoint);
		// insert the pool in appropriate place
		pool->next = addpoint->next;
		addpoint->next = pool;
		pool->idx = addpoint->idx+1;
	}
	if(pool->idx > 64) {
		opp_watchdog_report(WATCHDOG_ALERT, "pool->idx > 64");
	}

	obuff->pool_count++;
	opp_factory_profiler_checkleak();

	SYNC_UWORD8_T*ret = (SYNC_UWORD8_T*)(pool+1);
	// clear memory
	memset(ret, 0, obuff->bitstring_size);
	// setup pool
	pool->bitstring = (BITSTRING_TYPE*)ret;
#ifdef OPP_HAS_RECYCLING
	pool->recycled = NULL;
#endif
	pool->head = ret + (obuff->bitstring_size);
	pool->end = ret + obuff->memory_chunk_size - sizeof(struct opp_pool);
	pool->flags = nofreememory?0:OPP_POOL_FREEABLE;
	CHECK_POOL(pool);
	return pool;
}

void*opp_alloc4(struct opp_factory*obuff, SYNC_UWORD16_T size, SYNC_UWORD8_T doubleref, SYNC_UWORD8_T require_clean, void*init_data, ...) {
	SYNC_UWORD8_T*ret = NULL;
	SYNC_UWORD8_T slots = 1;
	if(!require_clean)
		require_clean = obuff->property & OPPF_MEMORY_CLEAN;
	
	SYNC_ASSERT(obuff->sign == OPPF_INITIALIZED_INTERNAL);

	OPP_LOCK(obuff);
	do {
		if(size) {
			OPP_NORMALIZE_SIZE(size);
			size += sizeof(struct opp_object);
			slots = size / obuff->obj_size + ((size % obuff->obj_size)?1:0);
			if(slots > BIT_PER_STRING || slots > obuff->pool_size) {
				SYNC_LOG(SYNC_ERROR, "Too big allocation request %d\n", size);
				break;
			}
		}
#ifdef OPP_HAS_RECYCLING
		if(slots == 1) {
			struct opp_pool*pool;
			for(pool = obuff->pools;pool; pool = pool->next) {
				CHECK_POOL(pool);
				if(pool->recycled) {
					SYNC_ASSERT(!pool->recycled->refcount);
					ret = (SYNC_UWORD8_T*)pool->recycled;
					pool->recycled = pool->recycled->recycled;
					break;
				}
			}
		}
		if(ret) {
			break;
		}
#endif
		struct opp_pool*pool = NULL,*addpoint = NULL;
		for(addpoint = NULL, pool = obuff->pools;pool;pool = pool->next) {
			int k = 0;
			if(!addpoint && (!pool->next || (pool->idx+1 != pool->next->idx))) {
				addpoint = pool;
			}
			CHECK_POOL(pool);
			BITSTRING_TYPE*bitstring = pool->bitstring;
			for(;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {
				// find first 0
				BITSTRING_TYPE bsv = (~(*bitstring | *(bitstring+BITFIELD_PAIRED)));
				if(!bsv) continue;
#ifdef OPP_DEBUG
				int loop_breaker = 0;
#endif
				while(bsv) {
#ifdef OPP_DEBUG
					loop_breaker++;
					SYNC_ASSERT(loop_breaker < BIT_PER_STRING);
#endif
					if(slots > 1 && SYNC_OBJ_POPCOUNT(bsv) < slots) {
						break;
					}
					SYNC_UWORD8_T bit_idx = SYNC_OBJ_CTZ(bsv);
					if(slots > 1 && bit_idx + slots > BIT_PER_STRING) {
						// we cannot do it
						break;
					}
					
#if 0
					for(j=1;j<slots;j++) {
						if(!(bsv & (1<<(bit_idx+j)))) {
							j = 44;
							break;
						}
					}
					if(j == 44) {
						bsv &= ~(1<<bit_idx);
						continue;
					}
#else
					BITSTRING_TYPE mask = ((1 << slots)-1)<<bit_idx;
					if((mask & bsv) != mask) {
						bsv &= ~mask;
						continue;
					}
#endif
					SYNC_UWORD16_T obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
					//printf("%d\n", bit_idx);
					if(obj_idx < obuff->pool_size) {
						ret = pool->head + obj_idx*obuff->obj_size;
						struct opp_object*obj = (struct opp_object*)ret;
						obj->bit_idx = bit_idx;
						obj->bitstring = bitstring;
#ifdef OPP_HAS_TOKEN
						if(obuff->property & OPPF_EXTENDED) {
							((struct opp_object_ext*)(obj+1))->token = obuff->token_offset + pool->idx*obuff->pool_size + obj_idx;
						}
#endif
						obj->obuff = obuff;
						CHECK_POOL(pool);
					}
					break;
				}
				if(ret) {
					break;
				}
			}
			if(ret) break;
		}

		if(ret) {
#ifdef OPP_HAS_RECYCLING
			pool->recycled = NULL;
#endif
			break;
		}

		pool = opp_factory_create_pool_donot_use(obuff, addpoint, NULL);
		if(!pool) {
			ret = NULL;
			break;
		}
		ret = pool->head;
		struct opp_object*obj = (struct opp_object*)ret;
		obj->bit_idx = 0;
		obj->bitstring = pool->bitstring;
#ifdef OPP_HAS_TOKEN
		if(obuff->property & OPPF_EXTENDED) {
			((struct opp_object_ext*)(obj+1))->token = obuff->token_offset + pool->idx*obuff->pool_size;
		}
#endif
		obj->obuff = obuff;
	}while(0);

	va_list ap;
	va_start(ap, init_data);

	do {
		if(!ret)
			break;

		struct opp_object*obj = (struct opp_object*)ret;
		ret = (SYNC_UWORD8_T*)(obj+1);

		if(*(obj->bitstring+BITFIELD_FINALIZE) & ( 1 << obj->bit_idx)) {
			OPP_FINALIZE_NOW(obuff,obj);
		}
#ifdef FACTORY_OBJ_SIGN
		obj->signature = FACTORY_OBJ_SIGN;
#endif
		if(obuff->property & OPPF_EXTENDED) {
			((struct opp_object_ext*)(obj+1))->flag = OPPN_ALL;
			((struct opp_object_ext*)(obj+1))->hash = 0;
		}
		obj->refcount = doubleref?2:1;
		obj->slots = slots;

//		*(obj->bitstring) |= ( 1 << obj->bit_idx);
		*(obj->bitstring+BITFIELD_FINALIZE) |= ( 1 << obj->bit_idx);
#ifndef OPP_NO_FLAG_OPTIMIZATION
		*(obj->bitstring+BITFIELD_PERFORMANCE) &= ~( 1 << obj->bit_idx);
		*(obj->bitstring+BITFIELD_PERFORMANCE1) &= ~( 1 << obj->bit_idx);
		*(obj->bitstring+BITFIELD_PERFORMANCE2) &= ~( 1 << obj->bit_idx);
		*(obj->bitstring+BITFIELD_PERFORMANCE3) &= ~( 1 << obj->bit_idx);
#endif
		obuff->use_count++;
#ifdef OPP_DEBUG_REFCOUNT
		obj->rt_idx = 0;
		int i;
		for(i=0; i<OPP_TRACE_SIZE; i++) {
			obj->ref_trace[i].filename = NULL;
		}
#endif

		SET_PAIRED_BITS(obj);
#if 0
		if(!(obuff->property & OPPF_FAST_INITIALIZE)&& obuff->callback && opp_callback2(ret, OPPN_ACTION_INITIALIZE, (void*)init_data, obj->slots*obuff->obj_size - sizeof(struct opp_object))) {
			opp_set_flag(ret, OPPN_ZOMBIE);
			ret = NULL;
			obj->refcount = 0;
			*(obj->bitstring+BITFIELD_FINALIZE) &= ~( 1 << obj->bit_idx);
			UNSET_PAIRED_BITS(obj);
			obuff->use_count--;
			break;
		}
		*(obj->bitstring) |= ( 1 << obj->bit_idx);
#else
		*(obj->bitstring) |= ( 1 << obj->bit_idx);
#endif
	} while(0);

	if(ret && !(obuff->property & OPPF_FAST_INITIALIZE) && obuff->callback) {
		if(require_clean) {
			opp_force_memclean(ret);
			require_clean = 0;
		}
				
		if(obuff->callback(ret, OPPN_ACTION_INITIALIZE
					, (void*)init_data
					, ap, ((struct opp_object*)ret-1)->slots*obuff->obj_size - sizeof(struct opp_object))) {
			void*dup = ret;
			OPPUNREF(ret);
			if(doubleref) {
				OPPUNREF(dup);
			}
		}
	}
#ifdef OPP_DEBUG
	if(obuff->pools && obuff->pools->bitstring) {
		BITSTRING_TYPE*bitstring;
		for(bitstring = obuff->pools->bitstring;((void*)bitstring) < ((void*)obuff->pools->head);bitstring+=BITFIELD_SIZE) {
			SYNC_ASSERT(!(*(bitstring) & *(bitstring+BITFIELD_PAIRED)));
		}
	}
#endif

	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
	if(ret) {
		if(require_clean) {
			opp_force_memclean(ret);
			require_clean = 0;
		}
		if((obuff->property & OPPF_FAST_INITIALIZE) && obuff->callback && obuff->callback(ret, OPPN_ACTION_INITIALIZE, (void*)init_data, ap, ((struct opp_object*)ret-1)->slots*obuff->obj_size - sizeof(struct opp_object))) {
			void*dup = ret;
			OPPUNREF(ret);
			if(doubleref) {
				OPPUNREF(dup);
			}
		}
	}
	va_end(ap);
//	SYNC_ASSERT(ret);
	return ret;
}

#define data_to_opp_object(x) ({(struct opp_object*)pointer_arith_sub_byte(x,sizeof(struct opp_object));})
int opp_callback(void*data, int callback, void*cb_data) {
	struct opp_object*obj = data_to_opp_object(data);
	struct opp_factory*obuff = obj->obuff;
	SYNC_ASSERT(obuff->callback);
	CHECK_OBJ(obj);
	static va_list va;
	return obuff->callback(data, callback, cb_data, va, obj->slots*obuff->obj_size - sizeof(struct opp_object));
}

int opp_callback2(void*data, int callback, void*cb_data, ...) {
	struct opp_object*obj = data_to_opp_object(data);
	struct opp_factory*obuff = obj->obuff;
	SYNC_ASSERT(obuff->callback);
	CHECK_OBJ(obj);
	va_list va;
	va_start(va, cb_data);
	int ret = obuff->callback(data, callback, cb_data, va, obj->slots*obuff->obj_size - sizeof(struct opp_object));
	va_end(va);
	return ret;
}

#ifdef OPP_HAS_TOKEN
void*opp_get(struct opp_factory*obuff, int token) {
	int k, idx;
	int pool_idx;
	void*data = NULL;
	struct opp_pool*pool;

	OPP_LOCK(obuff);
	do {
		if( (idx = (token - obuff->token_offset)) < 0 ) break;
		k = idx%obuff->pool_size;
		pool_idx = (idx - k)/obuff->pool_size;

		for(pool = obuff->pools;pool;pool = pool->next) {
			CHECK_POOL(pool);
			if(pool->idx != pool_idx) {
				continue;
			}

			struct opp_object*obj = (struct opp_object*)(pool->head + obuff->obj_size*k);
			BITSTRING_TYPE bsv = *(pool->bitstring+OPP_INDEX_TO_BITSTRING_INDEX(k)*BITFIELD_SIZE);
			int bit_idx = k % BIT_PER_STRING;
//			if(obj->refcount) {
//				SYNC_ASSERT(obj->bit_idx == bit_idx && obj->obuff == obuff && (bsv & 1<<bit_idx));
//			}
			if((bsv & (1<<bit_idx)) && (obj->bit_idx == bit_idx) && obj->refcount
					/*&& (!(obuff->property & OBJ_FACTORY_EXTENDED) || ((struct sync_object_ext_tiny*)(obj+1))->flag != OBJ_ITEM_ZOMBIE)*/) {
				CHECK_OBJ(obj);
				data = obj+1;
				OPPREF(data);
			}
			break;
		}
	} while(0);
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
	return data;
}

void opp_shrink(void*data, int size) {
	struct opp_object*obj = data_to_opp_object(data);
	int slots;
	struct opp_factory*obuff = obj->obuff;
	
	size += sizeof(struct opp_object);
	slots = size / obuff->obj_size + ((size % obuff->obj_size)?1:0);
	
	if(!slots || slots > BIT_PER_STRING || slots == obj->slots) {
		return;
	}
	
	CHECK_OBJ(obj);
	OPP_LOCK(obuff);
	UNSET_PAIRED_BITS(obj);
	
	obj->slots = slots;
	
	SET_PAIRED_BITS(obj);
	if(obuff->callback){
		int new_len = slots*obuff->obj_size - sizeof(struct opp_object);
		static va_list va;
		obuff->callback(data, OPPN_ACTION_SHRINK, &new_len, va, new_len);
	}
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
}


void opp_set_flag_by_token(struct opp_factory*obuff, int token, unsigned int flag) {
	SYNC_ASSERT(obuff->property & OPPF_EXTENDED);
	OPP_LOCK(obuff);
	void*data = opp_get(obuff,token);
	if(data) {
		opp_set_flag(data,flag);
		OPPUNREF(data);
	}
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
}

void opp_unset_flag_by_token(struct opp_factory*obuff, int token, unsigned int flag) {
	SYNC_ASSERT(obuff->property & OPPF_EXTENDED);
	OPP_LOCK(obuff);
	void*data = opp_get(obuff,token);
	if(data) {
		opp_unset_flag(data,flag);
		OPPUNREF(data);
	}
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
}
#endif

void opp_unset_flag(void*data, unsigned int flag) {
	struct opp_object*obj = data_to_opp_object(data);
	CHECK_OBJ(obj);
	SYNC_ASSERT(obj->refcount);
#ifndef SYNC_HAS_ATOMIC_OPERATION
	struct opp_factory*obuff = obj->obuff;
	OPP_LOCK(obuff);
#endif

	SYNC_ASSERT(obj->obuff->property & OPPF_EXTENDED);
	SYNC_ASSERT(!(flag & OPPN_ALL) && !(flag & OPPN_INTERNAL_1) && !(flag & OPPN_INTERNAL_2));
	BINARY_AND_HELPER(SYNC_UWORD16_T, &((struct opp_object_ext*)data)->flag, ~flag);
#ifndef OPP_NO_FLAG_OPTIMIZATION
	if(flag & OPPN_PERFORMANCE) {
		BINARY_AND_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE), ~( 1 << obj->bit_idx));
	}
	if(flag & OPPN_PERFORMANCE1) {
		BINARY_AND_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE1), ~( 1 << obj->bit_idx));
	}
	if(flag & OPPN_PERFORMANCE2) {
		BINARY_AND_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE2), ~( 1 << obj->bit_idx));
	}
	if(flag & OPPN_PERFORMANCE3) {
		BINARY_AND_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE3), ~( 1 << obj->bit_idx));
	}
#endif
#ifndef SYNC_HAS_ATOMIC_OPERATION
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
#endif
}

void opp_set_flag(void*data, unsigned int flag) {
	struct opp_object*obj = data_to_opp_object(data);
	struct opp_object_ext*ext = (struct opp_object_ext*)data;
	CHECK_OBJ(obj);
	SYNC_ASSERT(obj->refcount);
	struct opp_factory*obuff = obj->obuff;
#ifndef SYNC_HAS_ATOMIC_OPERATION
	OPP_LOCK(obuff);
#endif
	SYNC_ASSERT(obuff->property & OPPF_EXTENDED);
	SYNC_ASSERT(!(flag & OPPN_ALL) && !(flag & OPPN_INTERNAL_1) && !(flag & OPPN_INTERNAL_2));
	if((flag & OPPN_ZOMBIE) && (obuff->property & OPPF_SEARCHABLE)) {
#ifdef SYNC_HAS_ATOMIC_OPERATION
		OPP_LOCK(obuff);
#endif
		if((ext->flag & OPPN_INTERNAL_1)) {
			opp_lookup_table_delete(&obuff->tree, ext);
			BINARY_AND_HELPER(SYNC_UWORD16_T, &ext->flag, ~OPPN_INTERNAL_1);
		}
		BINARY_OR_HELPER(SYNC_UWORD16_T, &ext->flag, flag);
#ifdef SYNC_HAS_ATOMIC_OPERATION
		OPP_UNLOCK(obuff);
#endif
	} else {
		BINARY_OR_HELPER(SYNC_UWORD16_T, &ext->flag, flag);
	}
#ifndef OPP_NO_FLAG_OPTIMIZATION
	if(flag & OPPN_PERFORMANCE) {
		BINARY_OR_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE), ( 1 << obj->bit_idx));
	}
	if(flag & OPPN_PERFORMANCE1) {
		BINARY_OR_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE1), ( 1 << obj->bit_idx));
	}
	if(flag & OPPN_PERFORMANCE2) {
		BINARY_OR_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE2), ( 1 << obj->bit_idx));
	}
	if(flag & OPPN_PERFORMANCE3) {
		BINARY_OR_HELPER(SYNC_UWORD16_T, (obj->bitstring+BITFIELD_PERFORMANCE3), ( 1 << obj->bit_idx));
	}
#endif
#ifndef SYNC_HAS_ATOMIC_OPERATION
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
#endif
}


void opp_force_memclean(void*data) {
	struct opp_object*obj = data_to_opp_object(data);
	struct opp_object_ext*ext = (struct opp_object_ext*)data;
	struct opp_factory*obuff = obj->obuff;
	int sz = obj->slots * obuff->obj_size - sizeof(struct opp_object);
	if(obuff->property & OPPF_EXTENDED) {
		memset(ext+1, 0, sz - sizeof(struct opp_object_ext));
	} else {
		memset(data, 0, sz);
	}
}

void opp_set_hash(void*data, opp_hash_t hash) {
	struct opp_object*obj = data_to_opp_object(data);
	struct opp_object_ext*ext = (struct opp_object_ext*)data;
	struct opp_factory*obuff = obj->obuff;
	CHECK_OBJ(obj);
	SYNC_ASSERT(obj->refcount);
	SYNC_ASSERT(obuff->property & OPPF_EXTENDED);
	if(obuff->property & OPPF_SEARCHABLE) {
		OPP_LOCK(obuff);
		if((ext->flag & OPPN_INTERNAL_1)) {
			opp_lookup_table_delete(&obuff->tree, ext);
			BINARY_AND_HELPER(SYNC_UWORD16_T, &ext->flag, ~OPPN_INTERNAL_1);
		}

		ext->hash = hash;
		if(!(ext->flag & OPPN_ZOMBIE) && !opp_lookup_table_insert(&obuff->tree, ext)) {
			BINARY_OR_HELPER(SYNC_UWORD16_T, &ext->flag, OPPN_INTERNAL_1);
		}
		CHECK_OBJ(obj);
		DO_AUTO_GC_CHECK(obuff);
		OPP_UNLOCK(obuff);
	} else {
		ext->hash = hash;
	}
}

#ifdef OPP_CAN_TEST_FLAG
int obj_test_flag(const void*data, unsigned int flag) {
	const struct opp_object*obj = data_to_opp_object(data);
	int ret = 0;
	CHECK_OBJ(obj);
	SYNC_ASSERT(obj->refcount);
	OPP_LOCK(obj->obuff);
	ret = (obj->flag & flag);
	DO_AUTO_GC_CHECK(obj->obuff);
	OPP_UNLOCK(obj->obuff);
	return ret;
}
#endif

void*opp_ref(void*data, const char*filename, int lineno) {
	struct opp_object*obj = data_to_opp_object(data);
	SYNC_ASSERT(data);
	CHECK_OBJ(obj);
#ifdef SYNC_HAS_ATOMIC_OPERATION
#ifdef OPP_DEBUG_REFCOUNT
	obj->rt_idx++;
	obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	if(!(obj->rt_idx >= 2 && obj->ref_trace[obj->rt_idx-2].lineno == lineno)) {
		obj->ref_trace[obj->rt_idx].filename = filename;
		obj->ref_trace[obj->rt_idx].lineno = lineno;
		obj->ref_trace[obj->rt_idx].refcount = obj->refcount;
		obj->ref_trace[obj->rt_idx].op = '+';
	} else {
		obj->rt_idx--;
		obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	}
#endif

	do {
		refcount_t oldval,newval;
		oldval = obj->refcount;
		newval = oldval+1;
		if(!oldval || newval > 40000) {
			return NULL;
		}
		if(sync_do_compare_and_swap(&(obj->refcount), oldval, newval)) {
			break;
		}
	} while(1);
#else
	OPP_LOCK(obj->obuff);

#ifdef OPP_DEBUG_REFCOUNT
	obj->rt_idx++;
	obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	obj->ref_trace[obj->rt_idx].filename = filename;
	obj->ref_trace[obj->rt_idx].lineno = lineno;
	obj->ref_trace[obj->rt_idx].refcount = obj->refcount;
	obj->ref_trace[obj->rt_idx].op = '+';
#endif

	SYNC_ASSERT(obj->refcount);
	obj->refcount++;
	DO_AUTO_GC_CHECK(obj->obuff);
	OPP_UNLOCK(obj->obuff);
#endif
	return data;
}

#if 0
int opp_assert_ref_count(void*data, int refcount, const char*filename, int lineno) {
	struct opp_object*obj = data_to_opp_object(*data);
	SYNC_ASSERT(data);
	CHECK_OBJ(obj);
	SYNC_ASSERT(obj->refcount == refcount);
	return 0;
}
#endif

//#ifdef OPP_BUFFER_HAS_LOCK
void opp_unref_unlocked(void**data, const char*filename, int lineno) {
	struct opp_object*obj = data_to_opp_object(*data);
#ifdef OPP_HAS_RECYCLING
	struct opp_pool*pool;
#endif
	if(!*data)
		return;
	CHECK_OBJ(obj);
#ifdef OPP_DEBUG_REFCOUNT
	obj->rt_idx++;
	obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	if(!(obj->rt_idx >= 2 && obj->ref_trace[obj->rt_idx-2].lineno == lineno)) {
		obj->ref_trace[obj->rt_idx].filename = filename;
		obj->ref_trace[obj->rt_idx].lineno = lineno;
		obj->ref_trace[obj->rt_idx].refcount = obj->refcount;
		obj->ref_trace[obj->rt_idx].op = '-';
	} else {
		obj->rt_idx--;
		obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	}
#endif

	*data = NULL;
	SYNC_ASSERT(obj->refcount);
#ifdef SYNC_HAS_ATOMIC_OPERATION
	refcount_t oldval,newval;
	do {
		oldval = obj->refcount;
		newval = oldval - 1;
		SYNC_ASSERT(oldval);
	} while(!sync_do_compare_and_swap(&(obj->refcount), oldval, newval));
	if(!newval) {
#else
	obj->refcount--;
	if(!obj->refcount) {
#endif
#ifdef OPP_HAS_RECYCLING
		for(pool = obj->obuff->pools;pool;pool = pool->next) {
			CHECK_POOL(pool);
			if((void*)obj <= (void*)pool->end && (void*)obj >= (void*)pool->head) {
				obj->recycled = pool->recycled;
				pool->recycled = obj;
				CHECK_POOL(pool);
				break;
			}
		}
#endif
		*(obj->bitstring) &= ~( 1 << obj->bit_idx);
		if(obj->obuff->property & OPPF_SWEEP_ON_UNREF) {
			OPP_FINALIZE_NOW(obj->obuff,obj);
		}
		obj->obuff->use_count--;
	}
	DO_AUTO_GC_CHECK(obj->obuff);
}
//#endif

void opp_unref(void**data, const char*filename, int lineno) {
	struct opp_object*obj = data_to_opp_object(*data);
	if(!*data)
		return;
#ifdef OPP_DEBUG_REFCOUNT
	obj->rt_idx++;
	obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	if(!(obj->rt_idx >= 2 && obj->ref_trace[obj->rt_idx-2].lineno == lineno)) {
		obj->ref_trace[obj->rt_idx].filename = filename;
		obj->ref_trace[obj->rt_idx].lineno = lineno;
		obj->ref_trace[obj->rt_idx].refcount = obj->refcount;
		obj->ref_trace[obj->rt_idx].op = '-';
	} else {
		obj->rt_idx--;
		obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
	}
#endif

	*data = NULL;
#ifdef SYNC_HAS_ATOMIC_OPERATION
	refcount_t oldval,newval;
	struct opp_factory*obuff = NULL;
	do {
		oldval = obj->refcount;
		newval = oldval - 1;
		SYNC_ASSERT(oldval);
	} while(!sync_do_compare_and_swap(&(obj->refcount), oldval, newval));
	if(newval) {
		return;
	} else {
		obuff = obj->obuff;
		OPP_LOCK(obuff);
#else
	SYNC_ASSERT(obj->refcount);
	struct opp_factory*obuff = obj->obuff;
	OPP_LOCK(obuff);
	obj->refcount--;
	if(!obj->refcount) {
#endif
		CHECK_OBJ(obj);

#ifdef OPP_HAS_RECYCLING
		struct opp_pool*pool;
		for(pool = obj->obuff->pools;pool;pool = pool->next) {
			CHECK_POOL(pool);
			if((void*)obj <= (void*)pool->end && (void*)obj >= (void*)pool->head) {
				obj->recycled = pool->recycled;
				pool->recycled = obj;
				CHECK_POOL(pool);
				break;
			}
		}
#endif
		*(obj->bitstring) &= ~( 1 << obj->bit_idx);
		if(obuff->property & OPPF_SWEEP_ON_UNREF) {
			OPP_FINALIZE_NOW(obuff,obj);
		}
		obuff->use_count--;
	}
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
}

#ifdef OPP_HAS_HIJACK
int opp_hijack(void**src, void*dest, const char*filename, int lineno) {
	struct opp_object*obj = data_to_opp_object(*src);
	int ret = -1;
	struct opp_factory*obuff = obj->obuff;
#ifdef OPP_HAS_RECYCLING
	struct opp_pool*pool;
#endif
	OPP_LOCK(obuff);
	do {
		CHECK_OBJ(obj);
#ifdef OPP_DEBUG_REFCOUNT
		obj->rt_idx++;
		obj->rt_idx = obj->rt_idx%OPP_TRACE_SIZE;
		obj->ref_trace[obj->rt_idx].filename = filename;
		obj->ref_trace[obj->rt_idx].lineno = lineno;
		obj->ref_trace[obj->rt_idx].refcount = obj->refcount;
		obj->ref_trace[obj->rt_idx].op = 0;
#endif

#ifdef OPP_DEBUG
		SYNC_ASSERT(obj->refcount);
#endif
		// see if we can do hijack
		if(obj->refcount != 1) {
			break;
		}

		// hijack
//		memcpy(dest,*src,obuff->obj_size - sizeof(struct opp_object));
		if(obuff->callback){
			va_list ap;
			obuff->callback(*src, OPPN_ACTION_DEEP_COPY, dest, ap);
		}
		obj->refcount--;
#ifdef OPP_HAS_RECYCLING
		for(pool = obj->obuff->pools;pool;pool = pool->next) {
			CHECK_POOL(pool);
			if((void*)obj <= (void*)pool->end && (void*)obj >= (void*)pool->head) {
				obj->recycled = pool->recycled;
				pool->recycled = obj;
				CHECK_POOL(pool);
				break;
			}
		}
#endif
		// clear flags
		*(obj->bitstring) &= ~( 1 << obj->bit_idx);
		*(obj->bitstring+BITFIELD_FINALIZE) &= ~( 1 << obj->bit_idx);
		UNSET_PAIRED_BITS(obj);
		obuff->use_count--;
		*src = dest;
		ret = 0;
	} while(0);
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
	return ret;
}
#endif

#define CHECK_WEAK_OBJ(x) ({if(!x->refcount){bsv &= ~( 1 << bit_idx);continue;}})
void*opp_search(struct opp_factory*obuff
	, opp_hash_t hash, obj_comp_t compare_func, const void*compare_data, void**rval) {
	void*ret = NULL;
	SYNC_ASSERT(obuff->property & OPPF_SEARCHABLE);
	OPP_LOCK(obuff);
	if((ret = opp_lookup_table_search(&obuff->tree, hash, compare_func, compare_data))) {
		OPPREF(ret);
	}
	OPP_UNLOCK(obuff);
	if(rval != NULL) {
		*rval = ret;
	}
	return ret;
}

void*opp_find_list_full_donot_use(struct opp_factory*obuff, obj_comp_t compare_func
		, const void*compare_data, unsigned int if_flag, unsigned int if_not_flag, opp_hash_t hash, int shouldref) {
	int k;
	BITSTRING_TYPE*bitstring,bsv;
	SYNC_UWORD16_T oflag;
	SYNC_UWORD16_T bit_idx, obj_idx;
	void *retval = NULL;
	const struct opp_object *obj = NULL;
	const opp_pointer_ext_t*item = NULL;
#ifdef OPTIMIZE_OBJ_LOOP
	int use_count = 0, iteration_count = 0;
#endif
	struct opp_pool*pool;
	OPP_LOCK(obuff);
	if(!obuff->use_count) {
		OPP_UNLOCK(obuff);
		return NULL;
	}
#ifdef OPTIMIZE_OBJ_LOOP
	use_count = obuff->use_count;
#endif
	for(pool = obuff->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
#ifdef OPTIMIZE_OBJ_LOOP
		if(iteration_count >= use_count) {
			break;
		}
#endif
		// traverse the bitset
		k = 0;
		bitstring = pool->bitstring;
		for(;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {

			bsv = *bitstring;
#ifdef OPTIMIZE_OBJ_LOOP
			if(iteration_count >= use_count) {
				break;
			}
			iteration_count += SYNC_OBJ_POPCOUNT(bsv);
#endif
			// get the bits to finalize
			while(bsv) {
				CHECK_POOL(pool);
				bit_idx = SYNC_OBJ_CTZ(bsv);
				obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
				if(obj_idx < obuff->pool_size) {
					obj = (struct opp_object*)(pool->head + obj_idx*obuff->obj_size);
					CHECK_OBJ(obj);
					CHECK_WEAK_OBJ(obj);
					item = (opp_pointer_ext_t*)(obj+1);
					obj = data_to_opp_object(item->obj_data);
					CHECK_OBJ(obj);
					CHECK_WEAK_OBJ(obj);
					if(obuff->property & OPPF_EXTENDED) {
						oflag = ((struct opp_object_ext*)(obj+1))->flag;
						if(!(oflag & if_flag) || (oflag & if_not_flag) || (hash != 0 && ((struct opp_object_ext*)(obj+1))->hash != hash)) {
							// clear
							bsv &= ~( 1 << bit_idx);
							continue;
						}
					}
					if(compare_func(compare_data, item->obj_data)) {
						retval = item->obj_data;
						if(shouldref) {
							OPPREF(retval);
						}
						goto exit_point;
					}
					CHECK_OBJ(obj);
					// clear
					bsv &= ~( 1 << bit_idx);
				}
			}
		}
	}
	exit_point:
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
	return retval;
}


void*opp_find_full(struct opp_factory*obuff, obj_comp_t compare_func, const void*compare_data
		, unsigned int if_flag, unsigned int if_not_flag, opp_hash_t hash, unsigned int shouldref) {
	int k;
	BITSTRING_TYPE*bitstring,bsv;
	void*data;
	SYNC_UWORD16_T oflag;
	SYNC_UWORD16_T bit_idx,obj_idx;
	void *retval = NULL;
	const struct opp_object *obj = NULL;
#ifdef OPTIMIZE_OBJ_LOOP
	int use_count = 0, iteration_count = 0;
#endif
	struct opp_pool*pool;
	OPP_LOCK(obuff);
	if(!obuff->use_count) {
		OPP_UNLOCK(obuff);
		return NULL;
	}
#ifdef OPTIMIZE_OBJ_LOOP
	use_count = obuff->use_count;
#endif

	for(pool = obuff->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
#ifdef OPTIMIZE_OBJ_LOOP
		if(iteration_count >= use_count) {
			break;
		}
#endif
		// traverse the bitset
		k = 0;
		bitstring = pool->bitstring;
		for(;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {

			bsv = *bitstring;
#ifdef OPTIMIZE_OBJ_LOOP
			if(iteration_count >= use_count) {
				break;
			}
			iteration_count += SYNC_OBJ_POPCOUNT(bsv);
#endif
#ifndef OPP_NO_FLAG_OPTIMIZATION
			if(obuff->property & OPPF_EXTENDED) {
				if((if_flag & OPPN_PERFORMANCE) && !(if_flag & ~OPPN_PERFORMANCE)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE);
				}
				if(if_not_flag & OPPN_PERFORMANCE) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE));
				}
				if((if_flag & OPPN_PERFORMANCE1) && !(if_flag & ~OPPN_PERFORMANCE1)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE1);
				}
				if(if_not_flag & OPPN_PERFORMANCE1) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE1));
				}
				if((if_flag & OPPN_PERFORMANCE2) && !(if_flag & ~OPPN_PERFORMANCE2)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE2);
				}
				if(if_not_flag & OPPN_PERFORMANCE2) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE2));
				}
				if((if_flag & OPPN_PERFORMANCE3) && !(if_flag & ~OPPN_PERFORMANCE3)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE3);
				}
				if(if_not_flag & OPPN_PERFORMANCE3) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE3));
				}
			}
#endif
			// get the bits to finalize
			while(bsv) {
				CHECK_POOL(pool);
				bit_idx = SYNC_OBJ_CTZ(bsv);
				obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
				if(obj_idx < obuff->pool_size) {
					obj = (const struct opp_object*)(pool->head + obj_idx*obuff->obj_size);
					data = (void*)(obj+1);
					CHECK_OBJ(obj);
					CHECK_WEAK_OBJ(obj);
					if(obuff->property & OPPF_EXTENDED) {
						oflag = ((struct opp_object_ext*)(data))->flag;
						if(!(oflag & if_flag) || (oflag & if_not_flag) || (hash != 0 && ((struct opp_object_ext*)(data))->hash != hash)) {
							// clear
							bsv &= ~( 1 << bit_idx);
							continue;
						}
					}
					if((compare_func?compare_func(compare_data, data):1)) {
						retval = data;
						if(shouldref) {
							OPPREF(retval);
						}
						goto exit_point;
					}
					CHECK_OBJ(obj);
					// clear
					bsv &= ~( 1 << bit_idx);
				}
			}
		}
	}
	exit_point:
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
	return retval;
}

int opp_count_donot_use(const struct opp_factory*obuff) {
	return obuff->use_count;
}

static void opp_factory_gc_nolock(struct opp_factory*obuff) {
	int k;
	BITSTRING_TYPE*bitstring,bsv;
	int use_count;
	SYNC_UWORD16_T bit_idx,obj_idx;
	struct opp_object*obj;
	struct opp_pool*pool,*prev_pool,*next;
	opp_factory_profiler_checkleak();
	for(pool = obuff->pools, prev_pool = NULL;pool;pool = next) {
		use_count = 0;

		CHECK_POOL(pool);
		next = pool->next;
		// traverse the bitset
		k = 0;
		bitstring = pool->bitstring;
		for(;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {

			use_count += SYNC_OBJ_POPCOUNT((*bitstring) & BITSTRING_MASK);
			// get the bits to finalize
			while((bsv = (~(*bitstring)) & (*(bitstring+BITFIELD_FINALIZE)))) {
				CHECK_POOL(pool);
				bit_idx = SYNC_OBJ_CTZ(bsv);
				obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
				if(obj_idx < obuff->pool_size) {
					obj = (struct opp_object*)(pool->head + obj_idx*obuff->obj_size);
					OPP_FINALIZE_NOW(obuff,obj);
				}
			}
		}

		// destroy memory chunk
		if(use_count == 0) {
#ifdef FACTORY_OBJ_SIGN
//			obj = (struct sync_object*)pool->head;
//			CHECK_OBJ(obj);
#endif
			if(prev_pool) {
				prev_pool->next = pool->next;
			} else {
				obuff->pools = pool->next;
			}
			if(pool->flags & OPP_POOL_FREEABLE) {
				//sync_free(pool);
				profiler_replace_free(pool, obuff->memory_chunk_size);
			}
			pool = NULL;
			obuff->pool_count--;
			opp_factory_profiler_checkleak();
		} else {
			prev_pool = pool;
		}
	}
	opp_factory_profiler_checkleak();
}

int opp_exists(struct opp_factory*obuff, const void*data) {
	struct opp_pool*pool = NULL;
	int found = 0;
	OPP_LOCK(obuff);

	for(pool = obuff->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
		// TODO check the bitflag not the refcount
		if(data >= (void*)pool->head && data < (void*)pool->end) {
			found = 1;
			CHECK_OBJ((struct opp_object*)((unsigned char*)data - sizeof(struct opp_object)));
			break;
		}
	}
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
	return found;
}

void opp_factory_lock_donot_use(struct opp_factory*obuff) {
	OPP_LOCK(obuff);
}

void opp_factory_unlock_donot_use(struct opp_factory*obuff) {
	OPP_UNLOCK(obuff);
}

void opp_factory_gc_donot_use(struct opp_factory*obuff) {
	OPP_LOCK(obuff);
	opp_factory_gc_nolock(obuff);
	OPP_UNLOCK(obuff);
}

void opp_factory_list_do_full(struct opp_factory*obuff, obj_do_t obj_do, void*func_data
		, unsigned int if_list_flag, unsigned int if_not_list_flag, unsigned int if_flag, unsigned int if_not_flag
		, opp_hash_t list_hash, opp_hash_t hash) {
	int k;
	BITSTRING_TYPE*bitstring,bsv;
	SYNC_UWORD16_T oflag;
	SYNC_UWORD16_T bit_idx, obj_idx;
	const struct opp_object *obj = NULL;
	opp_pointer_ext_t*item = NULL;
#ifdef OPTIMIZE_OBJ_LOOP
	int use_count = 0, iteration_count = 0;
#endif
	struct opp_pool*pool;
	OPP_LOCK(obuff);
	if(!obuff->use_count) {
		OPP_UNLOCK(obuff);
		return;
	}
#ifdef OPTIMIZE_OBJ_LOOP
	use_count = obuff->use_count;
#endif
	for(pool = obuff->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
#ifdef OPTIMIZE_OBJ_LOOP
		if(iteration_count >= use_count) {
			break;
		}
#endif

		// traverse the bitset
		k = 0;
		bitstring = pool->bitstring;
		for(;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {

			bsv = *bitstring;
#ifdef OPTIMIZE_OBJ_LOOP
			if(iteration_count >= use_count) {
				break;
			}
			iteration_count += SYNC_OBJ_POPCOUNT(bsv);
#endif
#ifndef OPP_NO_FLAG_OPTIMIZATION
			if(obuff->property & OPPF_EXTENDED) {
				if((if_list_flag & OPPN_PERFORMANCE) && !(if_list_flag & ~OPPN_PERFORMANCE)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE);
				}
				if(if_not_list_flag & OPPN_PERFORMANCE) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE));
				}
				if((if_list_flag & OPPN_PERFORMANCE1) && !(if_list_flag & ~OPPN_PERFORMANCE1)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE1);
				}
				if(if_not_list_flag & OPPN_PERFORMANCE1) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE1));
				}
				if((if_list_flag & OPPN_PERFORMANCE2) && !(if_list_flag & ~OPPN_PERFORMANCE2)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE2);
				}
				if(if_not_list_flag & OPPN_PERFORMANCE2) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE2));
				}
				if((if_list_flag & OPPN_PERFORMANCE3) && !(if_list_flag & ~OPPN_PERFORMANCE3)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE3);
				}
				if(if_not_list_flag & OPPN_PERFORMANCE3) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE3));
				}
			}
#endif
			// get the bits to finalize
			while(bsv) {
				CHECK_POOL(pool);
				bit_idx = SYNC_OBJ_CTZ(bsv);
				obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
				if(obj_idx < obuff->pool_size) {
					obj = (struct opp_object*)(pool->head + obj_idx*obuff->obj_size);
					CHECK_WEAK_OBJ(obj);
					CHECK_OBJ(obj);
					item = (opp_pointer_ext_t*)(obj+1);
					if(obuff->property & OPPF_EXTENDED) {
						oflag = ((struct opp_object_ext*)(obj+1))->flag;
						if(!(oflag & if_flag) || (oflag & if_not_flag)) {
							// clear
							bsv &= ~( 1 << bit_idx);
							continue;
						}
					}
					obj = data_to_opp_object(item->obj_data);
					CHECK_WEAK_OBJ(obj);
					CHECK_OBJ(obj);
					if(obj->obuff->property & OPPF_EXTENDED) {
						oflag = ((struct opp_object_ext*)(obj+1))->flag;
						if(!(oflag & if_flag) || (oflag & if_not_flag) || (hash != 0 && ((struct opp_object_ext*)(obj+1))->hash != hash)) {
							// clear
							bsv &= ~( 1 << bit_idx);
							continue;
						}
					}
					if(obj_do && obj_do(func_data, item)) {
						goto exitpoint;
					}
					CHECK_OBJ(obj);
					// clear
					bsv &= ~( 1 << bit_idx);
				}
			}
		}
	}
exitpoint:
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
}

int opp_iterator_create(struct opp_iterator*iterator, struct opp_factory*fac, unsigned int if_flag, unsigned int if_not_flag, opp_hash_t hash) {
	iterator->fac = fac;
	iterator->pool = NULL;
	iterator->k = 0;
	iterator->if_flag = if_flag;
	iterator->if_not_flag = if_not_flag;
	iterator->hash = hash;
	iterator->bit_idx = -1;
	iterator->data = NULL;
	return 0;
}

void*opp_iterator_next(struct opp_iterator*iterator) {
	struct opp_pool*pool = NULL;
	if(!iterator->fac->use_count) {
		return NULL;
	}
	OPP_LOCK(iterator->fac);
	if(iterator->data)OPPUNREF_UNLOCKED(iterator->data);
	for(pool = iterator->fac->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
		if(iterator->pool && pool != iterator->pool) {
			continue;
		}
		// traverse the bitset
		iterator->pool = NULL;
		int k = iterator->k;
		iterator->k = 0;
		const int pool_size = iterator->fac->pool_size;
		BITSTRING_TYPE*bitstring,bsv;
		bitstring = pool->bitstring;
		bitstring += k*BITFIELD_SIZE;

		for(;BITSTRING_IDX_TO_BITS(k) < pool_size;k++,bitstring+=BITFIELD_SIZE) {

			bsv = *bitstring;
			// test performance flag
#ifndef OPP_NO_FLAG_OPTIMIZATION
			if(bsv && (iterator->fac->property & OPPF_EXTENDED)) {
				if((iterator->if_flag & OPPN_PERFORMANCE) && !(iterator->if_flag & ~OPPN_PERFORMANCE)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE);
				}
				if(iterator->if_not_flag & OPPN_PERFORMANCE) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE));
				}
				if((iterator->if_flag & OPPN_PERFORMANCE1) && !(iterator->if_flag & ~OPPN_PERFORMANCE1)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE1);
				}
				if(iterator->if_not_flag & OPPN_PERFORMANCE1) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE1));
				}
				if((iterator->if_flag & OPPN_PERFORMANCE2) && !(iterator->if_flag & ~OPPN_PERFORMANCE2)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE2);
				}
				if(iterator->if_not_flag & OPPN_PERFORMANCE2) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE2));
				}
				if((iterator->if_flag & OPPN_PERFORMANCE3) && !(iterator->if_flag & ~OPPN_PERFORMANCE3)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE3);
				}
				if(iterator->if_not_flag & OPPN_PERFORMANCE3) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE3));
				}
			}
#endif
			if(iterator->bit_idx != -1) {
				if(iterator->bit_idx == BIT_PER_STRING-1) {
					bsv = 0;
				} else {
					bsv &= ~(( 1 << (iterator->bit_idx+1))-1);
				}
				iterator->bit_idx = -1;
			}

			// get the bits to finalize
			while(bsv) {
				CHECK_POOL(pool);
				SYNC_UWORD16_T bit_idx = SYNC_OBJ_CTZ(bsv);
				SYNC_UWORD16_T obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
				if(obj_idx < pool_size) {
					struct opp_object *obj = (struct opp_object *)(pool->head + obj_idx*iterator->fac->obj_size);
					CHECK_OBJ(obj);
					if(iterator->fac->property & OPPF_EXTENDED) {
						SYNC_UWORD16_T oflag = ((struct opp_object_ext*)(obj+1))->flag;
						if(!(oflag & iterator->if_flag) || (oflag & iterator->if_not_flag) || (iterator->hash != 0 && ((struct opp_object_ext*)(obj+1))->hash != iterator->hash)) {
							// clear
							bsv &= ~( 1 << bit_idx);
							continue;
						}
					}
					void*itdata = OPPREF((obj+1));
					if(!itdata) {
						bsv &= ~( 1 << bit_idx);
						continue;
					}
					iterator->bit_idx = bit_idx;
					iterator->k = k;
					iterator->data = itdata;
					iterator->pool = pool;
					goto exit_point;
				}
			}
		}
	}
exit_point:
	OPP_UNLOCK(iterator->fac);
	return iterator->data;
}

int opp_iterator_destroy(struct opp_iterator*iterator) {
	if(iterator->data)OPPUNREF(iterator->data);
	return 0;
}

void opp_factory_do_pre_order(struct opp_factory*obuff, obj_do_t obj_do, void*func_data, unsigned int if_flag
		, unsigned int if_not_flag) {
	SYNC_ASSERT(obuff->property & OPPF_SEARCHABLE);
	OPP_LOCK(obuff);
	opp_lookup_table_traverse(&obuff->tree, obj_do, func_data, if_flag, if_not_flag);
	OPP_UNLOCK(obuff);
}

void opp_factory_do_full(struct opp_factory*obuff, obj_do_t obj_do, void*func_data, unsigned int if_flag
		, unsigned int if_not_flag, opp_hash_t hash) {
#if 0
	int i;
	SYNC_UWORD8_T*j;
	OPP_LOCK(obuff);
	for(i=0;i<OBJ_MAX_POOL_COUNT;i++) {
		if(pool->bitstring) {
			j = pool->head;
			for(;j<pool->end;j+=obuff->obj_size) {
				if(((struct opp_object*)(j))->refcount && (((struct opp_object*)(j))->flag & if_flag) && !(((struct opp_object*)(j))->flag & if_not_flag) && (hash == 0 || hash == ((struct opp_object*)(j))->flag)) {
					if(obj_do && obj_do(func_data, j + sizeof(struct opp_object))) {
						goto exitpoint;
					}
				}
			}
		}
	}
exitpoint:
	OPP_UNLOCK(obuff);
#else
	int k;
	BITSTRING_TYPE*bitstring,bsv;
	SYNC_UWORD16_T oflag;
	SYNC_UWORD16_T bit_idx, obj_idx;
	const struct opp_object *obj = NULL;
#ifdef OPTIMIZE_OBJ_LOOP
	int use_count = 0, iteration_count = 0;
#endif
	struct opp_pool*pool;
	OPP_LOCK(obuff);
	if(!obuff->use_count) {
		OPP_UNLOCK(obuff);
		return;
	}
#ifdef OPTIMIZE_OBJ_LOOP
	use_count = obuff->use_count;
#endif
	for(pool = obuff->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
#ifdef OPTIMIZE_OBJ_LOOP
		if(iteration_count >= use_count) {
			break;
		}
#endif
		// traverse the bitset
		k = 0;
		bitstring = pool->bitstring;
		for(;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {

			bsv = *bitstring;
#ifdef OPTIMIZE_OBJ_LOOP
			if(iteration_count >= use_count) {
				break;
			}
			iteration_count += SYNC_OBJ_POPCOUNT(bsv);
#endif
#ifndef OPP_NO_FLAG_OPTIMIZATION
			if(obuff->property & OPPF_EXTENDED) {
				if((if_flag & OPPN_PERFORMANCE) && !(if_flag & ~OPPN_PERFORMANCE)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE);
				}
				if((if_flag & OPPN_PERFORMANCE1) && !(if_flag & ~OPPN_PERFORMANCE1)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE1);
				}
				if((if_flag & OPPN_PERFORMANCE2) && !(if_flag & ~OPPN_PERFORMANCE2)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE2);
				}
				if((if_flag & OPPN_PERFORMANCE3) && !(if_flag & ~OPPN_PERFORMANCE3)) {
					bsv &= *(bitstring+BITFIELD_PERFORMANCE3);
				}
				if(if_not_flag & OPPN_PERFORMANCE) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE));
				}
				if(if_not_flag & OPPN_PERFORMANCE1) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE1));
				}
				if(if_not_flag & OPPN_PERFORMANCE2) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE2));
				}
				if(if_not_flag & OPPN_PERFORMANCE3) {
					bsv &= ~(*(bitstring+BITFIELD_PERFORMANCE3));
				}
			}
#endif
			// get the bits to finalize
			while(bsv) {
				CHECK_POOL(pool);
				bit_idx = SYNC_OBJ_CTZ(bsv);
				obj_idx = BITSTRING_IDX_TO_BITS(k) + bit_idx;
				if(obj_idx < obuff->pool_size) {
					obj = (struct opp_object*)(pool->head + obj_idx*obuff->obj_size);
					CHECK_OBJ(obj);
					if(obuff->property & OPPF_EXTENDED) {
						oflag = ((struct opp_object_ext*)(obj+1))->flag;
						if(!(oflag & if_flag) || (oflag & if_not_flag) || (hash != 0 && ((struct opp_object_ext*)(obj+1))->hash != hash)) {
							// clear
							bsv &= ~( 1 << bit_idx);
							continue;
						}
					}
					if(obj_do && obj_do(func_data, (void*)(obj+1))) {
						goto exitpoint;
					}
//					CHECK_OBJ(obj);
					// clear
					bsv &= ~( 1 << bit_idx);
				}
			}
		}
	}
exitpoint:
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
#endif
}

struct dump_log {
	void (*log)(void *log_data, const char*fmt, ...);
	void*log_data;
};

#ifdef OPP_DEBUG_REFCOUNT
static int obj_debug_dump(const void*data, const void*func_data) {
	const struct dump_log*dump = (const struct dump_log*)func_data;
	const struct opp_object*obj = data_to_opp_object(data);
	int i;

	dump->log(dump->log_data, "== Ref:%d\n", obj->refcount);
	int idx = obj->rt_idx+1;
	for(i=0; i<OPP_TRACE_SIZE; i++,idx++) {
		idx = idx%OPP_TRACE_SIZE;

		if(obj->ref_trace[idx].filename) {
			dump->log(dump->log_data, "== count:%d[%c],file:%s(%d)\n"
					, obj->ref_trace[idx].refcount
					, obj->ref_trace[idx].op
					, obj->ref_trace[idx].filename
					, obj->ref_trace[idx].lineno);
		}
	}
	return 0;
}
#endif

void opp_factory_verb(struct opp_factory*obuff, opp_verb_t verb_obj, const void*func_data, void (*log)(void *log_data, const char*fmt, ...), void*log_data) {
#if 0
	int i, use_count = 0, pool_count = 0;
	SYNC_UWORD8_T*j;
	OPP_LOCK(obuff);
	for(i=0;i<OBJ_MAX_POOL_COUNT;i++) {
		if(pool->bitstring) {
			j = pool->head;
			for(;j<pool->end;j+=obuff->obj_size) {
				if(((struct opp_object*)(j))->refcount) {
					if(verb_obj)verb_obj(j + sizeof(struct opp_object), func_data);
					use_count++;
				}
			}
			pool_count++;
		}
	}

	if(log)
	log(log_data, "pool count:%d, use count: %d, total memory: %d bytes, total used: %d bytes"
//#ifdef OPP_DEBUG
	", obuff use count(internal) :%d"
	", obuff slot use count(internal) :%d"
	", bitstring size :%d"
	", pool size :%d"
//#endif
	"\n"
		, pool_count
		, use_count
		, (int)(pool_count*obuff->memory_chunk_size)
		, (int)(obuff->slot_use_count*obuff->obj_size)
//#ifdef OPP_DEBUG
		, obuff->use_count
		, obuff->slot_use_count
		, (int)obuff->bitstring_size
		, (int)obuff->pool_size
//#endif
	);
	DO_AUTO_GC_CHECK(obuff);
	OPP_UNLOCK(obuff);
#else
#ifdef OPP_DEBUG_REFCOUNT
	struct dump_log dump = {.log = log, .log_data = log_data};
	if(!verb_obj) {
		verb_obj = obj_debug_dump;
		func_data = &dump;
	}
#endif
	OPP_LOCK(obuff);
	opp_factory_do_full(obuff, (int (*)(void*data, void*func_data))verb_obj, (void*)func_data, OPPN_ALL, 0, 0);
	if(log) {
#if 0
		if((obuff->property & OPPF_SEARCHABLE) && obuff->tree.rb_count) {
			opp_lookup_table_verb(&obuff->tree, "hashtable", log, log_data);
		}
#endif
		log(log_data, "pool count:%d, total memory: %d bytes, used: %d bytes"
		", %d objs"
		", slots :%d"
		", bitstring size :%d"
		", pool size :%d"
		"\n"
			, obuff->pool_count
			, (int)(obuff->pool_count*obuff->memory_chunk_size)
			, (int)(obuff->slot_use_count*obuff->obj_size)
			, obuff->use_count
			, obuff->slot_use_count
			, (int)obuff->bitstring_size
			, (int)obuff->pool_size
		);
	}
	OPP_UNLOCK(obuff);
#endif
}

void opp_factory_destroy(struct opp_factory*obuff) {
	BITSTRING_TYPE*bitstring;
	int k;
	struct opp_pool*pool;
	if(obuff->sign != OPPF_INITIALIZED_INTERNAL) {
		return;
	}

	OPP_LOCK(obuff);
	for(pool = obuff->pools;pool;pool = pool->next) {
		CHECK_POOL(pool);
		bitstring = pool->bitstring;
		for(k=0;BITSTRING_IDX_TO_BITS(k) < obuff->pool_size;k++,bitstring+=BITFIELD_SIZE) {
			*bitstring = 0;
		}
	}
	opp_factory_gc_nolock(obuff);
	obuff->sign = 1;
	OPP_UNLOCK(obuff);
#ifdef OPP_BUFFER_HAS_LOCK
	if((obuff->property &  OPPF_HAS_LOCK)) {
		sync_mutex_destroy(&obuff->lock);
	}
#endif
}


#ifdef TEST_OBJ_FACTORY_UTILS
int opp_dump(const void*data, void (*log)(void *log_data, const char*fmt, ...), void*log_data) {
#ifdef OPP_DEBUG_REFCOUNT
	struct dump_log dump = {.log = log, .log_data = log_data};
	return obj_debug_dump(data, &dump);
#else
	return 0;
#endif
}

struct pencil {
	struct opp_object_ext opp_internal_ext;
	int color;
	int depth;
};

struct pencil_logger {
	void (*log)(void *log_data, const char*fmt, ...);
	void*log_data;
};

static int pencil_verb(const void*data, const void*func_data) {
	const struct pencil* pen = data;
	const struct pencil_logger*logger = func_data;
	logger->log(logger->log_data, "Pen (color:%d,depth:%d)\n",pen->color,pen->depth);
	return 0;
}

static int pencil_compare(const void*compare_data, const void*data) {
	const int *color = compare_data;
	const struct pencil* pen = data;
	if(pen->color == *color) return 1;
	return 0;
}

static int pencil_compare_all(const void*compare_data, const void*data) {
	return 1;
}

static int pencil_do(void*data, void*func_data) {
	const struct pencil* pen = data;
	const struct pencil_logger*logger = func_data;
	logger->log(logger->log_data, "Pen (color:%d,depth:%d)\n", pen->color,pen->depth);
	return 0;
}

static int obj_utils_test_helper(int inc, struct pencil_logger*logger) {
	struct opp_factory bpencil;
	struct pencil*pen;
	struct pencil hijacked;
	struct opp_factory list;
	opp_pointer_ext_t*item = NULL;
	int count = 0;
	int color = 3;
	int idx = 0;
	int depth_list[17] = {1, 2, 2, 3, 4, 5, 0, 7, 8, 9, 3, 4, 5, 6, 7, 8, 9};
	int ret = 0;

	logger->log(logger->log_data, "Testing %d\n", inc);
	opp_factory_create_full(&bpencil, inc, sizeof(struct pencil), 0, OPPF_EXTENDED, NULL);

	// create 10 pencils
	for(idx = 0; idx < 10; idx++) {
		pen = OPP_ALLOC1(&bpencil);
		pen->color = (idx%2)?3:1;
		pen->depth = idx;
		SYNC_ASSERT(pen->opp_internal_ext.flag == OPPN_ALL);
	}
	// remove 3
	pen = opp_get(&bpencil, 0);
	OPPUNREF(pen);
	pen = opp_get(&bpencil, 1);
	OPP_FACTORY_HIJACK(pen,&hijacked); // hijack one
	pen = opp_get(&bpencil, 6);
	OPPUNREF(pen);
	if(inc%2) {
		opp_factory_gc_donot_use(&bpencil);
	}
	// create more 10
	for(idx = 0; idx < 10; idx++) {
		pen = OPP_ALLOC1(&bpencil);
		pen->color = (idx%2)?3:1;
		pen->depth = idx;
		SYNC_ASSERT(pen->opp_internal_ext.flag == OPPN_ALL);
	}
	opp_factory_verb(&bpencil, pencil_verb, logger, logger->log, logger->log_data);

	if(!OPP_FIND(&bpencil, pencil_compare, &color)) {
		SYNC_LOG(SYNC_ERROR, "TEST failed while finding color:3\n");
		ret = -1;
	}

	OPP_LIST_CREATE_NOLOCK_EXT(&list, 10);
	if((count = opp_list_find_from_factory(&bpencil, &list, pencil_compare_all, NULL))) {
		if(count != 17) {
			SYNC_LOG(SYNC_ERROR, "TEST failed while finding all\n");
			ret = 1;
		}
		for(idx = 0; (item = opp_get(&list,idx)); idx++) {
			pen = item->obj_data;
			if(pen->depth != depth_list[idx]) {
				SYNC_LOG(SYNC_ERROR, "TEST failed while matching depth\n");
				ret = -1;
			}
			//ast_verb(1, "There is a pencil in the list (color:%d,depth:%d)\n", pen->color, pen->depth);
		}
	}
	opp_factory_destroy(&list);
	OPP_LIST_CREATE_NOLOCK_EXT(&list, 10);
	if((count = opp_list_find_from_factory(&bpencil, &list, pencil_compare, &color))) {
		if(count != 9) {
			SYNC_LOG(SYNC_ERROR, "TEST failed while finding pencil color");
			ret = 1;
		}
		for(idx = 0; (item = opp_get(&list,idx)); idx++) {
			pen = item->obj_data;
			if(pen->color != 3) {
				SYNC_LOG(SYNC_ERROR, "TEST failed while checking pencil color\n");
				ret = -1;
			}
			//ast_verb(1, "There is a pencil in the list (color:%d,depth:%d)\n", pen->color, pen->depth);
		}
	}

	opp_factory_destroy(&list);
	OPP_FACTORY_DO(&bpencil, pencil_do, logger);

	opp_factory_gc_donot_use(&bpencil);
	opp_factory_destroy(&bpencil);
	logger->log(logger->log_data, "Test [OK]\n");

	return ret;
}

static int obj_utils_test_search_tree(struct pencil_logger*logger) {
	struct opp_factory bpencil;
	struct pencil*pen,*first;
	int ret = -1;
	int i;
	opp_factory_create_full(&bpencil, 5,sizeof(struct pencil), 0, OPPF_SEARCHABLE | OPPF_EXTENDED, NULL);

	first = OPP_ALLOC1(&bpencil);
	opp_set_hash(first, 0);
	for(i=1;i<10;i++) {
		pen = OPP_ALLOC1(&bpencil);
		opp_set_hash(pen, i);
	}
	// try to delete the root
	OPPUNREF(first);
	if((pen = opp_search(&bpencil, 4, NULL, NULL)) && pen->opp_internal_ext.hash == 4) {
		ret = 0;
		logger->log(logger->log_data, "Search Test [OK]\n");
	} else {
		logger->log(logger->log_data, "Search Test [FAILED]\n");
	}
	opp_factory_destroy(&bpencil);
	return ret;
}

static int obj_utils_test_helper2(struct pencil_logger*logger) {
	struct opp_factory bstrings;
	int i;
	const int CUT_SIZE = 8;
	const char*test_string = "Need help with Red Hat Enterprise Linux? The Global Support Services portal features comprehensive options to getting assistance in managing your Linux system. You've got Red Hat Enterprise Linux, now get the skills. Check out Red Hat's training courses and industry-acclaimed certifications — the most respected certifications in the Linux space. Need help with Red Hat Enterprise Linux? The Global Support Services portal features comprehensive options to getting assistance in managing your Linux system. You've got Red Hat Enterprise Linux, now get the skills. Check out Red Hat's training courses and industry-acclaimed certifications — the most respected certifications in the Linux space.";
	char*string;
	int ret = 0;
	opp_factory_create_full(&bstrings, 32, 32, 0, OPPF_SWEEP_ON_UNREF, NULL);

	string = opp_alloc4(&bstrings, strlen(test_string) + 1, 0, NULL);
	strcpy(string, test_string);
	logger->log(logger->log_data, "%s\n", string);

	opp_shrink(string, CUT_SIZE);
	string[CUT_SIZE-1] = '\0';

	for(i=0;i<6;i++) {
		string = opp_alloc4(&bstrings, CUT_SIZE, 0, NULL);
		string[CUT_SIZE-1] = '\0';
		logger->log(logger->log_data, "%s\n", string);

		if(strstr(test_string, string)) {
			logger->log(logger->log_data, "Test [OK]\n");
		} else {
			logger->log(logger->log_data, "Test 2 [failed]\n");
			ret = -1;
		}
	}

	opp_factory_destroy(&bstrings);
	return ret;
}

static int obj_utils_test_helper4(struct pencil_logger*logger) {
	struct opp_factory bstrings;
	struct opp_queue queue;
	const int CUT_SIZE = 8;
	const char*test_string = "Need help with Red Hat Enterprise Linux? The Global Support Services portal features comprehensive options to getting assistance in managing your Linux system. You've got Red Hat Enterprise Linux, now get the skills. Check out Red Hat's training courses and industry-acclaimed certifications — the most respected certifications in the Linux space. Need help with Red Hat Enterprise Linux? The Global Support Services portal features comprehensive options to getting assistance in managing your Linux system. You've got Red Hat Enterprise Linux, now get the skills. Check out Red Hat's training courses and industry-acclaimed certifications — the most respected certifications in the Linux space.";
	char*string;
	int ret = 0, i;
	opp_queue_init2(&queue, 0);
	opp_factory_create_full(&bstrings, 32, 2, 0, OPPF_SWEEP_ON_UNREF, NULL);

	string = opp_alloc4(&bstrings, strlen(test_string) + 1, 0, NULL);
	strcpy(string, test_string);
	logger->log(logger->log_data, "%s\n", string);

	opp_shrink(string, CUT_SIZE);
	string[CUT_SIZE-1] = '\0';

	for(i=0;i<6;i++) {
		string = opp_alloc4(&bstrings, CUT_SIZE, 0, NULL);
		string[CUT_SIZE-1] = '\0';
		opp_enqueue(&queue, string);
	}
	
	while((string = opp_dequeue(&queue))) {
		logger->log(logger->log_data, "%s\n", string);
		if(strstr(test_string, string)) {
			logger->log(logger->log_data, "Test [OK]\n");
		} else {
			logger->log(logger->log_data, "Test 4 [failed]\n");
			ret = -1;
		}
		OPPUNREF(string);
	}
	
	opp_queue_deinit(&queue);
	opp_factory_destroy(&bstrings);
	return ret;
}

static int obj_utils_test_helper3(struct pencil_logger*logger) {
	struct opp_factory bstrings;
	const int CUT_SIZE = 8;
	const char*test_string = "Need help with Red Hat Enterprise Linux? The Global Support Services portal features comprehensive options to getting assistance in managing your Linux system. You've got Red Hat Enterprise Linux, now get the skills. Check out Red Hat's training courses and industry-acclaimed certifications — the most respected certifications in the Linux space. Need help with Red Hat Enterprise Linux? The Global Support Services portal features comprehensive options to getting assistance in managing your Linux system. You've got Red Hat Enterprise Linux, now get the skills. Check out Red Hat's training courses and industry-acclaimed certifications — the most respected certifications in the Linux space.";
	char*string, *string2, *string3;
	int ret = 0;
	opp_factory_create_full(&bstrings, 256, 2, 0, OPPF_SWEEP_ON_UNREF, NULL);

	string = opp_alloc4(&bstrings, strlen(test_string) + 1, 0, NULL);
	strcpy(string, test_string);
	logger->log(logger->log_data, "%s\n", string);

	string2 = opp_alloc4(&bstrings, CUT_SIZE, 0, NULL);
	logger->log(logger->log_data, "%s\n", string);

	if(strcmp(string, test_string)) {
		logger->log(logger->log_data, "Test 3 [failed]\n");
		ret = -1;
	}

	opp_shrink(string, CUT_SIZE<<1);
	string3 = opp_alloc4(&bstrings, CUT_SIZE, 0, NULL);
	OPPUNREF(string);
	string = opp_alloc4(&bstrings, CUT_SIZE, 0, NULL);
	
	opp_factory_destroy(&bstrings);
	return ret;
}

static SYNC_UWORD32_T somevalue = 0;
#define SOME_INC() do {\
	old_value = somevalue; \
	new_value += old_value; \
} while(!sync_do_compare_and_swap(&somevalue,old_value,new_value));

#define SOME_DEC() do {\
	old_value = somevalue; \
	new_value += old_value; \
} while(!sync_do_compare_and_swap(&somevalue,old_value,new_value));

int opp_utils_multithreaded_test() {
#ifndef SYNC_HAS_ATOMIC_OPERATION
	return 0;
#else
	volatile SYNC_UWORD32_T old_value,new_value;
	SOME_INC();
	int i;
	for(i=0;i<1000;i++) {
		SOME_INC();
	}
	for(i=0;i<1000;i++) {
		SOME_DEC();
	}
	for(i=0;i<1000;i++) {
		SOME_INC();
	}
	for(i=0;i<1000;i++) {
		SOME_DEC();
	}
	SOME_DEC();
#endif
	return somevalue;
}

int opp_utils_test(void (*alog)(void *log_data, const char*fmt, ...), void*alog_data) {
	int i;
	struct pencil_logger logger = {
		.log = alog,
		.log_data = alog_data,
	};

	opp_queuesystem_init();
	for(i=30;i>6;i--) {
		if(obj_utils_test_helper(i, &logger) != 0) {
			return -1;
		}
	}
	if(obj_utils_test_search_tree(&logger)) {
		return -1;
	}
	if(obj_utils_test_helper2(&logger)) {
		return -1;
	}
	if(obj_utils_test_helper3(&logger)) {
		return -1;
	}
	if(obj_utils_test_helper4(&logger)) {
		return -1;
	}
	alog(alog_data, "Test Fully [OK]\n");
	return 0;
}

#endif

C_CAPSULE_END
