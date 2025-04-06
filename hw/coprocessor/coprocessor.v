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
  localparam ScenePayloadSize = 27;
  localparam FragmentSize = 3;
  localparam DummyData = 32'hCAFEBABE;

  // State encoding
  localparam IDLE = 3'b000;
  localparam RECV_SCENE = 3'b001;
  localparam DISPATCH_RENDER = 3'b010;
  localparam WAIT_FOR_FRAGMENT = 3'b011;
  localparam SEND_FRAGMENT = 3'b100;

  // State declaration
  reg [2:0] state;

  reg [$clog2(ScenePayloadSize) - 1:0] recv_counter;
  reg [31:0] send_counter;


  always @(posedge aclk or negedge resetn) begin
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
          send_counter  <= 0;

          if (s_axis_tvalid) begin
            s_axis_tready <= 1;

            state <= RECV_SCENE;
          end
        end

        // Receive scene properties such as the camera configuration via AXIS slave
        RECV_SCENE: begin
          if (s_axis_tvalid) begin
            // TODO: Do something with s_axis_data

            if (recv_counter == ScenePayloadSize - 1) begin
              s_axis_tready <= 0;

              state <= DISPATCH_RENDER;
            end else begin
              recv_counter <= recv_counter + 1;
            end
          end
        end

        // Configure and dispatch the renderer
        DISPATCH_RENDER: begin
          // TODO: Implement render module
          state <= WAIT_FOR_FRAGMENT;
        end

        // Wait for renderer to complete a fragment
        WAIT_FOR_FRAGMENT: begin
          // TODO: Implement fragment handoff between render module
          state <= SEND_FRAGMENT;
        end

        // Send out fragment via AXIS master
        SEND_FRAGMENT: begin
          m_axis_tvalid <= 1;
          m_axis_tdata  <= DummyData + send_counter;

          if (m_axis_tready) begin
            if (send_counter == FragmentSize - 1) begin
              m_axis_tlast <= 1;

              // FIXME: Return to WAIT_FOR_FRAGMENT
              state <= IDLE;
            end else begin
              send_counter <= send_counter + 1;
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


endmodule
