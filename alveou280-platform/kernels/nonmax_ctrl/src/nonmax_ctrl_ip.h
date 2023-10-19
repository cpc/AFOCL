
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"

#define MAX_LINE_WIDTH (4480)
#define LINE_BUF_SIZE (MAX_LINE_WIDTH + 2)

#define VEC_WIDTH_BITS 512
#define VEC_WIDTH_BYTES (512 / 8)

#define VEC_WIDTH_I (VEC_WIDTH_BYTES / sizeof(unsigned short))
#define VEC_WIDTH_O (VEC_WIDTH_BYTES / sizeof(unsigned char))

typedef hls::vector< unsigned short, VEC_WIDTH_I > t_Vec_i;
typedef hls::vector< unsigned char, VEC_WIDTH_O > t_Vec_o;

typedef hls::axis<t_Vec_i, 0, 0, 5> packet_i;
typedef hls::axis<t_Vec_o, 0, 0, 5> packet_o;

void nonmax_ctrl_ip(hls::stream<packet_i> &in0,
            hls::stream<packet_o> &in1,
            uint16_t threshold_lower,
            uint16_t threshold_upper,
            uint32_t width,
            uint32_t height,
            ap_uint<5> tdest,
			hls::stream<packet_o> &out0);
