
//#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"

const int VEC_WIDTH_BYTES = (VEC_WIDTH_BITS / 8);
const int VEC_WIDTH = (VEC_WIDTH_BYTES / sizeof(unsigned short));

typedef hls::vector< unsigned short, VEC_WIDTH > t_Vec_o;
typedef hls::vector< signed short, VEC_WIDTH > t_Vec_i;

void magnitude_ip(hls::stream<t_Vec_i> &in0,
			hls::stream<t_Vec_i> &in1,
            hls::stream<t_Vec_o> &out0);
