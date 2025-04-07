#pragma once

#include <gtest/gtest.h>

#include "scene.h"

#define EXPECT_VEC_NEAR(RAW, B, err)                                           \
  EXPECT_NEAR(FIX_2_FLOAT(RAW[0]), B[0], err);                                 \
  EXPECT_NEAR(FIX_2_FLOAT(RAW[1]), B[1], err);                                 \
  EXPECT_NEAR(FIX_2_FLOAT(RAW[2]), B[2], err);