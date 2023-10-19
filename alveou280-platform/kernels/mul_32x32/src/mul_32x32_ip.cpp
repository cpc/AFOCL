// mul_32x32_ip.cpp, a simple ip that can multiply two unsigned integers
// from axi stream ports and write the result to a stream port.
// uses the axilite port for control.


#include "mul_32x32_ip.h"

void mul_32x32_ip (hls::stream<t_uint32Vec > &A,
                 hls::stream<t_uint32Vec > &B,
                 hls::stream<t_uint32Vec > &C)
{
// configure ports
#pragma HLS INTERFACE axis port=A
#pragma HLS INTERFACE axis port=B
#pragma HLS INTERFACE axis port=C
#pragma hls interface ap_ctrl_none port=return

  while (1)
    {
      if (!A.empty () && !B.empty ())
        {
          t_uint32Vec dataA = A.read ();
          t_uint32Vec dataB = B.read ();
          //printf ("read from A: %d\n", dataA.data.to_uint ());
          //printf ("read from B: %d\n", dataB.data.to_uint ());
          //dataA.data = dataA.data.to_uint () + dataB.data.to_uint ();
          //printf ("written to C: %d\n", dataA.data.to_uint ());
          t_uint32Vec dataC = dataA * dataB;
          C.write (dataC);

          //if (dataA.last)
          //  {
          //    printf ("received last flag\n");
          //    break;
          //  }

        }

    }
}
