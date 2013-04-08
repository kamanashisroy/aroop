
/*enum aroop_non_class_types {
	AROOP_NON_CLASS_TYPE_STRUCT = 0,
};

union _aroop_type_desc {
	opp_callback_t cb;
	enum aroop_non_class_types tp;
};*/

typedef opp_callback_t aroop_type_desc;

// Generic argument
#define aroop_generic_type_for_class(x) x##_pray



