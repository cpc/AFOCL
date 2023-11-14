
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
//#pragma HLS pipeline off
//#pragma HLS dataflow
#pragma HLS pipeline II=1 style=flp
    static bool process_first_vector_half = true;
    static t_Vec_o dataPhase;
    //#pragma HLS array_partition variable=dataPhase complete

    t_Vec_i dataX1 = in0.read();
    t_Vec_i dataY1 = in1.read();
    uint8_t outputOffset;
    if (process_first_vector_half) {
        outputOffset = 0;
    } else {
        outputOffset = VEC_WIDTH_I;
    }
    for (int i = 0; i < VEC_WIDTH_I; i++) {
#pragma HLS unroll
        // range = [-pi, pi]
        //float angle = hls::atan2((float)dataY1[i], (float)dataX1[i]);
        //float angle = hls::atan2((float)dataY1[i], (float)dataX1[i]);
        //float angle = hls::atan2((double)dataY1[i], (double)dataX1[i]);
        ap_fixed<22, 3> atan2out;
        ap_fixed<22, 16> atan2iny = dataY1[i];
        ap_fixed<22, 16> atan2inx = dataX1[i];
        atan2out = hls::atan2(atan2iny, atan2inx);
        float angle = atan2out;
        // Shift range -127.5:127.5
        angle *= (float)(127.5 / PI);

        // Shift range 0:255
        angle += (127.5 + 0.5);
        unsigned char val = (unsigned char)angle;
        dataPhase[outputOffset + i] = val;
    }
    if (!process_first_vector_half) {
        out0.write(dataPhase);
        process_first_vector_half = true;
    } else {
        process_first_vector_half = false;
    }
}
