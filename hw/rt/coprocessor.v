// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

// Vivado's IP Integrator forces me to keep this in plain verilog, otherwise it complaints
// about modports (from sfp_if) having the "wrong" name.

module coprocessor (
    input wire aclk,
    input wire resetn,

    // AXIS Slave
    output reg s_axis_tready,
    input wire [31 : 0] s_axis_tdata,
    input wire s_axis_tlast,
    input wire s_axis_tvalid,

    // AXIS Master
    output reg m_axis_tvalid,
    output reg [31 : 0] m_axis_tdata,
    output reg m_axis_tlast,
    input wire m_axis_tready
);

  // State encoding
  localparam IDLE = 3'b000;
  localparam RECV_SCENE = 3'b010;
  localparam SEND_FRAGMENT = 3'b100;

  // State declaration
  reg [2:0] state;

  // Counters
  reg [$clog2(CameraPayloadSize) - 1:0] recv_counter;

  // Camera Config RAM
  // 27 * 4 bytes payload
  localparam CameraPayloadSize = 27;

  /*
   * Contents
   *
   * | Parameter           | Len (in words) | Offset |
   * |---------------------|----------------|--------|
   * | aspect_ratio        | 1              | 0      |
   * | image_width         | 1              | 1      |
   * | image_height        | 1              | 2      |
   * | focal_length        | 1              | 3      |
   * | viewport_height     | 1              | 4      |
   * | viewport_width      | 1              | 5      |
   * | viewport_u          | 3              | 6      |
   * | viewport_v          | 3              | 9      |
   * | viewport_upper_left | 3              | 12     |
   * | camera_center       | 3              | 15     |
   * | pixel_delta_u       | 3              | 18     |
   * | pixel_delta_v       | 3              | 21     |
   * | pixel_00_loc        | 3              | 24     |
   */
  parameter WORD_LEN = 32;
  parameter OFF_ASPECT_RATIO = 0;
  parameter OFF_IMAGE_WIDTH = 1;
  parameter OFF_IMAGE_HEIGHT = 2;
  parameter OFF_FOCAL_LENGTH = 3;
  parameter OFF_VIEWPORT_HEIGHT = 4;
  parameter OFF_VIEWPORT_WIDTH = 5;
  parameter OFF_VIEWPORT_U = 6;
  parameter OFF_VIEWPORT_V = 9;
  parameter OFF_VIEWPORT_UPPER_LEFT = 12;
  parameter OFF_CAMERA_CENTER = 15;
  parameter OFF_PIXEL_DELTA_U = 18;
  parameter OFF_PIXEL_DELTA_V = 21;
  parameter OFF_PIXEL_00_LOC = 24;

  reg [WORD_LEN-1:0] aspect_ratio;
  reg [WORD_LEN-1:0] image_width;
  reg [WORD_LEN-1:0] image_height;
  reg [WORD_LEN-1:0] focal_length;

  reg [WORD_LEN-1:0] viewport_height;
  reg [WORD_LEN-1:0] viewport_width;

  // Viewport U vector
  reg [WORD_LEN-1:0] viewport_u_x;
  reg [WORD_LEN-1:0] viewport_u_y;
  reg [WORD_LEN-1:0] viewport_u_z;

  // Viewport V vector
  reg [WORD_LEN-1:0] viewport_v_x;
  reg [WORD_LEN-1:0] viewport_v_y;
  reg [WORD_LEN-1:0] viewport_v_z;

  // Viewport upper-left corner
  reg [WORD_LEN-1:0] viewport_upper_left_x;
  reg [WORD_LEN-1:0] viewport_upper_left_y;
  reg [WORD_LEN-1:0] viewport_upper_left_z;

  // Camera center
  reg [WORD_LEN-1:0] camera_center_x;
  reg [WORD_LEN-1:0] camera_center_y;
  reg [WORD_LEN-1:0] camera_center_z;

  // Pixel delta U
  reg [WORD_LEN-1:0] pixel_delta_u_x;
  reg [WORD_LEN-1:0] pixel_delta_u_y;
  reg [WORD_LEN-1:0] pixel_delta_u_z;

  // Pixel delta V
  reg [WORD_LEN-1:0] pixel_delta_v_x;
  reg [WORD_LEN-1:0] pixel_delta_v_y;
  reg [WORD_LEN-1:0] pixel_delta_v_z;

  // Pixel (0,0) location
  reg [WORD_LEN-1:0] pixel_00_loc_x;
  reg [WORD_LEN-1:0] pixel_00_loc_y;
  reg [WORD_LEN-1:0] pixel_00_loc_z;

  // Render (rt_core)
  reg render_start;
  reg render_stall;

  wire render_valid;
  wire render_last;
  wire [FP_WL - 1:0] render_pixel;

  reg deferred_last;


  always @(posedge aclk) begin
    if (!resetn) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          // Reset AXIS
          s_axis_tready <= 0;
          m_axis_tvalid <= 0;
          m_axis_tlast  <= 0;

          // Reset Stream Control Registers
          recv_counter  <= 0;

          // Reset rt_core registers
          render_start  <= 0;
          render_stall  <= 0;

          if (s_axis_tvalid) begin
            s_axis_tready <= 1;

            state <= RECV_SCENE;
          end
        end

        // Receive scene properties such as the camera configuration via AXIS slave
        RECV_SCENE: begin
          if (s_axis_tvalid) begin
            case (recv_counter)
              OFF_ASPECT_RATIO:    aspect_ratio <= s_axis_tdata;
              OFF_IMAGE_WIDTH:     image_width <= s_axis_tdata;
              OFF_IMAGE_HEIGHT:    image_height <= s_axis_tdata;
              OFF_FOCAL_LENGTH:    focal_length <= s_axis_tdata;
              OFF_VIEWPORT_HEIGHT: viewport_height <= s_axis_tdata;
              OFF_VIEWPORT_WIDTH:  viewport_width <= s_axis_tdata;

              OFF_VIEWPORT_U:     viewport_u_x <= s_axis_tdata;
              OFF_VIEWPORT_U + 1: viewport_u_y <= s_axis_tdata;
              OFF_VIEWPORT_U + 2: viewport_u_z <= s_axis_tdata;

              OFF_VIEWPORT_V:     viewport_v_x <= s_axis_tdata;
              OFF_VIEWPORT_V + 1: viewport_v_y <= s_axis_tdata;
              OFF_VIEWPORT_V + 2: viewport_v_z <= s_axis_tdata;

              OFF_VIEWPORT_UPPER_LEFT: viewport_upper_left_x <= s_axis_tdata;
              OFF_VIEWPORT_UPPER_LEFT + 1: viewport_upper_left_y <= s_axis_tdata;
              OFF_VIEWPORT_UPPER_LEFT + 2: viewport_upper_left_z <= s_axis_tdata;

              OFF_CAMERA_CENTER:     camera_center_x <= s_axis_tdata;
              OFF_CAMERA_CENTER + 1: camera_center_y <= s_axis_tdata;
              OFF_CAMERA_CENTER + 2: camera_center_z <= s_axis_tdata;

              OFF_PIXEL_DELTA_U:     pixel_delta_u_x <= s_axis_tdata;
              OFF_PIXEL_DELTA_U + 1: pixel_delta_u_y <= s_axis_tdata;
              OFF_PIXEL_DELTA_U + 2: pixel_delta_u_z <= s_axis_tdata;

              OFF_PIXEL_DELTA_V:     pixel_delta_v_x <= s_axis_tdata;
              OFF_PIXEL_DELTA_V + 1: pixel_delta_v_y <= s_axis_tdata;
              OFF_PIXEL_DELTA_V + 2: pixel_delta_v_z <= s_axis_tdata;

              OFF_PIXEL_00_LOC:     pixel_00_loc_x <= s_axis_tdata;
              OFF_PIXEL_00_LOC + 1: pixel_00_loc_y <= s_axis_tdata;
              OFF_PIXEL_00_LOC + 2: pixel_00_loc_z <= s_axis_tdata;

              default: ;  // ignore
            endcase

            if (recv_counter == CameraPayloadSize - 1) begin
              s_axis_tready <= 0;
              render_start <= 1;

              state <= SEND_FRAGMENT;
            end else begin
              recv_counter <= recv_counter + 1;
            end
          end
        end

        // Send out fragment via AXIS master
        SEND_FRAGMENT: begin
          render_start <= 0;

          // AXIS Master Bus Control

          // Do not update data when pipeline is stalled
          if (!render_stall) begin
            m_axis_tvalid <= render_valid;
            m_axis_tdata  <= render_pixel;
            m_axis_tlast  <= render_last;
          end

          if (m_axis_tready) begin
            render_stall <= 0;

            // Renderer signaled that this is the last fragment
            if (render_last || deferred_last) begin
              state <= IDLE;
            end else begin  // Wait for new fragments
              state <= SEND_FRAGMENT;
            end
          end else begin
            render_stall <= 1;
          end
        end

        // Something very bad happened...
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end


  rt_core_wrapper render (
      .clk(aclk),
      .resetn(resetn),
      .start(render_start),
      .stall(render_stall),
      .valid(render_valid),
      .last(render_last),
      .pixel(render_pixel),
      .image_width(image_width),
      .image_height(image_height),
      .camera_center_x(camera_center_x),
      .camera_center_y(camera_center_y),
      .camera_center_z(camera_center_z),
      .pixel_delta_u_x(pixel_delta_u_x),
      .pixel_delta_u_y(pixel_delta_u_y),
      .pixel_delta_u_z(pixel_delta_u_z),
      .pixel_delta_v_x(pixel_delta_v_x),
      .pixel_delta_v_y(pixel_delta_v_y),
      .pixel_delta_v_z(pixel_delta_v_z),
      .pixel_00_loc_x(pixel_00_loc_x),
      .pixel_00_loc_y(pixel_00_loc_y),
      .pixel_00_loc_z(pixel_00_loc_z)
  );



endmodule
