
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"
#include <stdio.h>

//#define ADD_I32_DATA_SIZE_BITS 1024
//#define packet_type ap_axis<ADD_I32_DATA_SIZE_BITS,0,0,0>

//#define ADD_I32_DATA_SIZE  (ADD_I32_DATA_SIZE_BITS /8)

typedef hls::vector< unsigned, 16 > t_uint32Vec;

//void add_i32_ip(hls::stream< packet_in_type> &A,
////			hls::stream< ap_axis<32,2,5,6>> &B,
//			hls::stream< packet_out_type> &C);

void add_32x32_ip(hls::stream<t_uint32Vec> &A,
			hls::stream<t_uint32Vec> &B,
			hls::stream<t_uint32Vec> &C);
