// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.

// Reduce word length of the unsigned integer input, clipping values
// higher/lower than the output word length can fit.
module clip_unsigned #(
    parameter int INW  = 0,  // input word length
    parameter int OUTW = 0   // output word length
) (
    input  [ INW-1:0] in,       // input
    output [OUTW-1:0] out,      // clipped output
    output            clipping  // clipping indicator (active-high)
);

  // selects the bits that are to be checked for clipping
  wire [INW-2:OUTW-1] msbs = in[INW-1:OUTW];

  // check if there was a positive clip
  assign clipping = |(msbs);

  // full scale positive value
  wire [OUTW-1:0] maxval = OUTW'('1);

  // clipped value
  assign out = clipping ? maxval : in[OUTW-1:0];

endmodule
