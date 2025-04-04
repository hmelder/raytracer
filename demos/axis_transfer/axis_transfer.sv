module axis_transfer #(
    parameter WIDTH  = 20,
    parameter HEIGHT = 20
) (
    input logic aclk,
    input logic aresetn,

    // AXI4-Stream Master Interface
    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast
);

  logic [ 4:0] x;
  logic [ 4:0] y;

  logic [31:0] color;

  gradient #(
      .WIDTH (WIDTH),
      .HEIGHT(HEIGHT)
  ) gradient_mod (
      .x(x),
      .y(y),
      .pixel(color),
      .clipping()
  );

  // Define states with explicit encoding (optional)
  typedef enum logic {
    IDLE,
    SEND_DATA
  } state_t;

  state_t state;
  always_ff @(posedge aclk) begin
    m_axis_tvalid <= 1'b0;
    m_axis_tlast  <= 1'b0;

    if (!aresetn) begin
      state <= IDLE;
      x <= 0;
      y <= 0;
      m_axis_tdata <= 0;
    end else begin
      // State transitions and output assignments
      case (state)
        IDLE: begin
          state <= SEND_DATA;
        end

        SEND_DATA: begin
          m_axis_tvalid <= 1'b1;
          m_axis_tdata  <= color;

          // Index Incrementing
          if (x == WIDTH - 1) begin
            x <= 0;
            y <= y + 1;
          end else x <= x + 1;

          if (x == WIDTH - 1 && y == HEIGHT - 1) begin
            m_axis_tlast <= 1'b1;
            state <= IDLE;
          end
        end

        // Optional: handle unexpected states
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
