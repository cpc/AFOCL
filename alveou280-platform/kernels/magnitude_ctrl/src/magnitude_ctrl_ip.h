
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"

#define VEC_WIDTH_BITS 512
#define VEC_WIDTH_BYTES (512 / 8)
#define VEC_WIDTH (VEC_WIDTH_BYTES / sizeof(unsigned short))

typedef hls::vector< unsigned short, VEC_WIDTH > t_Vec_o;
typedef hls::vector< signed short, VEC_WIDTH > t_Vec_i;

typedef hls::axis<t_Vec_i, 0, 0, 5> packet_i;
typedef hls::axis<t_Vec_o, 0, 0, 5> packet_o;


void magnitude_ctrl_ip(hls::stream<packet_i> &in0,
			hls::stream<packet_i> &in1,
            hls::stream<packet_o> &out0,
            uint32_t width,
            uint32_t height,
            ap_uint<5> tdest);
