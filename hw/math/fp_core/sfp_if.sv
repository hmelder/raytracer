// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Skyworks Inc.
// Copyright (c) 2025 Hugo Melder

// This interface represents a signed fixed point
interface sfp_if #(
    parameter  int signed   IW = 1,       // number of integer bits (sign bit included)
    parameter  int unsigned QW = 1,       // number of fractional bits
    localparam int unsigned WL = IW + QW  // total number of bits
) ();
  logic signed [WL-1:0] val;  // holds the fixed point scaler
  localparam int IsSigned = 1;

  modport out(output val);
  modport in(input val);
endinterface
