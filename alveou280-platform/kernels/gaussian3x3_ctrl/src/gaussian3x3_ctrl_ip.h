
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"
#include <stdio.h>

//#define ADD_I32_DATA_SIZE_BITS 1024
//#define packet_type ap_axis<ADD_I32_DATA_SIZE_BITS,0,0,0>

const int MAX_LINE_WIDTH = (4480);
const int LINE_BUF_SIZE = (MAX_LINE_WIDTH + 2);

const int VEC_WIDTH = VEC_WIDTH_BITS / 8;

typedef hls::vector< unsigned char, VEC_WIDTH > t_Vec;
typedef hls::axis<t_Vec, 0, 0, 5> packet_i;

//void add_i32_ip(hls::stream< packet_in_type> &A,
////			hls::stream< ap_axis<32,2,5,6>> &B,
//			hls::stream< packet_out_type> &C);

void gaussian3x3_ctrl_ip(hls::stream<packet_i> &in0,
			hls::stream<packet_i> &out0,
            uint32_t width,
            uint32_t height,
            ap_uint<5> tdest);
