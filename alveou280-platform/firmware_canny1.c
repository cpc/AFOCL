/* firmware.c - Example firmware for tta device implementing AlmaIF.

   Copyright (c) 2022 Topi Leppänen / Tampere University

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


//#include <stdint.h>
#include <stdarg.h>

#ifndef QUEUE_LENGTH
#define QUEUE_LENGTH 3
#endif

#define AQL_PACKET_INVALID (1)
#define AQL_PACKET_KERNEL_DISPATCH (2)
#define AQL_PACKET_BARRIER_AND (3)
#define AQL_PACKET_AGENT_DISPATCH (4)
#define AQL_PACKET_BARRIER_OR (5)
#define AQL_PACKET_BARRIER (1 << 8)
#define AQL_PACKET_LENGTH (64)

#define AQL_MAX_SIGNAL_COUNT (5)

#define ALMAIF_STATUS_REG (0x00)
#define ALMAIF_STATUS_REG_PC (0x04)
#define ALMAIF_STATUS_REG_CC_LOW (0x08)
#define ALMAIF_STATUS_REG_CC_HIGH (0x0C)
#define ALMAIF_STATUS_REG_SC_LOW (0x10)
#define ALMAIF_STATUS_REG_SC_HIGH (0x14)

#define SLEEP_CYCLES 400

#ifndef QUEUE_START
#define QUEUE_START 0
#endif

#define __cq__ __attribute__ ((address_space (5)))
#define __buffer__ __attribute__ ((address_space (1)))

#include "printf_base.h"


#define PRINTF_BUFFER_AS __attribute__((address_space(1)))


enum BuiltinKernelId : uint16_t
{
    // CD = custom device, BI = built-in
    // 1D array byte copy, get_global_size(0) defines the size of data to copy
    // kernel prototype: pocl.copy(char *input, char *output)
    POCL_CDBI_COPY_I8 = 0,
    POCL_CDBI_ADD_I32 = 1,
    POCL_CDBI_MUL_I32 = 2,
    POCL_CDBI_LEDBLINK = 3,
    POCL_CDBI_COUNTRED = 4,
    POCL_CDBI_DNN_CONV2D_RELU_I8 = 5,
    POCL_CDBI_SGEMM_LOCAL_F32 = 6,
    POCL_CDBI_SGEMM_TENSOR_F16F16F32_SCALE = 7,
    POCL_CDBI_SGEMM_TENSOR_F16F16F32 = 8,
    POCL_CDBI_ABS_F32 = 9,
    POCL_CDBI_DNN_DENSE_RELU_I8 = 10,
    POCL_CDBI_MAXPOOL_I8 = 11,
    POCL_CDBI_ADD_I8 = 12,
    POCL_CDBI_MUL_I8 = 13,
    POCL_CDBI_ADD_I16 = 14,
    POCL_CDBI_MUL_I16 = 15,
    POCL_CDBI_STREAMOUT_I32 = 16,
    POCL_CDBI_STREAMIN_I32 = 17,
    POCL_CDBI_OPENVX_MINMAXLOC_R1_U8 = 24,
    POCL_CDBI_SOBEL3X3_U8 = 25,
    POCL_CDBI_PHASE_U8 = 26,
    POCL_CDBI_MAGNITUDE_U16 = 27,
    POCL_CDBI_ORIENTED_NONMAX_U16 = 28,
    POCL_CDBI_25_26_27_28 = 29,
    POCL_CDBI_LAST,
    POCL_CDBI_JIT_COMPILER = 0xFFFF
};

struct AQLQueueInfo
{
    uint32_t type;
    uint32_t features;

    uint32_t base_address_low;
    uint32_t base_address_high;
    uint32_t doorbell_signal_low;
    uint32_t doorbell_signal_high;

    uint32_t size;
    uint32_t reserved0;

    uint32_t id_low;
    uint32_t id_high;

    volatile uint32_t write_index_low;
    volatile uint32_t write_index_high;

    uint32_t read_index_low;
    uint32_t read_index_high;

    uint32_t reserved1;
    uint32_t reserved2;
};

struct CommandMetadata
{
    uint32_t completion_signal;
    uint32_t reserved0;
    uint32_t start_timestamp_l;
    uint32_t start_timestamp_h;
    uint32_t finish_timestamp_l;
    uint32_t finish_timestamp_h;
    uint32_t reserved1;
    uint32_t reserved2;
};

struct AQLDispatchPacket
{
    uint16_t header;
    uint16_t dimensions;

    uint16_t workgroup_size_x;
    uint16_t workgroup_size_y;
    uint16_t workgroup_size_z;

    uint16_t reserved0;

    uint32_t grid_size_x;
    uint32_t grid_size_y;
    uint32_t grid_size_z;

    uint32_t private_segment_size;
    uint32_t group_segment_size;
    uint32_t kernel_object_low;
    uint32_t kernel_object_high;
    uint32_t kernarg_address_low;
    uint32_t kernarg_address_high;

    uint32_t reserved1;
    uint32_t reserved2;

    uint32_t completion_signal_low;
    uint32_t completion_signal_high;
};

struct AQLAndPacket
{
    uint16_t header;
    uint16_t reserved0;
    uint32_t reserved1;

    uint32_t dep_signals[10];

    uint32_t signal_count_low;
    uint32_t signal_count_high;

    uint32_t completion_signal_low;
    uint32_t completion_signal_high;
};


int
main ()
{
    __cq__ volatile struct AQLQueueInfo *queue_info
        = (__cq__ volatile struct AQLQueueInfo *)QUEUE_START;
    int read_iter = queue_info->read_index_low;

    uint32_t dma0_address = 0x81E00000;
    uint32_t dma1_address = 0x81E10000;
    uint32_t dma2_address = 0x81E20000;
    uint32_t dma3_address = 0x81E30000;
    uint32_t dma4_address = 0x81E40000;
    uint32_t dma5_address = 0x81E50000;
    uint32_t dma6_address = 0x81E60000;

    uint32_t s2mm0_address = 0x81E70000;
    uint32_t s2mm1_address = 0x81E80000;
    uint32_t s2mm2_address = 0x81E90000;
    uint32_t s2mm3_address = 0x81EA0000;
    uint32_t s2mm4_address = 0x81EB0000;

    uint32_t sobel_address = 0x81EC0000;
    //uint32_t phase_address = 0x81E80000;
    //uint32_t magnitude_address = 0x81E90000;
    uint32_t nonmax_address = 0x81ED0000;
    int mm2s_ptr_offset = 0x8/4;
    int mm2s_len_offset = 0x18/4;
    int s2mm_ptr_offset = 0x10/4;
    int s2mm_len_offset = 0x18/4;

    __buffer__ volatile uint32_t* DMA_SOBEL_IN = (__buffer__ volatile uint32_t*)dma0_address;
    __buffer__ volatile uint32_t* DMA_SOBEL_OUT0 = (__buffer__ volatile uint32_t*)(s2mm0_address);
    __buffer__ volatile uint32_t* DMA_SOBEL_OUT1 = (__buffer__ volatile uint32_t*)(s2mm1_address);
    __buffer__ volatile uint32_t* DMA_PHASE_IN0 = (__buffer__ volatile uint32_t*)(dma1_address);
    __buffer__ volatile uint32_t* DMA_PHASE_IN1 = (__buffer__ volatile uint32_t*)(dma2_address);
    __buffer__ volatile uint32_t* DMA_PHASE_OUT = (__buffer__ volatile uint32_t*)(s2mm2_address);
    __buffer__ volatile uint32_t* DMA_MAGNITUDE_IN0 = (__buffer__ volatile uint32_t*)(dma3_address);
    __buffer__ volatile uint32_t* DMA_MAGNITUDE_IN1 = (__buffer__ volatile uint32_t*)(dma4_address);
    __buffer__ volatile uint32_t* DMA_MAGNITUDE_OUT = (__buffer__ volatile uint32_t*)(s2mm3_address);
    
    
    __buffer__ volatile uint32_t* DMA_NONMAX_IN0 = (__buffer__ volatile uint32_t*)(dma5_address);
    __buffer__ volatile uint32_t* DMA_NONMAX_IN1 = (__buffer__ volatile uint32_t*)(dma6_address);
    __buffer__ volatile uint32_t* DMA_NONMAX_OUT = (__buffer__ volatile uint32_t*)(s2mm4_address);
    __buffer__ volatile uint32_t* SOBEL = (__buffer__ volatile uint32_t*)(sobel_address);
    //__buffer__ volatile uint32_t* PHASE = (__buffer__ volatile uint32_t*)(phase_address);
    //__buffer__ volatile uint32_t* MAGNITUDE = (__buffer__ volatile uint32_t*)(magnitude_address);
    __buffer__ volatile uint32_t* NONMAX = (__buffer__ volatile uint32_t*)(nonmax_address);
   
    DMA_SOBEL_OUT0[0] = (1 << 28);
    DMA_SOBEL_OUT1[0] = (1 << 28);
    DMA_PHASE_OUT[0] = (1 << 28);
    DMA_MAGNITUDE_OUT[0] = (1 << 28);
    DMA_NONMAX_OUT[0] = (1 << 28);

    int sobel_running0 = 0;
    int sobel_running1 = 0;
    int phase_running = 0;
    int magnitude_running = 0;
    int nonmax_running = 0;
    __buffer__ volatile uint32_t * stream_in_completion_signal = NULL;
    __buffer__ volatile uint32_t * stream_out_completion_signal = NULL;
    __buffer__ volatile uint32_t * sobel_completion_signal = NULL;
    __buffer__ volatile uint32_t * phase_completion_signal = NULL;
    __buffer__ volatile uint32_t * magnitude_completion_signal = NULL;
    __buffer__ volatile uint32_t * nonmax_completion_signal = NULL;

    queue_info->base_address_high = 42;
    while (1)
    {
        if (sobel_running0) {
            uint32_t status = DMA_SOBEL_OUT0[0] & (1 << 29);
            if (status != 0) {
                sobel_running0 = 0;
                if (sobel_running1 == 0) {
                    *sobel_completion_signal = 1;
                }
            }
        }
        if (sobel_running1) {
            uint32_t status = DMA_SOBEL_OUT1[0] & (1 << 29);
            if (status != 0) {
                sobel_running1 = 0;
                if (sobel_running0 == 0) {
                    *sobel_completion_signal = 1;
                }
            }
        }
        if (phase_running) {
            uint32_t status = DMA_PHASE_OUT[0] & (1 << 29);
            if (status != 0) {
                phase_running = 0;
                *phase_completion_signal = 1;
            }
        }
        if (magnitude_running) {
            uint32_t status = DMA_MAGNITUDE_OUT[0] & (1 << 29);
            if (status != 0) {
                magnitude_running = 0;
                *magnitude_completion_signal = 1;
            }
        }
        if (nonmax_running) {
            uint32_t status = DMA_NONMAX_OUT[0] & (1 << 29);
            if (status != 0) {
                nonmax_running = 0;
                *nonmax_completion_signal = 1;
            }
        }

        // Compute packet location
        uint32_t packet_loc = QUEUE_START + AQL_PACKET_LENGTH
            + ((read_iter % QUEUE_LENGTH) * AQL_PACKET_LENGTH);
        __cq__ volatile struct AQLDispatchPacket *packet
            = (__cq__ volatile struct AQLDispatchPacket *)packet_loc;
        // The driver will mark the packet as not INVALID when it wants us to
        // compute it
        //
        queue_info->doorbell_signal_low = 47;
        if (packet->header == AQL_PACKET_INVALID) { continue; }
        uint16_t header = packet->header;
        queue_info->type = header;
        if (header & (1 << AQL_PACKET_BARRIER_AND))
        {
            /*queue_info->doorbell_signal_low = 152;
            queue_info->type = header;
            __cq__ volatile struct AQLAndPacket *andPacket
                = (__cq__ volatile struct AQLAndPacket *)packet_loc;

            for (int i = 0; i < AQL_MAX_SIGNAL_COUNT; i++)
            {
                volatile __buffer__ uint32_t *signal
                    = (volatile __buffer__ uint32_t *)(andPacket
                            ->dep_signals[2 * i]);
                if (signal != 0)
                {
                    while (*signal == 0)
                    {
                        for (int kk = 0; kk < SLEEP_CYCLES; kk++)
                        {
                            asm volatile("...;");
                        }
                    }
                }
            }*/
        }
        else if (header & (1 << AQL_PACKET_KERNEL_DISPATCH))
        {
            queue_info->base_address_high = 35;

            char *printf_buffer;
            uint32_t *printf_buffer_position;
            uint32_t printf_buffer_capacity;

            __buffer__ volatile struct CommandMetadata *cmd_meta
            = (__buffer__ volatile struct CommandMetadata *)packet->completion_signal_low;
            queue_info->doorbell_signal_high = packet->completion_signal_low;
            printf_buffer = (char *)(cmd_meta->reserved0);
            printf_buffer_capacity = cmd_meta->reserved1;
            printf_buffer_position = (uint32_t*)(cmd_meta->reserved2);
            queue_info->type = cmd_meta->reserved0;
            queue_info->features = cmd_meta->reserved1;
            queue_info->base_address_low = cmd_meta->reserved2;
            param_t p = { 0 };

            p.printf_buffer = (PRINTF_BUFFER_AS char *)printf_buffer;
            p.printf_buffer_capacity = printf_buffer_capacity;
            p.printf_buffer_index
                = *(PRINTF_BUFFER_AS uint32_t *)printf_buffer_position;

            __pocl_printf_puts(&p, "test\n");

            *(PRINTF_BUFFER_AS uint32_t *)printf_buffer_position
                = p.printf_buffer_index;

            queue_info->base_address_high = 37;
            queue_info->doorbell_signal_low = p.printf_buffer_index;
            uint32_t kernel_id = packet->kernel_object_low;

            __buffer__ uint32_t *kernarg_ptr
                = (__buffer__ uint32_t *)(packet->kernarg_address_low);

            uint32_t arg0 = kernarg_ptr[0];
            uint32_t arg1 = kernarg_ptr[1];
            uint32_t arg2 = kernarg_ptr[2];
            uint32_t arg3 = kernarg_ptr[3];
            uint32_t arg4 = kernarg_ptr[4];

            uint32_t dim_x = packet->grid_size_x;
            uint32_t dim_y = packet->grid_size_y;

            if (0 ||
                    (arg0 >= ONCHIP_MEM_START && arg0 < ONCHIP_MEM_END)
               )
            {
                if (kernel_id == POCL_CDBI_SOBEL3X3_U8) {
                    //TODO
                }

            } else {
                switch (kernel_id) {
                    case POCL_CDBI_SOBEL3X3_U8:
                        {
                            if (sobel_running0 || sobel_running1) {
                                continue;
                            }
                            SOBEL[4] = dim_x;
                            SOBEL[6] = dim_y;
                            //Physical starting addresses of the buffers
                            DMA_SOBEL_IN[mm2s_ptr_offset] = arg0;
                            uint32_t pixel_count = dim_x * dim_y;
                            //Num of bytes to transfer (triggers the dma to actually start transferring)
                            DMA_SOBEL_IN[mm2s_len_offset] = pixel_count;
                            DMA_SOBEL_IN[0] = ((1 << 31) | (1 << 28));
                            // Launch the accelerator
                            SOBEL[0] = 1;
                            // Start writing the output back to mem
                            DMA_SOBEL_OUT0[s2mm_ptr_offset] = arg1;
                            DMA_SOBEL_OUT1[s2mm_ptr_offset] = arg2;
                            DMA_SOBEL_OUT0[s2mm_len_offset] = pixel_count * 2;
                            DMA_SOBEL_OUT1[s2mm_len_offset] = pixel_count * 2;
                            DMA_SOBEL_OUT0[0] = ((1 << 31) | (1 << 28));
                            DMA_SOBEL_OUT1[0] = ((1 << 31) | (1 << 28));
                            sobel_running0 = 1;
                            sobel_running1 = 1;
                            sobel_completion_signal = (__buffer__ uint32_t *)packet->completion_signal_low;
                        }
                        break;
                    case POCL_CDBI_PHASE_U8:
                        {
                            if (phase_running) {
                                continue;
                            }
                            DMA_PHASE_IN0[mm2s_ptr_offset] = arg0;
                            uint32_t pixel_count = dim_x * dim_y;
                            //Num of bytes to transfer (triggers the dma to actually start transferring)
                            DMA_PHASE_OUT[s2mm_ptr_offset] = arg2;
                            DMA_PHASE_OUT[s2mm_len_offset] = pixel_count;
                            DMA_PHASE_OUT[0] = ((1 << 31) | (1 << 28));
                            
                            DMA_PHASE_IN0[mm2s_len_offset] = pixel_count * 2;
                            DMA_PHASE_IN1[mm2s_ptr_offset] = arg1;
                            DMA_PHASE_IN1[mm2s_len_offset] = pixel_count * 2;
                            DMA_PHASE_IN0[0] = ((1 << 31) | (1 << 28));
                            DMA_PHASE_IN1[0] = ((1 << 31) | (1 << 28));
/*
                            PHASE[4] = dim_x;
                            PHASE[6] = dim_y;
                            PHASE[0] = 1;
  */                          // Start writing the output back to mem
                            phase_running = 1;
                            phase_completion_signal = (__buffer__ uint32_t *)packet->completion_signal_low;
                        }
                        break;
                    case POCL_CDBI_MAGNITUDE_U16:
                        {
                            if (magnitude_running) {
                                continue;
                            }
                            uint32_t pixel_count = dim_x * dim_y * 2;
                            //Num of bytes to transfer (triggers the dma to actually start transferring)
                            DMA_MAGNITUDE_OUT[s2mm_ptr_offset] = arg2;
                            DMA_MAGNITUDE_OUT[s2mm_len_offset] = pixel_count;
                            DMA_MAGNITUDE_OUT[0] = ((1 << 31) | (1 << 28));
                            
                            DMA_MAGNITUDE_IN0[mm2s_ptr_offset] = arg0;
                            DMA_MAGNITUDE_IN0[mm2s_len_offset] = pixel_count;
                            DMA_MAGNITUDE_IN1[mm2s_ptr_offset] = arg1;
                            DMA_MAGNITUDE_IN1[mm2s_len_offset] = pixel_count;
                            DMA_MAGNITUDE_IN0[0] = ((1 << 31) | (1 << 28));
                            DMA_MAGNITUDE_IN1[0] = ((1 << 31) | (1 << 28));

    /*                        MAGNITUDE[4] = dim_x;
                            MAGNITUDE[6] = dim_y;
                            MAGNITUDE[0] = 1;
      */                      // Start writing the output back to mem
                            magnitude_running = 1;
                            magnitude_completion_signal = (__buffer__ uint32_t *)packet->completion_signal_low;
                        }
                        break;
                    case POCL_CDBI_ORIENTED_NONMAX_U16:
                        {
                            if (nonmax_running) {
                                continue;
                            }
                            uint16_t threshold_lower = (uint16_t)arg3;
                            uint16_t threshold_upper = (uint16_t)arg4;
                            NONMAX[4] = threshold_lower;
                            NONMAX[6] = threshold_upper;
                            NONMAX[8] = dim_x;
                            NONMAX[10] = dim_y;
                            //Physical starting addresses of the buffers
                            uint32_t pixel_count = dim_x * dim_y;
                            DMA_NONMAX_IN0[mm2s_ptr_offset] = arg0;
                            DMA_NONMAX_IN0[mm2s_len_offset] = pixel_count * 2;
                            DMA_NONMAX_IN1[mm2s_ptr_offset] = arg1;
                            DMA_NONMAX_IN1[mm2s_len_offset] = pixel_count;
                            DMA_NONMAX_IN0[0] = ((1 << 31) | (1 << 28));
                            DMA_NONMAX_IN1[0] = ((1 << 31) | (1 << 28));
                            // Start writing the output back to mem
                            DMA_NONMAX_OUT[s2mm_ptr_offset] = arg2;
                            DMA_NONMAX_OUT[s2mm_len_offset] = pixel_count;
                            DMA_NONMAX_OUT[0] = ((1 << 31) | (1 << 28));
                            // Launch the accelerator
                            NONMAX[0] = 1;
                            nonmax_running = 1;
                            nonmax_completion_signal = (__buffer__ uint32_t *)packet->completion_signal_low;
                        }
                        break;
                }
            }
        }
        // Completion signal is given as absolute address
        /*if (packet->completion_signal_low)
        {
            *(__buffer__ uint32_t *)packet->completion_signal_low = 1;
        }*/
        packet->header = AQL_PACKET_INVALID;

        read_iter++; // move on to the next AQL packet
        queue_info->read_index_low = read_iter;
    }
}
