// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

module sfp_vec_mul_s #(
    parameter int N = 3,
    parameter CLIP = 1  // (if reducing iw) 0 = wrap, 1 = clip
) (
    sfp_if.in  a  [N],
    sfp_if.in  s,
    sfp_if.out out[N]
);

  // FIXME: Accumulate clipping status flags
  genvar i;
  generate
    for (i = 0; i < N; i++) begin : gen_add
      sfp_mul #(
          .CLIP(CLIP)
      ) add_i (
          .x(a[i]),
          .y(s),
          .out(out[i]),
          .clipping()
      );
    end
  endgenerate

endmodule
