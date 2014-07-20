
/*enum aroop_non_class_types {
	AROOP_NON_CLASS_TYPE_STRUCT = 0,
};

union aroop_internal_type_desc {
	opp_callback_t cb;
	enum aroop_non_class_types tp;
};*/

typedef opp_callback_t aroop_type_desc;

// Generic argument
#define aroop_generic_type_for_class(x) x##_pray

#define aroop_type_value_equals(tx,x,unused1,y,unused2) ({tx(x, OPPN_ACTION_IS_EQUAL, y, 0, 0);})
#define aroop_type_get_value_size(tx) ({tx(NULL, OPPN_ACTION_GET_SIZE, NULL, 0, 0);})

#define aroop_generic_type_init_val(tx) NULL
#define aroop_base_access(x,y) ((x)y)
#define aroop_base_method_call(x,y) (x.y)
