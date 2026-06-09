# raylib-craftinfo

Craftinfo for mulle-sde to build [raylib](//github.com/<|GITHUB_USER|>/raylib)

``` bash
mulle-sde dependency add --github <|GITHUB_USER|> raylib
mulle-sde dependency mark raylib singlephase
# mulle-sde dependency set raylib aliases raylib-other
# mulle-sde dependency set raylib include raylib-other.h
# mulle-sde environment --global set MULLE_CRAFT_USE_SCRIPTS raylib-build
```

## Tips

* If you want to define `CFLAGS` use `definition/set/append/CFLAGS` instead of `definition/set/CFLAGS` so that you can still add flags with the environment variable `CFLAGS`. Or use `mulle-sde dependency craftinfo  set --append raylib CFLAGS "-DX=0`
* use `CPPFLAGS` instead of `CFLAGS` to match C++, C and Objective-C
* you can use `definition/set/append0` to append a string without an intervening space
* you can use `definition/set/remove` to remove a definition
