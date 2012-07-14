/*
 * sync_thread.h
 *
 *  Created on: Jan 27, 2011
 *      Author: shuva
 */

#ifndef SYNC_THREAD_H_
#define SYNC_THREAD_H_

#include "config.h"

#ifdef HAS_THREAD
#ifdef ASTERISK_CHANNEL
#include "ast_thread.h"
#else
#ifdef QT
#include "qt_thread.h"
#else
#include "linux_thread.h"
#endif
#endif
#else

typedef char sync_pthread_t;
typedef char sync_mutex_t;
typedef char sync_cond_t;
#define sync_thread_self ({NULL;})
#define sync_mutex_lock(x) ({0;})
#define sync_mutex_trylock(x) ({0;})
#define sync_mutex_unlock(x) ({0;})
#define sync_mutex_create(x) ({0;})
#define sync_mutex_init(x) ({0;})
#define sync_mutex_destroy(x) ({0;})
#define sync_usleep(x) ({0;})
#define sync_pthread_create_background(x,y,z,w) ({0;})
#define sync_pthread_kill(x,y) ({0;})
#define sync_pthread_join(x,y) ({0;})
#define sync_cond_init(x) ({0;})
#define sync_cond_wait(x,y) ({0;})
#define sync_cond_signal(x) ({0;})
#define sync_cond_destroy(x) ({0;})
#define sync_do_fetch_and_add16(x,y) ({x+=y;})
#endif

#define AVOID_DEAD_LOCK(x) do { \
	if(sync_mutex_trylock(x)) { \
		sync_usleep(1); \
	} else { \
		break; \
	} \
} while(1)

#define RETURN_ON_DEAD_LOCK(x, y) do { i=10;while(1){ \
	if(!i--) { \
		SYNC_DEBUG_VERB(1, "Avoiding deadlock at %d in file %s\n", __LINE__, __FILE__);\
		return y; \
	} \
	if(sync_mutex_trylock(x)) { \
		usleep(1); \
	} else { \
		break; \
	} \
}}while(0)


#endif /* SYNC_THREAD_H_ */
