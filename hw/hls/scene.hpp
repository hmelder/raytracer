#pragma once

#include "camera.hpp"
#include "math/vec3.hpp"
#include "parameters.hpp"

#define FLOAT_2_FIX(a) ((signed int)(a * FP_2_POW_QW))
#define FIX_2_FLOAT(a) ((float)((signed int)a) / FP_2_POW_QW)
#define VEC_2_FIX(vec, a)                                                      \
  a[0] = FLOAT_2_FIX(vec[0]);                                                  \
  a[1] = FLOAT_2_FIX(vec[1]);                                                  \
  a[2] = FLOAT_2_FIX(vec[2]);

#define ASSIGN_RAW_VEC(A, B)                                                   \
  A[0] = B[0];                                                                 \
  A[1] = B[1];                                                                 \
  A[2] = B[2];

class scene {
public:
  // Instance Variables
  float image_width;
  float image_height;
  float viewport_height;
  float viewport_width;
  float aspect_ratio;
  float focal_length;

  vec3<float> camera_center;
  vec3<float> viewport_u;
  vec3<float> viewport_v;
  vec3<float> viewport_upper_left;

  vec3<float> pixel_delta_u;
  vec3<float> pixel_delta_v;
  vec3<float> pixel_00_loc;

  scene(float image_width, float aspect_ratio, float focal_length)
      : image_width(image_width), aspect_ratio(aspect_ratio),
        focal_length(focal_length) {

    image_height = int(image_width / aspect_ratio);
    if (image_height < 1) {
      image_height = 1;
    }
    viewport_height = 2.0f;
    viewport_width = viewport_height * (image_width / image_height);

    camera_center = vec3<float>(0, 0, 0);

    // Calculate the vectors across the horizontal and down the vertical
    // viewport edges.
    viewport_u = vec3<float>(viewport_width, 0, 0);
    viewport_v = vec3<float>(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    pixel_delta_u = viewport_u / image_width;
    pixel_delta_v = viewport_v / image_height;

    // Calculate the location of the upper left pixel.
    viewport_upper_left = camera_center - vec3<float>(0, 0, focal_length) -
                          viewport_u / 2.0f - viewport_v / 2.0f;

    pixel_00_loc = viewport_upper_left + 0.5f * (pixel_delta_u + pixel_delta_v);

    cam.aspect_ratio = FLOAT_2_FIX(aspect_ratio);
    cam.image_width = FLOAT_2_FIX(image_width);
    cam.image_height = FLOAT_2_FIX(image_height);

    cam.focal_length = FLOAT_2_FIX(focal_length);
    cam.viewport_height = FLOAT_2_FIX(viewport_height);
    VEC_2_FIX(camera_center, cam.camera_center);

    VEC_2_FIX(viewport_u, cam.viewport_u);
    VEC_2_FIX(viewport_v, cam.viewport_v);
    VEC_2_FIX(viewport_upper_left, cam.viewport_upper_left);

    VEC_2_FIX(pixel_delta_u, cam.pixel_delta_u);
    VEC_2_FIX(pixel_delta_v, cam.pixel_delta_v);
    VEC_2_FIX(pixel_00_loc, cam.pixel_00_loc);
  }

  uint32_t *serialised() { return (uint32_t *)&cam; }

  struct camera raw_camera() {
    return cam;
  }

  vec3<float> pixel_center(int x, int y) {
    return pixel_00_loc + (float(x) * pixel_delta_u) +
           (float(y) * pixel_delta_v);
  }

private:
  struct camera cam;
};