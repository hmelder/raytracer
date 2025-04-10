#pragma once

#include <random>

inline float random_float() {
  static std::uniform_real_distribution<float> distribution(0.0f, 1.0f);
  static std::mt19937 generator;
  return distribution(generator);
}

inline float random_float(float min, float max) {
  // Returns a random float in [min, max).
  return min + (max - min) * random_float();
}
