// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

// return vec3(u.e[1] * v.e[2] - u.e[2] * v.e[1],
//             u.e[2] * v.e[0] - u.e[0] * v.e[2],
//             u.e[0] * v.e[1] - u.e[1] * v.e[0]);

module sfp_vec3_cross #(
    parameter CLIP = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
    sfp_if.in  a  [3],
    sfp_if.in  b  [3],
    sfp_if.out out[3]
);

  // Product must have the correct iw/qw for a full width operation
  sfp_if #(
      .IW(a.IW + b.IW),
      .QW(a.QW + b.QW)
  )
      left_prod_fp[3] (), right_prod_fp[3] ();

  // Multiply left-side
  sfp_mul_full mul_l_x (
      .in1(a[1]),
      .in2(b[2]),
      .out(left_prod_fp[0])
  );
  sfp_mul_full mul_l_y (
      .in1(a[2]),
      .in2(b[0]),
      .out(left_prod_fp[1])
  );
  sfp_mul_full mul_l_z (
      .in1(a[0]),
      .in2(b[1]),
      .out(left_prod_fp[2])
  );

  // Multiply right-side
  sfp_mul_full mul_r_x (
      .in1(a[2]),
      .in2(b[1]),
      .out(right_prod_fp[0])
  );
  sfp_mul_full mul_r_y (
      .in1(a[0]),
      .in2(b[2]),
      .out(right_prod_fp[1])
  );
  sfp_mul_full mul_r_z (
      .in1(a[1]),
      .in2(b[0]),
      .out(right_prod_fp[2])
  );

  // Accumulate and Resize
  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_sub
      sfp_sub #(
          .CLIP(CLIP)
      ) sub_i (
          .in1(left_prod_fp[i]),
          .in2(right_prod_fp[i]),
          .out(out[i]),
          .clipping()
      );
    end
  endgenerate

endmodule
