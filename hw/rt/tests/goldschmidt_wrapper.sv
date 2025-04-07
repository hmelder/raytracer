module goldschmidt_wrapper (
    input  logic clk,
    input  logic resetn,
    input  logic start,
    output logic valid,

    input  logic [31:0] in,
    input  logic [31:0] est,
    output logic [31:0] rsqrt,
    output logic [31:0] sqrt
);

  sfp_if #(16, 16) in_fp (), est_fp (), rsqrt_fp (), sqrt_fp ();

  assign in_fp.val = in;
  assign est_fp.val = est;
  assign rsqrt = rsqrt_fp.val;
  assign sqrt = sqrt_fp.val;

  goldschmidt dut (
      .clk(clk),
      .resetn(resetn),
      .start(start),
      .valid(valid),
      .in(in_fp),
      .est(est_fp),
      .rsqrt(rsqrt_fp),
      .sqrt(sqrt_fp)
  );

endmodule
