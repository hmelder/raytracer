// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

// Implements (1.0 - norm) * a + norm * b
module sfp_vec_lerp #(
    parameter int N = 3,
    parameter CLIP = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
    sfp_if.in a[N],
    sfp_if.in b[N],
    sfp_if.in norm[N],
    sfp_if.out out[N]
);
  sfp_if #(
      .IW(out.IW),
      .QW(out.QW)
  )
      left_side[N] (), right_side[N] ();

  // Compute -norm + 1.0
  sfp_if #(
      .IW(norm.IW),
      .QW(norm.QW)
  )
      norm_neg[N] (), constant_one (), one_minus_norm[N] ();

  assign constant_one.val = 1'h1 << constant_one.QW;

  sfp_vec_neg #(
      .N(N)
  ) neg (
      .in (norm),
      .out(norm_neg)
  );

  sfp_vec_add_s #(
      .N(N),
      .CLIP(CLIP)
  ) add_left (
      .a  (norm_neg),
      .s  (constant_one),
      .out(one_minus_norm)
  );

  // Compute one_minus_norm * a

  sfp_vec_mul #(
      .N(N),
      .CLIP(CLIP)
  ) left_mul (
      .a  (one_minus_norm),
      .b  (a),
      .out(left_side)
  );

  sfp_vec_mul #(
      .N(N),
      .CLIP(CLIP)
  ) right_mul (
      .a  (norm),
      .b  (b),
      .out(right_side)
  );

  sfp_vec_add #(
      .N(N),
      .CLIP(CLIP)
  ) acc (
      .a  (left_side),
      .b  (right_side),
      .out(out)
  );

endmodule
