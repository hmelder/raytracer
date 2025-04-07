// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

// Vivado's IP Integrator forces me to keep this in plain verilog, otherwise it complaints
// about modports (from sfp_if) having the "wrong" name.

module coprocessor #(
) (
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

  // 27 * 4 bytes payload
  localparam CameraPayloadSize = 27;


  // State encoding
  localparam IDLE = 3'b000;
  localparam RECV_SCENE = 3'b001;
  localparam DISPATCH_RENDER = 3'b010;
  localparam WAIT_FOR_FRAGMENT = 3'b011;
  localparam SEND_FRAGMENT = 3'b100;

  // State declaration
  reg [2:0] state;

  reg [$clog2(CameraPayloadSize) - 1:0] recv_counter;
  reg [31:0] recv_buffer[CameraPayloadSize];

  reg [31:0] send_counter;

  // Render Core
  reg render_start;
  wire render_valid;
  wire render_last;
  reg render_ready;
  wire [31:0] render_fragment;
  reg [31:0] fragment_reg;
  reg done;


  always @(posedge aclk or negedge resetn) begin
    if (!resetn) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          // Reset AXIS
          s_axis_tready <= 0;
          m_axis_tvalid <= 0;
          m_axis_tlast <= 0;

          // Reset Stream Control Registers
          recv_counter <= 0;
          send_counter <= 0;
          done <= 0;

          // Render Core Control Registers
          render_ready <= 0;
          render_start <= 0;

          if (s_axis_tvalid) begin
            s_axis_tready <= 1;

            state <= RECV_SCENE;
          end
        end

        // Receive scene properties such as the camera configuration via AXIS slave
        RECV_SCENE: begin
          if (s_axis_tvalid) begin
            recv_buffer[recv_counter] <= s_axis_tdata;

            if (recv_counter == CameraPayloadSize - 1) begin
              s_axis_tready <= 0;

              state <= DISPATCH_RENDER;
            end else begin
              recv_counter <= recv_counter + 1;
            end
          end
        end

        // Configure and dispatch the renderer
        DISPATCH_RENDER: begin
          render_start <= 1;
          render_ready <= 1;
          state <= WAIT_FOR_FRAGMENT;
        end

        // Wait for renderer to complete a fragment
        WAIT_FOR_FRAGMENT: begin
          // AXIS Master Bus Control
          m_axis_tvalid <= 0;

          // Render has valid fragment(s)?
          if (render_valid) begin
            fragment_reg <= render_fragment;  // Latch current result
            render_ready <= 0;  // Not ready to receive more fragments from render_core
            state <= SEND_FRAGMENT;  // Send out fragment via the AXIS Master channel

            // Renderer signals that this is the last fragment?
            if (render_last) begin
              done <= 1;
            end
          end
        end

        // Send out fragment via AXIS master
        SEND_FRAGMENT: begin
          // AXIS Master Bus Control
          m_axis_tvalid <= 1;
          m_axis_tdata  <= fragment_reg;

          render_ready  <= 0;  // Not ready to receieve new data

          if (m_axis_tready) begin
            render_ready <= 1; // Receiver latched fragment, ready to receive new fragments from renderer

            // Renderer signaled that this is the last fragment
            if (done) begin
              m_axis_tlast <= 1;
              state <= IDLE;
            end else begin  // Wait for new fragments
              state <= WAIT_FOR_FRAGMENT;
            end
          end
        end

        // Something very bad happened...
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  render_core core (
      .cam_buf(recv_buffer),
      .clk(aclk),
      .resetn(resetn),
      .start(render_start),
      .valid(render_valid),
      .ready(render_ready),
      .last(render_last),
      .fragment(render_fragment)
  );


endmodule
