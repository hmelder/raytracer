// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

// From Vivado Design Suite User Guide: Synthesis (UG901)

module dp_block_ram #(
    parameter WORD_LEN = 32,
    parameter DEPTH = 256,
) (
    clk,
    ena,
    enb,
    wea,
    addra,
    addrb,
    dia,
    dob
);

  input clk, ena, enb, wea;
  input [$clog2(DEPTH) - 1:0] addra, addrb;
  input [$clog2(WORD_LEN) - 1:0] dia;
  output [$clog2(WORD_LEN) - 1:0] dob;
  reg [$clog2(WORD_LEN) - 1:0] ram[$clog2(DEPTH) - 1:0];
  reg [$clog2(WORD_LEN) - 1:0] doa, dob;

  always @(posedge clk) begin
    if (ena) begin
      if (wea) ram[addra] <= dia;
    end
  end

  always @(posedge clk) begin
    if (enb) dob <= ram[addrb];
  end

endmodule
