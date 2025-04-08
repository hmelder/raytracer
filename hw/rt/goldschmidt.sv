
`include "macros.svh"

module goldschmidt (
    input  logic clk,
    input  logic resetn,
    input  logic start,
    output logic valid,

    sfp_if.in in,  // S
    sfp_if.in est,  // y0
    sfp_if.out rsqrt,
    sfp_if.out sqrt
);

  sfp_if #(IW, QW) const_3 ();

  parameter IW = in.IW;  // * 2;
  parameter QW = in.QW;  // * 2;

  assign const_3.val = 3 << IW;

  // --- Pipeline Registers ---
  // Stage -1: (Sorry this was bolted on later)
  sfp_if #(IW, QW) b_0_reg (), y_0_reg ();

  // Stage 0:
  sfp_if #(IW, QW) x_0_reg (), YY_0_reg ();

  // Stage 1 
  sfp_if #(IW, QW) x_0_reg_stage1 (), y_0_reg_stage1 (), b_1_reg ();

  // Stage 2
  sfp_if #(IW, QW) x_0_reg_stage2 (), y_0_reg_stage2 (), b_1_reg_stage2 (), Y_1_reg ();

  // Stage 3
  sfp_if #(IW, QW) YY_1_reg (), b_1_reg_stage3 ();
  sfp_if #(rsqrt.IW, rsqrt.QW) y_1_reg ();
  sfp_if #(sqrt.IW, sqrt.QW) x_1_reg ();


  // --- Pipeline Control ---
  localparam PIPE_DEPTH = 5;
  logic [PIPE_DEPTH-1:0] pipe_valid;  // Shift register for valid signal


  // --- Combinational Logic for Pipeline Stages ---
  sfp_if #(IW, QW) tmp_x_0_stage0 (), tmp_YY_0_stage0 ();

  // Stage 0 Logic (Inputs: b_0_reg, y_0_reg)
  // x_0 = S * y_0 <=> in * est
  sfp_mul mul_x_0_stage0 (
      .x(b_0_reg),
      .y(y_0_reg),
      .out(tmp_x_0_stage0),
      .clipping()
  );

  // YY_0 = Y_0 * Y_0
  sfp_mul mul_YY_0_stage0 (
      .x(y_0_reg),
      .y(y_0_reg),
      .out(tmp_YY_0_stage0),
      .clipping()
  );

  // Stage 1 (Inputs: b_0_reg, YY_0_reg)
  sfp_if #(IW, QW) tmp_b_1_stage1 ();

  // b_1 = b_0 * YY_0
  sfp_mul mul_b_1_stage1 (
      .x(b_0_reg),
      .y(YY_0_reg),
      .out(tmp_b_1_stage1),
      .clipping()
  );

  // Stage 2 (Inputs: b_1_reg)
  sfp_if #(IW, QW) tmp_Y_1_stage2 ();

  // Y_1 = 1/2 * (3-b_1) <=> Y_1 = (3-b_1) >>> 1 (Shift done below in register assignment)
  sfp_sub sub_Y_1_stage2 (
      .in1(const_3),
      .in2(b_1_reg),
      .out(tmp_Y_1_stage2),
      .clipping()
  );

  // Stage 3 (Inputs: x_0_reg_stage2, y_0_reg_stage2, Y_1_reg, b_1_reg_stage2)
  sfp_if #(rsqrt.IW, rsqrt.QW) tmp_y_1_stage3 ();
  sfp_if #(sqrt.IW, sqrt.QW) tmp_x_1_stage3 ();
  //  sfp_if #(IW, QW) tmp_YY_1_stage3 ();

  // x_1 = x_0 * Y_1
  sfp_mul mul_x_1_stage3 (
      .x(x_0_reg_stage2),
      .y(Y_1_reg),
      .out(tmp_x_1_stage3),
      .clipping()
  );
  // y_1 = y_0 * Y_1
  sfp_mul mul_y_1_stage3 (
      .x(y_0_reg_stage2),
      .y(Y_1_reg),
      .out(tmp_y_1_stage3),
      .clipping()
  );

  // --- Sequential Logic (Registers and Control) ---
  always_ff @(posedge clk) begin
    if (!resetn) begin
      // Reset pipeline registers and control
      pipe_valid <= '0;
    end else begin
      // Pipeline Staging and Input Latching
      pipe_valid <= {pipe_valid[PIPE_DEPTH-2:0], start};  // Shift valid bit
    end

    // Stage -1
    if (start) begin
      b_0_reg.val <= in.val;
      y_0_reg.val <= est.val;
    end

    // Stage 0
    if (pipe_valid[0]) begin
      x_0_reg.val  <= tmp_x_0_stage0.val;
      YY_0_reg.val <= tmp_YY_0_stage0.val;
    end

    // Stage 1
    if (pipe_valid[1]) begin
      x_0_reg_stage1.val <= x_0_reg.val;
      y_0_reg_stage1.val <= y_0_reg.val;
      b_1_reg.val = tmp_b_1_stage1.val;
    end

    // Stage 2
    if (pipe_valid[2]) begin
      x_0_reg_stage2.val <= x_0_reg_stage1.val;
      y_0_reg_stage2.val <= y_0_reg_stage1.val;
      b_1_reg_stage2.val <= b_1_reg.val;
      Y_1_reg.val <= (tmp_Y_1_stage2.val >>> 1);
    end

    // Stage 3
    if (pipe_valid[3]) begin
      x_1_reg.val <= tmp_x_1_stage3.val;
      y_1_reg.val <= tmp_y_1_stage3.val;
    end

  end


  // --- Output Assignments ---
  // Assign registered values to outputs
  assign rsqrt.val = y_1_reg.val;
  assign sqrt.val = x_1_reg.val;

  // valid signal is high when the last stage of the pipeline is valid
  assign valid = pipe_valid[PIPE_DEPTH-1];


endmodule
