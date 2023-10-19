
//#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"

#define VEC_WIDTH_BITS 512
#define VEC_WIDTH_BYTES (VEC_WIDTH_BITS / 8)

#define VEC_WIDTH_I (VEC_WIDTH_BYTES / sizeof(signed short))
#define VEC_WIDTH_O (VEC_WIDTH_BYTES / sizeof(unsigned char))

typedef hls::vector< signed short, VEC_WIDTH_I > t_Vec_i;
typedef hls::vector< unsigned char, VEC_WIDTH_O > t_Vec_o;

void phase_ip(hls::stream<t_Vec_i> &in0,
			hls::stream<t_Vec_i> &in1,
            hls::stream<t_Vec_o> &out0);
