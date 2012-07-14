#ifndef AROOP_CORE_H_
#define AROOP_CORE_H_

#include "core/config.h"
#include "opp/opp_factory.h"

typedef void aroop_god;
typedef int bool;

#define true 1
#define false 0

typedef struct opp_factory opp_factory_t;
typedef struct opp_pool opp_pool_t;
typedef char string;



C_CAPSULE_START

int aroop_init(int argc, char ** argv);
void*aroop_object_alloc (int size, opp_callback_t cb);

C_CAPSULE_END

#endif // AROOP_CORE_H_
