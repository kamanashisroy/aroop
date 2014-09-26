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


[CCode (cname = "SYNC_UWORD8_T", default_value = "0U")]
[IntegerType (rank = 3, min = 0, max = 255)]
public struct aroop.aroop_uword8 {
}

[CCode (cname = "SYNC_UWORD16_T", default_value = "0U")]
[IntegerType (rank = 5, min = 0, max = 65535)]
public struct aroop.aroop_uword16 {
}

[CCode (cname = "SYNC_UWORD32_T", default_value = "0U")]
[IntegerType (rank = 7)]
public struct aroop.aroop_uword32 {
}

[CCode (cname = "opp_hash_t", default_value = "0U")] // NOTE regression error may occur here
[IntegerType (rank = 7)]
public struct aroop.aroop_hash {
}

[CCode (cname = "SYNC_UWORD32_T", default_value = "0U")] // NOTE: this will work for 32 and 16 bit processor
[IntegerType (rank = 7)]
public struct aroop.aroop_magic {
}

[CCode (lower_case_cprefix = "AROOP_FLAG_")]
enum aroop.factory_flags {
	HAS_LOCK = 1,
	SWEEP_ON_UNREF = 1<<1,
	EXTENDED = 1<<2,
	SEARCHABLE = 1<<3,
	FAST_INITIALIZE = 1<<4,
	MEMORY_CLEAN = 1<<5,
}

//public delegate void aroop.verb_func(Replicable data, void*func_data);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile", has_free_function = true, free_function="aroop_factory_cpy_or_destroy")]
public struct aroop.CountableSet {
	[CCode (cname = "aroop_factory_mark_all")]
	public void markAll(ulong flg);
	[CCode (cname = "aroop_factory_unmark_all")]
	public void unmarkAll(ulong flg);
	[CCode (cname = "aroop_factory_prune_marked")]
	public void pruneMarked(ulong flg);
	[CCode (cname = "OPP_FACTORY_USE_COUNT")]
	public int count_unsafe();
	//[CCode (cname = "opp_factory_gc_donot_use")]
	[CCode (cname = "aroop_donothing")]
	public void gc_unsafe();
	[CCode (cname = "opp_factory_destroy_and_remove_profile")]
	public int destroy();
}

[CCode (cname = "opp_hash_function_t", cheader_filename = "aroop/opp/opp_hash_table.h", has_copy_function=false, has_destroy_function=false)]
public delegate aroop_hash aroop.getHashCb(Replicable data);

[CCode (cname = "opp_equals_t", cheader_filename = "aroop/opp/opp_hash_table.h", has_copy_function=false, has_destroy_function=false)]
public delegate bool aroop.equalsCb(Replicable x, Replicable y);

[CCode (cname = "opp_hash_table_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_hash_table_destroy")]
public struct aroop.HashTable<K,G> : aroop.CountableSet {
	[CCode (cname = "aroop_hash_table_create")]
	public HashTable(aroop.getHashCb hcb, aroop.equalsCb ecb, int inc = 16, uchar flag = 0);
	[CCode (cname = "opp_hash_table_set")]
	public int set(K key, G val);
	[CCode (cname = "aroop_hash_table_get")]
	public unowned G? get(K key);
	[CCode (cname = "aroop_hash_table_get")]
	public unowned G? getProperty(extring*key); // Hack when K == xtring 
	[CCode (cname = "aroop_factory_iterator_get")]
	public int iterator_hacked(aroop.Iterator<AroopPointer<G>>*it, uint if_flag = Replica_flags.ALL, uint ifnflag = 0, aroop_hash hash = 0);
	[CCode (cname = "aroop_hash_table_use_count")]
	public int count_unsafe();
}

[CCode (cname = "struct opp_iterator", cheader_filename = "aroop/opp/opp_iterator.h", has_copy_function=false, copy_function="aroop_iterator_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_iterator_destroy", has_free_function = true, free_function = "aroop_iterator_cpy_or_destroy")]
public struct aroop.Iterator<G> {
	[CCode (cname = "aroop_memclean_raw_2args")]
	public Iterator.EMPTY();
	[CCode (cname = "aroop_iterator_create")]
	public Iterator(aroop.Factory*fac, uint if_flag = Replica_flags.ALL, uint ifnflag = 0, aroop_hash hash = 0);
	[CCode (cname = "aroop_iterator_next")]
	public bool next();
	[CCode (cname = "aroop_iterator_get")]
	public G? get();
	[CCode (cname = "aroop_iterator_get_unowned")]
	public unowned G? get_unowned ();
	[CCode (cname = "aroop_iterator_unlink")]
	public void unlink();
	[CCode (cname = "opp_iterator_destroy")]
	public void destroy();
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_factory_cpy_or_destroy", has_free_function = true, free_function = "aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct aroop.ArrayList<G> : aroop.SearchableSet {
	[CCode (cname = "aroop_array_list_create")]
	public ArrayList(int inc = 16);
	[CCode (cname = "aroop_indexed_list_get")]
	public G? get(aroop_hash index);
	[CCode (cname = "aroop_indexed_list_set")]
	public void set(aroop_hash index, G item);
}

[CCode (cname = "opp_pointer_ext_t", cheader_filename = "aroop/opp/opp_list.h", has_copy_function=false, has_destroy_function=false)]
public class aroop.AroopPointer<G> : Hashable {
	[CCode (cname = "aroop_list_item_get")]
	public unowned G getUnowned();
	[CCode (cname = "aroop_list_item_set")]
	public void set(G x);
	[CCode (cname = "opp_unset_flag")]
	public void unmark(ulong flg);
	[CCode (cname = "opp_set_flag")]
	public void mark(ulong flg);
	[CCode (cname = "opp_test_flag")]
	public bool isMarked(ulong flg);
}

[CCode (cname = "opp_map_pointer_ext_t", cheader_filename = "aroop/opp/opp_hash_table.h", has_copy_function=false, has_destroy_function=false)]
public class aroop.AroopHashTablePointer<K,G> : aroop.AroopPointer<G> {
	[CCode (cname = "aroop_hash_table_pointer_get_key")]
	public unowned K key();
}

[CCode (cname = "aroop_do_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.iterator_cb(Replicable data);

[CCode (cname = "aroop_do_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.pointer_iterator_cb<G>(AroopPointer<G> data);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_memcpy_struct",has_free_function=true, free_function = "aroop_factory_cpy_or_destroy",  has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct aroop.Set<G> : aroop.CountableSet {
	[CCode (cname = "aroop_list_create")]
	public Set(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	//[CCode (cname = "opp_list_create2")]
	//public int create(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_list_add")]
	public bool add(G item);
	[CCode (cname = "aroop_list_add_container")]
	public AroopPointer<G> addPointer(G item, aroop_hash hash = 0, uint flag = 0);
	[CCode (cname = "aroop_factory_get_by_token2")]
	public AroopPointer<G>? getByToken(uint token);
	//[CCode (cname = "aroop_list_remove")]
	//public void remove(G item);
	[CCode (cname = "aroop_factory_do_full")]
	public int visit_each_hacked(iterator_cb do_func, uint if_flag, uint if_not_flag, aroop_hash hash);
	[CCode (cname = "aroop_factory_list_do_full")]
	public int visit_each(iterator_cb callback
		, uint if_list_flag, uint if_not_list_flag, uint if_flag, uint if_not_flag
		, aroop_hash list_hash, aroop_hash hash);
	[CCode (cname = "aroop_factory_iterator_get")]
	public int iterator_hacked(aroop.Iterator<AroopPointer<G>>*it, uint if_flag = Replica_flags.ALL, uint ifnflag = 0, aroop_hash hash = 0);
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=true, copy_function="aroop_memcpy_struct",has_free_function=true, free_function = "aroop_factory_cpy_or_destroy",  has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct aroop.SearchableSet<G> : aroop.Set<G> {
	[CCode (cname = "aroop_searchable_list_create")]
	public SearchableSet(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_searchable_list_prune")]
	public void prune(aroop_hash hash, G item);
	/*! \brief Searches set for any entry.
	 *
	 * @param [in] compare_func  A function reference that returns 0 on match.
	 */
	[CCode (cname = "aroop_search_no_ret_arg")]
	public AroopPointer<G>? search(aroop_hash hash, pointer_iterator_cb<G>? compare_func);
}

[CCode (cname = "opp_queue_t", cheader_filename = "aroop/opp/opp_queue.h", has_copy_function=false, copy_function="aroop_memcpy_strt2", has_destroy_function=true, destroy_function="opp_queue_deinit", has_free_function=true, free_function="aroop_queue_copy_or_destroy")]
public struct aroop.Queue<G> {
	[CCode (cname = "aroop_queue_init", cheader_filename = "aroop/aroop_factory.h")]
	public Queue(int scindex = 0);
	[CCode (cname = "opp_queue_deinit")]
	public int destroy();
	[CCode (cname = "opp_enqueue")]
	public int enqueue(G data);
	[CCode (cname = "aroop_dequeue", cheader_filename = "aroop/aroop_factory.h")]
	public G? dequeue();
	[CCode (cname = "OPP_QUEUE_SIZE")]
	public int count_unsafe();
}

[CCode (cname = "opp_object_ext_tiny_t", cheader_filename = "aroop/opp/opp_factory.h", destroy_function = "")]
struct aroop.hashable_ext {
}

[CCode (cname = "opp_object_ext_t", cheader_filename = "aroop/opp/opp_factory.h", destroy_function = "")]
public struct aroop.searchable_ext {
	[CCode (cname = "aroop_unmark_searchable_ext")]
	public void unmark(ulong flg);
	[CCode (cname = "aroop_mark_searchable_ext")]
	public void mark(ulong flg);
	[CCode (cname = "aroop_test_searchable_ext")]
	public bool test(ulong flg);
}

[CCode (cname = "opp_callback_t", cheader_filename = "aroop/opp/opp_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.factory_cb(void*data, int callback, void*cb_data, /*va_list*/void* ap, int size);
[CCode (cname = "opp_log_t", cheader_filename = "aroop/opp/opp_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.factory_log(void*log_data, char*fmt, ...);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy",has_free_function=true, free_function = "aroop_factory_cpy_or_destroy",  has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct aroop.Factory<G> : aroop.CountableSet {
	[CCode (cname = "aroop_assert_factory_creation_full")]
	private Factory(uint inc=16, uint datalen, int token_offset, uchar flags, aroop.factory_cb callback);
	[CCode (cname = "aroop_assert_factory_creation_for_type_full")]
	public Factory.for_type_full(uint inc=16, uint datalen, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_assert_factory_creation_for_type")]
	public Factory.for_type(uint inc=16, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_alloc_full")]
	public G? alloc_full(uint16 size = 0, int doubleref = 0, bool mclean = false, void*init_data = null);
	[CCode (cname = "aroop_alloc_added_size")]
	public G? alloc_added_size(uint16 addedSize = 0);
	[CCode (cname = "aroop_factory_get_by_token")]
	public G? get(uint token);
	[CCode (cname = "aroop_factory_do_full")]
	public int visit_each(iterator_cb do_func, uint if_flag = Replica_flags.ALL, uint if_not_flag = 0, aroop_hash hash = 0);
	[CCode (cname = "opp_factory_lock_donot_use")]
	public int lock_donot_use();
	[CCode (cname = "opp_factory_unlock_donot_use")]
	public int unlock_donot_use();
	[CCode (cname = "aroop_factory_iterator_get")]
	public int iterator(aroop.Iterator<G>*it, uint if_flag, uint ifnflag, aroop_hash hash);
	[CCode (cname = "aroop_factory_do_full")]
	public int verb(iterator_cb do_func, factory_log log, void*log_data);
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop/aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy",has_free_function=true, free_function = "aroop_factory_cpy_or_destroy",  has_destroy_function=true, destroy_function="opp_factory_destroy_and_remove_profile")]
public struct aroop.SearchableFactory<G> : aroop.Factory<G> {
	[CCode (cname = "aroop_srcblefac_constr")]
	private SearchableFactory(uint inc=16, uint datalen, int token_offset, uchar flags = factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED | factory_flags.SEARCHABLE, aroop.factory_cb callback);
	[CCode (cname = "aroop_srcblefac_constr_4_type_full")]
	public SearchableFactory.for_type_full(uint inc=16, uint datalen, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED | factory_flags.SEARCHABLE);
	[CCode (cname = "aroop_srcblefac_constr_4_type")]
	public SearchableFactory.for_type(uint inc=16, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED | factory_flags.SEARCHABLE);
	[CCode (cname = "aroop_search")]
	public G? search(aroop_hash hash, iterator_cb compare_func);
	[CCode (cname = "opp_factory_do_pre_order")]
	public int do_preorder(iterator_cb do_func, void*func_data, uint if_flag, uint if_not_flag, aroop_hash hash);
}

[CCode (lower_case_cprefix = "OPPN_", cname = "int", cheader_filename = "aroop/opp/opp_factory.h")]
public enum aroop.Replica_flags {
	ALL = 1<<15,
	INTERNAL_1 = 1<<14,
	INTERNAL_2 = 1<<13,
	ZOMBIE = 1<<12,
	// you can use 1, 1<<1, 1<<2 etc .
}

[CCode (lower_case_cprefix = "OPPN_ACTION_", cprefix = "OPPN_ACTION_", cname = "int")]
public enum aroop.prayer {
	INITIALIZE = 512,
	FINALIZE,
	REUSE,
	DEEP_COPY,
	SHRINK,
	VIEW,
	GET_SIZE,
	IS_EQUAL,
	SET_GENERIC_TYPES,
	REF,
	UNREF,
	DESCRIBE,
}

[CCode (cname = "opp_object_ext_tiny_t", cheader_filename = "aroop/aroop_factory.h", destroy_function = "")]
public abstract class aroop.Hashable : aroop.Replicable {
	private hashable_ext _ext;
	[CCode (cname = "aroop_donothing")]
	public Hashable();
	[CCode (cname = "opp_set_hash")]
	protected void set_hash(aroop_hash hash);
	[CCode (cname = "obj_get_hash")]
	protected aroop_hash get_hash();
	[CCode (cname = "aroop_get_token")]
	public uint16 get_token();
	[CCode (cname = "aroop_memclean")]
	protected void memclean(ulong size);
}

[CCode (cname = "opp_object_ext_t", cheader_filename = "aroop/aroop_factory.h", destroy_function = "")]
public abstract class aroop.Searchable : aroop.Hashable {
	private searchable_ext _ext;
	[CCode (cname = "aroop_donothing")]
	public Searchable();
	[CCode (cname = "aroop_memclean")]
	protected void memclean(ulong size);
}

[CCode (cname = "aroop_none")]
public struct aroop.Substance { // We can call it, Substance(in religion) 
	//[CCode (cname = "aroop_none_pray")]
	//public void pray(int callback, void*cb_data = null);
	[CCode (cname = "aroop_donothing")]
	public void describe();
}

#if true
// XXX This should be hidden from user ?
[CCode (cname = "aroop_wrong", cheader_filename = "aroop/aroop_error.h")]
public struct aroop.AroopWrong {
	[CCode (cname = "aroop_error_to_string")]
	public unowned string to_string();
}
#endif

/* Nothing is that which fills no space. - Leonardo da Vinci */
[CCode (cname = "aroop_none")]
public interface aroop.Replicable {
#if NOREFFF
	[CCode (cname = "OPPREF")]
	public static void ref();
	[CCode (cname = "OPPUNREF")]
	public static void unref();
#endif
	[CCode (cname = "OPPREF")]
	public Replicable pin();
	[CCode (cname = "aroop_none_unpin")]
	public void unpin();
	[CCode (cname = "aroop_none_describe")]
	public virtual void describe();
	[CCode (cname = "aroop_none_get_source_module")]
	public virtual void get_source_module(extring*module_name_output);
	[CCode (cname = "aroop_none_get_class_name")]
	public virtual void get_class_name(extring*class_name_output);
	[CCode (cname = "aroop_none_pray")]
	public void pray(int callback, void*cb_data = null);
	[CCode (cname = "aroop_none_is_same")]
	public bool is_same(aroop.Replicable another);
	[CCode (cname = "opp_unset_flag")]
	public void unmark(ulong flg);
	[CCode (cname = "opp_set_flag")]
	public void mark(ulong flg);
	[CCode (cname = "opp_test_flag")]
	public bool isMarked(ulong flg);
	[CCode (cname = "aroop_none_shrink")]
	public void shrink(int additional_size);
	[CCode (cname = "opp_force_memclean")]
	protected void memclean_raw();
}

[CCode (cname = "aroop_searchable_txt_t", cheader_filename = "aroop/aroop_core.h", cheader_filename = "aroop/core/xtring.h", ref_function="aroop_object_ref", unref_function="aroop_object_unref", has_destroy_function=true, destroy_function="aroop_txt_destroy")]
public class aroop.SearchableString : aroop.Searchable {
	[CCode (cname = "tdata")]
	public extring tdata;
	[CCode (cname = "aroop_searchable_string_rehash")]
	public void rehash();
	[CCode (cname = "aroop_txt_searchable_factory_build_and_copy_deep")]
	public static SearchableString factory_build_and_copy_deep(Factory*fac, extring*src);
}

[CCode (cname = "aroop_txt_t", cheader_filename = "aroop/core/xtring.h", has_destroy_function = true, destroy_function="aroop_txt_destroy", has_copy_function = true, copy_function="aroop_extring_copy_or_destroy", has_free_function = true, free_function = "aroop_extring_copy_or_destroy")]
public struct aroop.extring : aroop.Substance { // embeded txt
	[CCode (cname = "aroop_memclean_raw2")]
	public extring(); // empty
	[CCode (cname = "aroop_txt_embeded")]
	public extring.set_string(string content, Replicable?proto = null);
	[CCode (cname = "aroop_txt_embeded_set_static_string")]
	public extring.set_static_string(string content);
	[CCode (cname = "aroop_txt_embeded_set_content")]
	public extring.set_content(string content, uint len, Replicable?proto = null);
	[CCode (cname = "aroop_txt_embeded_txt_copy_shallow")]
	public extring.copy_shallow(aroop.extring*proto);
	[CCode (cname = "aroop_txt_embeded_copy_on_demand")]
	public extring.copy_on_demand(aroop.extring*proto);
	[CCode (cname = "aroop_txt_embeded_copy_deep")]
	public extring.copy_deep(aroop.extring*proto);
	[CCode (cname = "aroop_txt_embeded_copy_string")]
	public extring.copy_string(string src);
	[CCode (cname = "aroop_txt_embeded_copy_static_string")]
	public extring.copy_static_string(string src);
	[CCode (cname = "aroop_txt_embeded_stackbuffer")]
	public extring.stack(int size);
	[CCode (cname = "aroop_txt_embeded_stackbuffer_from_txt")]
	public extring.stack_copy_deep(aroop.extring*proto);
	[CCode (cname = "aroop_txt_embeded_buffer")]
	public bool rebuild_in_heap(int size);
	[CCode (cname = "aroop_txt_embeded_rebuild_and_set_content")]
	public void rebuild_and_set_content(string content, uint len, Replicable?proto=null);
	[CCode (cname = "aroop_txt_embeded_rebuild_and_set_static_string")]
	public void rebuild_and_set_static_string(string content);
	[CCode (cname = "aroop_txt_embeded_rebuild_copy_on_demand")]
	public void rebuild_and_copy_on_demand(aroop.extring*proto);
	[CCode (cname = "aroop_txt_embeded_rebuild_copy_shallow")]
	public void rebuild_and_copy_shallow(aroop.extring*proto);
	[CCode (cname = "aroop_txt_size")]
	public int size();
	[CCode (cname = "aroop_txt_to_string")]
	public unowned string to_memory();
	[CCode (cname = "aroop_txt_to_vala_string")]
	public unowned string to_string();
	[CCode (cname = "aroop_txt_to_int")]
	public int to_int();
	[CCode (cname = "aroop_txt_length")]
	public int length();
	[CCode (cname = "aroop_txt_set_length")]
	public int setLength(uint len);
	[CCode (cname = "aroop_txt_trim_to_length")]
	public int trim_to_length(uint len);
	[CCode (cname = "aroop_txt_get_hash")]
	public aroop_hash getStringHash();
	[CCode (cname = "aroop_txt_to_vala_string_magical")]
	public unowned string to_string_magical();
	//[CCode (cname = "aroop_txt_or_string_magical")]
	//public unowned string or_string_magical(string*other);
	[CCode (cname = "aroop_txt_or")]
	public aroop.extring* or_magical(aroop.extring*other);
	[CCode (cname = "aroop_txt_is_empty")]
	public bool is_empty();
	[CCode (cname = "aroop_txtcmp")]
	public int cmp(aroop.extring*other);
	[CCode (cname = "aroop_txt_is_empty_magical")]
	public bool is_empty_magical();
	[CCode (cname = "aroop_txt_equals")]
	public bool equals(aroop.extring*other);
	[CCode (cname = "aroop_txt_iequals")]
	public bool iequals(aroop.extring*other);
	[CCode (cname = "aroop_txt_equals_chararray")]
	public bool equals_string(string other);
	[CCode (cname = "aroop_txt_equals_static")]
	public bool equals_static_string(string other);
	[CCode (cname = "aroop_txt_zero_terminate")]
	public void zero_terminate(); // It only tries to zero terminate the string, but it may fail if there is space in the end
	[CCode (cname = "aroop_txt_is_zero_terminated")]
	public bool is_zero_terminated();
	[CCode (cname = "aroop_txt_printf")]
	[PrintfFormat]
	public void printf(string format,...);
	[CCode (cname = "aroop_txt_printf_extra")]
	[PrintfFormat]
	public void printf_extra(string format,...); // TODO implement a way to put string as xtring ..
	[CCode (cname = "aroop_txt_shift_token")]
	public void shift_token(string delim, extring*output);
	//[CCode (cname = "aroop_txt_move_to_what_the_hell")]
	//public void move_to_may_be_you_are_doing_wrong(extring*space);
	[CCode (cname = "aroop_txt_char_at")]
	public uchar char_at(uint index);
	[CCode (cname = "aroop_txt_set_char_at")]
	public void set_char_at(uint index, uchar x);
	[CCode (cname = "aroop_txt_contains_char")]
	public bool contains_char(uchar x);
	/* "good".shift(1) will give "ood"
	 * "good".shift(-1) will give "goo" */
	[CCode (cname = "aroop_txt_shift")]
	public bool shift(int inc);
	[CCode (cname = "aroop_txt_concat")]
	public bool concat(extring*other);
	[CCode (cname = "aroop_txt_concat_string")]
	public bool concat_string(string*other);
	[CCode (cname = "aroop_txt_concat_char")]
	public bool concat_char(uchar c);
	[CCode (cname = "aroop_txt_destroy")]
	public void destroy();
	[CCode (cname = "aroop_txt_memcopy_from_etxt_factory_build")]
	public int factory_build_and_copy_on_tail_no_length_check(extring*src);
	[CCode (cname = "aroop_txt_make_constant")]
	public void makeConstant();
}


[CCode (cname = "aroop_txt_t", cheader_filename = "aroop/core/xtring.h", ref_function="aroop_object_ref", unref_function="aroop_object_unref", has_destroy_function=true, destroy_function="aroop_txt_destroy")]
public class aroop.xtring : aroop.Replicable {
	[CCode (cname = "aroop_txt_new")]
	public xtring(char*content, uint len = 0, aroop.Replicable? proto = null, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_new_alloc")]
	public xtring.alloc(uint len = 0, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_new_copy_on_demand")]
	public xtring.copy_on_demand(extring*src, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_new_copy_shallow")]
	public xtring.copy_shallow(extring*src, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_new_copy_deep")]
	public xtring.copy_deep(extring*src, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_new_copy_content_deep")]
	public xtring.copy_content(char*content, uint len = 0, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_copy_string")]
	public xtring.copy_string(string*content, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_copy_static_string")]
	public xtring.copy_static_string(string*content, aroop.Factory<xtring>*pool = null);
	[CCode (cname = "aroop_txt_set_static_string")]
	public xtring.set_static_string(string*content, aroop.Factory<xtring>*pool = null);
	//[CCode (cname = "aroop_txt_destroy")]
	//~str();
	[CCode (cname = "aroop_txt_to_embeded_pointer")]
	public extring*fly();
	[CCode (cname = "BLANK_STRING")]
	public static aroop.xtring BLANK_STRING;
	//[CCode (cname = "aroop_txt_memcopy_from_etxt_factory_build")]
	//public int factory_build_by_memcopy_from_extring_unsafe_no_length_check(extring*src);
	[CCode (cname = "aroop_txt_equals_cb")]
	public static aroop.equalsCb eCb;
	[CCode (cname = "aroop_txt_get_hash_cb")]
	public static aroop.getHashCb hCb;
	//[CCode (cname = "aroop_txt_factory_build_and_copy_deep")]
	//public static xtring factory_build_and_copy_deep(Factory*fac, extring*src);
}


/**
 * Most of the time it is kind of hack, so you may want to use unowned variable to avoid object reference.
 *
 */
[Compact]
[CCode (cname = "char", has_free_function = false)]
public class aroop.mem {
	[CCode (cname = "aroop_mem_copy")]
	public bool copy_from(aroop.mem other, uint len);
	[CCode (cname = "aroop_mem_shift")]
	public unowned aroop.mem shift(int inc);
}

[CCode (cname = "aroop_write_output_stream_t", cheader_filename = "aroop/aroop_memory_profiler.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.writeOutputStream(extring*buf);
public class aroop.core {
	[CCode (cname = "aroop_assert")]
	public static void assert(bool value);
	[CCode (cname = "aroop_assert")]
	public static void die(string x);
	[CCode (cname = "aroop_assert_no_error", cheader_filename="errno.h")]
	public static void assert_no_error();
	[CCode (cname = "opp_any_obj_assert_no_module", cheader_filename="aroop/opp/opp_any_obj.h")]
	public static void assert_no_module_object(string module_name);
	[CCode (cname = "opp_factory_profiler_assert_no_module", cheader_filename="aroop/opp/opp_any_obj.h")]
	public static void assert_no_module_factory(string module_name);
	[CCode (cname = "aroop_init")]
	public static int libinit(int argc, char ** argv);
	[CCode (cname = "aroop_deinit")]
	public static void libdeinit();
	[CCode (cname = "opp_str2_alloc")]
	public static Replicable memory_alloc(ulong size);
	[CCode (cname = "aroop_memclean_raw")]
	public static void memclean_raw(void*ptr, ulong size);
	[CCode (cname = "aroop_memory_profiler_dump")]
	public static void memory_profiler_dump(writeOutputStream dump);
	[CCode (cname = "aroop_string_buffer_dump")]
	public static void string_buffer_dump(writeOutputStream dump);
	//[CCode (cname = "opp_factory_profiler_get_total_memory")]
	//public static void memory_profiler_get_unsafe(int*grasped,int*really_allocated);
	[CCode (cname = "aroop_get_source_file")]
	public static unowned string sourceFileName();
	[CCode (cname = "aroop_get_source_lineno")]
	public static int sourceLineNo();
	[CCode (cname = "aroop_get_argc")]
	public static int argc();
	[CCode (cname = "aroop_get_argv")]
	public static unowned string[] argv();
	//[CCode (cname = "aroop_core_gc_unsafe")]
	[CCode (cname = "aroop_donothing")]
	public static void gc_unsafe();
	[CCode (cname = "aroop_get_source_module")]
	public static unowned string sourceModuleName();
}

[Compact]
[CCode (cname = "char", has_free_function = false)]
public struct aroop.genericValueHack<G,H> {
	[CCode (cname = "aroop_donothing")]
	public void genericValueHack();
	[CCode (cname = "aroop_value_set")]
	public void set(G*a, H*b);
}

public class aroop.generihack<G,H> {
	[CCode (cname = "aroop_build_generics")]
	public static void build_generics(Replicable obj);
	[CCode (cname = "aroop_easy_swap2")]
	public static void swap(G a, G b);
}

[CCode (cname = "struct rb_table", has_free_function = false)]
public struct aroop.RBTreeLeaf {
	/*void*opp_lookup_table_search(const struct rb_table *tree
		, SYNC_UWORD32_T hash
		, obj_comp_t compare_func, const void*compare_data);*/
		
	[CCode (cname = "opp_lookup_table_init")]
	public int RBTreeLeaf(ulong control_flags = 0);
	[CCode (cname = "opp_lookup_table_insert")]
	public int insert(searchable_ext*node);
	[CCode (cname = "opp_lookup_table_delete")]
	public int remove(searchable_ext*node);
}
