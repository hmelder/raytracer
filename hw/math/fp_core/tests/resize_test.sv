// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

module resize_test #(
    parameter int IN_IW,
    parameter int IN_QW,
    parameter int OUT_IW,
    parameter int OUT_QW
) (
    input  logic [  (IN_IW + IN_QW - 1):0] in,           // Input raw value
    input  logic                           should_clip,
    output logic [(OUT_IW + OUT_QW - 1):0] out,          // Output raw value
    output logic                           clipping      // Clipping indicator
);

  // Define the input and output fixed-point interfaces
  ufp_if #(
      .IW(IN_IW),
      .QW(IN_QW)
  ) in_if ();
  ufp_if #(
      .IW(OUT_IW),
      .QW(OUT_QW)
  ) out_clipped_if ();
  ufp_if #(
      .IW(OUT_IW),
      .QW(OUT_QW)
  ) out_wrapped_if ();

  assign in_if.val = in;

  ufp_resize #(
      .clip(1)
  ) u_resize_clipped (
      .in(in_if.in),
      .out(out_clipped_if.out),
      .clipping(clipping)
  );
  ufp_resize #(
      .clip(0)
  ) u_resize_wrapped (
      .in(in_if.in),
      .out(out_wrapped_if.out),
      .clipping(clipping)
  );

  always_comb begin
    if (should_clip) out = out_clipped_if.val;
    else out = out_wrapped_if.val;
  end

endmodule
