#pragma once

#include "interval.hpp"
#include "ray.hpp"

class material;

class hit_record {
public:
  vec3f p;
  vec3f normal;
  std::shared_ptr<material> mat;
  float t;
  bool front_face;

  void set_face_normal(const ray &r, const vec3f &outward_normal) {
    // Sets the hit record normal vector.
    // NOTE: the parameter `outward_normal` is assumed to have unit length.

    front_face = dot(r.direction(), outward_normal) < 0;
    normal = front_face ? outward_normal : -outward_normal;
  }
};

class hittable {
public:
  virtual ~hittable() = default;

  virtual bool hit(const ray &r, interval ray_t, hit_record &rec) const = 0;
};
