// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

module resize_up_test (
    input  logic [31:0] in,           // Input raw value
    input  logic        should_clip,
    output logic [63:0] out,          // Output raw value
    output logic        clipping      // Clipping indicator
);

  resize_test #(
      .IN_IW (16),
      .IN_QW (16),
      .OUT_IW(32),
      .OUT_QW(32)
  ) impl (
      .in(in),
      .should_clip(should_clip),
      .out(out),
      .clipping(clipping)
  );

endmodule
