// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

module sfp_add_wrapper (
    input logic [31:0] x,
    input logic [31:0] y,
    input should_clip,
    output logic [31:0] out,
    output clipping
);

  localparam w = 16;

  sfp_if #(
      .IW(w),
      .QW(w)
  ) x_if ();
  sfp_if #(
      .IW(w),
      .QW(w)
  ) y_if ();
  sfp_if #(
      .IW(w),
      .QW(w)
  ) out_clipped_if ();
  sfp_if #(
      .IW(w),
      .QW(w)
  ) out_wrapped_if ();

  assign x_if.val = x;
  assign y_if.val = y;

  sfp_add #(
      .CLIP(0)
  ) add_wrapped (
      .in1(x_if),
      .in2(y_if),
      .out(out_wrapped_if),
      .clipping(clipping)
  );

  sfp_add #(
      .CLIP(0)
  ) add_clipped (
      .in1(x_if),
      .in2(y_if),
      .out(out_clipped_if),
      .clipping(clipping)
  );

  always_comb begin
    if (should_clip) out = out_clipped_if.val;
    else out = out_wrapped_if.val;
  end

endmodule
