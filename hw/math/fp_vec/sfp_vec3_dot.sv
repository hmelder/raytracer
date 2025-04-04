// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

module sfp_vec3_dot #(
    parameter CLIP = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
    sfp_if.in a[3],
    sfp_if.in b[3],
    sfp_if.out out,
    output clipping
);

  // Product must have the correct iw/qw for a full width operation
  sfp_if #(
      .IW(a.IW + b.IW),
      .QW(a.QW + b.QW)
  ) prod_fp[3] ();

  // Multiply element-wise
  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_mul
      sfp_mul_full mul_i (
          .in1(a[i]),
          .in2(b[i]),
          .out(prod_fp[i])
      );
    end
  endgenerate

  // Accumulate elements of prod_fp
  sfp_if #(
      .IW(a.IW + b.IW),
      .QW(a.QW + b.QW)
  ) acc_fp ();

  assign acc_fp.val = prod_fp[0].val + prod_fp[1].val + prod_fp[2].val;

  // Resize
  sfp_resize #(
      .clip(CLIP)
  ) u_resize (
      .in(acc_fp),
      .out(out),
      .clipping(clipping)
  );

endmodule
