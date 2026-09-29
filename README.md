# libopenwch-template

Starting point for WCH QingKe firmware, with
[libopenwch](https://github.com/LrkSeraph/libopenwch) and optional
[libopenwch-tools](https://github.com/LrkSeraph/libopenwch-tools) as submodules.
Contains `Makefile`, `src/main.c`, and build rules; everything else is yours.

> libopenwch is incubating: pre-1.0, CH32V00x and CH58x only.

## Quick start

```sh
git clone --recurse-submodules \
    https://github.com/LrkSeraph/libopenwch-template.git my-firmware
cd my-firmware
rm -rf .git && git init
$EDITOR Makefile          # PROJECT, DEVICE
$EDITOR src/main.c
make                      # .elf, .bin, .hex
make flash                # minichlink by default
```

Missing submodules: `git submodule update --init`. Alternative library
checkout: `make OPENWCH_DIR=/path/to/libopenwch`.

## What to change

| Where | What |
|---|---|
| `PROJECT` | output basename |
| `DEVICE` | exact part, e.g. `ch32v003f4p6` |
| `CFILES`, `CPPFLAGS` | sources and include paths |
| `src/main.c` | application entry |

`DEVICE` selects ISA, linker script, and archive. Never add `-march`/`-mabi`.
Useful variables: `OPENWCH_DIR`, `OPT`, `CSTD`, `PREFIX`,
`LIBOPENWCH_NOSTDLIB`, `PROGRAMMER`, `MINICHLINK`, `MINICHLINK_FLAGS`,
`WRITE_SECTION`, `WCHLINK`.

## Toolchain and flashing

```sh
sudo apt-get install -y gcc-riscv64-unknown-elf
make flash
make monitor
make unbrick
make size
```

Library probes common RISC-V prefixes; override with `make PREFIX=...`. If the
link fails on `-lc`, use `make LIBOPENWCH_NOSTDLIB=1`.

For the companion flasher:

```sh
git submodule update --init tools/wchlink
make wchlink                    # needs libusb-1.0
make flash PROGRAMMER=wchlink
```

## Layout

```text
Makefile              project name, part, sources
src/main.c            application entry
libopenwch/           library submodule (mk/, ld/, include/, lib/)
tools/wchlink/        optional flasher submodule
```

Build rules come from the library submodule, so updating it picks up fixes.
`main()` is the only symbol the application must provide.

Licence: LGPL-3.0-or-later, derived from libopencm3-template. Not affiliated
with WCH.
