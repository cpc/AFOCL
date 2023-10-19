
#include "ap_axi_sdata.h"
#include "hls_stream.h"
#include "hls_vector.h"
#include <stdio.h>

typedef hls::vector< unsigned short, 32 > t_uint16Vec;

void add_16x64_ip(hls::stream<t_uint16Vec> &A,
			hls::stream<t_uint16Vec> &B,
			hls::stream<t_uint16Vec> &C);
