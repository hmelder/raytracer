// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2024 Hugo Melder

#include <cstdint>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <memory>

#include "Vcoprocessor.h"
#include "vec3.h"
#include "gtest/gtest.h"

#define SCENE_PAYLOAD_SIZE 27
#define FRAGMENT_SIZE 3
#define DUMMY_DATA 0xCAFEBABE

#pragma mark - Scene Properties

// Keep in sync with rt_camera_t.svh
static const int CAMERA_IW = 14;
static const int CAMERA_QW = 18;
static const int CAMERA_2_QW = 262144;
static const int CAMERA_WL = 32;

#define float2fix(a) ((signed int)(a * CAMERA_2_QW))
#define fix2float(a) ((float)((signed int)a) / CAMERA_2_QW)
#define vec2fix(vec, a)                                                        \
  a[0] = float2fix(vec[0]);                                                    \
  a[1] = float2fix(vec[1]);                                                    \
  a[2] = float2fix(vec[2]);

class Scene {
public:
  // Keep in sync with hw/rt/rt_camera_t.svh
  struct camera {
    uint32_t aspect_ratio;
    uint32_t image_width;
    uint32_t image_height; // int(image_width / aspect_ratio)

    uint32_t focal_length;
    uint32_t viewport_height;
    uint32_t viewport_width; // viewport_height * (image_width/image_height);
    uint32_t camera_center[3];

    uint32_t viewport_u[3];
    uint32_t viewport_v[3];
    uint32_t viewport_upper_left[3];

    uint32_t pixel_delta_u[3];
    uint32_t pixel_delta_v[3];
    uint32_t pixel_00_loc[3];
  };

  static_assert(sizeof(camera) / sizeof(uint32_t) == SCENE_PAYLOAD_SIZE,
                "Camera struct not in sync with rtl");

  // Instance Variables
  float image_width;
  float image_height;
  float viewport_height;
  float viewport_width;
  float aspect_ratio;
  float focal_length;

  vec3 camera_center;
  vec3 viewport_u;
  vec3 viewport_v;
  vec3 viewport_upper_left;

  vec3 pixel_delta_u;
  vec3 pixel_delta_v;
  vec3 pixel_00_loc;

  Scene(float image_width, float aspect_ratio, float focal_length)
      : image_width(image_width), aspect_ratio(aspect_ratio),
        focal_length(focal_length) {

    image_height = int(image_width / aspect_ratio);
    viewport_height = 2.0f;
    viewport_width = viewport_height * (image_width / image_height);

    camera_center = vec3(0, 0, 0);

    // Calculate the vectors across the horizontal and down the vertical
    // viewport edges.
    viewport_u = vec3(viewport_width, 0, 0);
    viewport_v = vec3(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    pixel_delta_u = viewport_u / image_width;
    pixel_delta_v = viewport_v / image_height;

    // Calculate the location of the upper left pixel.
    viewport_upper_left = camera_center - vec3(0, 0, focal_length) -
                          viewport_u / 2 - viewport_v / 2;

    pixel_00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);

    cam.aspect_ratio = float2fix(aspect_ratio);
    cam.image_width = float2fix(image_width);
    cam.image_height = float2fix(image_height);

    cam.focal_length = float2fix(focal_length);
    cam.viewport_height = float2fix(viewport_height);
    vec2fix(camera_center, cam.camera_center);

    vec2fix(viewport_u, cam.viewport_u);
    vec2fix(viewport_v, cam.viewport_v);
    vec2fix(viewport_upper_left, cam.viewport_upper_left);

    vec2fix(pixel_delta_u, cam.pixel_delta_u);
    vec2fix(pixel_delta_v, cam.pixel_delta_v);
    vec2fix(pixel_00_loc, cam.pixel_00_loc);
  }

  uint32_t *serialised() { return (uint32_t *)&cam; }

private:
  struct camera cam;
};

#pragma mark - Clock Generation

static const int CLOCK_PERIOD = 10;
static const int CLOCK_HALF_PERIOD = 5;

// Keep tlast from the previous clock cycle
static int m_axis_tlast_prev = 0;

static void tick(std::shared_ptr<Vcoprocessor> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace) {
  // Save tlast
  m_axis_tlast_prev = dut->m_axis_tlast;

  // Cycle the clock
  dut->aclk ^= 1;
  dut->eval();
  m_trace->dump(Verilated::time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);

  dut->aclk ^= 1;
  dut->eval();
  m_trace->dump(Verilated::time());
  Verilated::timeInc(CLOCK_HALF_PERIOD);
}
static void tick(std::shared_ptr<Vcoprocessor> dut,
                 std::shared_ptr<VerilatedVcdC> m_trace, int cycles) {
  for (int i = 0; i < cycles; i++) {
    tick(dut, m_trace);
  }
}

#pragma mark - Unit Test

namespace {

class CoprocessorTest : public testing::Test {};

TEST_F(CoprocessorTest, Basic) {
  std::shared_ptr<Vcoprocessor> dut = std::make_shared<Vcoprocessor>();
  std::shared_ptr<VerilatedVcdC> trace = std::make_shared<VerilatedVcdC>();

  int send_counter = 0;
  int recv_counter = 0;

  Verilated::traceEverOn(true);

  // Register trace object
  dut->trace(trace.get(), 10);
  trace->open("coprocessor_waveform.vcd");

  // Initial AXIS Configuration
  dut->s_axis_tvalid = 0;
  dut->s_axis_tlast = 0;
  dut->m_axis_tready = 0;

  // Reset Coprocessor
  dut->resetn = 0;     // Assert reset (active low)
  tick(dut, trace, 2); // Hold reset for 2 clock cycles
  dut->resetn = 1;     // Deassert reset
  tick(dut, trace);

  // Get Scene
  Scene scene(400.0f, 16.0f / 9.0f, 1.0f);
  uint32_t *serialised_scene = scene.serialised();

  // Send Camera Configuration
  dut->s_axis_tvalid = 1;
  while (send_counter < SCENE_PAYLOAD_SIZE) {
    if (dut->s_axis_tready) {
      dut->s_axis_tdata = serialised_scene[send_counter];

      if (send_counter == SCENE_PAYLOAD_SIZE - 1) {
        dut->s_axis_tlast = 1;
      }

      send_counter += 1;
    }
    tick(dut, trace);
  }
  dut->s_axis_tvalid = 0;
  dut->s_axis_tlast = 0;

  EXPECT_EQ(send_counter, SCENE_PAYLOAD_SIZE);

  // Receive Fragment
  dut->m_axis_tready = 1;
  int recv_cycles = 0;
  int x = 0;
  int y = 0;
  int image_width = int(scene.image_width);
  int image_height = int(scene.image_height);
  const int max_receive_cycles = 1000000;
  while ((dut->m_axis_tlast | !m_axis_tlast_prev) &&
         (recv_cycles < max_receive_cycles)) {
    if (dut->m_axis_tvalid) {
      recv_counter += 1;

      // Validation
      vec3 pixel_center = scene.pixel_00_loc + (x * scene.pixel_delta_u) +
                          (y * scene.pixel_delta_v);
      vec3 ray_direction = pixel_center - scene.camera_center;

      EXPECT_NEAR(fix2float(dut->m_axis_tdata), ray_direction[0], 0.0005);

      // Image Coordinate Handling
      if (x == image_width - 1 && y == image_height - 1) { // Done
      } else if (x == image_width - 1) {
        x = 0;
        y += 1;
      } else {
        x += 1;
      }
    }

    tick(dut, trace);
    recv_cycles += 1;
  }
  dut->m_axis_tready = 0;

  EXPECT_FALSE(recv_counter > image_width * image_height)
      << "Received more words in transaction than allowed";

  std::cout << "recv_cycles: " << recv_cycles << std::endl;

  // EXPECT_EQ(recv_counter, FRAGMENT_SIZE);
}

} // namespace