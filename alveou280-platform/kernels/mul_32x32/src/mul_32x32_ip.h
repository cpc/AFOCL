
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"
#include <stdio.h>

typedef hls::vector< unsigned, 16 > t_uint32Vec;

void mul_32x32_ip(hls::stream<t_uint32Vec> &A,
			hls::stream<t_uint32Vec> &B,
			hls::stream<t_uint32Vec> &C);
