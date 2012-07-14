/*
 * hash.h
 *
 *  Created on: Dec 27, 2010
 *      Author: kgm212
 */

#ifndef OPP_HASH_H_
#define OPP_HASH_H_

#include "opp/opp_factory.h"

C_CAPSULE_START
unsigned long opp_get_hash(const char *z);
unsigned long opp_get_hash_bin(const void*data, int size);

#if 0
int hash_test();
#endif

C_CAPSULE_END

#endif /* OPP_HASH_H_ */
