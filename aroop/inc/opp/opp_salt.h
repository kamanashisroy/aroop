/*
 * opp_salt.h
 *
 *  Created on: Dec 13, 2011
 *      Author: ayaskanti
 */

#ifndef OPP_SALT_H_
#define OPP_SALT_H_

#define opp_get_ncode(var, factory, token, code) if((var = opp_get(factory, token))) {code;OPPUNREF(var);}

#define opp_at_ncode(var, factory, index, code) if((factory) && (var = opp_indexed_list_get(factory, index))) {code;OPPUNREF(var);}
#define opp_at_ncode2(var, type, factory, index, code) if((var = (type)opp_indexed_list_get(factory, index))) {code;OPPUNREF(var);}

/*#define opp_search_ncode(var, count, arg, code) ({\
	void*var[count]; \
	oppn_search(); \
})
*/

#if 0
int opp_search_multi(struct opp_factory*obuff
		, opp_hash_t hash
		, void*result[], int resultlen
		, ...);

#define opp_search_multi_ncode(var, count, code, ...) ({\
	void*var[count+1]; \
	oppn_search(); \
})
#endif

#endif /* OPP_SALT_H_ */
