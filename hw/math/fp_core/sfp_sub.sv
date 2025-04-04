// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.
// Copyright (c) 2025 Hugo Melder

`include "macros.svh"

// Subtraction of sfp signals followed by resizing (equivalant to sfp_sub_full + sfp_resize_ind)
module sfp_sub #(
    parameter CLIP = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
           sfp_if.in  in1,
    in2,  // input sfp signal
           sfp_if.out out,      // output sfp signal (= in1 - in2)
    output            clipping  // clipping indicator (active-high)
);
  localparam iw_sum = `max(in1.IW, in2.IW) + 1;
  localparam qw_sum = `max(in1.QW, in2.QW);

  sfp_if #(
      .IW(iw_sum),
      .QW(qw_sum)
  ) sub ();
  sfp_sub_full u_sub (
      .in1(in1),
      .in2(in2),
      .out(sub)
  );
  sfp_resize #(
      .clip(CLIP)
  ) u_resize (
      .in(sub),
      .out(out),
      .clipping(clipping)
  );

endmodule
