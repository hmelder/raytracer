module gradient #(
    parameter int WIDTH  = 20,
    parameter int HEIGHT = 20,

    localparam int WidthBits  = $clog2(WIDTH),
    localparam int HeightBits = $clog2(HEIGHT)
) (
    input logic [WidthBits-1:0] x,
    input logic [HeightBits-1:0] y,
    output logic [31:0] pixel,
    output clipping
);

  localparam int W = 16;

  ufp_if #(
      .IW(W),
      .QW(W)
  ) width_inv_if ();
  ufp_if #(
      .IW(W),
      .QW(W)
  ) height_inv_if ();
  ufp_if #(
      .IW(W),
      .QW(W)
  ) color_max_if ();
  ufp_if #(
      .IW(W),
      .QW(W)
  ) x_if ();
  ufp_if #(
      .IW(W),
      .QW(W)
  ) y_if ();

  ufp_if #(
      .IW(W),
      .QW(W)
  ) norm_x_if ();
  ufp_if #(
      .IW(W),
      .QW(W)
  ) norm_y_if ();

  ufp_if #(
      .IW(W),
      .QW(W)
  ) out_r_if ();
  ufp_if #(
      .IW(W),
      .QW(W)
  ) out_g_if ();

  logic clipping_norm_x;
  logic clipping_norm_y;
  logic clipping_out_r;
  logic clipping_out_g;

  // FIXME: Not parameterised
  assign width_inv_if.val = 32'h00000d79;  // 1/(WIDTH-1)
  assign height_inv_if.val = 032'h00000d79;  // 1/(HEIGHT-1)

  // 255.999
  assign color_max_if.val = 32'h00ffffbe;
  assign x_if.val = {{(16 - WidthBits) {1'b0}}, x, 16'b0};
  assign y_if.val = {{(16 - HeightBits) {1'b0}}, y, 16'b0};


  assign clipping = clipping_norm_x | clipping_norm_y | clipping_out_g | clipping_out_r;

  // norm_x_if = (x << 16) * WIDTH_INV
  ufp_mul #(
      .CLIP(1)
  ) mul_norm_x (
      .x(x_if),
      .y(width_inv_if),
      .out(norm_x_if),
      .clipping(clipping_norm_x)
  );
  // norm_y_if = (y << 16) * WIDTH_INV
  ufp_mul #(
      .CLIP(1)
  ) mul_norm_y (
      .x(y_if),
      .y(height_inv_if),
      .out(norm_y_if),
      .clipping(clipping_norm_y)
  );

  // out_r_if = norm_x_if * COLOR_MAX
  ufp_mul #(
      .CLIP(1)
  ) mul_out_r (
      .x(norm_x_if),
      .y(color_max_if),
      .out(out_r_if),
      .clipping(clipping_out_r)
  );

  // out_g_if = norm_y_if * COLOR_MAX
  ufp_mul #(
      .CLIP(1)
  ) mul_out_g (
      .x(norm_y_if),
      .y(color_max_if),
      .out(out_g_if),
      .clipping(clipping_out_g)
  );


  assign pixel = {out_r_if.val[23:16], out_g_if.val[23:16], 16'b0};

endmodule
