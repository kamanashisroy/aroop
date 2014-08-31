#ifndef AROOP_ERROR_H
#define AROOP_ERROR_H

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#endif

C_CAPSULE_START

struct aroop_internal_wrong {
	char*(*domain)(SYNC_UWORD32_T code, char*msg);
	SYNC_UWORD32_T code;
	char*msg;
};
typedef struct aroop_internal_wrong aroop_wrong;

//#define aroop_error_new_literal(xdomain,xcode,xmsg) ({aroop_wrong xer;xer.domain = xdomain##_desc;xer.code = xcode;xer.msg = xmsg;&xer;})
#define aroop_error_new_literal(xdomain,xcode,xmsg) ({aroop_wrong*xer=NULL;opp_str2_alloc2(&xer,sizeof(struct aroop_internal_wrong));xer->domain = xdomain##_desc;xer->code = xcode;xer->msg = xmsg;xer;})
#define aroop_error_to_string(x) ({(x)->msg;})

#define aroop_unhandled_error(x) ({if(x != NULL)assert(!"Unhandled exception");})
//#define aroop_handled_error(x) ({x = NULL;})
#define aroop_handled_error(x) ({aroop_object_unref(aroop_wrong*,unused,x);})

#define aroop_throw_exception(x) ({*aroop_internal_err = x;})

#define aroop_free_error(unused1,unused2,x) ({x=NULL;})
//#define aroop_free_error opp_object_unref

C_CAPSULE_END

#endif // AROOP_ERROR_H
