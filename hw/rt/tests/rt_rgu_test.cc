// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vrt_rgu_wrapper.h"
#include "vec3.h"
#include "gtest/gtest.h"

// Keep in sync with rt_camera_t.svh
static const int CAMERA_IW = 14;
static const int CAMERA_QW = 18;
static const int CAMERA_2_QW = 262144;
static const int CAMERA_WL = 32;

#define float2fix(a) ((signed int)(a * CAMERA_2_QW))
#define fix2float(a) ((float)((signed int)a) / CAMERA_2_QW)

#define VEC_TO_FIX(vec, a)                                                     \
  a[0] = float2fix(vec[0]);                                                    \
  a[1] = float2fix(vec[1]);                                                    \
  a[2] = float2fix(vec[2]);

#define FIX_TO_VEC(a) vec3(fix2float(a[0]), fix2float(a[1]), fix2float(a[2]))

#define EXPECT_VEC_EQUAL(vec1, vec2)                                           \
  EXPECT_FLOAT_EQ(vec1.x(), vec2.x());                                         \
  EXPECT_FLOAT_EQ(vec1.y(), vec2.y());                                         \
  EXPECT_FLOAT_EQ(vec1.z(), vec2.z());

#define EXPECT_VEC_NEAR(vec1, vec2, abs_err)                                   \
  EXPECT_NEAR(vec1.x(), vec2.x(), abs_err);                                    \
  EXPECT_NEAR(vec1.y(), vec2.y(), abs_err);                                    \
  EXPECT_NEAR(vec1.z(), vec2.z(), abs_err);

namespace {

class RtRGUTest : public testing::Test {};

TEST_F(RtRGUTest, Basic) {
  std::unique_ptr<Vrt_rgu_wrapper> dut = std::make_unique<Vrt_rgu_wrapper>();

  float aspect_ratio = 16.0f / 9.0f;
  float image_width = 400.0f;
  float image_height = int(image_width / aspect_ratio);

  float focal_length = 1.0f;
  float viewport_height = 2.0f;
  float viewport_width = viewport_height * (image_width / image_height);

  vec3 camera_center(0, 0, 0);

  // Calculate the vectors across the horizontal and down the vertical viewport
  // edges.
  vec3 viewport_u(viewport_width, 0, 0);
  vec3 viewport_v(0, -viewport_height, 0);

  // Calculate the horizontal and vertical delta vectors from pixel to pixel.
  vec3 pixel_delta_u = viewport_u / image_width;
  vec3 pixel_delta_v = viewport_v / image_height;

  // Calculate the location of the upper left pixel.
  vec3 viewport_upper_left = camera_center - vec3(0, 0, focal_length) -
                             viewport_u / 2 - viewport_v / 2;

  vec3 pixel_00_loc =
      viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

  // Populate verilated struct
  dut->cam.__PVT__aspect_ratio = float2fix(aspect_ratio);
  dut->cam.__PVT__image_width = float2fix(image_width);
  dut->cam.__PVT__image_height = float2fix(image_height);

  dut->cam.__PVT__focal_length = float2fix(focal_length);
  dut->cam.__PVT__viewport_height = float2fix(viewport_height);
  dut->cam.__PVT__viewport_width = float2fix(viewport_width);

  VEC_TO_FIX(camera_center, dut->cam.__PVT__camera_center)
  VEC_TO_FIX(viewport_u, dut->cam.__PVT__viewport_u)
  VEC_TO_FIX(viewport_v, dut->cam.__PVT__viewport_v)
  VEC_TO_FIX(viewport_upper_left, dut->cam.__PVT__viewport_upper_left);
  VEC_TO_FIX(pixel_delta_u, dut->cam.__PVT__pixel_delta_u)
  VEC_TO_FIX(pixel_delta_v, dut->cam.__PVT__pixel_delta_v)
  VEC_TO_FIX(pixel_00_loc, dut->cam.__PVT__pixel_00_loc);

  for (int y = 0; y < int(image_height); y++) {
    for (int x = 0; x < int(image_width); x++) {
      // Validation
      vec3 pixel_center =
          pixel_00_loc + (x * pixel_delta_u) + (y * pixel_delta_v);
      vec3 ray_direction = pixel_center - camera_center;

      // RTL test
      dut->x = x << CAMERA_QW;
      dut->y = y << CAMERA_QW;
      dut->eval();

      vec3 origin = FIX_TO_VEC(dut->ray_origin);
      vec3 direction = FIX_TO_VEC(dut->ray_direction);

      EXPECT_VEC_EQUAL(origin, camera_center);
      EXPECT_VEC_NEAR(direction, ray_direction, 0.0005);
    }
  }
}

} // namespace
