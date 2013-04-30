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

#ifndef AROOP_CONCATENATED_FILE
#include "opp/opp_factory.h"
#endif
#ifdef OPP_RBTREE
#ifndef AROOP_CONCATENATED_FILE
#include "opp/opp_rbtree_internal.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define RB_RED 0
#define RB_BLACK 1

int opp_lookup_table_init(opp_lookup_table_t *tree, unsigned long flags) {
	memset(tree, 0, sizeof(opp_lookup_table_t));
	return 0;
}

void*opp_lookup_table_search(const struct rb_table *tree
		, SYNC_UWORD32_T hash
		, obj_comp_t compare_func, const void*compare_data)
{
  const struct opp_object_ext *p;

  SYNC_ASSERT (tree != NULL);
  for (p = tree->rb_root; p != NULL; )
    {
//      int cmp = tree->rb_compare (item, p->rb_data, tree->rb_param);

      if (hash < p->hash)
        p = p->rb_link[0];
      else if (hash > p->hash)
        p = p->rb_link[1];
      else {/* |cmp == 0| */
        for(;p;p=p->sibling) {
    	  if(!compare_func || !compare_func(compare_data, p)) {
        	return (struct opp_object_ext *)p;
    	  }
        }
        return NULL;
      }
    }

  return NULL;
}


static void opp_lookup_table_traverse_helper(struct opp_object_ext *p, obj_do_t obj_do, void*func_data, unsigned int if_flag
		, unsigned int if_not_flag) {
	// TODO make it nonrecursive ..
	SYNC_ASSERT(p);
	struct opp_object_ext *q;
	for(q=p;q;q=q->sibling) {
		if ((q->flag & if_flag) && !(q->flag & if_not_flag)) {
			obj_do(func_data, q);
		}
	}
	if(p->rb_link[0]) {
		opp_lookup_table_traverse_helper(p->rb_link[0], obj_do, func_data, if_flag, if_not_flag);
	}
	if(p->rb_link[1]){
		opp_lookup_table_traverse_helper(p->rb_link[1], obj_do, func_data, if_flag, if_not_flag);
	}
}

int opp_lookup_table_traverse(struct rb_table *tree, obj_do_t obj_do, void*func_data, unsigned int if_flag
		, unsigned int if_not_flag) {
	if(tree && tree->rb_root) {
		opp_lookup_table_traverse_helper(tree->rb_root, obj_do, func_data, if_flag, if_not_flag);
	}
	return 0;
}

/* Inserts |item| into |tree| and returns a pointer to |item|'s address.
   If a duplicate item is found in the tree,
   returns a pointer to the duplicate without inserting |item|.
   Returns |NULL| in case of memory allocation failure. */
static int
rb_probe (struct rb_table *tree, struct opp_object_ext *item)
{
  struct opp_object_ext *pa[RB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                             /* Stack height. */

  struct opp_object_ext *p; /* Traverses tree looking for insertion point. */
//  struct sync_object_ext *n; /* Newly inserted node. */

#ifdef __cplusplus
  struct opp_object_ext placeholder;
  placeholder.rb_link[0] = NULL,placeholder.rb_link[1] = NULL;
  placeholder.sibling = NULL;
#else
  struct opp_object_ext placeholder = {.rb_link={NULL,NULL},.sibling=NULL};
#endif

//  C_CAPSULE_DEC_ST(struct opp_object_ext, placeholder, (rb_link = {NULL, NULL}), .sibling = NULL);

  SYNC_ASSERT (tree != NULL && item != NULL);

  item->rb_link[0] = item->rb_link[1] = item->sibling = NULL;
  item->rb_color = RB_RED;
  placeholder.rb_link[0] = tree->rb_root;
  pa[0] = &placeholder;//(struct sync_object_ext *) &tree->rb_root;
  da[0] = 0;
  k = 1;
  for (p = tree->rb_root; p; p = p->rb_link[da[k - 1]])
    {
      if (item->hash == p->hash) {
    	for(;p;p=p->sibling) {
    		if(item == p) {
    			SYNC_ASSERT(!"We cannot insert it twice");
    			return 0;
    		} else if(!p->sibling) {
    			p->sibling = item;
    			return 0;
    		}
    	}
        SYNC_ASSERT(!"This cannot reach\n");
      }

      pa[k] = p;
      da[k++] = item->hash > p->hash;
    }

  pa[k - 1]->rb_link[da[k - 1]] = item;
  tree->rb_count++;
  tree->rb_generation++;

  while (k >= 3 && pa[k - 1]->rb_color == RB_RED)
    {
      if (da[k - 2] == 0)
        {
          struct opp_object_ext *y = pa[k - 2]->rb_link[1];
          if (y != NULL && y->rb_color == RB_RED)
            {
              pa[k - 1]->rb_color = y->rb_color = RB_BLACK;
              pa[k - 2]->rb_color = RB_RED;
              k -= 2;
            }
          else
            {
              struct opp_object_ext *x;

              if (da[k - 1] == 0)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->rb_link[1];
                  x->rb_link[1] = y->rb_link[0];
                  y->rb_link[0] = x;
                  pa[k - 2]->rb_link[0] = y;
                }

              x = pa[k - 2];
              x->rb_color = RB_RED;
              y->rb_color = RB_BLACK;

              x->rb_link[0] = y->rb_link[1];
              y->rb_link[1] = x;
              pa[k - 3]->rb_link[da[k - 3]] = y;
              break;
            }
        }
      else
        {
          struct opp_object_ext *y = pa[k - 2]->rb_link[0];
          if (y != NULL && y->rb_color == RB_RED)
            {
              pa[k - 1]->rb_color = y->rb_color = RB_BLACK;
              pa[k - 2]->rb_color = RB_RED;
              k -= 2;
            }
          else
            {
              struct opp_object_ext *x;

              if (da[k - 1] == 1)
                y = pa[k - 1];
              else
                {
                  x = pa[k - 1];
                  y = x->rb_link[0];
                  x->rb_link[0] = y->rb_link[1];
                  y->rb_link[1] = x;
                  pa[k - 2]->rb_link[1] = y;
                }

              x = pa[k - 2];
              x->rb_color = RB_RED;
              y->rb_color = RB_BLACK;

              x->rb_link[1] = y->rb_link[0];
              y->rb_link[0] = x;
              pa[k - 3]->rb_link[da[k - 3]] = y;
              break;
            }
        }
    }
  if(tree->rb_root != placeholder.rb_link[0]) {
	  tree->rb_root = placeholder.rb_link[0];
  }
  tree->rb_root->rb_color = RB_BLACK;
  return 0;
}

/* Inserts |item| into |table|.
   Returns |NULL| if |item| was successfully inserted
   or if a memory allocation error occurred.
   Otherwise, returns the duplicate item. */
int opp_lookup_table_insert(opp_lookup_table_t *tree, struct opp_object_ext*node)
{
  return rb_probe (tree, node);
}

/* Deletes from |tree| and returns an item matching |item|.
   Returns a null pointer if no matching item found. */
int opp_lookup_table_delete(opp_lookup_table_t *tree, struct opp_object_ext*node)
{
  struct opp_object_ext *pa[RB_MAX_HEIGHT]; /* Nodes on stack. */
  unsigned char da[RB_MAX_HEIGHT];   /* Directions moved from stack nodes. */
  int k;                             /* Stack height. */

  struct opp_object_ext *p;    /* The node to delete, or a node part way to it. */
//  int cmp;              /* Result of comparison between |item| and |p|. */
  SYNC_ASSERT (tree != NULL && node != NULL);
#ifdef __cplusplus
  struct opp_object_ext placeholder;
  placeholder.rb_link[0] = NULL,placeholder.rb_link[1] = NULL;
  placeholder.sibling = NULL;
#else
  struct opp_object_ext placeholder = {.rb_link = {NULL,NULL},.sibling = NULL};
#endif

  placeholder.rb_link[0] = tree->rb_root;
#if 1
  k = 1;
  pa[0] = &placeholder;
  da[0] = 0;
  p = tree->rb_root;
  while(p && node->hash != p->hash)
    {
      int dir = node->hash > p->hash;

      pa[k] = p;
      da[k++] = dir;

      p = p->rb_link[dir];
      if (p == NULL) {
        SYNC_ASSERT(!"obj lookup failure");
    	return 0;
      }
    }
#else
  int cmp;
  k = 0;
  p = &placeholder;
  for (cmp = -1; cmp != 0;
         cmp = node->hash - p->hash)
      {
        int dir = cmp > 0;

        pa[k] = p;
        da[k++] = dir;

        p = p->rb_link[dir];
        if (!p) {
          SYNC_ASSERT(!"obj lookup failure");
        }
      }
#endif

  if(p != node) {
	  for(;p;p = p->sibling) {
		  if(p->sibling == node) {
			  p->sibling = node->sibling;
			  return 0;
		  }
	  }
	  SYNC_ASSERT(!"obj lookup failure");
  }

  if(p->sibling) {
#define	COPY_RB_NODE(dest,src) ({dest->rb_link[0] = src->rb_link[0],dest->rb_link[1] = src->rb_link[1],dest->rb_color = src->rb_color;})
	  COPY_RB_NODE(p->sibling, p);
	  if(tree->rb_root == p) {
		  tree->rb_root = p->sibling;
		  return 0;
	  }
	  pa[k - 1]->rb_link[da[k - 1]] = p->sibling;
	  return 0;
  }

  if (p->rb_link[1] == NULL)
    pa[k - 1]->rb_link[da[k - 1]] = p->rb_link[0];
  else
    {
      int t;
      struct opp_object_ext *r = p->rb_link[1];

      if (r->rb_link[0] == NULL)
        {
          r->rb_link[0] = p->rb_link[0];
          t = r->rb_color;
          r->rb_color = p->rb_color;
          p->rb_color = t;
          pa[k - 1]->rb_link[da[k - 1]] = r;
          da[k] = 1;
          pa[k++] = r;
        }
      else
        {
          struct opp_object_ext *s;
          int j = k++;

          for (;;)
            {
              da[k] = 0;
              pa[k++] = r;
              s = r->rb_link[0];
              if (s->rb_link[0] == NULL)
                break;

              r = s;
            }

          da[j] = 1;
          pa[j] = s;
          pa[j - 1]->rb_link[da[j - 1]] = s;

          s->rb_link[0] = p->rb_link[0];
          r->rb_link[0] = s->rb_link[1];
          s->rb_link[1] = p->rb_link[1];

          t = s->rb_color;
          s->rb_color = p->rb_color;
          p->rb_color = t;
        }
    }

  if (p->rb_color == RB_BLACK)
    {
      for (;;)
        {
          struct opp_object_ext *x = pa[k - 1]->rb_link[da[k - 1]];
          if (x != NULL && x->rb_color == RB_RED)
            {
              x->rb_color = RB_BLACK;
              break;
            }
          if (k < 2)
            break;

          if (da[k - 1] == 0)
            {
              struct opp_object_ext *w = pa[k - 1]->rb_link[1];

              if (w->rb_color == RB_RED)
                {
                  w->rb_color = RB_BLACK;
                  pa[k - 1]->rb_color = RB_RED;

                  pa[k - 1]->rb_link[1] = w->rb_link[0];
                  w->rb_link[0] = pa[k - 1];
                  pa[k - 2]->rb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 0;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->rb_link[1];
                }

              if ((w->rb_link[0] == NULL
                   || w->rb_link[0]->rb_color == RB_BLACK)
                  && (w->rb_link[1] == NULL
                      || w->rb_link[1]->rb_color == RB_BLACK))
                w->rb_color = RB_RED;
              else
                {
                  if (w->rb_link[1] == NULL
                      || w->rb_link[1]->rb_color == RB_BLACK)
                    {
                      struct opp_object_ext *y = w->rb_link[0];
                      y->rb_color = RB_BLACK;
                      w->rb_color = RB_RED;
                      w->rb_link[0] = y->rb_link[1];
                      y->rb_link[1] = w;
                      w = pa[k - 1]->rb_link[1] = y;
                    }

                  w->rb_color = pa[k - 1]->rb_color;
                  pa[k - 1]->rb_color = RB_BLACK;
                  w->rb_link[1]->rb_color = RB_BLACK;

                  pa[k - 1]->rb_link[1] = w->rb_link[0];
                  w->rb_link[0] = pa[k - 1];
                  pa[k - 2]->rb_link[da[k - 2]] = w;
                  break;
                }
            }
          else
            {
              struct opp_object_ext *w = pa[k - 1]->rb_link[0];

              if (w->rb_color == RB_RED)
                {
                  w->rb_color = RB_BLACK;
                  pa[k - 1]->rb_color = RB_RED;

                  pa[k - 1]->rb_link[0] = w->rb_link[1];
                  w->rb_link[1] = pa[k - 1];
                  pa[k - 2]->rb_link[da[k - 2]] = w;

                  pa[k] = pa[k - 1];
                  da[k] = 1;
                  pa[k - 1] = w;
                  k++;

                  w = pa[k - 1]->rb_link[0];
                }

              if ((w->rb_link[0] == NULL
                   || w->rb_link[0]->rb_color == RB_BLACK)
                  && (w->rb_link[1] == NULL
                      || w->rb_link[1]->rb_color == RB_BLACK))
                w->rb_color = RB_RED;
              else
                {
                  if (w->rb_link[0] == NULL
                      || w->rb_link[0]->rb_color == RB_BLACK)
                    {
                      struct opp_object_ext *y = w->rb_link[1];
                      y->rb_color = RB_BLACK;
                      w->rb_color = RB_RED;
                      w->rb_link[1] = y->rb_link[0];
                      y->rb_link[0] = w;
                      w = pa[k - 1]->rb_link[0] = y;
                    }

                  w->rb_color = pa[k - 1]->rb_color;
                  pa[k - 1]->rb_color = RB_BLACK;
                  w->rb_link[0]->rb_color = RB_BLACK;

                  pa[k - 1]->rb_link[0] = w->rb_link[1];
                  w->rb_link[1] = pa[k - 1];
                  pa[k - 2]->rb_link[da[k - 2]] = w;
                  break;
                }
            }

          k--;
        }

    }

  if(tree->rb_root != placeholder.rb_link[0]) {
	tree->rb_root = placeholder.rb_link[0];
  }
//  tree->rb_alloc->libavl_free (tree->rb_alloc, p);
  tree->rb_count--;
  tree->rb_generation++;
  return 0;
}

/* Prints the structure of |node|,
   which is |level| levels from the top of the tree. */
void
static obj_lookup_table_verb_helper (const struct opp_object_ext *node, int level, void (*log)(void *log_data, const char*fmt, ...), void*log_data)
{
  /* You can set the maximum level as high as you like.
     Most of the time, you'll want to debug code using small trees,
     so that a large |level| indicates a ``loop'', which is a bug. */
  if (level > 16)
    {
	  log (log_data,"[...]");
      return;
    }

  if (node == NULL)
    return;

  log (log_data, "%ld", node->hash);
  if (node->rb_link[0] != NULL || node->rb_link[1] != NULL)
    {
	  log (log_data, "(");

      obj_lookup_table_verb_helper (node->rb_link[0], level + 1, log, log_data);
      if (node->rb_link[1] != NULL)
        {
    	  log (log_data, ",");
          obj_lookup_table_verb_helper (node->rb_link[1], level + 1, log, log_data);
        }

      log (log_data, ")");
    }
}

/* Prints the entire structure of |tree| with the given |title|. */
void
opp_lookup_table_verb (const struct rb_table *tree, const char *title, void (*log)(void *log_data, const char*fmt, ...), void*log_data)
{
  log (log_data, "%s: ", title);
  obj_lookup_table_verb_helper (tree->rb_root, 0, log, log_data);
  log (log_data, "\n");
}

#ifdef __cplusplus
}
#endif

#endif


