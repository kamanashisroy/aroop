

#define aroop_object_silent_cast(x,y,z) (void*)z //(x*)z

#define aroop_type_value_copy(tvar, x, nouse2, y, nouse3) ({if(tvar != NULL){if(y == NULL)aroop_generic_object_unref(void*,tvar,x);else x = aroop_generic_object_ref(y);} else {x = y;}})
