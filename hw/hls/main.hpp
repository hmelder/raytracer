#pragma once

#include <ap_axi_sdata.h>
#include <ap_fixed.h>
#include <hls_stream.h>

#define NUMBER_OF_INPUT_WORDS 4
#define NUMBER_OF_OUTPUT_WORDS 4

#define FIXED_2_RAW(fixed, raw) raw.range() = fixed.range();
#define RAW_2_FIXED(raw, fixed) fixed.range() = raw.range();
#define RAW_2_FIXED_V(raw, fixed)                                              \
  {                                                                            \
    for (int i = 0; i < 3; i++) {                                              \
      ap_uint<32> v = raw[i];                                                  \
      RAW_2_FIXED(v, fixed[i])                                                 \
    }                                                                          \
  }

typedef ap_fixed<32, 16> sfp;
typedef ap_uint<32> u32;

typedef hls::axis_data<u32, AXIS_ENABLE_LAST> pkt;

void myip_v1_0_HLS(hls::stream<pkt> &S_AXIS, hls::stream<pkt> &M_AXIS);