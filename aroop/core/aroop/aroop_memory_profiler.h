
#ifndef AROOP_MEMORY_PROFILER_DUMP_H_
#define AROOP_MEMORY_PROFILER_DUMP_H_


#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/xtring.h"
#include "aroop/aroop_memory_profiler.h"
#endif

typedef struct {
	void*cb_data;
	int (*cb)(void*log_data, struct aroop_txt*content);
}aroop_write_output_stream_t;

void aroop_string_buffer_dump(aroop_write_output_stream_t log);
int aroop_memory_profiler_dump(aroop_write_output_stream_t log, struct aroop_txt*select_module, int checkMemory);

#endif // AROOP_MEMORY_PROFILER_DUMP_H_
