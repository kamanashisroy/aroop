
#include "aroop_core.h"
#include "opp/opp_any_obj.h"

void*aroop_object_alloc (int size, opp_callback_t cb) {
	return opp_any_obj_alloc(size, cb);
}
