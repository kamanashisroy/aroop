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
public struct aroop_uword8 {
}

[CCode (cname = "SYNC_UWORD16_T", default_value = "0U")]
[IntegerType (rank = 5, min = 0, max = 65535)]
public struct aroop_uword16 {
}

[CCode (cname = "SYNC_UWORD32_T", default_value = "0U")]
[IntegerType (rank = 7)]
public struct aroop_uword32 {
}

[CCode (cname = "opp_hash_t", default_value = "0U")] // NOTE regression error may occur here
[IntegerType (rank = 7)]
public struct aroop_hash {
}

[CCode (cname = "sync_mutex_t", has_destroy_function=true, destroy_function="sync_mutex_destroy")]
public struct aroop_mutex {
	[CCode (cname = "sync_mutex_init")]
	aroop_mutex();
	[CCode (cname = "sync_mutex_lock")]
	public int lockup();
	[CCode (cname = "sync_mutex_unlock")]
	public int unlock();
	[CCode (cname = "AVOID_DEAD_LOCK")]
	public int sleepy_trylock();
	[CCode (cname = "sync_mutex_destroy")]
	public int destroy();
}

[CCode (cname = "SYNC_UWORD32_T", default_value = "0U")] // NOTE: this will work for 32 and 16 bit processor
[IntegerType (rank = 7)]
public struct aroop_magic {
}

[CCode (cprefix = "AROOP_FLAG_")]
enum factory_flags {
	HAS_LOCK = 1,
	SWEEP_ON_UNREF = 1<<1,
	EXTENDED = 1<<2,
	SEARCHABLE = 1<<3,
	INITIALIZE = 1<<4,
}

//public delegate void aroop.verb_func(God data, void*func_data);

public struct aroop.countable {
	[CCode (cname = "OPP_FACTORY_USE_COUNT")]
	public int count_unsafe();
	[CCode (cname = "opp_factory_destroy")]
	public int destroy();
}

[CCode (cname = "struct opp_iterator", cheader_filename = "opp/opp_iterator.h", has_copy_function=false, has_destroy_function=true, destroy_function="opp_iterator_destroy")]
public struct aroop.Iterator<G> {
	[CCode (cname = "opp_iterator_create")]
	public Iterator(aroop.Factory fac, uint if_flag, uint ifnflag, aroop_hash hash);
	[CCode (cname = "aroop_iterator_next")]
	public bool next ();
	[CCode (cname = "aroop_iterator_get")]
	public G? get ();
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.ArrayList<G> : aroop.countable {
	[CCode (cname = "aroop_array_list_create")]
	public ArrayList(int inc = 16);
	[CCode (cname = "aroop_indexed_list_get")]
	public G? get(int index);
	[CCode (cname = "aroop_indexed_list_set")]
	public void set(int index, G item);
}

[CCode (cname = "opp_list_item", cheader_filename = "opp/opp_list.h", has_copy_function=false, has_destroy_function=false)]
public class aroop.container : God {
	[CCode (cname = "aroop_list_item_get")]
	public God get();
}

public delegate int aroop.iterator_cb(God data, void*func_data);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.Set<G> : aroop.countable {
	[CCode (cname = "aroop_list_create")]
	public Set(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	//[CCode (cname = "opp_list_create2")]
	//public int create(int inc = 16, uchar mark = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_list_add")]
	public bool add(G item);
	[CCode (cname = "opp_factory_do_full")]
	public int visit_each_hacked(iterator_cb do_func, void*func_data, uint if_flag, uint if_not_flag, aroop_hash hash);
	[CCode (cname = "opp_factory_list_do_full")]
	public int visit_each(iterator_cb callback, void*func_data
		, uint if_list_flag, uint if_not_list_flag, uint if_flag, uint if_not_flag
		, aroop_hash list_hash, aroop_hash hash);
}

[CCode (cname = "opp_factory_t", cheader_filename = "opp/opp_list.h", has_copy_function=false, has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.SearchableSet<G> : aroop.Set<G> {
	[CCode (cname = "opp_search")]
	public G? search(aroop_hash hash, iterator_cb compare_func, void*compare_data);
}

[CCode (cname = "opp_queue_t", cheader_filename = "opp/opp_queue.h", has_destroy_function=true, destroy_function="opp_queue_deinit")]
public struct aroop.Queue<G> {
	[CCode (cname = "opp_queue_init2")]
	public Queue(int scindex = 0);
	[CCode (cname = "opp_queue_deinit")]
	public int destroy();
	[CCode (cname = "opp_enqueue")]
	public int enqueue(G data);
	[CCode (cname = "opp_dequeue")]
	public G? dequeue();
	[CCode (cname = "OPP_QUEUE_SIZE")]
	public int count_unsafe();
}

[CCode (cname = "struct opp_object_ext", cheader_filename = "opp/opp_factory.h", destroy_function = "")]
struct hashable_ext {
}

public delegate int aroop.factory_cb(void*data, int callback, void*cb_data, /*va_list*/void* ap, int size);
public delegate int aroop.factory_log(void*log_data, char*fmt, ...);

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.Factory<G> : aroop.countable {
	[CCode (cname = "aroop_assert_factory_creation_full")]
	private Factory(uint inc=16, uint datalen, int token_offset, uchar flags, aroop.factory_cb callback);
	[CCode (cname = "aroop_assert_factory_creation_for_type_full")]
	public Factory.for_type_full(uint inc=16, uint datalen, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "aroop_assert_factory_creation_for_type")]
	public Factory.for_type(uint inc=16, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF);
	[CCode (cname = "opp_alloc4")]
	public G? alloc_full(uint16 size = 0, int doubleref = 0, void*init_data = null);
	[CCode (cname = "opp_get")]
	public G? get(uint token);
	[CCode (cname = "opp_factory_do_full")]
	public int visit_each(iterator_cb do_func, void*func_data, uint if_flag, uint if_not_flag, aroop_hash hash);
	[CCode (cname = "aroop_factory_iterator_get")]
	public int iterator(aroop.Iterator<G> it, uint if_flag, uint ifnflag, aroop_hash hash);
	[CCode (cname = "opp_factory_do_full")]
	public int verb(iterator_cb do_func, void*func_data, factory_log log, void*log_data);
}

[CCode (cname = "opp_factory_t", cheader_filename = "aroop_factory.h", has_copy_function=false, copy_function="aroop_factory_cpy_or_destroy", has_destroy_function=true, destroy_function="opp_factory_destroy")]
public struct aroop.SearchableFactory<G> : aroop.Factory<G> {
	[CCode (cname = "aroop_srcblefac_constr")]
	private SearchableFactory(uint inc=16, uint datalen, int token_offset, uchar flags = factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED, aroop.factory_cb callback);
	[CCode (cname = "aroop_srcblefac_constr_4_type_full")]
	public SearchableFactory.for_type_full(uint inc=16, uint datalen, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF | factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED);
	[CCode (cname = "aroop_srcblefac_constr_4_type")]
	public SearchableFactory.for_type(uint inc=16, int token_offset = 0, uchar flags = factory_flags.HAS_LOCK | factory_flags.SWEEP_ON_UNREF | factory_flags.SWEEP_ON_UNREF | factory_flags.EXTENDED);
	[CCode (cname = "opp_search")]
	public G? search(aroop_hash hash, iterator_cb compare_func, void*compare_data);
	[CCode (cname = "opp_factory_do_pre_order")]
	public int do_preorder(iterator_cb do_func, void*func_data, uint if_flag, uint if_not_flag, aroop_hash hash);
}

[CCode (cprefix = "OPPN_", cname = "int", cheader_filename = "opp/opp_factory.h")]
public enum aroop.god_flag {
	ALL = 1<<15,
	INTERNAL_1 = 1<<14,
	INTERNAL_2 = 1<<13,
	ZOMBIE = 1<<12,
}

[CCode (cprefix = "OPPN_ACTION_", cname = "int")]
public enum aroop.prayer {
	INITIALIZE = 512,
	FINALIZE,
	REUSE,
	DEEP_COPY,
	SHRINK,
	VIEW,
	DESCRIBE,
}

[CCode (cname = "struct opp_object_ext", cheader_filename = "opp/opp_factory.h", destroy_function = "")]
public abstract class aroop.Searchable : aroop.God {
	private hashable_ext _ext;
	[CCode (cname = "aroop_donothing")]
	public Searchable();
	[CCode (cname = "opp_set_hash")]
	protected void set_hash(aroop_hash hash);
	[CCode (cname = "aroop_get_token")]
	public uint16 get_token();
	[CCode (cname = "aroop_memclean")]
	protected void memclean(ulong size);
}

public struct aroop.Trident {
	//[CCode (cname = "aroop_god_pray")]
	//public void pray(int callback, void*cb_data = null);
}

[CCode (cname = "aroop_god")]
public interface aroop.God {
#if NOREFFF
	[CCode (cname = "OPPREF")]
	public static void ref();
	[CCode (cname = "OPPUNREF")]
	public static void unref();
#endif
	[CCode (cname = "OPPREF")]
	public God pin();
	[CCode (cname = "OPPUNREF")]
	public void unpin();
	[CCode (cname = "aroop_god_pray")]
	public void pray(int callback, void*cb_data = null);
	[CCode (cname = "aroop_god_is_same")]
	public bool is_same(aroop.God another);
	[CCode (cname = "opp_unset_flag")]
	public void unmark(ulong flg);
	[CCode (cname = "opp_set_flag")]
	public void mark(ulong flg);
	[CCode (cname = "opp_test_flag")]
	public bool test(ulong flg);
	[CCode (cname = "aroop_god_shrink")]
	public void shrink(int additional_size);
}

[CCode (cname = "struct aroop_txt", cheader_filename = "core/txt.h")]
public struct aroop.etxt : aroop.Trident { // embeded txt
	[CCode (cname = "aroop_txt_embeded")]
	public etxt(string content);
	[CCode (cname = "aroop_txt_embeded_static")]
	public etxt.from_static(string content);
	[CCode (cname = "aroop_txt_create")]
	public etxt.from_txt(aroop.txt proto);
	[CCode (cname = "aroop_txt_to_vala")]
	public string to_string();
	[CCode (cname = "aroop_txt_length")]
	public int length();
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
	[CCode (cname = "aroop_txt_equals")]
	public bool equals(aroop.etxt other);
	[CCode (cname = "aroop_txt_iequals")]
	public bool iequals(aroop.etxt*other);
	[CCode (cname = "aroop_txt_equals_static")]
	public bool equals_string(string other);
	[CCode (cname = "aroop_txt_destroy")]
	public void destroy();
}

[CCode (cname = "struct aroop_txt", cheader_filename = "core/txt.h", has_destroy_function=true, destroy_function="aroop_txt_destroy")]
public class aroop.txt : aroop.God {
	/*aroop.txt*proto;
	aroop_hash hash;
	int size;
	int len;
	char*str;*/
	[CCode (cname = "aroop_txt_new")]
	public txt(char*content, int len = 0, aroop.txt? proto = null, int scalability_index = 0);
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
}

[Compact]
[CCode (cname = "char", has_free_function = false)]
public class aroop.mem {
	[CCode (cname = "aroop_mem_copy")]
	public bool copy_from(aroop.mem other, uint len);
	[CCode (cname = "aroop_mem_shift")]
	public aroop.mem shift(int inc);
}

public class aroop.core {
	[CCode (cname = "aroop_assert")]
	public static void assert(bool value);
	[CCode (cname = "aroop_init")]
	public static int libinit(int argc, char ** argv);
	[CCode (cname = "aroop_deinit")]
	public static void libdeinit();
	[CCode (cname = "aroop_memory_alloc")]
	public static God memory_alloc(ulong size);
	[CCode (cname = "aroop_memclean_raw")]
	public static void memclean_raw(void*ptr, ulong size);
}

