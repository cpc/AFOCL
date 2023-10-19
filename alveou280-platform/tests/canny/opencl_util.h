/* COMP.CE.350 Parallelization Exercise util functions
   Copyright (c) 2023 Topi Leppanen topi.leppanen@tuni.fi
*/

#ifndef OPENCL_UTIL_H
#define OPENCL_UTIL_H

#include <CL/cl.h>

const char* clErrorString(int e);
char* read_source(char* kernelPath);
cl_ulong getStartEndTime(cl_event event);

#endif
