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
	INITIALIZE = 1<<4,
}

//public delegate void aroop.verb_func(Replicable data, void*func_data);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.CountableSet {
	[CCode (cname = "OPP_FACTORY_USE_COUNT")]
	public int count_unsafe();
	[CCode (cname = "opp_factory_destroy")]
	public int destroy();
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.HashTable<G> : aroop.CountableSet {
	[CCode (cname = "aroop_hash_table_create")]
	public HashTable(int inc = 16, uchar mark = 0);
	[CCode (cname = "opp_hash_table_set")]
	public int set(etxt*key, G val);
	[CCode (cname = "aroop_hash_table_get")]
	public unowned G? get(etxt*key);
	[CCode (cname = "opp_factory_destroy")]
	public int destroy();
}

[CCode (cname = "struct opp_iterator", cheader_filename = "opp/opp_iterator.h", has_copy_function=false, copy_function="aroop_iterator_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_iterator_destroy")]
public struct aroop.Iterator<G> {
	[CCode (cname = "aroop_memclean_raw_2args")]
	public Iterator.EMPTY();
	[CCode (cname = "aroop_iterator_create")]
	public Iterator(aroop.Factory*fac, uint if_flag = Replica_flags.ALL, uint ifnflag, aroop_hash hash);
	[CCode (cname = "aroop_iterator_next")]
	public bool next ();
	[CCode (cname = "aroop_iterator_get")]
	public G? get ();
	[CCode (cname = "aroop_iterator_get_unowned")]
	public unowned G? get_unowned ();
	[CCode (cname = "opp_iterator_destroy")]
	public void destroy();
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, free_function="aroop_factory_free_function", copy_function="aroop_factory_cpy_or_destroy", has_free_function = false, has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.ArrayList<G> : aroop.SearchableSet {
	[CCode (cname = "aroop_array_list_create")]
	public ArrayList(int inc = 16);
	[CCode (cname = "aroop_indexed_list_get")]
	public G? get(int index);
	[CCode (cname = "aroop_indexed_list_set")]
	public void set(int index, G item);
	// TODO support marking mark() unmark()
}

[CCode (cname = "struct opp_list_item", cheader_filename = "opp/opp_list.h", has_copy_function=false, has_destroy_function=false)]
public class aroop.container<G> : Hashable {
	[CCode (cname = "aroop_list_item_get")]
	public unowned G get();
	[CCode (cname = "opp_unset_flag")]
	public void unmark(ulong flg);
	[CCode (cname = "opp_set_flag")]
	public void mark(ulong flg);
	[CCode (cname = "opp_test_flag")]
	public bool isMarked(ulong flg);
}

[CCode (cname = "obj_do_t", cheader_filename = "aroop_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.iterator_cb(Replicable data);

[CCode (cname = "obj_do_t", cheader_filename = "aroop_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.container_iterator_cb<G>(container<G> data);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=true, copy_function="aroop_memcpy_struct", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.Set<G> : aroop.CountableSet {
	[CCode (cname = "aroop_list_create")]
	public Set(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	//[CCode (cname = "opp_list_create2")]
	//public int create(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_list_add")]
	public bool add(G item);
	[CCode (cname = "aroop_list_add_container")]
	public container<G> add_container(G item, aroop_hash hash = 0, uint flag = 0);
	//[CCode (cname = "aroop_list_remove")]
	//public void remove(G item);
	[CCode (cname = "aroop_factory_do_full")]
	public int visit_each_hacked(iterator_cb do_func, uint if_flag, uint if_not_flag, aroop_hash hash);
	[CCode (cname = "aroop_factory_list_do_full")]
	public int visit_each(iterator_cb callback
		, uint if_list_flag, uint if_not_list_flag, uint if_flag, uint if_not_flag
		, aroop_hash list_hash, aroop_hash hash);
	[CCode (cname = "aroop_factory_iterator_get")]
	public int iterator_hacked(aroop.Iterator<container<G>>*it, uint if_flag, uint ifnflag, aroop_hash hash);
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=true, copy_function="aroop_memcpy_struct", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.SearchableSet<G> : aroop.Set<G> {
	[CCode (cname = "aroop_searchable_list_create")]
	public SearchableSet(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	/*! \brief Searches set for any entry.
	 *
	 * @param [in] compare_func  A function reference that returns 0 on match.
	 */
	[CCode (cname = "aroop_searchable_list_prune")]
	public void prune(aroop_hash hash, G item);
	[CCode (cname = "aroop_search_no_ret_arg")]
	public container<G>? search(aroop_hash hash, container_iterator_cb<G>? compare_func);
}

[CCode (cname = "opp_queue_t", cheader_filename = "opp/opp_queue.h", has_copy_function=false, copy_function="aroop_memcpy_strt2", has_destroy_function=true, destroy_function="opp_queue_deinit")]
public struct aroop.Queue<G> {
	[CCode (cname = "aroop_queue_init", cheader_filename = "aroop_factory.h")]
	public Queue(int scindex = 0);
	[CCode (cname = "opp_queue_deinit")]
	public int destroy();
	[CCode (cname = "opp_enqueue")]
	public int enqueue(G data);
	[CCode (cname = "aroop_dequeue", cheader_filename = "aroop_factory.h")]
	public G? dequeue();
	[CCode (cname = "OPP_QUEUE_SIZE")]
	public int count_unsafe();
}

[CCode (cname = "struct opp_object_ext_tiny", cheader_filename = "opp/opp_factory.h", destroy_function = "")]
struct aroop.hashable_ext {
}

[CCode (cname = "struct opp_object_ext", cheader_filename = "opp/opp_factory.h", destroy_function = "")]
public struct aroop.searchable_ext {
	[CCode (cname = "aroop_unmark_searchable_ext")]
	public void unmark(ulong flg);
	[CCode (cname = "aroop_mark_searchable_ext")]
	public void mark(ulong flg);
	[CCode (cname = "aroop_test_searchable_ext")]
	public bool test(ulong flg);
}

[CCode (cname = "opp_callback_t", cheader_filename = "opp/opp_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.factory_cb(void*data, int callback, void*cb_data, /*va_list*/void* ap, int size);
[CCode (cname = "opp_log_t", cheader_filename = "opp/opp_factory.h", has_copy_function=false, has_destroy_function=false)]
public delegate int aroop.factory_log(void*log_data, char*fmt, ...);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.Factory<G> : aroop.CountableSet {
	[CCode (cname = "aroop_assert_factory_creation_full")]
	private Factory(uint inc=16, uint datalen, int token_offset, uchar flags, aroop.factory_cb callback);
	[CCode (cname = "aroop_assert_factory_creation_for_type_full")]
	public Factory.for_type_full(uint inc=16, uint datalen, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_assert_factory_creation_for_type")]
	public Factory.for_type(uint inc=16, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_alloc_full")]
	public G? alloc_full(uint16 size = 0, int doubleref = 0, void*init_data = null);
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
	public int iterator(aroop.Iterator<G> it, uint if_flag, uint ifnflag, aroop_hash hash);
	[CCode (cname = "aroop_factory_do_full")]
	public int verb(iterator_cb do_func, factory_log log, void*log_data);
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
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

[CCode (lower_case_cprefix = "OPPN_", cname = "int", cheader_filename = "opp/opp_factory.h")]
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

[CCode (cname = "struct opp_object_ext_tiny", cheader_filename = "aroop_factory.h", destroy_function = "")]
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

[CCode (cname = "struct opp_object_ext", cheader_filename = "opp/opp_factory.h", destroy_function = "")]
public abstract class aroop.Searchable : aroop.Hashable {
	private searchable_ext _ext;
	[CCode (cname = "aroop_donothing")]
	public Searchable();
	[CCode (cname = "aroop_memclean")]
	protected void memclean(ulong size);
}

public struct aroop.Substance { // We can call it, Substance(in religion) 
	//[CCode (cname = "aroop_none_pray")]
	//public void pray(int callback, void*cb_data = null);
	[CCode (cname = "aroop_donothing")]
	public void describe();
}

#if false
// This should be hidden from user
[CCode (cname = "struct _aroop_wrong", cheader_filename = "core/aroop_error.h")]
public struct aroop.aroop_wrong : aroop.Substance {
}
#endif

/* Nothing is that which fills no space. - Leonardo da Vinci */
[CCode (cname = "aroop_none")]
public interface aroop.Replicable/*Possible alternatives Computable,Replicable /*/ { // We can call it, Omnipresent(in religion)
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

[CCode (cname = "aroop_txt_t", cheader_filename = "core/txt.h")]
public struct aroop.etxt : aroop.Substance { // embeded txt
	[CCode (cname = "aroop_txt_embeded")]
	public etxt(string content, Replicable?proto = null);
	[CCode (cname = "aroop_txt_embeded_new_with_length")]
	public etxt.given_length(string content, int len, Replicable?proto = null);
	[CCode (cname = "aroop_txt_embeded_static")]
	public etxt.from_static(string content);
	[CCode (cname = "aroop_txt_embeded_share_txt")]
	public etxt.from_txt(aroop.txt proto);
	[CCode (cname = "aroop_txt_embeded_reuse_embeded")]
	public etxt.from_etxt(aroop.etxt*proto);
	[CCode (cname = "aroop_txt_embeded_share_embeded")]
	public etxt.share_etxt(aroop.etxt*proto);
	[CCode (cname = "aroop_memclean_raw2")]
	public etxt.EMPTY();
	[CCode (cname = "aroop_txt_embeded_dup_embeded")]
	public etxt.dup_etxt(aroop.etxt*proto);
	[CCode (cname = "aroop_txt_embeded_dup_string")]
	public etxt.dup_string(string src);
	[CCode (cname = "aroop_txt_embeded_same_same")]
	public etxt.same_same(aroop.etxt*other);
	[CCode (cname = "aroop_txt_embeded_buffer")]
	public bool buffer(int size);
	[CCode (cname = "aroop_txt_embeded_stackbuffer")]
	public etxt.stack(int size);
	[CCode (cname = "aroop_txt_embeded_stackbuffer_from_txt")]
	public etxt.stack_from_txt(aroop.txt proto);
	[CCode (cname = "aroop_txt_embeded_stackbuffer_from_txt")]
	public etxt.stack_from_etxt(aroop.etxt*proto);
	[CCode (cname = "aroop_txt_embeded_with_length")]
	public void set_string_full(string content, int len, Replicable?proto=null);
	[CCode (cname = "aroop_txt_size")]
	public int size();
	[CCode (cname = "aroop_txt_to_vala")]
	public string to_string();
	[CCode (cname = "aroop_txt_to_int")]
	public int to_int();
	[CCode (cname = "aroop_txt_length")]
	public int length();
	[CCode (cname = "aroop_txt_trim_to_length")]
	public int trim_to_length(uint len);
	[CCode (cname = "aroop_txt_get_hash")]
	public aroop_hash get_hash();
	[CCode (cname = "aroop_txt_to_vala_magical")]
	public string to_string_magical();
	[CCode (cname = "aroop_txt_string_or_magical")]
	public string or_magical(aroop.txt other);
	[CCode (cname = "aroop_txt_string_or")]
	public aroop.etxt* e_or_magical(aroop.etxt*other);
	[CCode (cname = "aroop_txt_is_empty")]
	public bool is_empty();
	[CCode (cname = "aroop_txtcmp")]
	public int cmp(aroop.etxt*other);
	[CCode (cname = "aroop_txt_is_empty_magical")]
	public bool is_empty_magical();
	[CCode (cname = "aroop_txt_equals")]
	public bool equals(aroop.etxt*other);
	[CCode (cname = "aroop_txt_iequals")]
	public bool iequals(aroop.etxt*other);
	[CCode (cname = "aroop_txt_equals_chararray")]
	public bool equals_string(string other);
	[CCode (cname = "aroop_txt_equals_static")]
	public bool equals_static_string(string other);
	[CCode (cname = "aroop_txt_zero_terminate")]
	public void zero_terminate();
	[CCode (cname = "aroop_txt_is_zero_terminated")]
	public bool is_zero_terminated();
	[CCode (cname = "aroop_txt_printf")]
	[PrintfFormat]
	public void printf(string format,...);
	[CCode (cname = "aroop_txt_printf_extra")]
	[PrintfFormat]
	public void printf_extra(string format,...);
	[CCode (cname = "aroop_txt_shift_token")]
	public void shift_token(string delim, etxt*output);
	[CCode (cname = "aroop_txt_move_to_what_the_hell")]
	public void move_to_may_be_you_are_doing_wrong(etxt*space);
	[CCode (cname = "aroop_txt_char_at")]
	public char char_at(uint index);
	[CCode (cname = "aroop_txt_contains_char")]
	public bool contains_char(char x);
	/* "good".shift(1) will give "ood"
	 * "good".shift(-1) will give "goo" */
	[CCode (cname = "aroop_txt_shift")]
	public bool shift(int inc);
	[CCode (cname = "aroop_txt_concat")]
	public bool concat(etxt*other);
	[CCode (cname = "aroop_txt_concat_char")]
	public bool concat_char(uchar c);
	[CCode (cname = "aroop_txt_destroy")]
	public void destroy();
	/**
	 * For example,
	 * SearchableString x = myTxtFactory.alloc_added_size(src.length()+1);
	 * x.tdata.factory_build_by_memcopy_from_etxt_unsafe_no_length_check(&src);
	 */
	[CCode (cname = "aroop_txt_memcopy_from_etxt_factory_build")]
	public int factory_build_by_memcopy_from_etxt_unsafe_no_length_check(etxt*src);
}

[CCode (cname = "aroop_searchable_txt_t", cheader_filename = "aroop_core.h", cheader_filename = "core/txt.h", ref_function="aroop_object_ref", unref_function="aroop_object_unref", has_destroy_function=true, destroy_function="aroop_txt_destroy")]
public class aroop.SearchableString : aroop.Searchable {
	[CCode (cname = "tdata")]
	public etxt tdata;
	[CCode (cname = "aroop_searchable_string_rehash")]
	public void rehash();
}

[CCode (cname = "aroop_txt_t", cheader_filename = "core/txt.h", ref_function="aroop_object_ref", unref_function="aroop_object_unref", has_destroy_function=true, destroy_function="aroop_txt_destroy")]
public class aroop.txt : aroop.Replicable {
	[CCode (cname = "aroop_txt_new")]
	public txt(char*content, int len = 0, aroop.txt? proto = null, int scalability_index = 0);
	[CCode (cname = "aroop_txt_clone")]
	public txt.memcopy(char*content, int len = 0, int scalability_index = 0);
	[CCode (cname = "aroop_txt_clone_etxt")]
	public txt.memcopy_etxt(etxt*src);
	/**
	 * For example,
	 * txt kw = myTxtFactory.alloc_full(sizeof(txt)+src.length()+1)
				.factory_build_by_memcopy_from_etxt_unsafe_no_length_check(&src);
	 */
	[CCode (cname = "aroop_txt_memcopy_from_etxt_factory_build")]
	public int factory_build_by_memcopy_from_etxt_unsafe_no_length_check(etxt*src);
	//[CCode (cname = "aroop_txt_destroy")]
	//~txt();
	[CCode (cname = "aroop_txt_new_static")]
	public txt.from_static(char*content);
	[CCode (cname = "aroop_txt_to_vala")]
	public string to_string();
	[CCode (cname = "aroop_txt_length")]
	public int length();
	[CCode (cname = "BLANK_STRING")]
	public static aroop.txt BLANK_STRING;
	[CCode (cname = "aroop_txt_get_hash")]
	public aroop_hash get_hash();
	[CCode (cname = "aroop_txt_to_vala_magical")]
	public string to_string_magical();
	[CCode (cname = "aroop_txt_string_or_magical")]
	public aroop.txt or_magical(aroop.txt other);
	[CCode (cname = "aroop_txt_is_empty_magical")]
	public bool is_empty_magical();
	[CCode (cname = "aroop_txtcmp")]
	public int cmp(aroop.txt other);
	[CCode (cname = "aroop_txt_equals_static")]
	public bool equals_string(string other);
	[CCode (cname = "aroop_txt_equals")]
	public bool equals(aroop.txt other);
	[CCode (cname = "aroop_txt_char_at")]
	public char char_at(uint index);
	[CCode (cname = "aroop_txt_to_int")]
	public int to_int();
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

public class aroop.core {
	[CCode (cname = "aroop_assert")]
	public static void assert(bool value);
	[CCode (cname = "aroop_assert")]
	public static void die(string x);
	[CCode (cname = "aroop_assert_no_error", cheader_filename="errno.h")]
	public static void assert_no_error();
	[CCode (cname = "aroop_init")]
	public static int libinit(int argc, char ** argv);
	[CCode (cname = "aroop_deinit")]
	public static void libdeinit();
	[CCode (cname = "opp_str2_alloc")]
	public static Replicable memory_alloc(ulong size);
	[CCode (cname = "aroop_memclean_raw")]
	public static void memclean_raw(void*ptr, ulong size);
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
