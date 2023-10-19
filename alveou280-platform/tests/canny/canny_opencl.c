/* COMP.CE.350 Parallelization Excercise 2023
   Copyright (c) 2023 Topi Leppanen topi.leppanen@tuni.fi
                      Jan Solanti

VERSION 23.0 - Created
*/

#include <CL/cl.h>
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "opencl_util.h"
#include "util.h"

#define VERBOSE 1
#define PLATFORM_INDEX 0

// Is used to find out frame times
int previousFinishTime = 0;
unsigned int frameNumber = 0;
unsigned int seed = 0;

typedef struct {
    uint16_t x;
    uint16_t y;
} coord_t;

const coord_t neighbour_offsets[8] = {
    {-1, -1}, {0, -1},  {+1, -1}, {-1, 0},
    {+1, 0},  {-1, +1}, {0, +1},  {+1, +1},
};
// Utility function to convert 2d index with offset to linear index
// Uses clamp-to-edge out-of-bounds handling
size_t
idx(size_t x, size_t y, size_t width, size_t height, int xoff, int yoff) {
    size_t resx = x;
    if ((xoff > 0 && x < width - xoff) || (xoff < 0 && x >= (-xoff)))
        resx += xoff;
    size_t resy = y;
    if ((yoff > 0 && y < height - yoff) || (yoff < 0 && y >= (-yoff)))
        resy += yoff;
    return resy * width + resx;
}

int any_mismatch = 0;
// ## You may add your own variables here ##

cl_context context;
cl_command_queue commandQueue[4];
cl_program program[4];
cl_kernel sobel_kernel;
cl_kernel phase_kernel;
cl_kernel magnitude_kernel;
cl_kernel nonmax_suppr_kernel;
cl_kernel canny_kernel;
int sobel_kernel_enabled = 0;
int sobel_kernel_device_idx = 0;
int phase_kernel_enabled = 0;
int phase_kernel_device_idx = 0;
int magnitude_kernel_enabled = 0;
int magnitude_kernel_device_idx = 0;
int suppr_kernel_enabled = 0;
int suppr_kernel_device_idx = 0;
int canny_kernel_enabled = 0;
int canny_kernel_device_idx = 0;
cl_mem input_buffer;
cl_mem sobel_x_buffer;
cl_mem sobel_y_buffer;
cl_mem phase_buffer;
cl_mem magnitude_buffer;
cl_mem suppressed_buffer;

// ## You may add your own initialization routines here ##
void
init(
    size_t width, size_t height, uint16_t threshold_lower,
    uint16_t threshold_upper) {
    // Get available OpenCL platforms
    const int MAX_CL_PLATFORMS = 10;
    cl_uint ret_num_platforms;
    cl_int retval = clGetPlatformIDs(0, NULL, &ret_num_platforms);
    cl_platform_id *platformId =
        malloc(sizeof(cl_platform_id) * ret_num_platforms);
    retval = clGetPlatformIDs(ret_num_platforms, platformId, NULL);
    if (retval != CL_SUCCESS) {
        printf("%s", clErrorString(retval));
    }

    // Print info about the platform
    size_t infoLength = 0;
    char *infoStr = NULL;
    if (VERBOSE) {
        for (unsigned int r = 0; r < (int)ret_num_platforms; ++r) {
            printf("Platform %d information:\n", r);

            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_PROFILE, 0, NULL, &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_PROFILE, infoLength, infoStr,
                NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Platform profile info error: %s\n",
                    clErrorString(retval));
            }
            printf("\tProfile: %s\n", infoStr);
            free(infoStr);

            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_VERSION, 0, NULL, &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_VERSION, infoLength, infoStr,
                NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Platform version info error: %s\n",
                    clErrorString(retval));
            }
            printf("\tVersion: %s\n", infoStr);
            free(infoStr);

            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_NAME, 0, NULL, &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_NAME, infoLength, infoStr, NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Platform name info error: %s\n", clErrorString(retval));
            }
            printf("\tName: %s\n", infoStr);
            free(infoStr);

            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_VENDOR, 0, NULL, &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_VENDOR, infoLength, infoStr, NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Platform vendor info error: %s\n",
                    clErrorString(retval));
            }
            printf("\tVendor: %s\n", infoStr);
            free(infoStr);

            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_EXTENSIONS, 0, NULL, &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetPlatformInfo(
                platformId[r], CL_PLATFORM_EXTENSIONS, infoLength, infoStr,
                NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Platform extensions info error: %s\n",
                    clErrorString(retval));
            }
            printf("\tExtensions: %s\n", infoStr);
            free(infoStr);
        }

        printf("\nUsing Platform %d.\n\n\n", PLATFORM_INDEX);
    }

    // Get available devices
    cl_uint ret_num_devices;
    retval = clGetDeviceIDs(
        platformId[PLATFORM_INDEX], CL_DEVICE_TYPE_CUSTOM, ret_num_devices, NULL,
        &ret_num_devices);
    cl_device_id *deviceIds = malloc((infoLength) * sizeof(char));
    retval = clGetDeviceIDs(
        platformId[PLATFORM_INDEX], CL_DEVICE_TYPE_CUSTOM, ret_num_devices,
        deviceIds, &ret_num_devices);
    if (retval != CL_SUCCESS) {
        printf("%s", clErrorString(retval));
    }
    free(platformId);


    context = clCreateContext(
            NULL, ret_num_devices, deviceIds, NULL, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf("Context creation error: %s\n", clErrorString(retval));
    }

    // Print info about the devices
    if (VERBOSE) {
        for (unsigned int r = 0; r < ret_num_devices; ++r) {
            printf("Device %d indormation:\n", r);

            retval = clGetDeviceInfo(
                deviceIds[r], CL_DEVICE_VENDOR, infoLength, NULL,
                &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetDeviceInfo(
                deviceIds[r], CL_DEVICE_VENDOR, infoLength, infoStr, NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Device Vendor info error: %s\n", clErrorString(retval));
            }
            printf("\tVendor: %s\n", infoStr);
            free(infoStr);

            retval = clGetDeviceInfo(
                deviceIds[r], CL_DEVICE_NAME, infoLength, NULL, &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetDeviceInfo(
                deviceIds[r], CL_DEVICE_NAME, infoLength, infoStr, NULL);
            if (retval != CL_SUCCESS) {
                printf("Device name info error: %s\n", clErrorString(retval));
            }
            printf("\tName: %s\n", infoStr);
            free(infoStr);

            retval = clGetDeviceInfo(
                deviceIds[r], CL_DEVICE_VERSION, infoLength, NULL,
                &infoLength);
            infoStr = malloc((infoLength) * sizeof(char));
            retval = clGetDeviceInfo(
                deviceIds[r], CL_DEVICE_VERSION, infoLength, infoStr, NULL);
            if (retval != CL_SUCCESS) {
                printf(
                    "Device version info error: %s\n", clErrorString(retval));
            }
            printf("\tVersion: %s\n\n", infoStr);
            free(infoStr);

            size_t bik_list_size = 0;
            retval = clGetDeviceInfo(deviceIds[r], CL_DEVICE_BUILT_IN_KERNELS, 0,
                    NULL, &bik_list_size);
            if (retval != CL_SUCCESS) {
                printf("Bik list size fetch error %s", clErrorString(retval));
            }
            char* bik_list = malloc(bik_list_size);
            retval = clGetDeviceInfo(deviceIds[r], CL_DEVICE_BUILT_IN_KERNELS, bik_list_size,
                    bik_list, NULL);
            if (retval != CL_SUCCESS) {
                printf("Bik list fetch error %s", clErrorString(retval));
            }
            printf("Found bik list %s\n", bik_list);
            if (strstr(bik_list, "pocl.sobel3x3.u8")) {
                sobel_kernel_enabled = 1;
                sobel_kernel_device_idx = r;
            }
            if (strstr(bik_list, "pocl.phase.u8")) {
                phase_kernel_enabled = 1;
                phase_kernel_device_idx = r;
            }
            if (strstr(bik_list, "pocl.magnitude.u16")) {
                magnitude_kernel_enabled = 1;
                magnitude_kernel_device_idx = r;
            }
            if (strstr(bik_list, "pocl.oriented.nonmaxsuppression.u16")) {
                suppr_kernel_enabled = 1;
                suppr_kernel_device_idx = r;
            }
            if (strstr(bik_list, "pocl.canny.u8")) {
                canny_kernel_enabled = 1;
                canny_kernel_device_idx = r;
            }

            program[r] =
                clCreateProgramWithBuiltInKernels(context, 1, &(deviceIds[r]),
                        bik_list, &retval);
            if (retval != CL_SUCCESS) {
                printf("Program creation error %s", clErrorString(retval));
            }

            free(bik_list);
            // Program compiling
            retval = clBuildProgram(
                    program[r], 1, &deviceIds[r], NULL, NULL, NULL);
            if (retval != CL_SUCCESS) {
                // Fetch build errors if there were some.
                if (retval == CL_BUILD_PROGRAM_FAILURE) {
                    infoLength = 0;
                    cl_int cl_build_retval = clGetProgramBuildInfo(
                            program[r], deviceIds[r], CL_PROGRAM_BUILD_LOG, 0, 0,
                            &infoLength);
                    infoStr = malloc(infoLength * sizeof(char));
                    cl_build_retval = clGetProgramBuildInfo(
                            program[r], deviceIds[r], CL_PROGRAM_BUILD_LOG,
                            infoLength, infoStr, 0);
                    if (cl_build_retval != CL_SUCCESS) {
                        printf(
                                "Build log fetch error: %s\n",
                                clErrorString(cl_build_retval));
                    }

                    printf("OpenCL build log:\n %s", infoStr);
                    free(infoStr);
                }

                printf("OpenCL build error: %s\n", clErrorString(retval));
            }

            // In ordercommand queue because not
            // CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE
            cl_queue_properties props[1];
            props[0] = CL_QUEUE_PROFILING_ENABLE;
            //   commandQueue = clCreateCommandQueueWithProperties(context,
            //   deviceIds[r],
            //      CL_QUEUE_PROFILING_ENABLE, &retval);
            commandQueue[r] = clCreateCommandQueue(
                    context, deviceIds[r], CL_QUEUE_PROFILING_ENABLE, &retval);
            if (retval != CL_SUCCESS) {
                printf("Command queue creation error%s", clErrorString(retval));
            }
        }
    }




    // Create input and output buffer for the kernel
    input_buffer = clCreateBuffer(
            context,
            CL_MEM_HOST_WRITE_ONLY | CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR,
            width * height, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf("Input buffer creation error: %s\n", clErrorString(retval));
    }

    sobel_x_buffer = clCreateBuffer(
        context, CL_MEM_READ_WRITE, 2 * width * height, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf("Sobel x buffer creation error: %s\n", clErrorString(retval));
    }
    sobel_y_buffer = clCreateBuffer(
        context, CL_MEM_READ_WRITE, 2 * width * height, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf("Sobel y buffer creation error: %s\n", clErrorString(retval));
    }
    phase_buffer = clCreateBuffer(
        context, CL_MEM_READ_WRITE, width * height, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf("Phase buffer creation error: %s\n", clErrorString(retval));
    }
    magnitude_buffer = clCreateBuffer(
        context, CL_MEM_READ_WRITE, 2 * width * height, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf(
            "Magnitude buffer creation error: %s\n", clErrorString(retval));
    }
    suppressed_buffer = clCreateBuffer(
        context,
        CL_MEM_HOST_READ_ONLY | CL_MEM_WRITE_ONLY | CL_MEM_ALLOC_HOST_PTR,
        width * height, NULL, &retval);
    if (retval != CL_SUCCESS) {
        printf(
            "Suppressed buffer creation error: %s\n", clErrorString(retval));
    }

    if (sobel_kernel_enabled) {
        sobel_kernel = clCreateKernel(program[sobel_kernel_device_idx], "pocl.sobel3x3.u8", &retval);
        if (retval != CL_SUCCESS) {
            printf("Kernel creation error: %s\n", clErrorString(retval));
        }
        // Set buffers to kernel arguments
        retval = clSetKernelArg(sobel_kernel, 0, sizeof(cl_mem), &input_buffer);
        if (retval != CL_SUCCESS) {
            printf("Sobel argument setting error: %s\n", clErrorString(retval));
        }
        retval = clSetKernelArg(sobel_kernel, 1, sizeof(cl_mem), &sobel_x_buffer);
        if (retval != CL_SUCCESS) {
            printf("Sobel argument setting error: %s\n", clErrorString(retval));
        }
        retval = clSetKernelArg(sobel_kernel, 2, sizeof(cl_mem), &sobel_y_buffer);
        if (retval != CL_SUCCESS) {
            printf("Sobel argument setting error: %s\n", clErrorString(retval));
        }
    }
    if (phase_kernel_enabled) {
        phase_kernel = clCreateKernel(program[phase_kernel_device_idx], "pocl.phase.u8", &retval);
        if (retval != CL_SUCCESS) {
            printf("Kernel creation error: %s\n", clErrorString(retval));
        }
        retval =
            clSetKernelArg(phase_kernel, 0, sizeof(cl_mem), &sobel_x_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "Phase argument setting error: %s\n", clErrorString(retval));
        }
        retval =
            clSetKernelArg(phase_kernel, 1, sizeof(cl_mem), &sobel_y_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "Phase argument setting error: %s\n", clErrorString(retval));
        }
        retval =
            clSetKernelArg(phase_kernel, 2, sizeof(cl_mem), &phase_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "Phase argument setting error: %s\n", clErrorString(retval));
        }
    }
    if (magnitude_kernel_enabled) {
        magnitude_kernel = clCreateKernel(program[magnitude_kernel_device_idx], "pocl.magnitude.u16", &retval);
        if (retval != CL_SUCCESS) {
            printf("Kernel creation error: %s\n", clErrorString(retval));
        }
        retval =
            clSetKernelArg(magnitude_kernel, 0, sizeof(cl_mem), &sobel_x_buffer);
        if (retval != CL_SUCCESS) {
            printf("Mag argument setting error: %s\n", clErrorString(retval));
        }
        retval =
            clSetKernelArg(magnitude_kernel, 1, sizeof(cl_mem), &sobel_y_buffer);
        if (retval != CL_SUCCESS) {
            printf("Mag argument setting error: %s\n", clErrorString(retval));
        }
        retval =
            clSetKernelArg(magnitude_kernel, 2, sizeof(cl_mem), &magnitude_buffer);
        if (retval != CL_SUCCESS) {
            printf("Mag argument setting error: %s\n", clErrorString(retval));
        }
    }
    if (suppr_kernel_enabled) {
        nonmax_suppr_kernel = clCreateKernel(program[suppr_kernel_device_idx], "pocl.oriented.nonmaxsuppression.u16", &retval);
        if (retval != CL_SUCCESS) {
            printf("Kernel creation error: %s\n", clErrorString(retval));
        }
        retval = clSetKernelArg(
                nonmax_suppr_kernel, 0, sizeof(cl_mem), &magnitude_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "NonMaxSuppresion argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval =
            clSetKernelArg(nonmax_suppr_kernel, 1, sizeof(cl_mem), &phase_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "NonMaxSuppresion argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval = clSetKernelArg(
                nonmax_suppr_kernel, 2, sizeof(cl_mem), &suppressed_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "NonMaxSuppresion argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval = clSetKernelArg(
                nonmax_suppr_kernel, 3, sizeof(int32_t), &threshold_lower);
        if (retval != CL_SUCCESS) {
            printf(
                    "NonMaxSuppresion argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval = clSetKernelArg(
                nonmax_suppr_kernel, 4, sizeof(int32_t), &threshold_upper);
        if (retval != CL_SUCCESS) {
            printf(
                    "NonMaxSuppresion argument setting error: %s\n",
                    clErrorString(retval));
        }
    }
    if (canny_kernel_enabled) {
        canny_kernel = clCreateKernel(program[canny_kernel_device_idx], "pocl.canny.u8", &retval);
        if (retval != CL_SUCCESS) {
            printf("Kernel creation error: %s\n", clErrorString(retval));
        }
        retval = clSetKernelArg(
                canny_kernel, 0, sizeof(cl_mem), &input_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "Canny argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval =
            clSetKernelArg(canny_kernel, 1, sizeof(cl_mem), &suppressed_buffer);
        if (retval != CL_SUCCESS) {
            printf(
                    "Canny argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval = clSetKernelArg(
                canny_kernel, 2, sizeof(int32_t), &threshold_lower);
        if (retval != CL_SUCCESS) {
            printf(
                    "Canny argument setting error: %s\n",
                    clErrorString(retval));
        }
        retval = clSetKernelArg(
                canny_kernel, 3, sizeof(int32_t), &threshold_upper);
        if (retval != CL_SUCCESS) {
            printf(
                    "Canny argument setting error: %s\n",
                    clErrorString(retval));
        }
    }

    free(deviceIds);
    printf("OpenCL initialization ended.\n");
}

void
destroy() {
    // Wait OpenCL to finish and then release everything
    // No error checking program is dying anyways
    clFinish(commandQueue[0]);
    clReleaseMemObject(input_buffer);
    clReleaseMemObject(sobel_x_buffer);
    clReleaseMemObject(sobel_y_buffer);
    clReleaseMemObject(phase_buffer);
    clReleaseMemObject(magnitude_buffer);
    clReleaseMemObject(suppressed_buffer);
    if (sobel_kernel_enabled)
        clReleaseKernel(sobel_kernel);
    if (phase_kernel_enabled)
        clReleaseKernel(phase_kernel);
    if (magnitude_kernel_enabled)
        clReleaseKernel(magnitude_kernel);
    if (suppr_kernel_enabled)
        clReleaseKernel(nonmax_suppr_kernel);
    if (canny_kernel_enabled)
        clReleaseKernel(canny_kernel);
    clReleaseProgram(program[0]);
    clReleaseCommandQueue(commandQueue[0]);
    clReleaseContext(context);
}

void
sobel3x3(
    const uint8_t *restrict in, size_t width, size_t height,
    int16_t *restrict output_x, int16_t *restrict output_y) {
    // LOOP 1.1
    for (size_t y = 0; y < height; y++) {
        // LOOP 1.2
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;

            /* 3x3 sobel filter, first in x direction */
            output_x[gid] = (-1) * in[idx(x, y, width, height, -1, -1)] +
                            1 * in[idx(x, y, width, height, 1, -1)] +
                            (-2) * in[idx(x, y, width, height, -1, 0)] +
                            2 * in[idx(x, y, width, height, 1, 0)] +
                            (-1) * in[idx(x, y, width, height, -1, 1)] +
                            1 * in[idx(x, y, width, height, 1, 1)];

            /* 3x3 sobel filter, in y direction */
            output_y[gid] = (-1) * in[idx(x, y, width, height, -1, -1)] +
                            1 * in[idx(x, y, width, height, -1, 1)] +
                            (-2) * in[idx(x, y, width, height, 0, -1)] +
                            2 * in[idx(x, y, width, height, 0, 1)] +
                            (-1) * in[idx(x, y, width, height, 1, -1)] +
                            1 * in[idx(x, y, width, height, 1, 1)];
        }
    }
}

void
phaseAndMagnitude(
    const int16_t *restrict in_x, const int16_t *restrict in_y, size_t width,
    size_t height, uint8_t *restrict phase_out,
    uint16_t *restrict magnitude_out) {
    // LOOP 2.1
    for (size_t y = 0; y < height; y++) {
        // LOOP 2.2
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;

            // Output in range -PI:PI
            float angle = atan2f(in_y[gid], in_x[gid]);

            // Shift range -1:1
            angle /= PI;

            // Shift range -127.5:127.5
            angle *= 127.5;

            // Shift range 0:255
            angle += 127.5;

            // Clamp to 0:255 before casting to a narrower type
            phase_out[gid] = (uint8_t)fmin(255.0, fmax(angle, 0.0));

            magnitude_out[gid] = abs(in_x[gid]) + abs(in_y[gid]);
        }
    }
}

void
nonMaxSuppression(
    const uint16_t *restrict magnitude, const uint8_t *restrict phase,
    size_t width, size_t height, int16_t threshold_lower,
    uint16_t threshold_upper, uint8_t *restrict out) {
    // LOOP 3.1
    for (size_t y = 0; y < height; y++) {
        // LOOP 3.2
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;

            uint8_t sobel_angle = phase[gid];

            if (sobel_angle > 127) {
                sobel_angle -= 128;
            }

            int sobel_orientation = 0;

            if (sobel_angle < 16 || sobel_angle >= (7 * 16)) {
                sobel_orientation = 2;
            } else if (sobel_angle >= 16 && sobel_angle < 16 * 3) {
                sobel_orientation = 1;
            } else if (sobel_angle >= 16 * 3 && sobel_angle < 16 * 5) {
                sobel_orientation = 0;
            } else if (sobel_angle > 16 * 5 && sobel_angle <= 16 * 7) {
                sobel_orientation = 3;
            }

            uint16_t sobel_magnitude = magnitude[gid];
            /* Non-maximum suppression
             * Pick out the two neighbours that are perpendicular to the
             * current edge pixel */
            uint16_t neighbour_max = 0;
            uint16_t neighbour_max2 = 0;
            switch (sobel_orientation) {
                case 0:
                    neighbour_max =
                        magnitude[idx(x, y, width, height, 0, -1)];
                    neighbour_max2 =
                        magnitude[idx(x, y, width, height, 0, 1)];
                    break;
                case 1:
                    neighbour_max =
                        magnitude[idx(x, y, width, height, -1, -1)];
                    neighbour_max2 =
                        magnitude[idx(x, y, width, height, 1, 1)];
                    break;
                case 2:
                    neighbour_max =
                        magnitude[idx(x, y, width, height, -1, 0)];
                    neighbour_max2 =
                        magnitude[idx(x, y, width, height, 1, 0)];
                    break;
                case 3:
                default:
                    neighbour_max =
                        magnitude[idx(x, y, width, height, 1, -1)];
                    neighbour_max2 =
                        magnitude[idx(x, y, width, height, -1, 1)];
                    break;
            }
            // Suppress the pixel here
            if ((sobel_magnitude < neighbour_max) ||
                (sobel_magnitude < neighbour_max2)) {
                sobel_magnitude = 0;
            }

            /* Double thresholding */
            // Marks YES pixels with 255, NO pixels with 0 and MAYBE pixels
            // with 127
            uint8_t t = 127;
            if (sobel_magnitude > threshold_upper) t = 255;
            if (sobel_magnitude <= threshold_lower) t = 0;
            out[gid] = t;
        }
    }
}


void
edgeTracing(uint8_t *restrict image, size_t width, size_t height) {
    // Uses a stack-based approach to incrementally spread the YES
    // pixels to every (8) neighbouring MAYBE pixel.
    //
    // Modifies the pixels in-place.
    //
    // Since the same pixel is never added to the stack twice,
    // the maximum stack size is quaranteed to never be above
    // the image size and stack overflow should be impossible
    // as long as stack size is 2*2*image_size (2 16-bit coordinates per
    // pixel).
    coord_t *tracing_stack = malloc(width * height * sizeof(coord_t));
    coord_t *tracing_stack_pointer = tracing_stack;

    // LOOP 4.1
    for (uint16_t y = 0; y < height; y++) {
        // LOOP 4.2
        for (uint16_t x = 0; x < width; x++) {
            // Collect all YES pixels into the stack
            if (image[y * width + x] == 255) {
                coord_t yes_pixel = {x, y};
                *tracing_stack_pointer = yes_pixel;
                tracing_stack_pointer++;  // increments by sizeof(coord_t)
            }
        }
    }

    // Empty the tracing stack one-by-one
    // LOOP 4.3
    while (tracing_stack_pointer != tracing_stack) {
        tracing_stack_pointer--;
        coord_t known_edge = *tracing_stack_pointer;
        // LOOP 4.4
        for (int k = 0; k < 8; k++) {
            coord_t dir_offs = neighbour_offsets[k];
            coord_t neighbour = {
                known_edge.x + dir_offs.x, known_edge.y + dir_offs.y};

            // Clamp to edge to prevent the algorithm from leaving the image.
            // Not using the idx()-function, since we want to preserve the x
            // and y on their own, since the pixel might be added to the stack
            // in the end.
            if (neighbour.x < 0) neighbour.x = 0;
            if (neighbour.x >= width) neighbour.x = width - 1;
            if (neighbour.y < 0) neighbour.y = 0;
            if (neighbour.y >= height) neighbour.y = height - 1;

            // Only MAYBE neighbours are potential edges
            if (image[neighbour.y * width + neighbour.x] == 127) {
                // Convert MAYBE to YES
                image[neighbour.y * width + neighbour.x] = 255;

                // Add the newly added pixel to stack, so changes will
                // propagate
                *tracing_stack_pointer = neighbour;
                tracing_stack_pointer++;
            }
        }
    }
// Clear all remaining MAYBE pixels to NO, these were not reachable from
// any YES pixels
// LOOP 4.5
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        // LOOP 4.6
        for (int x = 0; x < width; x++) {
            if (image[y * width + x] == 127) {
                image[y * width + x] = 0;
            }
        }
    }
}

void
cannyEdgeDetection(
    uint8_t *restrict input, size_t width, size_t height,
    uint16_t threshold_lower, uint16_t threshold_upper,
    uint8_t *restrict output, double *restrict runtimes) {
    size_t image_size = width * height;

    // Allocate arrays for intermediate results
    int16_t *sobel_x = malloc(image_size * sizeof(int16_t));
    assert(sobel_x);

    int16_t *sobel_y = malloc(image_size * sizeof(int16_t));
    assert(sobel_y);

    uint8_t *phase = malloc(image_size * sizeof(uint8_t));
    assert(phase);

    uint16_t *magnitude = malloc(image_size * sizeof(uint16_t));
    assert(magnitude);

    cl_event e1, e2, e3, e4, eb1, eb2, eb3;
    if (canny_kernel_enabled) {
        clEnqueueWriteBuffer(
                commandQueue[canny_kernel_device_idx], input_buffer, CL_FALSE, 0, width * height, input, 0,
                NULL, NULL);
        size_t global[2] = {width, height};

        clEnqueueNDRangeKernel(
                commandQueue[canny_kernel_device_idx], canny_kernel, 2, NULL, global, NULL, 0, NULL, &e1);
        clEnqueueReadBuffer(
                commandQueue[canny_kernel_device_idx], suppressed_buffer, CL_TRUE, 0, width * height, output,
                0, NULL, NULL);
        uint8_t *suppressed_ref = malloc(image_size * sizeof(uint8_t));
        assert(suppressed_ref);
        sobel3x3(input, width, height, sobel_x, sobel_y);
        phaseAndMagnitude(sobel_x, sobel_y, width, height, phase, magnitude);
        nonMaxSuppression_ref(magnitude, phase, width, height,
                threshold_lower, threshold_upper, suppressed_ref);
        printf("Suppressed:\n");
        for (int i = 0; i < width * height; i++) {
            if (output[i] != suppressed_ref[i]) {
                printf("%d:%hhu -- %hhu\n", i, suppressed_ref[i], output[i]);
                any_mismatch = -1;
            }
        }
    } else if (sobel_kernel_enabled) {
        clEnqueueWriteBuffer(
                commandQueue[sobel_kernel_device_idx], input_buffer, CL_FALSE, 0, width * height, input, 0,
                NULL, NULL);
        size_t global[2] = {width, height};

        clEnqueueNDRangeKernel(
                commandQueue[sobel_kernel_device_idx], sobel_kernel, 2, NULL, global, NULL, 0, NULL, &e1);
        runtimes[0] = getStartEndTime(e1);

        clEnqueueReadBuffer(
                commandQueue[sobel_kernel_device_idx], sobel_x_buffer, CL_FALSE, 0, width * height * 2, sobel_x,
                0, NULL, NULL);
        clEnqueueReadBuffer(
                commandQueue[sobel_kernel_device_idx], sobel_y_buffer, CL_TRUE, 0, width * height * 2, sobel_y,
                0, NULL, &eb3);
        int16_t *sobel_x_ref = malloc(image_size * sizeof(int16_t));
        assert(sobel_x_ref);
        int16_t *sobel_y_ref = malloc(image_size * sizeof(int16_t));
        assert(sobel_y_ref);
        sobel3x3_ref(input, width, height, sobel_x_ref, sobel_y_ref);
        printf("Sobel X:\n");
        for (int i = 0; i < width * height; i++) {
            if (sobel_x[i] != sobel_x_ref[i]) {
                printf("%d:%hi -- %hi\n", i, sobel_x_ref[i], sobel_x[i]);
                any_mismatch = -1;
            }
        }
        printf("Sobel Y:\n");
        for (int i = 0; i < width * height; i++) {
            if (sobel_y[i] != sobel_y_ref[i]) {
                printf("%d:%hi -- %hi\n", i, sobel_y_ref[i], sobel_y[i]);
                any_mismatch = -1;
            }
        }

        if (phase_kernel_enabled && magnitude_kernel_enabled) {
            clEnqueueNDRangeKernel(
                    commandQueue[phase_kernel_device_idx], phase_kernel, 2, NULL, global, NULL, 0, NULL, &e2);
            clEnqueueNDRangeKernel(
                    commandQueue[magnitude_kernel_device_idx], magnitude_kernel, 2, NULL, global, NULL, 0, NULL, &e3);
            runtimes[1] = getStartEndTime(e2) + getStartEndTime(e3);

            clEnqueueReadBuffer(
                    commandQueue[phase_kernel_device_idx], phase_buffer, CL_FALSE, 0, width * height, phase,
                    0, NULL, NULL);
            clEnqueueReadBuffer(
                    commandQueue[magnitude_kernel_device_idx], magnitude_buffer, CL_TRUE, 0, width * height * 2, magnitude,
                    0, NULL, &eb3);
            uint8_t *phase_ref = malloc(image_size * sizeof(uint8_t));
            assert(phase_ref);
            uint16_t *magnitude_ref = malloc(image_size * sizeof(uint16_t));
            assert(magnitude_ref);
            phaseAndMagnitude_ref(sobel_x, sobel_y, width, height,
                    phase_ref, magnitude_ref);
            printf("Phase:\n");
            for (int i = 0; i < width * height; i++) {
                if (phase[i] != phase_ref[i]) {
                    printf("%d:%hhu -- %hhu\n", i, phase_ref[i], phase[i]);
                    any_mismatch = -1;
                }
            }
            printf("Magnitude:\n");
            for (int i = 0; i < width * height; i++) {
                if (magnitude[i] != magnitude_ref[i]) {
                    printf("%d:%hu -- %hu\n", i, magnitude_ref[i], magnitude[i]);
                    any_mismatch = -1;
                }
            }

            if (suppr_kernel_enabled) {
                clEnqueueNDRangeKernel(
                        commandQueue[suppr_kernel_device_idx], nonmax_suppr_kernel, 2, NULL, global, NULL, 0, NULL, &e4);
                clEnqueueReadBuffer(
                        commandQueue[suppr_kernel_device_idx], suppressed_buffer, CL_TRUE, 0, width * height, output,
                        0, NULL, NULL);
                uint8_t *suppressed_ref = malloc(image_size * sizeof(uint8_t));
                assert(suppressed_ref);
                nonMaxSuppression_ref(magnitude, phase, width, height,
                        threshold_lower, threshold_upper, suppressed_ref);
                printf("Suppressed:\n");
                for (int i = 0; i < width * height; i++) {
                    if (output[i] != suppressed_ref[i]) {
                        printf("%d:%hhi -- %hhi\n", i, suppressed_ref[i], output[i]);
                        any_mismatch = -1;
                    }
                }

                runtimes[2] = getStartEndTime(e4);
            } else {
                clEnqueueReadBuffer(
                        commandQueue[phase_kernel_device_idx], phase_buffer, CL_FALSE, 0, width * height, phase,
                        0, NULL, NULL);
                clEnqueueReadBuffer(
                        commandQueue[magnitude_kernel_device_idx], magnitude_buffer, CL_TRUE, 0, width * height * 2, magnitude,
                        0, NULL, &eb3);
                uint64_t phase_mag_end = gettimemono_ns();
                nonMaxSuppression(
                        magnitude, phase, width, height, threshold_lower, threshold_upper,
                        output);
                uint64_t suppr_end = gettimemono_ns();
                runtimes[2] = suppr_end - phase_mag_end;
            }
        } else {
            clEnqueueReadBuffer(
                    commandQueue[sobel_kernel_device_idx], sobel_x_buffer, CL_FALSE, 0, width * height * 2, sobel_x,
                    0, NULL, NULL);
            clEnqueueReadBuffer(
                    commandQueue[sobel_kernel_device_idx], sobel_y_buffer, CL_TRUE, 0, width * height * 2, sobel_y,
                    0, NULL, &eb3);
            uint64_t sobel_end = gettimemono_ns();
            phaseAndMagnitude(sobel_x, sobel_y, width, height, phase, magnitude);
            uint64_t phase_mag_end = gettimemono_ns();

            nonMaxSuppression(
                    magnitude, phase, width, height, threshold_lower, threshold_upper,
                    output);
            uint64_t suppr_end = gettimemono_ns();
            runtimes[1] = phase_mag_end - sobel_end;
            runtimes[2] = suppr_end - phase_mag_end;
        }
    } else {
        uint64_t sobel_start = gettimemono_ns();
        sobel3x3(input, width, height, sobel_x, sobel_y);
        uint64_t sobel_end = gettimemono_ns();

        phaseAndMagnitude(sobel_x, sobel_y, width, height, phase, magnitude);
        uint64_t phase_mag_end = gettimemono_ns();

        nonMaxSuppression(
                magnitude, phase, width, height, threshold_lower, threshold_upper,
                output);
        uint64_t suppr_end = gettimemono_ns();
        runtimes[0] = sobel_end - sobel_start;
        runtimes[1] = phase_mag_end - sobel_end;
        runtimes[2] = suppr_end - phase_mag_end;
    }

    uint64_t tracing_time_start = gettimemono_ns();
    edgeTracing(output, width, height);  // modifies output in-place
    uint64_t tracing_time_end = gettimemono_ns();

    runtimes[0] /= 1000000.0;
    runtimes[1] /= 1000000.0;
    runtimes[2] /= 1000000.0;
    runtimes[3] = (tracing_time_end - tracing_time_start) / 1000000.0;

    /*    uint64_t write_time = getStartEndTime(eb1);
          uint64_t read_time = getStartEndTime(eb2);

          printf(
          "OpenCL input write time: %.1f, output read time: %.1f\n",
          write_time / 1000000.0, read_time / 1000000.0);
          */
}

////////////////////////////////////////////////
// ¤¤ DO NOT EDIT ANYTHING AFTER THIS LINE ¤¤ //
////////////////////////////////////////////////

enum PROCESSING_MODE { DEFAULT, BIG_MODE, SMALL_MODE, VIDEO_MODE };
// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
int
main(int argc, char **argv) {
    enum PROCESSING_MODE mode = DEFAULT;
    char input_image_path[256] = "canny_host/x_64x4.pgm";
    if (argc > 1) {
        char *mode_c = argv[1];
        if (strlen(mode_c) == 2) {
            if (strncmp(mode_c, "-B", 2) == 0) {
                mode = BIG_MODE;
                strcpy(input_image_path, argv[2]);
            } else if (strncmp(mode_c, "-b", 2) == 0) {
                mode = SMALL_MODE;
                strcpy(input_image_path, argv[2]);
            } else if (strncmp(mode_c, "-v", 2) == 0) {
                mode = VIDEO_MODE;
                strcpy(input_image_path, argv[2]);
            } else {
                printf(
                        "Invalid usage! Please set either -b, -B, -v or "
                        "nothing\n");
                return -1;
            }
        } else {
            strcpy(input_image_path, argv[1]);
        }
    }
    int benchmarking_iterations = 1;
    if (argc > 2) {
        benchmarking_iterations = atoi(argv[2]);
    }

    char *output_image_path = "";
    uint16_t threshold_lower = 0;
    uint16_t threshold_upper = 0;
    switch (mode) {
        case BIG_MODE:
            output_image_path = "hameensilta_output.pgm";
            // Arbitrarily selected to produce a nice-looking image
            // DO NOT CHANGE THESE WHEN BENCHMARKING
            threshold_lower = 120;
            threshold_upper = 300;
            printf(
                    "Enabling %d benchmarking iterations with the large %s "
                    "image\n",
                    benchmarking_iterations, input_image_path);
            break;
        case SMALL_MODE:
            output_image_path = "x_output.pgm";
            threshold_lower = 750;
            threshold_upper = 800;
            printf(
                    "Enabling %d benchmarking iterations with the small %s "
                    "image\n",
                    benchmarking_iterations, input_image_path);
            break;
        case VIDEO_MODE:
            if (system("which ffmpeg > /dev/null 2>&1") ||
                    system("which ffplay > /dev/null 2>&1")) {
                printf(
                        "Video mode is disabled because ffmpeg is not found\n");
                return -1;
            }
            benchmarking_iterations = 0;
            threshold_lower = 120;
            threshold_upper = 300;
            printf(
                    "Playing video %s with FFMPEG. Error check disabled.\n",
                    input_image_path);
            break;
        case DEFAULT:
        default:
            output_image_path = "x_output.pgm";
            // Carefully selected to produce a discontinuous edge without edge
            // tracing
            threshold_lower = 750;
            threshold_upper = 800;
            printf("Running with %s image\n", input_image_path);
            break;
    }

    uint8_t *input_image = NULL;
    size_t width = 0;
    size_t height = 0;
    if (mode == VIDEO_MODE) {
        width = 3840;
        height = 2160;
        init(width, height, threshold_lower, threshold_upper);

        uint8_t *output_image = malloc(width * height);
        assert(output_image);

        int count;
        uint8_t *frame = malloc(width * height * 3);
        assert(frame);
        char pipein_cmd[1024];
        snprintf(
                pipein_cmd, 1024,
                "ffmpeg -i %s -f image2pipe -vcodec rawvideo -an -s %zux%zu "
                "-pix_fmt gray - 2> /dev/null",
                input_image_path, width, height);
        FILE *pipein = popen(pipein_cmd, "r");
        char pipeout_cmd[1024];
        snprintf(
                pipeout_cmd, 1024,
                "ffplay -f rawvideo -pixel_format gray -video_size %zux%zu "
                "-an - 2> /dev/null",
                width, height);
        FILE *pipeout = popen(pipeout_cmd, "w");
        double runtimes[4];
        while (1) {
            count = fread(frame, 1, height * width, pipein);
            if (count != height * width) break;

            cannyEdgeDetection(
                    frame, width, height, threshold_lower, threshold_upper,
                    output_image, runtimes);

            double total_time =
                runtimes[0] + runtimes[1] + runtimes[2] + runtimes[3];
            printf("FPS: %0.1f\n", 1000 / total_time);
            fwrite(output_image, 1, height * width, pipeout);
        }
        fflush(pipein);
        pclose(pipein);
        fflush(pipeout);
        pclose(pipeout);
    } else {
        if ((input_image = read_pgm(input_image_path, &width, &height))) {
            printf(
                    "Input image read succesfully. Size %zux%zu\n", width,
                    height);
        } else {
            printf("Read failed\n");
            return -1;
        }
        init(width, height, threshold_lower, threshold_upper);

        uint8_t *output_image = malloc(width * height);
        assert(output_image);

        int all_the_runs_were_succesful = 1;
        double avg_runtimes[4] = {0.0, 0.0, 0.0, 0.0};
        double avg_total = 0.0;
        for (int iter = 0; iter < benchmarking_iterations; iter++) {
            double iter_runtimes[4];
            cannyEdgeDetection(
                    input_image, width, height, threshold_lower, threshold_upper,
                    output_image, iter_runtimes);

            for (int n = 0; n < 4; n++) {
                avg_runtimes[n] += iter_runtimes[n] / benchmarking_iterations;
                avg_total += iter_runtimes[n] / benchmarking_iterations;
            }

            uint8_t *output_image_ref = malloc(width * height);
            assert(output_image_ref);
            cannyEdgeDetection_ref(
                    input_image, width, height, threshold_lower, threshold_upper,
                    output_image_ref);

            uint8_t *fused_comparison = malloc(width * height);
            assert(fused_comparison);
            int failed = validate_result(
                    output_image, output_image_ref, width, height,
                    fused_comparison);
            if (failed) {
                all_the_runs_were_succesful = 0;
                printf(
                        "Error checking failed for benchmark iteration %d!\n"
                        "Writing your output to %s. The image that should've "
                        "been generated is written to ref.pgm\n"
                        "Generating fused.pgm for debugging purpose. Light-grey "
                        "pixels should've been white and "
                        "dark-grey pixels black. Corrupted pixels are colored "
                        "middle-grey\n",
                        iter, output_image_path);

                write_pgm("ref.pgm", output_image_ref, width, height);
                write_pgm("fused.pgm", fused_comparison, width, height);
            }
        }

        printf("Sobel3x3 time          : %0.3f ms\n", avg_runtimes[0]);
        printf("phaseAndMagnitude time : %0.3f ms\n", avg_runtimes[1]);
        printf("nonMaxSuppression time : %0.3f ms\n", avg_runtimes[2]);
        printf("edgeTracing time       : %0.3f ms\n", avg_runtimes[3]);
        printf("Total time             : %0.3f ms\n", avg_total);
        write_pgm(output_image_path, output_image, width, height);
        printf("Wrote output to %s\n", output_image_path);
        if (all_the_runs_were_succesful) {
            printf("Pixel error checks passed!\n");
        } else {
            printf("There were failing runs\n");
            any_mismatch = -1;
        }
    }
    destroy();
    return any_mismatch;
}
