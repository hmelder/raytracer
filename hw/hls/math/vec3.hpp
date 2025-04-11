#ifndef VEC3_H
#define VEC3_H

#include <iostream>

template <typename T> class vec3 {
public:
  T e[3];

  vec3() : e{0, 0, 0} {}
  vec3(T e0, T e1, T e2) : e{e0, e1, e2} {}
  vec3(T arr[3]) : e{arr[0], arr[1], arr[2]} {}

  T x() const { return e[0]; }
  T y() const { return e[1]; }
  T z() const { return e[2]; }

  vec3 operator-() const { return vec3(-e[0], -e[1], -e[2]); }
  T operator[](int i) const { return e[i]; }
  T &operator[](int i) { return e[i]; }

  vec3 &operator+=(const vec3 &v) {
    e[0] += v.e[0];
    e[1] += v.e[1];
    e[2] += v.e[2];
    return *this;
  }

  vec3 &operator*=(T t) {
    e[0] *= t;
    e[1] *= t;
    e[2] *= t;
    return *this;
  }

  vec3 &operator/=(T t) { return *this *= 1 / t; }
};

// Vector Utility Functions

template <typename T>
inline std::ostream &operator<<(std::ostream &out, const vec3<T> &v) {
  return out << v.e[0] << ' ' << v.e[1] << ' ' << v.e[2];
}
template <typename T>
inline vec3<T> operator+(const vec3<T> &u, const vec3<T> &v) {
  return vec3<T>(u.e[0] + v.e[0], u.e[1] + v.e[1], u.e[2] + v.e[2]);
}
template <typename T>
inline vec3<T> operator-(const vec3<T> &u, const vec3<T> &v) {
  return vec3<T>(u.e[0] - v.e[0], u.e[1] - v.e[1], u.e[2] - v.e[2]);
}
template <typename T>
inline vec3<T> operator*(const vec3<T> &u, const vec3<T> &v) {
  return vec3<T>(u.e[0] * v.e[0], u.e[1] * v.e[1], u.e[2] * v.e[2]);
}
template <typename T> inline vec3<T> operator*(T t, const vec3<T> &v) {
  return vec3<T>(t * v.e[0], t * v.e[1], t * v.e[2]);
}
template <typename T> inline vec3<T> operator*(const vec3<T> &v, T t) {
  return t * v;
}
template <typename T> inline vec3<T> operator/(const vec3<T> &v, T t) {
  return (1 / t) * v;
}
template <typename T> inline T dot(const vec3<T> &u, const vec3<T> &v) {
  return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
}
template <typename T> inline vec3<T> cross(const vec3<T> &u, const vec3<T> &v) {
  return vec3<T>(u.e[1] * v.e[2] - u.e[2] * v.e[1],
                 u.e[2] * v.e[0] - u.e[0] * v.e[2],
                 u.e[0] * v.e[1] - u.e[1] * v.e[0]);
}

#endif