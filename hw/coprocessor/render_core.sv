// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "rt_camera_t.svh"

// rt_camera_t fields are exposed as parameters, because coprocessor.v needs to
// be a plain verilog file
module render_core (
    // Config RAM read port (flattened 2D array)
    input logic [(32 * CAMERA_PAYLOAD_SIZE - 1):0] config_dout,

    // Control
    input logic clk,
    input logic resetn,
    input logic start,
    input logic ready,  // TODO: Make async
    output reg valid,
    output reg last,
    output reg [31:0] fragment
);

  parameter CONFIG_WIDTH = 32;
  // --- Recreate 2D Array Representation from Flattened Input ---
  // Declare an internal 2D wire array to map the config data
  wire [CONFIG_WIDTH-1:0] config_ram_2d[0:CAMERA_PAYLOAD_SIZE-1];

  // Use a generate block to perform the mapping from 1D 'config_dout' to 2D 'config_ram_2d'
  // This implements the "inverted for loop" concept for reconstruction.
  genvar k;
  generate
    for (k = 0; k < CAMERA_PAYLOAD_SIZE; k = k + 1) begin : unflatten_config_gen
      // Assign the k-th word (slice) from the flattened input to the k-th row of the 2D array.
      // Assumes config_dout was flattened as {ram[N-1], ..., ram[1], ram[0]}
      // So, ram[0] is at bits [31:0], ram[1] is at bits [63:32], etc.
      assign config_ram_2d[k] = config_dout[(k+1)*CONFIG_WIDTH-1 : k*CONFIG_WIDTH];
    end
  endgenerate
  // --- End of 2D Array Recreation ---

  typedef enum logic [2:0] {
    IDLE,
    GENERATE_RAY,
    INTERSECT,
    COLOR,
    OUTPUT  // Can be eliminated
  } state_t;

  sfp_if #(
      .IW(CAMERA_IW),
      .QW(CAMERA_QW)
  )
      x_fp (), y_fp (), ray_origin[3] (), ray_direction[3] ();

  logic [31:0] camera_center[3], pixel_delta_u[3], pixel_delta_v[3], pixel_00_loc[3];
  genvar j;
  generate
    for (j = 0; j < 3; j = j + 1) begin : rgu_var_assign
      assign camera_center[j] = config_ram_2d[OFF_CAMERA_CENTER+j];
      assign pixel_delta_u[j] = config_ram_2d[OFF_PIXEL_DELTA_U+j];
      assign pixel_delta_v[j] = config_ram_2d[OFF_PIXEL_DELTA_V+j];
      assign pixel_00_loc[j]  = config_ram_2d[OFF_PIXEL_00_LOC+j];
    end
  endgenerate

  rt_rgu rgu (
      .camera_center(camera_center),
      .pixel_delta_u(pixel_delta_u),
      .pixel_delta_v(pixel_delta_v),
      .pixel_00_loc(pixel_00_loc),
      .x(x_fp),
      .y(y_fp),
      .ray_origin(ray_origin),
      .ray_direction(ray_direction)
  );

  logic [CAMERA_IW-1 : 0] image_width_int;
  logic [CAMERA_IW-1 : 0] image_height_int;
  reg [CAMERA_IW-1 : 0] x, y;

  assign image_width_int  = CAMERA_IW'((config_ram_2d[OFF_IMAGE_WIDTH] >> CAMERA_QW));
  assign image_height_int = CAMERA_IW'((config_ram_2d[OFF_IMAGE_HEIGHT] >> CAMERA_QW));

  // Register result of RGU
  reg [CAMERA_WL-1 : 0] ray_origin_reg[3], ray_direction_reg[3];

  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_assign
      assign ray_origin_reg[i] = ray_origin[i].val;
      assign ray_direction_reg[i] = ray_direction[i].val;
    end
  endgenerate

  assign x_fp.val = {x, {CAMERA_QW{1'b0}}};
  assign y_fp.val = {y, {CAMERA_QW{1'b0}}};


  state_t state;
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          valid <= 1'b0;
          last <= 1'b0;
          x <= 0;
          y <= 0;
          if (start) begin
            state <= GENERATE_RAY;
          end
        end

        GENERATE_RAY: begin
          valid <= 1'b0;
          state <= INTERSECT;
        end

        INTERSECT: begin
          state <= COLOR;
        end

        COLOR: begin
          state <= OUTPUT;
        end

        OUTPUT: begin
          state <= GENERATE_RAY;

          valid <= 1'b1;
          fragment <= ray_direction_reg[0];

          if (ready) begin
            if (x == image_width_int - 1) begin
              x <= 0;
              y <= y + 1;
            end else begin
              x <= x + 1;
            end

            // Generated all rays for this scene?
            if ((x == image_width_int - 1) && (y == image_height_int - 1)) begin
              last  <= 1'b1;
              state <= IDLE;
            end
          end
        end

        default: state <= IDLE;

      endcase
    end
  end

endmodule
