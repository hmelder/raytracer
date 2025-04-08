// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "parameters.vh"

// Ray Generation Unit (RGU) - Sequential/Pipelined
module rt_rgu_5_stage (
    // Clock and Reset
    input logic clk,
    input logic resetn,

    // Control Interface
    input  logic start,  // Start calculation for one ray
    input  logic stall,
    output logic valid,  // Calculation finished, output is valid

    // Camera Properties (Inputs - assumed stable or registered externally if needed)
    input logic signed [FP_WL-1:0] pixel_00_loc [3],
    input logic signed [FP_WL-1:0] pixel_delta_u[3],
    input logic signed [FP_WL-1:0] pixel_delta_v[3],
    input logic signed [FP_WL-1:0] camera_center[3],

    // Image Coordinates (Input - registered on start)
    input logic [COORDINATE_BITS-1:0] x,
    input logic [COORDINATE_BITS-1:0] y,

    // Ray Output (Registered, valid when valid is high)
    sfp_if.out ray_origin[3],  // Registered Output
    sfp_if.out ray_direction[3]  // Registered Output
);

  // Wrap camera properties into the fixed point interface
  sfp_if #(FP_IW, FP_QW) pixel_00_loc_fp[3] ();
  sfp_if #(FP_IW, FP_QW) pixel_delta_u_fp[3] ();
  sfp_if #(FP_IW, FP_QW) pixel_delta_v_fp[3] ();
  sfp_if #(FP_IW, FP_QW) camera_center_fp[3] ();

  genvar i_cam;
  generate
    for (i_cam = 0; i_cam < 3; i_cam++) begin : assign_cam_params
      assign pixel_00_loc_fp[i_cam].val  = pixel_00_loc[i_cam];
      assign pixel_delta_u_fp[i_cam].val = pixel_delta_u[i_cam];
      assign pixel_delta_v_fp[i_cam].val = pixel_delta_v[i_cam];
      assign camera_center_fp[i_cam].val = camera_center[i_cam];
    end
  endgenerate

  // --- Pipeline Registers ---
  // Stage 0: Input Registers
  sfp_if #(FP_IW, FP_QW) x_reg ();
  sfp_if #(FP_IW, FP_QW) y_reg ();
  sfp_if #(FP_IW, FP_QW) ray_origin_reg[3] ();  // Register origin early

  // Stage 1: Multiplication Results
  sfp_if #(FP_IW, FP_QW) tmp_x_delta_u_reg[3] ();
  sfp_if #(FP_IW, FP_QW) tmp_y_delta_v_reg[3] ();

  // Stage 2: First Addition Result
  sfp_if #(FP_IW, FP_QW) tmp_pixel_off_reg[3] ();

  // Stage 3: Second Addition Result
  sfp_if #(FP_IW, FP_QW) pixel_center_reg[3] ();

  // Stage 4: Final Subtraction Result (Output Register)
  sfp_if #(FP_IW, FP_QW) ray_direction_reg[3] ();

  // --- Pipeline Control ---
  localparam PIPE_DEPTH = 5;  // 1 input reg + 4 calc stages
  logic [PIPE_DEPTH-1:0] pipe_valid;  // Shift register for valid signal

  // --- Combinational Logic for Pipeline Stages ---

  // Stage 1 Logic (Inputs: x_reg, y_reg)
  sfp_if #(FP_IW, FP_QW) tmp_x_delta_u_stage1[3] ();
  sfp_if #(FP_IW, FP_QW) tmp_y_delta_v_stage1[3] ();

  sfp_vec_mul_s #(
      .CLIP(0)
  ) mul_x_delta (
      .a(pixel_delta_u_fp),
      .s(x_reg),  // Use registered input
      .out(tmp_x_delta_u_stage1)
  );

  sfp_vec_mul_s #(
      .CLIP(0)
  ) mul_y_delta (
      .a(pixel_delta_v_fp),
      .s(y_reg),  // Use registered input
      .out(tmp_y_delta_v_stage1)
  );

  // Stage 2 Logic (Inputs: tmp_x_delta_u_reg, tmp_y_delta_v_reg)
  sfp_if #(FP_IW, FP_QW) tmp_pixel_off_stage2[3] ();

  sfp_vec_add #(
      .CLIP(0)
  ) add_pixel_off (
      .a  (tmp_x_delta_u_reg),    // Use registered inputs from Stage 1
      .b  (tmp_y_delta_v_reg),
      .out(tmp_pixel_off_stage2)
  );

  // Stage 3 Logic (Input: tmp_pixel_off_reg)
  sfp_if #(FP_IW, FP_QW) pixel_center_stage3[3] ();

  sfp_vec_add #(
      .CLIP(0)
  ) add_pixel_center (
      .a(pixel_00_loc_fp),  // Use camera param directly
      .b(tmp_pixel_off_reg),  // Use registered input from Stage 2
      .out(pixel_center_stage3)
  );

  // Stage 4 Logic (Inputs: pixel_center_reg, ray_origin_reg)
  sfp_if #(FP_IW, FP_QW) ray_direction_stage4[3] ();

  sfp_vec_sub #(
      .CLIP(0)
  ) sub_direction (
      .a  (pixel_center_reg),     // Use registered input from Stage 3
      .b  (ray_origin_reg),       // Use registered origin
      .out(ray_direction_stage4)
  );


  // --- Sequential Logic (Registers and Control) ---
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      // Reset pipeline registers and control
      pipe_valid <= '0;
      // Reset fixed-point registers (assign all fields if sfp_if is a struct)
      x_reg.val  <= '0;
      y_reg.val  <= '0;

      `ASSIGN_FP_VEC_S_SEQ(ray_origin_reg, '0)
      `ASSIGN_FP_VEC_S_SEQ(tmp_x_delta_u_reg, '0)
      `ASSIGN_FP_VEC_S_SEQ(tmp_y_delta_v_reg, '0)
      `ASSIGN_FP_VEC_S_SEQ(tmp_pixel_off_reg, '0)
      `ASSIGN_FP_VEC_S_SEQ(pixel_center_reg, '0)
      `ASSIGN_FP_VEC_S_SEQ(ray_direction_reg, '0)

    end else if (stall) begin
      // We stall the pipeline. Do nothing.
    end else begin
      // Pipeline Staging and Input Latching
      pipe_valid <= {pipe_valid[PIPE_DEPTH-2:0], start};  // Shift valid bit

      if (start) begin
        // Latch inputs on start
        x_reg.val <= {1'b0, x, {FP_QW{1'b0}}};
        y_reg.val <= {1'b0, y, {FP_QW{1'b0}}};
        // Latch ray origin (camera center) when starting
        `ASSIGN_FP_VEC_SEQ(ray_origin_reg, camera_center_fp);
      end

      // Stage 1 Registers (driven by Stage 1 combinational logic)
      if (pipe_valid[0]) begin  // If data entering stage 1 was valid
        `ASSIGN_FP_VEC_SEQ(tmp_x_delta_u_reg, tmp_x_delta_u_stage1);
        `ASSIGN_FP_VEC_SEQ(tmp_y_delta_v_reg, tmp_y_delta_v_stage1);
      end

      // Stage 2 Register (driven by Stage 2 combinational logic)
      if (pipe_valid[1]) begin  // If data entering stage 2 was valid
        `ASSIGN_FP_VEC_SEQ(tmp_pixel_off_reg, tmp_pixel_off_stage2);
      end

      // Stage 3 Register (driven by Stage 3 combinational logic)
      if (pipe_valid[2]) begin  // If data entering stage 3 was valid
        `ASSIGN_FP_VEC_SEQ(pixel_center_reg, pixel_center_stage3);
      end

      // Stage 4 Register (Output) (driven by Stage 4 combinational logic)
      if (pipe_valid[3]) begin  // If data entering stage 4 was valid
        `ASSIGN_FP_VEC_SEQ(ray_direction_reg, ray_direction_stage4);
      end
    end
  end

  // --- Output Assignments ---
  // Assign registered values to outputs

  genvar i_out;
  generate
    for (i_out = 0; i_out < 3; i_out++) begin : assign_out_params
      assign ray_origin[i_out].val = ray_origin_reg[i_out].val;  // Assign registered origin
      assign ray_direction[i_out].val = ray_direction_reg[i_out].val; // Assign registered direction
    end
  endgenerate

  // valid signal is high when the last stage of the pipeline is valid
  assign valid = pipe_valid[PIPE_DEPTH-1];

endmodule
