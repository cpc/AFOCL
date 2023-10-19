
#include "phase_ip.h"

#include <hls_math.h>

#define PI 3.14159265358979323846

void phase_ip(hls::stream<t_Vec_i> &in0,
			hls::stream<t_Vec_i> &in1,
            hls::stream<t_Vec_o> &out0)
{
// configure ports
#pragma HLS INTERFACE axis port=in0
#pragma HLS INTERFACE axis port=in1
#pragma HLS INTERFACE axis port=out0
#pragma hls interface ap_ctrl_none port=return
//    for (int y = 0; y < height; y++) {
//        for (int x = 0; x < width; x += VEC_WIDTH_O) {
            t_Vec_o dataPhase;
            t_Vec_i dataX1 = in0.read();
            t_Vec_i dataY1 = in1.read();
            for (int i = 0; i < VEC_WIDTH_I; i++) {
                // range = [-pi, pi]
                //float angle = hls::atan2((float)dataY1[i], (float)dataX1[i]);
                float angle = hls::atan2((float)dataY1[i], (float)dataX1[i]);

                // Shift range -127.5:127.5
                angle *= (float)(127.5 / PI);

                // Shift range 0:255
                angle += (127.5 + 0.5);
                unsigned char val = (unsigned char)angle;
                //unsigned char val = hls::lround(angle);
                dataPhase[i] = val;
            }
            t_Vec_i dataX2 = in0.read();
            t_Vec_i dataY2 = in1.read();
            for (int i = 0; i < VEC_WIDTH_I; i++) {
                // range = [-pi, pi]
                float angle = hls::atan2((float)dataY2[i], (float)dataX2[i]);

                // Shift range -127.5:127.5
                angle *= (float)(127.5 / PI);

                // Shift range 0:255
                // and then to 0.5:255.5 since we will cast this to int which then rounds it down
                angle += (127.5 + 0.5);
                unsigned char val = (unsigned char)angle;
                //angle += 127.5;
                //unsigned char val = hls::lround(angle);

                dataPhase[VEC_WIDTH_I + i] = val;
            }
            out0.write(dataPhase);
//        }
//    }
}
