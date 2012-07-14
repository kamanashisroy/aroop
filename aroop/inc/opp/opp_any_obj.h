/*
 * obj_watchdog.h
 *
 *  Created on: Jun 17, 2011
 *      Author: ayaskanti
 */

#ifndef OPP_ANY_OBJ_H_
#define OPP_ANY_OBJ_H_


#include "core/config.h"
#include "opp/opp_factory.h"

C_CAPSULE_START

void*opp_any_obj_alloc(int size, opp_callback_t cb, ...);

void opp_any_obj_system_init();
void opp_any_obj_system_deinit();


C_CAPSULE_END

#endif /* OPP_ANY_OBJ_H_ */
