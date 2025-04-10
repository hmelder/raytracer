#pragma once

#include <cinttypes>

#define CAMERA_STRUCT_LEN 27
struct __attribute__((packed)) camera {
  uint32_t aspect_ratio;
  uint32_t image_width;
  uint32_t image_height; // int(image_width / aspect_ratio)

  uint32_t focal_length;
  uint32_t viewport_height;
  uint32_t viewport_width; // viewport_height * (image_width/image_height);

  uint32_t viewport_u[3];
  uint32_t viewport_v[3];
  uint32_t viewport_upper_left[3];

  uint32_t camera_center[3];
  uint32_t pixel_delta_u[3];
  uint32_t pixel_delta_v[3];
  uint32_t pixel_00_loc[3];
};
