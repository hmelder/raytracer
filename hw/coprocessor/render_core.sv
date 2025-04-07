// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "rt_camera_t.svh"

// rt_camera_t fields are exposed as parameters, because coprocessor.v needs to
// be a plain verilog file
module render_core (
    // Control
    input logic clk,
    input logic resetn,
    input logic start,
    input logic ready,  // TODO: Make async
    output reg valid,
    output reg last,
    output reg [31:0] fragment,

    // Camera parameters
    input logic [31:0] image_width,
    input logic [31:0] image_height,

    input logic [31:0] camera_center_x,
    input logic [31:0] camera_center_y,
    input logic [31:0] camera_center_z,

    input logic [31:0] pixel_delta_u_x,
    input logic [31:0] pixel_delta_u_y,
    input logic [31:0] pixel_delta_u_z,

    input logic [31:0] pixel_delta_v_x,
    input logic [31:0] pixel_delta_v_y,
    input logic [31:0] pixel_delta_v_z,

    input logic [31:0] pixel_00_loc_x,
    input logic [31:0] pixel_00_loc_y,
    input logic [31:0] pixel_00_loc_z
);

  typedef enum logic [2:0] {
    IDLE,
    GENERATE_RAY,
    INTERSECT,
    COLOR,
    OUTPUT  // Can be eliminated
  } state_t;

  // Alias scalar inputs to 3D vectors
  logic [31:0] camera_center[3];
  logic [31:0] pixel_delta_u[3];
  logic [31:0] pixel_delta_v[3];
  logic [31:0] pixel_00_loc [3];

  always_comb begin
    camera_center[0] = camera_center_x;
    camera_center[1] = camera_center_y;
    camera_center[2] = camera_center_z;

    pixel_delta_u[0] = pixel_delta_u_x;
    pixel_delta_u[1] = pixel_delta_u_y;
    pixel_delta_u[2] = pixel_delta_u_z;

    pixel_delta_v[0] = pixel_delta_v_x;
    pixel_delta_v[1] = pixel_delta_v_y;
    pixel_delta_v[2] = pixel_delta_v_z;

    pixel_00_loc[0]  = pixel_00_loc_x;
    pixel_00_loc[1]  = pixel_00_loc_y;
    pixel_00_loc[2]  = pixel_00_loc_z;
  end

  sfp_if #(
      .IW(CAMERA_IW),
      .QW(CAMERA_QW)
  )
      x_fp (), y_fp (), ray_origin[3] (), ray_direction[3] ();

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

  assign image_width_int  = CAMERA_IW'(image_width >> CAMERA_QW);
  assign image_height_int = CAMERA_IW'(image_height >> CAMERA_QW);

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

  reg [$clog2(CAMERA_PAYLOAD_SIZE) - 1:0] addr_off;

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
