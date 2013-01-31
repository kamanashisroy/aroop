/* Produced by texiweb from libavl.w. */

/* libavl - library for manipulation of binary trees.
   Copyright (C) 1998, 1999, 2000, 2001, 2002, 2004 Free Software
   Foundation, Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
   02110-1301 USA.
*/
/* This file is modified to cope with the obj factory needs */
#ifndef OPP_RB_H
#define OPP_RB_H 1

#include "core/config.h"

C_CAPSULE_START

/* Maximum RB height. */
#ifndef RB_MAX_HEIGHT
#define RB_MAX_HEIGHT 128
#endif

#ifndef OPP_OBJECT_EXT_TINY
#error "undefined OPP_OBJECT_EXT_TINY"
#endif

/* A red-black tree node. */
struct opp_object_ext
  {
	OPP_OBJECT_EXT_TINY();
    struct opp_object_ext *rb_link[2];   /* Subtrees. */
    struct opp_object_ext *sibling;
    unsigned char rb_color;       /* Color. */
  };

/* Tree data structure. */
struct rb_table
  {
	struct opp_object_ext*rb_root;
    size_t rb_count;                   /* Number of items in tree. */
    unsigned long rb_generation;       /* Generation number. */
  };

typedef struct rb_table opp_lookup_table_t;

int opp_lookup_table_init(opp_lookup_table_t *tree, unsigned long flags);
int opp_lookup_table_insert(opp_lookup_table_t *tree, struct opp_object_ext*node);
int opp_lookup_table_delete(opp_lookup_table_t *tree, struct opp_object_ext*node);
void*opp_lookup_table_search(const struct rb_table *tree
		, SYNC_UWORD32_T hash
		, obj_comp_t compare_func, const void*compare_data);
void opp_lookup_table_verb (const opp_lookup_table_t *tree
		, const char *title, void (*log)(void *log_data, const char*fmt, ...), void*log_data);
int opp_lookup_table_traverse(struct rb_table *tree, obj_do_t obj_do, void*func_data, unsigned int if_flag
		, unsigned int if_not_flag);

C_CAPSULE_END

#endif /* rb.h */
