// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`ifndef PARAMETERS
`define PARAMETERS

parameter FP_IW = 16;
parameter FP_QW = 16;
parameter FP_WL = 32;

parameter COORDINATE_BITS = 15;

parameter PIXEL_WIDTH = 24;  // RGB

`define ASSIGN_FP_VEC_SEQ(A, B) \
    A[0].val <= B[0].val; \
    A[1].val <= B[1].val; \
    A[2].val <= B[2].val;

`define ASSIGN_FP_VEC_S_SEQ(A, s) \
  A[0].val <= s; \
  A[1].val <= s; \
  A[2].val <= s;

`endif
