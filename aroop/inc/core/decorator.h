#ifndef XULTB_DECORATOR_H
#define XULTB_DECORATOR_H

#define XULTB_CORE_UNIMPLEMENTED() assert(!"Unimplemented")

#define XULTB_ASSERT_RETURN(x,y) ({if(!(x)) return y;})


#ifdef __cplusplus
#define C_FUNCTION extern "C"
#define C_CAPSULE_START extern "C" {
#define C_CAPSULE_END }
//#define ST_ASS(x,y) x:y
#else
#define C_FUNCTION
#define C_CAPSULE_START
#define C_CAPSULE_END
//#define ST_ASS(x,y) .x=y
#endif

#define UNUSED_VAR(x)

#endif
