// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

module sfp_vec_neg #(
    parameter int N = 3
) (
    sfp_if.in  in [N],
    sfp_if.out out[N]
);

  genvar i;
  generate
    for (i = 0; i < N; i++) begin : gen_neg
      assign out[i].val = -in[i].val;
    end
  endgenerate

endmodule
