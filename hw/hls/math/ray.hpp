#pragma once

#include "vec3.hpp"

template <typename T> class ray {
public:
  ray() {}

  ray(const vec3<T> &origin, const vec3<T> &direction)
      : orig(origin), dir(direction) {}

  const vec3<T> &origin() const { return orig; }
  const vec3<T> &direction() const { return dir; }

  vec3<T> at(float t) const { return orig + t * dir; }

private:
  vec3<T> orig;
  vec3<T> dir;
};
