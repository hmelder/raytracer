// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`include "parameters.vh"

module rt_controller (
    input logic clk,
    input logic resetn,

    input  logic start,
    input  logic stall,
    // Signal consumer that there is only one pixel left in the pipeline
    output logic last,

    input logic [COORDINATE_BITS-1 : 0] image_width,
    input logic [COORDINATE_BITS-1 : 0] image_height,

    output logic rgu_start,
    output logic [COORDINATE_BITS-1:0] x,
    output logic [COORDINATE_BITS-1:0] y

);

  // State definition
  typedef enum logic [1:0] {
    IDLE,
    READY,
    DRAIN
  } state_t;

  // State registers
  state_t current_state, next_state;

  // Coordinate update logic
  logic [COORDINATE_BITS-1:0] x_reg, y_reg, x_reg_next, y_reg_next;
  logic last_pixel;

  parameter RGU_PIPELINE_DEPTH = 5;
  logic [$clog2(RGU_PIPELINE_DEPTH)-1:0] cycle_count, cycle_count_next;

  logic rgu_start_reg, rgu_start_next_reg;

  // State Register and coordinate register logic
  always_ff @(posedge clk) begin
    if (!resetn) begin
      current_state <= IDLE;
    end else if (stall) begin
      // Do nothing
    end else begin
      current_state <= next_state;
      rgu_start_reg <= rgu_start_next_reg;
      cycle_count <= cycle_count_next;
      x_reg <= x_reg_next;
      y_reg <= y_reg_next;
    end
  end

  // Next State Logic (Combinational)
  always_comb begin
    // Default to staying in the current state unless a transition condition is met
    next_state = current_state;

    case (current_state)
      IDLE: begin
        if (start) begin
          next_state = READY;
        end
      end

      READY: begin
        if (last_pixel) begin
          next_state = DRAIN;
        end
      end

      DRAIN: begin
        if (cycle_count == 4) begin
          next_state = IDLE;
        end
      end

      default: begin
        next_state = IDLE;  // Should not happen, but safe default
      end

    endcase
  end

  always_comb begin
    last_pixel = (x_reg == image_width - 1) && (y_reg == image_height - 1);
    rgu_start = rgu_start_reg;
    x = x_reg;
    y = y_reg;

    case (current_state)
      IDLE: begin
        x_reg_next = 0;
        y_reg_next = 0;
        cycle_count_next = 0;
        last = 0;
        rgu_start_next_reg = start;
      end
      READY: begin
        // Coordinate update logic
        if (x_reg == image_width - 1) begin
          x_reg_next = 0;
          y_reg_next = y_reg + 1;
        end else begin
          x_reg_next = x_reg + 1;
        end

        rgu_start_next_reg = !last_pixel;
      end
      DRAIN: begin
        cycle_count_next   = cycle_count + 1;
        rgu_start_next_reg = 0;
        if (cycle_count == 4) begin
          last = 1;
        end
      end
      default: begin
        // All outputs low
      end
    endcase
  end


endmodule

