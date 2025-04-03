// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

module clipping_test #(
) (
    input [31:0] in,
    output [15:0] out,
    output clipping
);

  clip_unsigned #(
      .INW (32),
      .OUTW(16)
  ) clipper (
      .in(in),
      .out(out),
      .clipping(clipping)
  );

endmodule
