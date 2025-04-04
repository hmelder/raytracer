// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.
// Copyright (c) 2025 Hugo Melder

`include "macros.svh"

// Subtraction of sfp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)
module sfp_sub_full (
    sfp_if.in  in1,
    sfp_if.in  in2,  // input sfp signal
    sfp_if.out out   // output sfp signal (= in1 - in2)
);

  localparam iw_aligned = `max(in1.IW, in2.IW);
  localparam qw_aligned = `max(in1.IW, in2.QW);

  if ((out.IW != iw_aligned + 1) || (out.QW != qw_aligned))
    $error(
        {
          "%m: Incorrect output word length for a full-width subtract!",
          "Make sure out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)!"
        }
    );

  // resize in1 and in2 to have the same word length with an aligned binary point

  sfp_if #(iw_aligned, qw_aligned) in1_aligned (), in2_aligned ();
  sfp_resize #(
      .clip(0)
  ) u_resize_in1 (
      .in(in1),
      .out(in1_aligned),
      .clipping()
  );
  sfp_resize #(
      .clip(0)
  ) u_resize_in2 (
      .in(in2),
      .out(in2_aligned),
      .clipping()
  );

  assign out.val = (in1_aligned.val) - (in2_aligned.val);

endmodule
