
#include "phase_ctrl_ip.h"

#include <hls_math.h>

#define PI 3.14159265358979323846

void phase_ctrl_ip(hls::stream<t_Vec_i> &in0,
			hls::stream<t_Vec_i> &in1,
            hls::stream<t_Vec_o> &out0,
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
        for (int x = 0; x < width; x += VEC_WIDTH_O) {
            packet_type_t_Vec_o dataPhase;
            packet_type_t_Vec_i dataX1 = in0.read().data;
            packet_type_t_Vec_i dataY1 = in1.read().data;
            for (int i = 0; i < VEC_WIDTH_I; i++) {
                // range = [-pi, pi]
/*                ap_fixed<32, 3> atan2out;
                ap_fixed<32, 16> atan2iny = dataY1[i];
                ap_fixed<32, 16> atan2inx = dataX1[i];
                atan2out = hls::atan2(atan2iny, atan2inx);
                float angle = atan2out;
*/
                float angle = hls::atan2((double)dataY1[i], (double)dataX1[i]);
                // Shift range -127.5:127.5
                angle *= (float)(127.5 / PI);
                // Shift range 0.5:255.5
                angle += (127.5 + 0.5);
                unsigned char val = (unsigned char)angle;
                dataPhase[i] = val;
            }
            packet_type_t_Vec_i dataX2 = in0.read().data;
            packet_type_t_Vec_i dataY2 = in1.read().data;
            for (int i = 0; i < VEC_WIDTH_I; i++) {
                // range = [-pi, pi]
                /*ap_fixed<32, 3> atan2out;
                ap_fixed<32, 16> atan2iny = dataY1[i];
                ap_fixed<32, 16> atan2inx = dataX1[i];
                atan2out = hls::atan2(atan2iny, atan2inx);
                float angle = atan2out;*/
                float angle = hls::atan2((double)dataY2[i], (double)dataX2[i]);
                // Shift range -127.5:127.5
                angle *= (float)(127.5 / PI);
                // Shift range 0:255
                // and then to 0.5:255.5 since we will cast this to int which then rounds it down
                angle += (127.5 + 0.5);
                unsigned char val = (unsigned char)angle;
                dataPhase[VEC_WIDTH_I + i] = val;
            }
            t_Vec_o output_packet;
            output_packet.dest = tdest;
            output_packet.data = dataPhase;
            out0.write(output_packet);
        }
    }
}
