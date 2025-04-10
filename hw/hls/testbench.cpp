#include <cmath>
#include <cstdint>
#include <stdio.h>

#include <hls_stream.h>
#include <memory.h>

#include "main.hpp"

#include "camera.hpp"
#include "scene.hpp"

#define EXPECT_NEAR(val1, val2, abs_err)                                       \
  do {                                                                         \
    if (std::fabs((val1) - (val2)) > (abs_err)) {                              \
      std::cerr << "EXPECT_NEAR failed: " << #val1 << " ≈ " << #val2 << " ± " \
                << #abs_err << "\n"                                            \
                << "  Actual: " << (val1) << " vs " << (val2) << "\n";         \
      std::exit(EXIT_FAILURE);                                                 \
    }                                                                          \
  } while (0)

int main() {
  pkt read_output, write_input;
  hls::stream<pkt> S_AXIS;
  hls::stream<pkt> M_AXIS;

  // Create a new scene
  int image_width = 5;
  float aspect_ratio = 1.0;
  float focal_length = 1.0;

  scene s(image_width, aspect_ratio, focal_length);
  int image_height = s.image_height;

  uint32_t *cam_buffer = s.serialised();

  std::vector<uint32_t> actual(image_width * image_height);
  std::vector<uint32_t> expected(image_width * image_height);

  for (int h = 0; h < image_height; h++) {
    for (int w = 0; w < image_width; w++) {
      auto pixel_center = s.pixel_center(w, h);
      auto ray_direction = pixel_center - s.camera_center;
      uint32_t val = FLOAT_2_FIX(ray_direction.y());
      expected.push_back(val);
    }
  }

  // Send data to co-processor
  for (int i = 0; i < CAMERA_STRUCT_LEN; i++) {
    write_input.data = cam_buffer[i];
    write_input.last = 0;
    if (i == NUMBER_OF_INPUT_WORDS - 1) {
      write_input.last = 1;
    }
    S_AXIS.write(write_input);
  }

  std::cout << "Invoke coprocessor" << std::endl;
  myip_v1_0_HLS(S_AXIS, M_AXIS);
  std::cout << "Invoked coprocessor" << std::endl;

  int dim = image_width * image_height;
  bool recv_last = 0;
  for (int i = 0; i < dim; i++) {
    read_output = M_AXIS.read(); // extract one word from the stream
                                 // actual[i] = read_output.data;
    uint32_t val = read_output.data;
    actual.push_back(val);
    if (i == (dim - 1)) {
      recv_last = read_output.last;
    }
  }

  std::cout << "receiveed last: " << recv_last << std::endl;

  /* Reception Complete */

  int success = 1;
  std::cout << " Comparing data" << std::endl;

  for (int i = 0; i < (image_width * image_height); i++) {
    uint32_t a = actual[i];
    uint32_t e = expected[i];

    float a_f = FIX_2_FLOAT(a);
    float e_f = FIX_2_FLOAT(e);

    EXPECT_NEAR(a_f, e_f, 0.00001);
  }

  return 0;
}
