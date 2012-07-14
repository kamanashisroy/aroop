
#include "aroop_core.h"
#include "opp/opp_any_obj.h"

int aroop_init(int argc, char ** argv) {
	opp_any_obj_system_init();
	aroop_txt_system_init();
}

void*aroop_object_alloc (int size, opp_callback_t cb) {
	return opp_any_obj_alloc(size, cb);
}
