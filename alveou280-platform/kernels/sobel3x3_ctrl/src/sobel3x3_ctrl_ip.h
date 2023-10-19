
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"
#include <stdio.h>

#define MAX_LINE_WIDTH (4480)
#define LINE_BUF_SIZE (MAX_LINE_WIDTH + 2)

#define VEC_WIDTH (64)
#define VEC_WIDTH_O (VEC_WIDTH / 2)

typedef hls::vector< unsigned char, VEC_WIDTH > t_Vec;
typedef hls::vector< unsigned short, VEC_WIDTH_O > t_Vec_o;

typedef hls::axis<t_Vec, 0, 0, 5> packet_i;
typedef hls::axis<t_Vec_o, 0, 0, 5> packet_o;

void sobel3x3_ctrl_ip(hls::stream<packet_i> &in0,
			hls::stream<packet_o> &out0,
			hls::stream<packet_o> &out1,
            uint32_t width,
            uint32_t height,
            ap_uint<5> tdest_x,
            ap_uint<5> tdest_y);
