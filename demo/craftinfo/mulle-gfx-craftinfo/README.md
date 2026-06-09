# mulle-gfx-craftinfo

Craftinfo for mulle-sde to build [mulle-gfx](//github.com/<|GITHUB_USER|>/mulle-gfx)

``` bash
mulle-sde dependency add --github <|GITHUB_USER|> mulle-gfx
mulle-sde dependency mark mulle-gfx singlephase
# mulle-sde dependency set mulle-gfx aliases mulle-gfx-other
# mulle-sde dependency set mulle-gfx include mulle-gfx-other.h
# mulle-sde environment --global set MULLE_CRAFT_USE_SCRIPTS mulle-gfx-build
```

## Tips

* If you want to define `CFLAGS` use `definition/set/append/CFLAGS` instead of `definition/set/CFLAGS` so that you can still add flags with the environment variable `CFLAGS`. Or use `mulle-sde dependency craftinfo  set --append mulle-gfx CFLAGS "-DX=0`
* use `CPPFLAGS` instead of `CFLAGS` to match C++, C and Objective-C
* you can use `definition/set/append0` to append a string without an intervening space
* you can use `definition/set/remove` to remove a definition
