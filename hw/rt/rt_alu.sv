// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`define ASSIGN_VEC_FP(A, B) \
    A[0] <= B[0].val; \
    A[1] <= B[1].val; \
    A[2] <= B[2].val;

module rt_alu_vec #(
    parameter WORD_LEN = 32,
    parameter IW = 16,
    patameter QW = 16,
    parameter OP_LEN = 4
) (
    input logic [OP_LEN - 1:0] op,

    input logic signed [WORD_LEN - 1:0] a[3],
    input logic signed [WORD_LEN - 1:0] b[3],

    output logic signed [WORD_LEN - 1:0] out[3]
);

  localparam OP_ADD = 4'b0000;  // Vector addition
  localparam OP_SUB = 4'b0001;  // Vector subtraction
  localparam OP_MUL = 4'b0010;  // Vector multiplication

  // Wrap into signed fixed-point interface
  sfp_if #(IW, QW) a_fp[3] (), b_fp[3] ();
  genvar i;
  generate
    for (i = 0; i < 3; i++) begin : gen_fp_assign
      assign a_fp[i].val = a[i];
      assign b_fp[i].val = b[i];
    end
  endgenerate

  // Arithmetic Modules

  sfp_if #(IW, QW) tmp_add_out[3] (), tmp_sub_out[3] (), tmp_mul_out[3] ();

  sfp_vec_add #(
      .CLIP(0)
  ) add_vec (
      .a  (a_fp),
      .b  (b_fp),
      .out(tmp_add_out)
  );

  sfp_vec_sub #(
      .CLIP(0)
  ) sub_vec (
      .a  (a_fp),
      .b  (b_fp),
      .out(tmp_sub_out)
  );

  sfp_vec_mul #(
      .CLIP(0)
  ) mul_vec (
      .a  (a_fp),
      .b  (b_fp),
      .out(tmp_mul_out)
  );


  // --- Output Selection Logic ---
  // Select the result based on the 'op' input code
  always_comb begin
    case (op)
      OP_ADD: begin
        `ASSIGN_VEC_FP(out, tmp_add_out)
      end
      OP_SUB: begin
        `ASSIGN_VEC_FP(out, tmp_sub_out)
      end
      OP_MUL: begin
        `ASSIGN_VEC_FP(out, tmp_mul_out)
      end

      default: begin  // Handles undefined opcodes
        `ASSIGN_VEC_FP(out, a_fp)
      end
    endcase
  end




endmodule
