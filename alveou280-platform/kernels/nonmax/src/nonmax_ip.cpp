// nonmax_ip.cpp, a simple ip that can add two unsigned integers
// from axi stream ports and write the result to a stream port.
// uses the axilite port for control.


#include "nonmax_ip.h"


void nonmax_ip(hls::stream<t_Vec_i> &in0,
            hls::stream<t_Vec_o> &in1,
            uint16_t threshold_lower,
            uint16_t threshold_upper,
            uint32_t width,
            uint32_t height,
			hls::stream<t_Vec_o> &out0)
{
// configure ports
#pragma HLS INTERFACE axis port=in0
#pragma HLS INTERFACE axis port=in1
#pragma HLS INTERFACE axis port=out0
#pragma hls interface ap_ctrl_hs port=return

    uint32_t width_in_vectors = width / VEC_WIDTH_I;
    uint32_t width_in_output_vectors = width / VEC_WIDTH_O;
    uint16_t line_mag1[LINE_BUF_SIZE];
    uint16_t line_mag2[LINE_BUF_SIZE];
    uint16_t line_mag3[LINE_BUF_SIZE];
#pragma HLS array_partition variable=line_mag1 type=cyclic factor=VEC_WIDTH_O
#pragma HLS array_partition variable=line_mag2 type=cyclic factor=VEC_WIDTH_O
#pragma HLS array_partition variable=line_mag3 type=cyclic factor=VEC_WIDTH_O
    for (int y = 0; y < height; y++) {
#pragma HLS pipeline II=1 style=flp
        if ( y == 0) {
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                t_Vec_i data1 = in0.read ();
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag1[i * VEC_WIDTH_I + k + 1] = data1[k];
                    line_mag2[i * VEC_WIDTH_I + k + 1] = data1[k];
                }
            }
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                t_Vec_i data2 = in0.read ();
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag3[i * VEC_WIDTH_I + k + 1] = data2[k];
                }
            }
        } else if ( y == (height - 1)) {
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag1[i * VEC_WIDTH_I + k + 1] = line_mag2[i * VEC_WIDTH_I + k + 1];
                }
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag2[i * VEC_WIDTH_I + k + 1] = line_mag3[i * VEC_WIDTH_I + k + 1];
                }
            }
        } else {
            for (int i = 0; i < width_in_vectors; i++) {
#pragma HLS pipeline II=1 style=flp
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag1[i * VEC_WIDTH_I + k + 1] = line_mag2[i * VEC_WIDTH_I + k + 1];
                }
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag2[i * VEC_WIDTH_I + k + 1] = line_mag3[i * VEC_WIDTH_I + k + 1];
                }
                t_Vec_i data1 = in0.read ();
                for (int k = 0; k < VEC_WIDTH_I; k++) {
                    line_mag3[i * VEC_WIDTH_I + k + 1] = data1[k];
                }
            }
        }
        line_mag1[0] = line_mag1[1];
        line_mag1[width + 1] = line_mag1[width];
        line_mag2[0] = line_mag2[1];
        line_mag2[width + 1] = line_mag2[width];
        line_mag3[0] = line_mag3[1];
        line_mag3[width + 1] = line_mag3[width];
        for (int i = 0; i < width; i += VEC_WIDTH_O) {
#pragma HLS pipeline II=1 style=flp
            t_Vec_o output_data;
            t_Vec_o phase_data = in1.read();
            for (int k = 0; k < VEC_WIDTH_O; k++) {
                uint8_t sobel_angle = phase_data[k];
                if (sobel_angle > 127) {
                    sobel_angle -= 128;
                }
                int sobel_orientation = 0;
                if (sobel_angle < 16 || sobel_angle >= (7 * 16)) {
                    sobel_orientation = 2;
                } else if (sobel_angle >= 16 && sobel_angle < 16 * 3) {
                    sobel_orientation = 1;
                } else if (sobel_angle >= 16 * 3 && sobel_angle < 16 * 5) {
                    sobel_orientation = 0;
                } else if (sobel_angle > 16 * 5 && sobel_angle <= 16 * 7) {
                    sobel_orientation = 3;
                }
                uint16_t sobel_magnitude = line_mag2[i + k + 1];
                /* Non-maximum suppression
                 * Pick out the two neighbours that are perpendicular to the
                 * current edge pixel */
                uint16_t neighbour_max = 0;
                uint16_t neighbour_max2 = 0;
                switch (sobel_orientation) {
                    case 0:
                        neighbour_max = line_mag1[i + k + 1];
                        neighbour_max2 = line_mag3[i + k + 1];
                        break;
                    case 1:
                        neighbour_max = line_mag1[i + k + 1 - 1];
                        neighbour_max2 = line_mag3[i + k + 1 + 1];
                        break;
                    case 2:
                        neighbour_max = line_mag2[i + k + 1 -1];
                        neighbour_max2 = line_mag2[i + k + 1 +1];
                        break;
                    case 3:
                    default:
                        neighbour_max = line_mag1[i + k + 1 + 1];
                        neighbour_max2 = line_mag3[i + k + 1 -1];
                        break;
                }

                if ((sobel_magnitude < neighbour_max) ||
                        (sobel_magnitude < neighbour_max2)) {
                    sobel_magnitude = 0;
                }

                /* Double thresholding */
                // Marks YES pixels with 255, NO pixels with 0 and MAYBE pixels
                // with 127
                uint8_t t = 127;
                if (sobel_magnitude > threshold_upper) t = 255;
                if (sobel_magnitude <= threshold_lower) t = 0;
                output_data[k] = t;
            }
            out0.write(output_data);
        }
    }
}
