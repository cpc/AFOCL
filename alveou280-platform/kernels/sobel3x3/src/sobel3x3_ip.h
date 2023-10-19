
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"
#include <stdio.h>

//#define ADD_I32_DATA_SIZE_BITS 1024
//#define packet_type ap_axis<ADD_I32_DATA_SIZE_BITS,0,0,0>

#define MAX_LINE_WIDTH (4480)
#define LINE_BUF_SIZE (MAX_LINE_WIDTH + 2)

#define VEC_WIDTH (64)
#define VEC_WIDTH_O (VEC_WIDTH / 2)

typedef hls::vector< unsigned char, VEC_WIDTH > t_Vec;
typedef hls::vector< unsigned short, VEC_WIDTH_O > t_Vec_o;

//void add_i32_ip(hls::stream< packet_in_type> &A,
////			hls::stream< ap_axis<32,2,5,6>> &B,
//			hls::stream< packet_out_type> &C);

void sobel3x3_ip(hls::stream<t_Vec> &in0,
			hls::stream<t_Vec_o> &out0,
			hls::stream<t_Vec_o> &out1,
            uint32_t width,
            uint32_t height);
