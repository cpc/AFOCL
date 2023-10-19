/* COMP.CE.350 Parallelization Exercise util functions
   Copyright (c) 2023 Topi Leppanen topi.leppanen@tuni.fi
*/

#include "opencl_util.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// This function reads in a text file and stores it as a char pointer
char *
read_source(char *kernelPath) {
    int status;
    FILE *fp;
    char *source;
    long int size;

    printf("Program file is: %s\n", kernelPath);

    fp = fopen(kernelPath, "rb");
    if (!fp) {
        printf("Could not open kernel file\n");
        exit(-1);
    }
    status = fseek(fp, 0, SEEK_END);
    if (status != 0) {
        printf("Error seeking to end of file\n");
        exit(-1);
    }
    size = ftell(fp);
    if (size < 0) {
        printf("Error getting file position\n");
        exit(-1);
    }

    rewind(fp);

    source = (char *)malloc(size + 1);

    int i;
    for (i = 0; i < size + 1; i++) {
        source[i] = '\0';
    }

    if (source == NULL) {
        printf("Error allocating space for the kernel source\n");
        exit(-1);
    }

    status = fread(source, 1, size, fp);
    if (status != size) {
        printf("Error reading the kernel file\n");
        exit(-1);
    }
    source[size] = '\0';

    return source;
}

const char *openclErrors[] = {
    "Success!",
    "Device not found.",
    "Device not available",
    "Compiler not available",
    "Memory object allocation failure",
    "Out of resources",
    "Out of host memory",
    "Profiling information not available",
    "Memory copy overlap",
    "Image format mismatch",
    "Image format not supported",
    "Program build failure",
    "Map failure",
    "Invalid value",
    "Invalid device type",
    "Invalid platform",
    "Invalid device",
    "Invalid context",
    "Invalid queue properties",
    "Invalid command queue",
    "Invalid host pointer",
    "Invalid memory object",
    "Invalid image format descriptor",
    "Invalid image size",
    "Invalid sampler",
    "Invalid binary",
    "Invalid build options",
    "Invalid program",
    "Invalid program executable",
    "Invalid kernel name",
    "Invalid kernel definition",
    "Invalid kernel",
    "Invalid argument index",
    "Invalid argument value",
    "Invalid argument size",
    "Invalid kernel arguments",
    "Invalid work dimension",
    "Invalid work group size",
    "Invalid work item size",
    "Invalid global offset",
    "Invalid event wait list",
    "Invalid event",
    "Invalid operation",
    "Invalid OpenGL object",
    "Invalid buffer size",
    "Invalid mip-map level",
    "Unknown",
};


const char *clErrorString(int e)
{
   switch (e) {
      case CL_SUCCESS:                            return openclErrors[ 0];
      case CL_DEVICE_NOT_FOUND:                   return openclErrors[ 1];
      case CL_DEVICE_NOT_AVAILABLE:               return openclErrors[ 2];
      case CL_COMPILER_NOT_AVAILABLE:             return openclErrors[ 3];
      case CL_MEM_OBJECT_ALLOCATION_FAILURE:      return openclErrors[ 4];
      case CL_OUT_OF_RESOURCES:                   return openclErrors[ 5];
      case CL_OUT_OF_HOST_MEMORY:                 return openclErrors[ 6];
      case CL_PROFILING_INFO_NOT_AVAILABLE:       return openclErrors[ 7];
      case CL_MEM_COPY_OVERLAP:                   return openclErrors[ 8];
      case CL_IMAGE_FORMAT_MISMATCH:              return openclErrors[ 9];
      case CL_IMAGE_FORMAT_NOT_SUPPORTED:         return openclErrors[10];
      case CL_BUILD_PROGRAM_FAILURE:              return openclErrors[11];
      case CL_MAP_FAILURE:                        return openclErrors[12];
      case CL_INVALID_VALUE:                      return openclErrors[13];
      case CL_INVALID_DEVICE_TYPE:                return openclErrors[14];
      case CL_INVALID_PLATFORM:                   return openclErrors[15];
      case CL_INVALID_DEVICE:                     return openclErrors[16];
      case CL_INVALID_CONTEXT:                    return openclErrors[17];
      case CL_INVALID_QUEUE_PROPERTIES:           return openclErrors[18];
      case CL_INVALID_COMMAND_QUEUE:              return openclErrors[19];
      case CL_INVALID_HOST_PTR:                   return openclErrors[20];
      case CL_INVALID_MEM_OBJECT:                 return openclErrors[21];
      case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR:    return openclErrors[22];
      case CL_INVALID_IMAGE_SIZE:                 return openclErrors[23];
      case CL_INVALID_SAMPLER:                    return openclErrors[24];
      case CL_INVALID_BINARY:                     return openclErrors[25];
      case CL_INVALID_BUILD_OPTIONS:              return openclErrors[26];
      case CL_INVALID_PROGRAM:                    return openclErrors[27];
      case CL_INVALID_PROGRAM_EXECUTABLE:         return openclErrors[28];
      case CL_INVALID_KERNEL_NAME:                return openclErrors[29];
      case CL_INVALID_KERNEL_DEFINITION:          return openclErrors[30];
      case CL_INVALID_KERNEL:                     return openclErrors[31];
      case CL_INVALID_ARG_INDEX:                  return openclErrors[32];
      case CL_INVALID_ARG_VALUE:                  return openclErrors[33];
      case CL_INVALID_ARG_SIZE:                   return openclErrors[34];
      case CL_INVALID_KERNEL_ARGS:                return openclErrors[35];
      case CL_INVALID_WORK_DIMENSION:             return openclErrors[36];
      case CL_INVALID_WORK_GROUP_SIZE:            return openclErrors[37];
      case CL_INVALID_WORK_ITEM_SIZE:             return openclErrors[38];
      case CL_INVALID_GLOBAL_OFFSET:              return openclErrors[39];
      case CL_INVALID_EVENT_WAIT_LIST:            return openclErrors[40];
      case CL_INVALID_EVENT:                      return openclErrors[41];
      case CL_INVALID_OPERATION:                  return openclErrors[42];
      case CL_INVALID_GL_OBJECT:                  return openclErrors[43];
      case CL_INVALID_BUFFER_SIZE:                return openclErrors[44];
      case CL_INVALID_MIP_LEVEL:                  return openclErrors[45];
      default:                                    return openclErrors[46];
   }
}

cl_ulong
getStartEndTime(cl_event event) {
    int status;

    cl_ulong start = 0;
    status = clGetEventProfilingInfo(
        event, CL_PROFILING_COMMAND_START, 8, &start, NULL);
    if (status != CL_SUCCESS) {
        printf("Failed to query event start time: %s", clErrorString(status));
    }

    cl_ulong end = 0;
    status = clGetEventProfilingInfo(
        event, CL_PROFILING_COMMAND_END, 8, &end, NULL);
    if (status != CL_SUCCESS) {
        printf("Failed to query event end time: %s", clErrorString(status));
    }

    return end - start;
}
