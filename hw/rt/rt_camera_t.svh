// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

`ifndef RT_CAMERA
`define RT_CAMERA

parameter int CAMERA_IW = 14;
parameter int CAMERA_QW = 18;
parameter int CAMERA_WL = 32;

// Max Integer in Q14.18: 2^14/2 - 1 = 8191
// Image coordinates are unsigned ints, thus 2^13 = 8192
parameter int COORDINATE_BITS = 13;
parameter int CAMERA_PAYLOAD_SIZE = 27;

parameter OFF_IMAGE_WIDTH = 1;
parameter OFF_IMAGE_HEIGHT = 2;
parameter OFF_CAMERA_CENTER = 15;
parameter OFF_PIXEL_DELTA_U = 18;
parameter OFF_PIXEL_DELTA_V = 21;
parameter OFF_PIXEL_00_LOC = 24;

`endif
