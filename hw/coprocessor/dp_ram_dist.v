module dp_ram_dist #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
) (
    input clk,
    input we,
    input [$clog2(DEPTH)-1:0] w_addr,
    input [WIDTH-1:0] di,
    // Parallel Read Outputs: One WIDTH-bit output for each location
    // The output 'parallel_dout[i]' corresponds to the data stored at address 'i'.
    output wire [WIDTH-1:0] parallel_dout[DEPTH-1:0]
);

  reg [WIDTH-1:0] ram[DEPTH-1:0];

  always @(posedge clk) begin
    if (we) ram[w_addr] <= di;
  end

  // Parallel Asynchronous Read Logic:
  // Continuously assigns each storage element to its dedicated output port.
  // Use a generate block for scalability and clarity.
  genvar i;
  generate
    for (i = 0; i < DEPTH; i = i + 1) begin : read_ports_gen
      // Assign the content of ram[i] directly to the output parallel_dout[i]
      // This read is asynchronous and combinational.
      assign parallel_dout[i] = ram[i];
    end
  endgenerate

endmodule
