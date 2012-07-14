
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


