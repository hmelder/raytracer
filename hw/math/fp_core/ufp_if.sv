// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.
// Copyright (c) 2025 Hugo Melder

interface ufp_if #(
    parameter  int signed   IW = 1,       // number of integer bits (sign bit included)
    parameter  int unsigned QW = 1,       // number of fractional bits
    localparam int unsigned WL = IW + QW  // total number of bits
) ();
  logic [WL-1:0] val;  // holds the fixed point scaler

  modport out(output val);
  modport in(input val);
endinterface
