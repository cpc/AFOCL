
#include "magnitude_ip.h"

#include "hls_math.h"

void magnitude_ip(hls::stream<t_Vec_i> &in0,
			hls::stream<t_Vec_i> &in1,
            hls::stream<t_Vec_o> &out0)
{
    // configure ports
#pragma HLS INTERFACE axis port=in0
#pragma HLS INTERFACE axis port=in1
#pragma HLS INTERFACE axis port=out0
#pragma hls interface ap_ctrl_none port=return

    //for (int y = 0; y < height; y++) {
    //    for (int x = 0; x < width; x += VEC_WIDTH) {
            t_Vec_o dataMagnitude;
            t_Vec_i dataX1 = in0.read();
            t_Vec_i dataY1 = in1.read();
            for (int i = 0; i < VEC_WIDTH; i++) {
                unsigned short val = hls::abs(dataX1[i]) + hls::abs(dataY1[i]);
                dataMagnitude[i] = val;
            }
            out0.write(dataMagnitude);
    //    }
    //}
}
