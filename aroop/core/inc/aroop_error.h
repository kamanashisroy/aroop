#ifndef AROOP_ERROR_H
#define AROOP_ERROR_H

#ifndef AROOP_CONCATENATED_FILE
#include "core/config.h"
#endif

C_CAPSULE_START

struct _aroop_wrong {
	char*(*domain)(SYNC_UWORD32_T code, char*msg);
	SYNC_UWORD32_T code;
	char*msg;
};
typedef struct _aroop_wrong aroop_wrong;

#define aroop_error_new_literal(xdomain,xcode,xmsg) ({aroop_wrong xer;xer.domain = xdomain##_desc;xer.code = xcode;xer.msg = xmsg;&xer;})

#define aroop_unhandled_error(x) ({x = NULL;assert(!"Unhandled exception");})
#define aroop_handled_error(x) ({x = NULL;})

#define aroop_throw_exception(x) ({*_err = x;})

#define aroop_free_error(x) ({x=NULL;})

C_CAPSULE_END

#endif // AROOP_ERROR_H