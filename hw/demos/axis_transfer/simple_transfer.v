module axis_transfer #(
    parameter WIDTH  = 20,
    parameter HEIGHT = 20
) (
    input aclk,
    input aresetn,

    output reg          s_axis_tready,  // Ready to accept data in
    input      [31 : 0] s_axis_tdata,   // Data in
    input               s_axis_tlast,   // Optional data in qualifier
    input               s_axis_tvalid,  // Data in is valid

    // AXI4-Stream Master Interface
    output reg [31:0] m_axis_tdata,
    output reg        m_axis_tvalid,
    input             m_axis_tready,
    output reg        m_axis_tlast
);
  // Define the states of state machine (one hot encoding)
  localparam Idle = 4'b1000;
  localparam Read_Inputs = 4'b0100;
  localparam Compute = 4'b0010;
  localparam Write_Outputs = 4'b0001;

  reg [ 3:0] state;

  // Accumulator to hold sum of inputs read at any point in time
  reg [31:0] sum;

  localparam NUMBER_OF_INPUT_WORDS = 1;
  localparam NUMBER_OF_OUTPUT_WORDS = 400;
  // Counters to store the number inputs read & outputs written.
  // Could be done using the same counter if reads and writes are not overlapped (i.e., no dataflow optimization)
  // Left as separate for ease of debugging
  reg [ $clog2(NUMBER_OF_INPUT_WORDS) - 1:0] read_counter;
  reg [$clog2(NUMBER_OF_OUTPUT_WORDS) - 1:0] write_counter;


  always @(posedge ACLK) begin
    // implemented as a single-always Moore machine
    // a Mealy machine that asserts S_AXIS_TREADY and captures S_AXIS_TDATA etc can save a clock cycle

    /****** Synchronous reset (active low) ******/
    if (!aresetn) begin
      // CAUTION: make sure your reset polarity is consistent with the system reset polarity
      state <= Idle;
    end else begin
      case (state)

        Idle: begin
          read_counter  <= 0;
          write_counter <= 0;
          sum           <= 0;
          m_axis_tvalid <= 0;
          m_axis_tlast  <= 0;
          if (s_axis_tvalid == 1) begin
            state         <= Read_Inputs;
            s_axis_tready <= 1;
            // start receiving data once you go into Read_Inputs
          end
        end


        Read_Inputs: begin
          s_axis_tready <= 1;
          if (s_axis_tvalid == 1) begin
            // Coprocessor function (adding the numbers together) happens here (partly)
            sum <= sum + s_axis_tdata;
            // If we are expecting a variable number of words, we should make use of S_AXIS_TLAST.
            // Since the number of words we are expecting is fixed, we simply count and receive 
            // the expected number (NUMBER_OF_INPUT_WORDS) instead.
            if (read_counter == NUMBER_OF_INPUT_WORDS - 1) begin
              state         <= Write_Outputs;
              s_axis_tready <= 0;
            end else begin
              read_counter <= read_counter + 1;
            end
          end
        end

        Write_Outputs: begin
          m_axis_tvalid <= 1;
          m_axis_tdata  <= sum + write_counter;
          // Coprocessor function (adding 1 to sum in each iteration = adding iteration count to sum) happens here (partly)
          if (m_axis_tready == 1) begin
            if (write_counter == NUMBER_OF_OUTPUT_WORDS - 1) begin
              state <= Idle;
              m_axis_tlast <= 1;
            end else begin
              write_counter <= write_counter + 1;
            end
          end
        end
      endcase
    end
  end

endmodule
