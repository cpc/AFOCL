/* firmware.c - Example firmware for tta device implementing AlmaIF.

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


#include <stdint.h>

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
    POCL_CDBI_LAST = 25,
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


    uint32_t dma0_address = 0x41E00000;
    uint32_t dma1_address = 0x41E10000;
    int dma_ptr_offset = 6;
    int dma_len_offset = 10;

    __buffer__ volatile uint32_t* DMA0 = (__buffer__ volatile uint32_t*)dma0_address;
    __buffer__ volatile uint32_t* DMA1 = (__buffer__ volatile uint32_t*)dma1_address;
    __buffer__ volatile uint32_t* DMA2 = (__buffer__ volatile uint32_t*)(dma0_address + 0x30);
    int need_to_reset = 0;

    queue_info->base_address_high = 42;
    //queue_info->reserved2 = 0;
    while (1)
    {
        if (need_to_reset) {
            // Soft reset the DMA engines
            // DMA2 gets resetted automatically together with DMA0 (MM2S and S2MM-pair)
            DMA0[0] = 0x4;
            DMA1[0] = 0x4;
            // Wait while reset in progress
            while ((DMA0[0] & 0x4) == 1);
            while ((DMA1[0] & 0x4) == 1);
            need_to_reset = 0;
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
        while (packet->header == AQL_PACKET_INVALID)
        {
            /*        *((__cq__ int*)0 ) = packet_loc;
             *((__cq__ int*)4 ) = read_iter + 5;
             *((__cq__ uint16_t*)8 ) = packet->header;
             */  };
        uint16_t header = packet->header;
        queue_info->type = header;
        if (header & (1 << AQL_PACKET_BARRIER_AND))
        {
            queue_info->doorbell_signal_low = 152;
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
            }
        }
        else if (header & (1 << AQL_PACKET_KERNEL_DISPATCH))
        {

            queue_info->base_address_low = 37;
            uint32_t kernel_id = packet->kernel_object_low;

            __buffer__ uint32_t *kernarg_ptr
                = (__buffer__ uint32_t *)(packet->kernarg_address_low);

            uint32_t input0 = kernarg_ptr[0];
            uint32_t input1 = kernarg_ptr[1];
            uint32_t output0 = kernarg_ptr[2];
            queue_info->type = input0;

            uint32_t dim_x = packet->grid_size_x;

            queue_info->base_address_low = (uint32_t)(&(DMA0[1]));

            queue_info->features = dim_x;
            queue_info->type = 108;
            if (0 ||
                    (input0 >= ONCHIP_MEM_START && input0 < ONCHIP_MEM_END)
               )
            {
                queue_info->features = input0;
                queue_info->base_address_low = input1;
                queue_info->base_address_high = output0;

                if (kernel_id == POCL_CDBI_ADD_I32) {
                    __buffer__ uint32_t* in0  = (__buffer__ uint32_t*)input0;
                    __buffer__ uint32_t* in1  = (__buffer__ uint32_t*)input1;
                    __buffer__ uint32_t* out0 = (__buffer__ uint32_t*)output0;
                    for (int x = 0; x < dim_x; x++) {
                        out0[x] = in0[x] + in1[x];
                    }

                } else if (kernel_id == POCL_CDBI_ADD_I16) {
                    __buffer__ uint16_t* in0  = (__buffer__ uint16_t*)input0;
                    __buffer__ uint16_t* in1  = (__buffer__ uint16_t*)input1;
                    __buffer__ uint16_t* out0 = (__buffer__ uint16_t*)output0;
                    for (int x = 0; x < dim_x; x++) {
                        out0[x] = in0[x] + in1[x];
                    }
                } else if (kernel_id == POCL_CDBI_MUL_I32) {
                    __buffer__ uint32_t* in0  = (__buffer__ uint32_t*)input0;
                    __buffer__ uint32_t* in1  = (__buffer__ uint32_t*)input1;
                    __buffer__ uint32_t* out0 = (__buffer__ uint32_t*)output0;
                    for (int x = 0; x < dim_x; x++) {
                        out0[x] = in0[x] * in1[x];
                    }
                }

            } else {
                queue_info->type = 110;

                DMA0[0] = 0x0001;
                uint32_t status = 1;
                // The DMA ip must be running before the parameters are written
                do {
                    status = DMA0[1];
                    queue_info->doorbell_signal_low = DMA0[0];
                    queue_info->doorbell_signal_high = DMA0[1];
                    status &= 0x1;
                } while ( status != 0 );

                DMA1[0] = 0x0001;
                uint32_t status1 = 1;
                do {
                    status1 = DMA1[1];
                    queue_info->doorbell_signal_low = DMA1[0];
                    queue_info->doorbell_signal_high = DMA1[1];
                    status1 &= 0x1;
                } while ( status1 != 0 );

                DMA2[0] = 0x0001;
                uint32_t status2 = 1;
                do {
                    status2 = DMA2[1];
                    queue_info->doorbell_signal_low = DMA2[0];
                    queue_info->doorbell_signal_high = DMA2[1];
                    status2 &= 0x1;
                } while ( status2 != 0 );

                //Physical starting addresses of the buffers
                DMA0[dma_ptr_offset] = input0;
                DMA1[dma_ptr_offset] = input1;
                DMA2[dma_ptr_offset] = output0;
                //Num of bytes to transfer (triggers the dma to actually start transferring)
                uint32_t pixel_count = 0;
                if (kernel_id == POCL_CDBI_ADD_I32 || kernel_id == POCL_CDBI_MUL_I32) {
                    pixel_count = dim_x * 4;
                } else if (kernel_id == POCL_CDBI_ADD_I16) {
                    pixel_count = dim_x * 2;
                } else {
                    continue;
                }
                DMA0[dma_len_offset] = pixel_count;
                DMA1[dma_len_offset] = pixel_count;
                DMA2[dma_len_offset] = pixel_count;

                uint32_t status3 = 0;
                do {
                    status3 = DMA2[1];
                    queue_info->doorbell_signal_low = DMA2[0];
                    queue_info->doorbell_signal_high = DMA2[1];
                    status3 &= 0x1;
                } while ( status3 == 0 );
                need_to_reset = 1;
            }
        }
        // Completion signal is given as absolute address
        if (packet->completion_signal_low)
        {
            *(__buffer__ uint32_t *)packet->completion_signal_low = 1;
        }
        packet->header = AQL_PACKET_INVALID;

        read_iter++; // move on to the next AQL packet
        queue_info->read_index_low = read_iter;
    }
}
