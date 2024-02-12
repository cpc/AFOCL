
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"

const int VEC_WIDTH_BYTES = (VEC_WIDTH_BITS / 8);

const int VEC_WIDTH_I = (VEC_WIDTH_BYTES / sizeof(signed short));
const int VEC_WIDTH_O = (VEC_WIDTH_BYTES / sizeof(unsigned char));


typedef hls::vector< signed short, VEC_WIDTH_I > packet_type_t_Vec_i;
typedef hls::vector< unsigned char, VEC_WIDTH_O > packet_type_t_Vec_o;

typedef hls::axis<packet_type_t_Vec_i, 0, 0, 5> t_Vec_i;
typedef hls::axis<packet_type_t_Vec_o, 0, 0, 5> t_Vec_o;


void phase_ctrl_ip(hls::stream<t_Vec_i> &in0,
			hls::stream<t_Vec_i> &in1,
            hls::stream<t_Vec_o> &out0,
            uint32_t width,
            uint32_t height,
            ap_uint<5> tdest);
