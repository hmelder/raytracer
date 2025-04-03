`timescale 1ns / 1ps

module axis_transfer (
    input logic aclk,
    input logic aresetn,

    // AXI4-Stream Master Interface
    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast
);

  // Define states with explicit encoding (optional)
  typedef enum logic [1:0] {
    IDLE      = 2'b00,
    SEND_DATA = 2'b01,
    SEND_LAST = 2'b10
  } state_t;

  // Use _q for current state, _d for next state (common convention)
  state_t state_q, state_d;

  // Sequential logic for state transitions
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  // Combinational logic for next state and outputs
  always_comb begin
    // Default assignments (helps avoid latches)
    state_d = state_q;
    m_axis_tvalid = 1'b0;
    m_axis_tlast = 1'b0;
    m_axis_tdata = 32'hDEADBEEF;

    // State transitions and output assignments
    case (state_q)
      IDLE: begin
        state_d = SEND_DATA;
      end

      SEND_DATA: begin
        m_axis_tvalid = 1'b1;
        if (m_axis_tready) begin
          state_d = SEND_LAST;
        end
      end

      SEND_LAST: begin
        m_axis_tvalid = 1'b1;
        m_axis_tlast  = 1'b1;
        if (m_axis_tready) begin
          state_d = IDLE;
        end
      end

      // Optional: handle unexpected states
      default: begin
        state_d = IDLE;
      end
    endcase
  end

endmodule
