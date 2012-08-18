
#include <pthread.h>
#include "opp/opp_factory.h"
#include "opp/opp_thread_main.h"


extern __thread struct opp_context*__opp_context_id;
int do_things(int*argc, char*args[]) {
	int i;
	for(i = 0; i < 10; i++) {
		printf("We are working on %d thread\n", __opp_context_id->token);
		usleep(20);
	}
}

void*start_thread(void*unused) {
	opp_thread_main(do_things, NULL, NULL);
	return NULL;
}

#define THREAD_COUNT 3
int main(int argc, char*args[]) {
	pthread_t threads[THREAD_COUNT];
	int i;	
	void*retval;

	for(i = 0; i < THREAD_COUNT; i++) {
		pthread_create(threads+i, NULL, start_thread, NULL);
	}
	for(i = 0; i < THREAD_COUNT; i++) {
		pthread_join(threads[i], &retval);
	}
}
