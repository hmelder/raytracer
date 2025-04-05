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

// TODO: Make packed?
typedef struct {
  // Image parameters
  logic [CAMERA_WL-1:0] aspect_ratio;
  logic [CAMERA_WL-1:0] image_width;
  logic [CAMERA_WL-1:0] image_height;  // int(image_width / aspect_ratio)

  // Camera parameters
  logic [CAMERA_WL-1:0] focal_length;
  logic [CAMERA_WL-1:0] viewport_height;
  logic [CAMERA_WL-1:0] viewport_width;    // viewport_height * (image_width/image_height);
  logic [CAMERA_WL-1:0] camera_center[3];

  logic [CAMERA_WL-1:0] viewport_u[3];
  logic [CAMERA_WL-1:0] viewport_v[3];
  logic [CAMERA_WL-1:0] viewport_upper_left[3];

  logic [CAMERA_WL-1:0] pixel_delta_u[3];
  logic [CAMERA_WL-1:0] pixel_delta_v[3];
  logic [CAMERA_WL-1:0] pixel_00_loc[3];
} rt_camera_t;

`endif
