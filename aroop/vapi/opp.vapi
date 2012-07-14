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
 *  Created on: Jul 15, 2012
 *  Author: Kamanashis Roy (kamanashisroy@gmail.com)
 */


public struct va_list {
}

[CCode (cname = "opp_pool_t")]
public struct opp_pool {
}

[CCode (cname = "opp_object_ext_t")]
public struct opp_object_ext {
}
 
[CCode (cname = "opp_lookup_table_t")]
public struct opp_lookup_table {
	opp_object_ext*rb_root;
	size_t rb_count;                   /* Number of items in tree. */
	ulong rb_generation;       /* Generation number. */
}

[CCode (cname = "opp_factory_t", cheader_filename = "opp/opp_factory.h")]
public struct opp_factory {
	aroop_uword16 sign;
	aroop_uword16 pool_size;
	aroop_uword16 pool_count;
	aroop_uword16 use_count;
	aroop_uword16 slot_use_count;
	aroop_uword16 token_offset;
	aroop_uword16 obj_size;
	aroop_uword16 bitstring_size;
	aroop_uword32 memory_chunk_size;
	aroop_uword8 property;
#if OPP_BUFFER_HAS_LOCK
	sync_mutex_t lock;
#endif
//	int (*initialize)(void*data, const void*init_data, unsigned short size);
//	int (*finalize)(void*data);
	public int callback(void*data, int callback, void*cb_data, va_list ap, int size);
	opp_pool pools;
	opp_lookup_table tree;
}


