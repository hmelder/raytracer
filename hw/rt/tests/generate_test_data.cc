// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

#include "scene.h"

#include <algorithm>
#include <cstdint>
#include <string>

#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

// https://stackoverflow.com/a/868894
char *getCmdOption(char **begin, char **end, const std::string &option) {
  char **itr = std::find(begin, end, option);
  if (itr != end && ++itr != end) {
    return *itr;
  }
  return 0;
}

bool cmdOptionExists(char **begin, char **end, const std::string &option) {
  return std::find(begin, end, option) != end;
}

std::string to_hex32(uint32_t value) {
  std::stringstream ss;
  ss << std::hex << std::setw(8) << std::setfill('0') << value;
  return ss.str();
}

int main(int argc, char *argv[]) {
  char *focal_length_arg = getCmdOption(argv, argv + argc, "-f");
  char *image_width_arg = getCmdOption(argv, argv + argc, "-i");

  float image_width = 20;
  float focal_length = 1.0f;
  float aspect_ratio = 16.0f / 9.0f;

  if (focal_length_arg) {
    focal_length = std::stof(focal_length_arg);
  }
  if (image_width_arg) {
    image_width = std::stoi(image_width_arg);
  }

  Scene scene(image_width, aspect_ratio, focal_length);

  std::cout << "Created Scene with image_width: " << scene.image_width
            << " and image_height: " << scene.image_height << std::endl;

  // Write Camera
  uint32_t *serialised = scene.serialised();
  std::ofstream file("camera.mem");
  for (int i = 0; i < SCENE_PAYLOAD_SIZE; i++) {
    file << to_hex32(serialised[i]) << std::endl;
  }
  file.close();

  // Write Expected
  // TODO: Change to Actual Pixel data
  std::ofstream pixels("pixels.mem");
  int image_height = scene.image_height;
  for (int h = 0; h < image_height; h++) {
    for (int w = 0; w < image_width; w++) {
      vec3 pixel_center = scene.pixel_center(w, h);
      vec3 ray_direction = pixel_center - scene.camera_center;
      uint32_t fp = FLOAT_2_FIX(ray_direction[0]);
      pixels << to_hex32(fp) << std::endl;
    }
  }
  pixels.close();
  return 0;
}
