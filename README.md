# soulver-cpp

Simple C++ bindings for the [SoulverCore](https://github.com/soulverteam/SoulverCore) Swift library.

# Build

The `SoulverCore` library is closed-source and distributed as a shared library.

This repository contains a copy of this library, originally distributed by the [Flare](https://github.com/ByteAtATime/flare) project.

We build the `SoulverWrapper` Swift library which exposes C bindings we can call from C++ code.

We also include and install a small header-only library to interface with the C ABI: the so-called bindings.

## Prerequisites

- A working swift toolchain for Swift >= 6.1.0 (required at compile time and runtime).
- [nlohmann/json](https://github.com/nlohmann/json) library, if you want to use the header-only library.

## Build

```
make
```

# Installation

```
sudo make install
```

> [!WARNING]
> Please make sure that `/usr/local/lib` is in `$LD_LIBRARY_PATH` and `/usr/local/share` is in `$XDG_DATA_DIRS` or Vicinae may not be able to find `libSoulverWrapper.so` or its resources.

If all of the above went well, you should be able to build the example repl:

```
make repl
```

Or you can build this example program:

```cpp
#include <iostream>
#include <print>
#include <soulver-cpp/core.hpp>

int main() {
  SoulverCore::Calculator calc;
  auto res = calc.calculate("time in ny in 2 hrs in utc");

  if (!res) {
    std::println(std::cerr, "Error: {}", res.error().error);
    return 1;
  }

  auto data = res.value();

  std::println("{} ({})", data.value, data.type);
}
```

Compile with:

```bash
g++ main.cpp -lSoulverWrapper -o test
```

# Vicinae usage

Newer versions of Vicinae will try to load the `libSoulverWrapper.so` shared library from standard system locations. If it succeeds, then the SoulverCore wrapper will become
selectable from the calculator extension's preferences.

Unless manually changed, `SoulverCore` will **not** be selected as the default backend.

# Acknowledgments

Thanks to the [Flare](https://github.com/ByteAtATime/flare) project for the `SoulverWrapper` and the Raycast currency provider: they made making these bindings way easier.
