## Dependencies

- Clang
- Verilator
- Google Test (Make sure that `pkg-config -cflags gtest` works)

## Building

```
cmake -B build -G Ninja
ninja -C build
```

### Testing

```
ninja -C build test
```