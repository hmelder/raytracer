// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2025 Hugo Melder

#include <cstdint>
#include <hls_stream.h>

#include "camera.hpp"
#include "main.hpp"
#include "math/vec3.hpp"

union cam_u {
  struct camera cam;
  uint32_t buf[CAMERA_STRUCT_LEN];
};

struct state {
  ap_uint<15> image_width;
  ap_uint<15> image_height;
  vec3<sfp> pixel_00_loc;
  vec3<sfp> pixel_delta_u;
  vec3<sfp> pixel_delta_v;
  vec3<sfp> camera_center;
};

struct state convert(struct camera &cam) {
  struct state s;

  sfp pixel_00_loc_fp[3], pixel_delta_u_fp[3], pixel_delta_v_fp[3],
      camera_center_fp[3];
  sfp image_width, image_height;

  ap_int<32> tmp_image_width = cam.image_width;
  ap_int<32> tmp_image_height = cam.image_height;

  RAW_2_FIXED_V(cam.pixel_00_loc, pixel_00_loc_fp);
  RAW_2_FIXED_V(cam.pixel_delta_u, pixel_delta_u_fp);
  RAW_2_FIXED_V(cam.pixel_delta_v, pixel_delta_v_fp);
  RAW_2_FIXED_V(cam.camera_center, camera_center_fp);
  RAW_2_FIXED(tmp_image_width, image_width);
  RAW_2_FIXED(tmp_image_height, image_height);

  s.image_width = image_width;
  s.image_height = image_height;

  s.pixel_00_loc = vec3<sfp>(pixel_00_loc_fp);
  s.pixel_delta_u = vec3<sfp>(pixel_delta_u_fp);
  s.pixel_delta_v = vec3<sfp>(pixel_delta_v_fp);
  s.camera_center = vec3<sfp>(camera_center_fp);

  return s;
}

void myip_v1_0_HLS(hls::stream<pkt> &A, hls::stream<pkt> &B) {
#pragma HLS INTERFACE ap_ctrl_none port = return
#pragma HLS INTERFACE axis port = A
#pragma HLS INTERFACE axis port = B

  union cam_u cam;

recv_loop:
  for (int i = 0; i < CAMERA_STRUCT_LEN; i++) {
    pkt tmp;

    A.read(tmp);
    cam.buf[i] = tmp.data;
  }

  struct state s = convert(cam.cam);

  pkt tmp;
  ap_uint<15> w, h;
send_outer:
  for (int h = 0; h < s.image_height; h++) {
  send_inner:
    for (int w = 0; w < s.image_width; w++) {
      auto pixel_center = s.pixel_00_loc + (sfp(w) * s.pixel_delta_u) +
                          (sfp(h) * s.pixel_delta_v);
      auto ray_direction = pixel_center - s.camera_center;
      FIXED_2_RAW(ray_direction.y(), tmp.data);

      tmp.last = (w == (s.image_width - 1) && (h == (s.image_height - 1)));
      B.write(tmp);
    }
  }
}