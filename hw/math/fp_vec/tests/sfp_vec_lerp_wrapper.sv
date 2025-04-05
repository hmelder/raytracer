// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

module sfp_vec_lerp_wrapper (
    input logic [31:0] a[3],
    input logic [31:0] b[3],
    input logic [31:0] norm[3],
    output logic [31:0] out[3]
);

  sfp_if #(
      .IW(16),
      .QW(16)
  )
      a_fp[3] (), b_fp[3] (), norm_fp[3] (), out_fp[3] ();

  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_sub
      assign a_fp[i].val = a[i];
      assign b_fp[i].val = b[i];
      assign norm_fp[i].val = norm[i];
      assign out[i] = out_fp[i].val;
    end
  endgenerate

  sfp_vec_lerp lerp (
      .a(a_fp),
      .b(b_fp),
      .norm(norm_fp),
      .out(out_fp)
  );

endmodule
