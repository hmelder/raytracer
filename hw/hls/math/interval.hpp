#pragma once

#include <cmath>
#include <limits>

template <typename T> class interval {
public:
  T min, max;

  interval() : min(+INFINITY), max(-INFINITY) {} // Default interval is empty

  interval(T min, T max) : min(min), max(max) {}

  T size() const { return max - min; }

  bool contains(T x) const { return min <= x && x <= max; }

  bool surrounds(T x) const { return min < x && x < max; }

  T clamp(T x) const {
    if (x < min) {
      return min;
    }
    if (x > max) {
      return max;
    }
    return x;
  }

  static const interval empty, universe;
};

template <typename T>
const interval<T> interval<T>::empty = interval(+INFINITY, -INFINITY);
template <typename T>
const interval<T> interval<T>::universe = interval(-INFINITY, +INFINITY);
