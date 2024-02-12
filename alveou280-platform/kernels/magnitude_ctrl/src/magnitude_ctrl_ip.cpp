
#include "magnitude_ctrl_ip.h"

#include "hls_math.h"

void magnitude_ctrl_ip(hls::stream<packet_i> &in0,
			hls::stream<packet_i> &in1,
            hls::stream<packet_o> &out0,
            uint32_t width,
            uint32_t height,
            ap_uint<5> tdest)
{
    // configure ports
#pragma HLS INTERFACE axis port=in0
#pragma HLS INTERFACE axis port=in1
#pragma HLS INTERFACE axis port=out0
#pragma hls interface ap_ctrl_hs port=return

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x += VEC_WIDTH) {
#pragma HLS pipeline II=1 style=flp
            t_Vec_o dataMagnitude;
            t_Vec_i dataX1 = in0.read().data;
            t_Vec_i dataY1 = in1.read().data;
            for (int i = 0; i < VEC_WIDTH; i++) {
#pragma HLS unroll
                unsigned short val = hls::abs(dataX1[i]) + hls::abs(dataY1[i]);
                dataMagnitude[i] = val;
            }
            packet_o output_packet;
            output_packet.dest = tdest;
            output_packet.data = dataMagnitude;
            out0.write(output_packet);
        }
    }
}
