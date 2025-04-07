// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "rt_camera_t.svh"

// rt_camera_t fields are exposed as parameters, because coprocessor.v needs to
// be a plain verilog file
module render_core (
    // rt_camera_t fields
    input logic [CAMERA_WL-1:0] cam_buf[27],

    // Control
    input logic clk,
    input logic resetn,
    input logic start,
    input logic ready,  // TODO: Make async
    output reg valid,
    output reg last,
    output reg [31:0] fragment
);

  typedef enum logic [2:0] {
    IDLE,
    GENERATE_RAY,
    INTERSECT,
    COLOR,
    OUTPUT  // Can be eliminated
  } state_t;

  rt_camera_t camera;

  // Arggh, not sure if there is a better way to unmarshal the buffer into the struct
  always_comb begin
    camera.aspect_ratio           = cam_buf[0];
    camera.image_width            = cam_buf[1];
    camera.image_height           = cam_buf[2];

    camera.focal_length           = cam_buf[3];
    camera.viewport_height        = cam_buf[4];
    camera.viewport_width         = cam_buf[5];

    camera.camera_center[0]       = cam_buf[6];
    camera.camera_center[1]       = cam_buf[7];
    camera.camera_center[2]       = cam_buf[8];

    camera.viewport_u[0]          = cam_buf[9];
    camera.viewport_u[1]          = cam_buf[10];
    camera.viewport_u[2]          = cam_buf[11];

    camera.viewport_v[0]          = cam_buf[12];
    camera.viewport_v[1]          = cam_buf[13];
    camera.viewport_v[2]          = cam_buf[14];

    camera.viewport_upper_left[0] = cam_buf[15];
    camera.viewport_upper_left[1] = cam_buf[16];
    camera.viewport_upper_left[2] = cam_buf[17];

    camera.pixel_delta_u[0]       = cam_buf[18];
    camera.pixel_delta_u[1]       = cam_buf[19];
    camera.pixel_delta_u[2]       = cam_buf[20];

    camera.pixel_delta_v[0]       = cam_buf[21];
    camera.pixel_delta_v[1]       = cam_buf[22];
    camera.pixel_delta_v[2]       = cam_buf[23];

    camera.pixel_00_loc[0]        = cam_buf[24];
    camera.pixel_00_loc[1]        = cam_buf[25];
    camera.pixel_00_loc[2]        = cam_buf[26];
  end


  sfp_if #(
      .IW(CAMERA_IW),
      .QW(CAMERA_QW)
  )
      x_fp (), y_fp (), ray_origin[3] (), ray_direction[3] ();

  rt_rgu rgu (
      .cam(camera),
      .x(x_fp),
      .y(y_fp),
      .ray_origin(ray_origin),
      .ray_direction(ray_direction)
  );

  logic [CAMERA_IW-1 : 0] image_width_int;
  logic [CAMERA_IW-1 : 0] image_height_int;
  reg [CAMERA_IW-1 : 0] x, y;

  assign image_width_int  = CAMERA_IW'((camera.image_width >> CAMERA_QW));
  assign image_height_int = CAMERA_IW'((camera.image_height >> CAMERA_QW));


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
