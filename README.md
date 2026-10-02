# MulleRCore

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

MulleRCore provides platform windows, events and gamepad input via
[raylib](https://github.com/raysan5/raylib). It serves the same role as
MulleGLFW and MulleSDL — a concrete platform backend for MulleUIApplication —
but uses raylib's windowing and input layer instead.



| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleRCore.svg) [![Build Status](https://github.com/MulleUI/MulleRCore/workflows/CI/badge.svg)](//github.com/MulleUI/MulleRCore/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleRCore](https://deepwiki.com/MulleUI/MulleRCore)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-r-core)




### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleRCore to your project:

``` sh
mulle-sde add github:MulleUI/MulleRCore
```

To only add the sources of MulleRCore with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleRCore
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleRCore and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleRCore/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleObjC](https://github.com/mulle-objc/MulleObjC)             | 💎 A collection of Objective-C root classes for mulle-objc
| [MulleUIApplication](https://github.com/MulleUI/MulleUIApplication)             | Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.
| [raylib](https://github.com/raysan5/raylib)             | 
| [mulle-objc-tools](https://github.com/mulle-objc/mulle-objc-tools)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleRCore/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleRCore/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleRCore** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



