/* accel_example.cpp - Example program for built-in kernels

   Copyright (c) 2023 Topi Leppänen / Tampere University

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to
   deal in the Software without restriction, including without limitation the
   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
   sell copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
   IN THE SOFTWARE.
*/


#include <CL/opencl.hpp>

#include <cfloat>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <deque>
#include <iostream>
#include <map>
#include <mutex>
#include <random>
#include <set>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

// SGEMM kernel requires 16
#define SGEMM_TILE 16
#define X 8
#define Y 32
#define BUFSIZE (X*Y*4)

int any_mismatch = 0;

#define CHECK_CL_ERROR(EXPR, ...) \
    if (EXPR != CL_SUCCESS) { std::cerr << __VA_ARGS__; return 12; }

cl_ulong getStartEndTime(cl::Event *event) {
  int status;

  cl_ulong start = event->getProfilingInfo<CL_PROFILING_COMMAND_START>(&status);
  CHECK_CL_ERROR(status, "Failed to query event start time");
  cl_ulong end = event->getProfilingInfo<CL_PROFILING_COMMAND_END>(&status);
  CHECK_CL_ERROR(status, "Failed to query event end time");

  return end - start;
}

int
main(int argc, char** argv)
{
    cl::Platform platform;
    std::vector<cl::Device> devices;
    cl::Context ClContext;

    cl::Device AccelDev;
    cl::CommandQueue AccelQueue;
    cl::Program AccelProgram;
    cl::Kernel AccelKernel;
    cl::Event event_buf1, event_buf2, event_buf3, event_kernel;

    cl::NDRange Offset, Global2D, Local2D, Global, Local;
    int err;
    double total_runtime = 0;
    double total_buf1_time = 0;
    double total_buf2_time = 0;
    double total_buf3_time = 0;
    double total_kernel_time = 0;
    double total_bufsum_time = 0;
    double min_buf1_time = DBL_MAX;
    double min_buf2_time = DBL_MAX;
    double min_buf3_time = DBL_MAX;
    double min_kernel_time = DBL_MAX;
    double min_bufsum_time = DBL_MAX;

    std::vector<cl::Platform> all_platforms;
    cl::Platform::get(&all_platforms);
    if(!all_platforms.size()) {
        std::cerr << "No OpenCL platforms available!\n";
        return 1;
    }

    platform = all_platforms[0];
    platform.getDevices(CL_DEVICE_TYPE_CUSTOM, &devices);
    if(devices.size() == 0) {
        platform.getDevices(CL_DEVICE_TYPE_ALL, &devices);
        if(devices.size() == 0) {
            std::cerr << "No OpenCL devices available!\n";
            return 2;
        }
    }

    const char* kernel_name = "pocl.add.i32";
    const char *known_kernels[] = {
        "pocl.add.i32", "pocl.mul.i32", "pocl.add.i16", NULL,
    };
    if (argc > 1)
      {
        kernel_name = argv[1];
        std::string k{kernel_name};
        int found = 0;
        unsigned i = 0;
        while (known_kernels[i]) {
            if (k.compare(known_kernels[i]) == 0) found = 1;
            ++i;
          }
        if (!found) {
            std::cerr << "unknown builtin kernel: " << kernel_name << "\n";
            return 3;
          }
      }
    int num_iterations = 1;
    if (argc > 2)
      {
        num_iterations = atoi(argv[2]);
      }

    std::string kernel_str{kernel_name};

    for (auto& D : devices) {
      std::string AccelBuiltinKernels = D.getInfo<CL_DEVICE_BUILT_IN_KERNELS>();
      std::cout << "Device " << D.getInfo<CL_DEVICE_NAME>() <<
                   " has builtin kernels: " << AccelBuiltinKernels << "\n";
      if (AccelBuiltinKernels.find(kernel_str) != std::string::npos)
      {
         AccelDev = D;
         break;
      }
    }
    if (AccelDev.get() == nullptr) {
        std::cerr << "no devices which support builtin kernel " << kernel_str << "\n";
        return 4;
      }

    std::cout << "Using device: " << AccelDev.getInfo<CL_DEVICE_NAME>() << "\n";
    std::cout << "Using builtin kernel: " << kernel_str << "\n";

    std::vector<cl::Device> AccelDevs = {AccelDev};
    ClContext = cl::Context(AccelDevs, nullptr, nullptr, nullptr, &err);
    CHECK_CL_ERROR(err, "Context creation failed\n");

    AccelQueue =
        cl::CommandQueue(ClContext, AccelDev, CL_QUEUE_PROFILING_ENABLE,
                         &err); // , CL_QUEUE_PROFILING_ENABLE
    CHECK_CL_ERROR(err, "CmdQueue creation failed\n");

    AccelProgram = cl::Program{ClContext, AccelDevs, kernel_str.c_str(), &err};
    CHECK_CL_ERROR(err, "Program creation failed\n");

    err = AccelProgram.build(AccelDevs);
    CHECK_CL_ERROR(err, "Program build failed\n");
    cl::Kernel Kernel = cl::Kernel(AccelProgram, kernel_str.c_str(), &err);
    CHECK_CL_ERROR(err, "Kernel creation failed\n");

    cl::Buffer Input1 = cl::Buffer(ClContext, CL_MEM_READ_WRITE, (cl::size_type)BUFSIZE, nullptr, &err);
    CHECK_CL_ERROR(err, "Input1 buffer creation failed\n");
    cl::Buffer Input2 = cl::Buffer(ClContext, CL_MEM_READ_WRITE, (cl::size_type)BUFSIZE, nullptr, &err);
    CHECK_CL_ERROR(err, "Input2 buffer creation failed\n");
    cl::Buffer Out1 = cl::Buffer(ClContext, CL_MEM_READ_WRITE, (cl::size_type)BUFSIZE, nullptr, &err);
    CHECK_CL_ERROR(err, "OUtput1 buffer creation failed\n");

    void *i1, *i2, *o1;
    Offset = cl::NullRange;
    Local = cl::NullRange;
    Local2D = cl::NullRange;
    Global2D = cl::NDRange(X, Y);
    if (kernel_str.compare("pocl.add.i16") == 0) {
        Global = cl::NDRange(X * Y * 2);
    } else {
        Global = cl::NDRange(X * Y);
    }

    if (kernel_str.compare("pocl.add.i32") == 0 ||
        kernel_str.compare("pocl.add.i16") == 0 ||
        kernel_str.compare("pocl.mul.i32") == 0) {
        Kernel.setArg(0, Input1);
        Kernel.setArg(1, Input2);
        Kernel.setArg(2, Out1);
    }

    std::mt19937 mt{234545649UL};
    for (int repeat_count = 0; repeat_count < num_iterations; repeat_count++) {
        if (kernel_str.compare("pocl.add.i16") == 0) {
         std::uniform_int_distribution<unsigned int> dist(10, 124);
         uint16_t *in1 = new uint16_t[X * Y * 2];
         uint16_t *in2 = new uint16_t[X * Y * 2];
         uint16_t *out1 = new uint16_t[X * Y * 2];
         for (size_t i = 0; i < X * Y * 2; ++i) {
           in1[i] = dist(mt);
           in2[i] = dist(mt);
           out1[i] = 0;
         }
         i1 = in1;
         i2 = in2;
         o1 = out1;
        } else {
         std::uniform_int_distribution<unsigned int> dist(10, 124);
         uint32_t *in1 = new uint32_t[X * Y];
         uint32_t *in2 = new uint32_t[X * Y];
         uint32_t *out1 = new uint32_t[X * Y];
         for (size_t i = 0; i < X * Y; ++i) {
           in1[i] = dist(mt);
           in2[i] = dist(mt);
           out1[i] = 0;
         }
         i1 = in1;
         i2 = in2;
         o1 = out1;
        }
        using clock_type = std::chrono::steady_clock;
        using second_type = std::chrono::duration<double, std::ratio<1>>;
        std::chrono::time_point<clock_type> m_beg{clock_type::now()};

        err = AccelQueue.enqueueWriteBuffer(Input1, CL_FALSE, 0, BUFSIZE, i1,
                                            NULL, &event_buf1);
        CHECK_CL_ERROR(err, "en 1");
        err = AccelQueue.enqueueWriteBuffer(Input2, CL_FALSE, 0, BUFSIZE, i2,
                                            NULL, &event_buf2);
        CHECK_CL_ERROR(err, "en 2");

        err = AccelQueue.enqueueNDRangeKernel(Kernel, Offset, Global, Local,
                                               NULL, &event_kernel);
        CHECK_CL_ERROR(err, "en 3");
        err = AccelQueue.enqueueReadBuffer(Out1, CL_TRUE, 0, BUFSIZE, o1, NULL,
                                           &event_buf3);
        CHECK_CL_ERROR(err, "en 4");

        std::chrono::time_point<clock_type> m_end{clock_type::now()};
        double diff =
            std::chrono::duration_cast<second_type>(m_end - m_beg).count();
        std::cout << "Execution time(s): " << diff << "\n";

        double buf1_time = float(getStartEndTime(&event_buf1)) / 1e6;
        double buf2_time = float(getStartEndTime(&event_buf2)) / 1e6;
        double buf3_time = float(getStartEndTime(&event_buf3)) / 1e6;
        double kernel_time = float(getStartEndTime(&event_kernel)) / 1e6;
        double bufsum_time = buf1_time + buf2_time + buf3_time;
        std::cout << "Buffer transfer times: " << buf1_time << ", " << buf2_time
                  << ", " << buf3_time << ". Kernel time: " << kernel_time
                  << std::endl;

        if (repeat_count != 0) {
         total_runtime += diff;
         total_buf1_time += buf1_time;
         total_buf2_time += buf2_time;
         total_buf3_time += buf3_time;
         total_kernel_time += kernel_time;
         total_bufsum_time += bufsum_time;
         if (buf1_time < min_buf1_time) {
           min_buf1_time = buf1_time;
         }
         if (buf2_time < min_buf2_time) {
           min_buf2_time = buf2_time;
         }
         if (buf3_time < min_buf3_time) {
           min_buf3_time = buf3_time;
         }
         if (kernel_time < min_kernel_time) {
           min_kernel_time = kernel_time;
         }
         if (bufsum_time < min_bufsum_time) {
           min_bufsum_time = bufsum_time;
         }
        }

        bool Failed = false;
        bool ResultChecked = false;
        if (kernel_str.compare("pocl.add.i16") == 0) {
         uint16_t *in1_h = (uint16_t *)i1;
         uint16_t *in2_h = (uint16_t *)i2;
         uint16_t *out1_h = (uint16_t *)o1;
         for (size_t i = 0; i < 10; ++i) {
           std::cout << "IN1: " << in1_h[i] << "  IN2: " << in2_h[i]
                     << "  OUT1: " << out1_h[i] << "\n";
         }
         ResultChecked = true;
         for (size_t i = 0; i < X * Y * 2; ++i) {
           if (out1_h[i] != in1_h[i] + in2_h[i]) {
             Failed = true;
             break;
           }
         }
        } else {
         uint32_t *in1 = (uint32_t *)i1;
         uint32_t *in2 = (uint32_t *)i2;
         uint32_t *out1 = (uint32_t *)o1;

         for (size_t i = 0; i < 10; ++i) {
           std::cout << "IN1: " << in1[i] << "  IN2: " << in2[i]
                     << "  OUT1: " << out1[i] << "\n";
         }

         if (kernel_str.compare("pocl.add.i32") == 0) {
           ResultChecked = true;
           for (size_t i = 0; i < X * Y; ++i) {
             if (out1[i] != in1[i] + in2[i]) {
               Failed = true;
               break;
             }
           }
         }

         if (kernel_str.compare("pocl.mul.i32") == 0) {
           ResultChecked = true;
           for (size_t i = 0; i < X * Y; ++i) {
             if (out1[i] != in1[i] * in2[i]) {
               Failed = true;
               break;
             }
           }
         }

         delete[] in1;
         delete[] in2;
         delete[] out1;
        }

        if (ResultChecked) {
          if (Failed) {
            std::cout << "TEST FAILED\n";
            any_mismatch = -1;
          }
          else {
            std::cout << "OK; TEST PASSED\n";
          }
        }
    }

    if (num_iterations > 1) {
        std::cout << "Total execution time(s): " << total_runtime << "\n";
        double avg_runtime = total_runtime / (num_iterations - 1);
        double avg_buf1_time = total_buf1_time / (num_iterations - 1);
        double avg_buf2_time = total_buf2_time / (num_iterations - 1);
        double avg_buf3_time = total_buf3_time / (num_iterations - 1);
        double avg_kernel_time = total_kernel_time / (num_iterations - 1);
        double avg_bufsum_time = total_bufsum_time / (num_iterations - 1);

        std::cout << "Average execution time(s): " << avg_runtime << "\n";
        std::cout << "Average buffer transfer times: " << avg_buf1_time << ", "
                  << avg_buf2_time << ", " << avg_buf3_time
                  << ". Kernel time: " << avg_kernel_time
                  << " Average sum of buffer transfers:" << avg_bufsum_time
                  << std::endl;
        std::cout << "Minimum buffer transfer times: " << min_buf1_time << ", "
                  << min_buf2_time << ", " << min_buf3_time
                  << ". Kernel time: " << min_kernel_time
                  << " Minimum sum of buffer transfers: " << min_bufsum_time
                  << std::endl;
    }

    return any_mismatch;
}
