module ufp_mul_test (
    input logic [31:0] x,
    input logic [31:0] y,
    input should_clip,
    output logic [31:0] out,
    output clipping
);

  localparam w = 16;

  ufp_if #(
      .IW(w),
      .QW(w)
  ) x_if ();
  ufp_if #(
      .IW(w),
      .QW(w)
  ) y_if ();
  ufp_if #(
      .IW(w),
      .QW(w)
  ) out_clipped_if ();
  ufp_if #(
      .IW(w),
      .QW(w)
  ) out_wrapped_if ();

  assign x_if.val = x;
  assign y_if.val = y;

  ufp_mul #(
      .CLIP(0)
  ) mul_wrapped (
      .x(x_if),
      .y(y_if),
      .out(out_wrapped_if),
      .clipping(clipping)
  );

  ufp_mul #(
      .CLIP(0)
  ) mul_clipped (
      .x(x_if),
      .y(y_if),
      .out(out_clipped_if),
      .clipping(clipping)
  );

  always_comb begin
    if (should_clip) out = out_clipped_if.val;
    else out = out_wrapped_if.val;
  end

endmodule
