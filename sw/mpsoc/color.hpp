#pragma once

#include "interval.hpp"
#include "vec3.hpp"

using color = vec3;

// very simple gammar correction
inline float linear_to_gamma(float linear_component) {
  if (linear_component > 0) {
    return std::sqrt(linear_component);
  }

  return 0;
}

struct rgb {
  uint8_t r;
  uint8_t g;
  uint8_t b;
};

rgb get_rgb(const color &pixel_color) {
  auto r = pixel_color.x();
  auto g = pixel_color.y();
  auto b = pixel_color.z();

  // Apply a linear to gamma transform for gamma 2
  r = linear_to_gamma(r);
  g = linear_to_gamma(g);
  b = linear_to_gamma(b);

  // Translate the [0,1] component values to the byte range [0,255].
  static const interval intensity(0.000f, 0.999f);
  uint8_t rbyte = uint8_t(256 * intensity.clamp(r));
  uint8_t gbyte = uint8_t(256 * intensity.clamp(g));
  uint8_t bbyte = uint8_t(256 * intensity.clamp(b));


  struct rgb s = {.r = rbyte, .g = gbyte, .b = bbyte};
  return s;
}

void write_color(std::ostream &out, const color &pixel_color) {
  auto p = get_rgb(pixel_color);
  // Write out the pixel color components.
  out << unsigned(p.r) << ' ' << unsigned(p.g) << ' ' << unsigned(p.b) << '\n';
}
