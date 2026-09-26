# libopenwch-template

A starting point for WCH QingKe firmware, with
[libopenwch](https://github.com/LrkSeraph/libopenwch) and the optional
[libopenwch-tools](https://github.com/LrkSeraph/libopenwch-tools) flasher as
git submodules.

It contains a `Makefile`, an empty `src/main.c`, and the build rules. Everything
else is yours.

> libopenwch is incubating: pre-1.0, implemented for CH32V00x and CH58x only.

## Quick start

```sh
git clone --recurse-submodules \
    https://github.com/LrkSeraph/libopenwch-template.git my-firmware
cd my-firmware
rm -rf .git && git init          # this is your project, not a fork to track

$EDITOR Makefile                 # PROJECT and DEVICE
$EDITOR src/main.c               # your code
make                             # .elf, .bin, .hex
make flash                       # WCH-Link + minichlink by default
```

If submodules are missing, `git submodule update --init` fetches them, or use
`make OPENWCH_DIR=/path/to/libopenwch`.

## What to change

| Where | What |
|---|---|
| `PROJECT` | output basename (`my_app` → `my_app.elf`) |
| `DEVICE` | exact part number, e.g. `ch32v003f4p6` |
| `CFILES`, `CPPFLAGS` | sources and include paths |
| `src/main.c` | application entry point |

`DEVICE` selects ISA, linker script, and archive. Do not add `-march`/`-mabi`
by hand.

Useful variables: `OPENWCH_DIR`, `OPT`, `CSTD`, `PREFIX`,
`LIBOPENWCH_NOSTDLIB`, `PROGRAMMER`, `MINICHLINK`, `MINICHLINK_FLAGS`,
`WRITE_SECTION`, `WCHLINK`.

## Toolchain

```sh
sudo apt-get install -y gcc-riscv64-unknown-elf
```

The library probes `riscv64-unknown-elf`, `riscv64-none-elf`,
`riscv32-unknown-elf`, `riscv-none-elf`, `riscv64-elf`, `riscv32-elf`; override
with `make PREFIX=...`. If the link fails on `-lc`, use the bundled libc:
`make LIBOPENWCH_NOSTDLIB=1`.

## Flashing

```sh
make flash                      # minichlink
make monitor                    # single-wire debug channel
make unbrick                    # recover a non-answering part
make size
make flash MINICHLINK=~/src/ch32fun/minichlink/minichlink
```

For the companion flasher:

```sh
git submodule update --init tools/wchlink
make wchlink                    # needs libusb-1.0
make flash PROGRAMMER=wchlink
```

`make wchlink` builds `tools/wchlink`; `PROGRAMMER=wchlink` then uses
`tools/wchlink/build/wchlink` or one on `PATH`. The default remains
`minichlink`.

## Layout

```
Makefile              project name, part, sources
src/main.c            application entry point
libopenwch/           library submodule (mk/, ld/, include/, lib/)
tools/wchlink/        optional flasher submodule
.clang-format         house style
.vscode/              editor configuration
```

The build rules are included from the library submodule, so updating the
submodule is enough to pick up fixes.

`main()` is the only symbol the application must provide.

## Licence

The skeleton is derived from libopencm3-template and is LGPL-3.0-or-later; see
`LICENSE` and `NOTICE`. Your application code remains yours.

Not affiliated with Nanjing Qinheng Microelectronics.
