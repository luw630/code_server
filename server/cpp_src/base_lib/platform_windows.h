#pragma once

#ifdef PLATFORM_WINDOWS 
int get_processor_number();

int get_cpu_usage(int pid);

void get_memory_info(int& workingSetSize, int& peakWorkingSetSize, int& pagefileUsage, int& peakPagefileUsage);
#endif
