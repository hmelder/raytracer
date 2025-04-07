// Module: dp_ram_dist_flat
// Description: A distributed RAM model with synchronous write and
//              asynchronous, flattened parallel read output.
//              The entire RAM content is available combinatorially
//              on a single wide output bus.
module dp_ram_dist_flat #(
    parameter WIDTH = 32,  // Data width of each memory location
    parameter DEPTH = 32   // Number of memory locations (depth)
) (
    input                     clk,     // Clock signal
    input                     we,      // Write enable (active high)
    input [$clog2(DEPTH)-1:0] w_addr,  // Write address
    input [        WIDTH-1:0] di,      // Data input for writing

    // Flattened Parallel Output: All locations concatenated into a single wide vector
    // The total width is DEPTH * WIDTH.
    // flat_dout[(i+1)*WIDTH-1 : i*WIDTH] corresponds to the data stored at address 'i'.
    output wire [DEPTH*WIDTH-1:0] flat_dout
);

  // Internal memory storage as an array of registers
  reg [WIDTH-1:0] ram[DEPTH-1:0];

  // Synchronous Write Logic:
  always @(posedge clk) begin
    if (we) begin
      ram[w_addr] <= di;
    end
  end

  // Asynchronous Flattened Parallel Read Logic:
  // Continuously assigns each storage element (ram[i]) to its corresponding
  // slice within the single flattened output vector 'flat_dout'.
  // Use a generate block for scalability and clarity.
  genvar i;
  generate
    for (i = 0; i < DEPTH; i = i + 1) begin : flatten_read_ports_gen
      // Assign the content of ram[i] directly to the corresponding slice
      // of the output vector flat_dout.
      // The slice for ram[i] is bits [(i+1)*WIDTH-1 : i*WIDTH].
      // This read is asynchronous and combinational.
      assign flat_dout[(i+1)*WIDTH-1 : i*WIDTH] = ram[i];
    end
  endgenerate

endmodule
