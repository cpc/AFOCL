
#include "hls_stream.h"
#include "hls_vector.h"

const int MAX_LINE_WIDTH = (4480);
const int LINE_BUF_SIZE = (MAX_LINE_WIDTH + 2);

const int VEC_WIDTH_BYTES = (VEC_WIDTH_BITS / 8);

const int VEC_WIDTH_I = (VEC_WIDTH_BYTES / sizeof(unsigned short));
const int VEC_WIDTH_O = (VEC_WIDTH_BYTES / sizeof(unsigned char));

typedef hls::vector< unsigned short, VEC_WIDTH_I > t_Vec_i;
typedef hls::vector< unsigned char, VEC_WIDTH_O > t_Vec_o;

void nonmax_ip(hls::stream<t_Vec_i> &in0,
            hls::stream<t_Vec_o> &in1,
            uint16_t threshold_lower,
            uint16_t threshold_upper,
            uint32_t width,
            uint32_t height,
			hls::stream<t_Vec_o> &out0);
