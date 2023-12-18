// gaussian3x3_ctrl_ip.cpp, a simple ip that can add two unsigned integers
// from axi stream ports and write the result to a stream port.
// uses the axilite port for control.


#include "gaussian3x3_ctrl_ip.h"


void gaussian3x3_ctrl_ip (hls::stream<packet_i > &in0,
                 hls::stream<packet_i > &out0,
                 uint32_t width,
                 uint32_t height,
                 ap_uint<5> tdest)
{
// configure ports
#pragma HLS INTERFACE axis port=in0
#pragma HLS INTERFACE axis port=out0
#pragma hls interface ap_ctrl_hs port=return

    uint32_t width_in_vectors = width / VEC_WIDTH;
    uint8_t line1[LINE_BUF_SIZE];
    uint8_t line2[LINE_BUF_SIZE];
    uint8_t line3[LINE_BUF_SIZE];
#pragma HLS array_partition variable=line1 type=cyclic factor=VEC_WIDTH
#pragma HLS array_partition variable=line2 type=cyclic factor=VEC_WIDTH
#pragma HLS array_partition variable=line3 type=cyclic factor=VEC_WIDTH
    for (int y = 0; y < height; y++) {
#pragma HLS pipeline II=1 style=flp
        if ( y == 0) {
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                t_Vec data1 = in0.read ().data;
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line1[i * VEC_WIDTH + k + 1] = data1[k];
                    line2[i * VEC_WIDTH + k + 1] = data1[k];
                }
            }
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                t_Vec data2 = in0.read ().data;
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line3[i * VEC_WIDTH + k + 1] = data2[k];
                }
            }
        } else if ( y == (height - 1)) {
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line1[i * VEC_WIDTH + k + 1] = line2[i * VEC_WIDTH + k + 1];
                }
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line2[i * VEC_WIDTH + k + 1] = line3[i * VEC_WIDTH + k + 1];
                }
            }
        } else {
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line1[i * VEC_WIDTH + k + 1] = line2[i * VEC_WIDTH + k + 1];
                }
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line2[i * VEC_WIDTH + k + 1] = line3[i * VEC_WIDTH + k + 1];
                }
                t_Vec data1 = in0.read ().data;
                for (int k = 0; k < VEC_WIDTH; k++) {
                    line3[i * VEC_WIDTH + k + 1] = data1[k];
                }
            }
        }
        line1[0] = line1[1];
        line1[width + 1] = line1[width];
        line2[0] = line2[1];
        line2[width + 1] = line2[width];
        line3[0] = line3[1];
        line3[width + 1] = line3[width];
        for (int i = 0; i < width; i += VEC_WIDTH) {
#pragma HLS pipeline II=1 style=flp
            t_Vec data_x;
            for (int k = 0; k < VEC_WIDTH; k++) {
                unsigned short blur_acc =
                    1 * line1[i + k + 1 - 1] +
                    2 * line1[i + k + 1 + 0] +
                    1 * line1[i + k + 1 + 1] +
                    2 * line2[i + k + 1 - 1] +
                    4 * line2[i + k + 1 + 0] +
                    2 * line2[i + k + 1 + 1] +
                    1 * line3[i + k + 1 - 1] +
                    2 * line3[i + k + 1 + 0] +
                    1 * line3[i + k + 1 + 1];
                data_x[k] = (unsigned char)(blur_acc >> 4);
            }
            packet_i x_packet;
            x_packet.dest = tdest;
            x_packet.data = data_x;
            out0.write (x_packet);
        }
    }
}
