// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

// Top-level module cannot have interfaces as parameter. We pack fp values
// inside logic vectors.
module sfp_vec_add_s_wrapper (
    input  logic [31:0] a[3],
    input  logic [31:0] s,
    output logic [31:0] o[3]
);

  sfp_if #(
      .IW(16),
      .QW(16)
  ) a_fp[3] ();
  sfp_if #(
      .IW(16),
      .QW(16)
  ) s_fp ();
  sfp_if #(
      .IW(16),
      .QW(16)
  ) out_fp[3] ();

  assign a_fp[0].val = a[0];
  assign a_fp[1].val = a[1];
  assign a_fp[2].val = a[2];

  assign s_fp.val = s;

  assign o[0] = out_fp[0].val;
  assign o[1] = out_fp[1].val;
  assign o[2] = out_fp[2].val;

  sfp_vec_add_s dot (
      .a  (a_fp),
      .s  (s_fp),
      .out(out_fp)
  );

endmodule
