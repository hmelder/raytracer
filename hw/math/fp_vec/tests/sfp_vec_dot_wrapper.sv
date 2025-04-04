// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

// Top-level module cannot have interfaces as parameter. We pack fp values
// inside logic vectors.
module sfp_vec_dot_wrapper (
    input logic [31:0] a[3],
    input logic [31:0] b[3],
    output logic [31:0] out,
    output clipping
);

  sfp_if #(
      .IW(16),
      .QW(16)
  )
      a_fp[3] (), b_fp[3] (), out_fp ();

  assign a_fp[0].val = a[0];
  assign a_fp[1].val = a[1];
  assign a_fp[2].val = a[2];

  assign b_fp[0].val = b[0];
  assign b_fp[1].val = b[1];
  assign b_fp[2].val = b[2];

  assign out = out_fp.val;

  sfp_vec3_dot dot (
      .a(a_fp),
      .b(b_fp),
      .out(out_fp),
      .clipping(clipping)
  );

endmodule
