// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`ifndef PARAMETERS
`define PARAMETERS

parameter int FP_IW = 14;
parameter int FP_QW = 18;
parameter int FP_WL = 32;

// Max Integer in Q14.18: 2^14/2 - 1 = 8191
// Image coordinates are unsigned ints, thus 2^13 = 8192
parameter int COORDINATE_BITS = 13;

`define ASSIGN_FP_VEC_SEQ(A, B) \
    A[0].val <= B[0].val; \
    A[1].val <= B[1].val; \
    A[2].val <= B[2].val;

`define ASSIGN_FP_VEC_S_SEQ(A, s) \
  A[0].val <= s; \
  A[1].val <= s; \
  A[2].val <= s;

`endif
