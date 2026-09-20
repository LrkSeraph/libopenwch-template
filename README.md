# libopenwch-template

A starting point for firmware on a WCH QingKe part, with
[libopenwch](https://github.com/LrkSeraph/libopenwch) wired in as a git
submodule.

It is deliberately close to empty.  A `Makefile` that says what your project is
called and which part it runs on, a `main.c` that does nothing yet, and the
library.  Everything else is yours to write.

> **libopenwch is incubating** — pre-1.0, and only the CH32V00x and CH58x
> families are implemented so far.  The library's own README explains what that
> means for you.

## Quick start

```sh
# 1. Copy the skeleton.  The submodule brings libopenwch with it.
git clone --recurse-submodules \
    https://github.com/LrkSeraph/libopenwch-template.git ~/src/my-firmware
cd ~/src/my-firmware

# 2. Make it yours.  This is a starting point, not an upstream to track.
rm -rf .git && git init

# 3. Say what it is and which part it runs on.
$EDITOR Makefile        # PROJECT and DEVICE
$EDITOR main.c

# 4. Build and flash.
make                    # -> my_app.elf, my_app.bin, my_app.hex
make flash              # needs a WCH-Link, see Flashing below
```

The first `make` also builds libopenwch, because the family archive it needs is
not in the submodule yet.  Later builds link against it and do nothing extra.

If you cloned without `--recurse-submodules`, the submodule directory is empty
and `make` stops with a message saying so; `git submodule update --init` fixes
it, and `make OPENWCH_DIR=/path/to/libopenwch` builds against a checkout
somewhere else instead.

## What to change

| Where | What |
|---|---|
| `PROJECT` in the Makefile | basename of every output file (`my_app` → `my_app.elf`, `my_app.bin`, `my_app.hex`) |
| `DEVICE` in the Makefile | the exact part number — `ch32v003f4p6`, not `ch32v003`.  The names are the part patterns in `libopenwch/ld/devices.data` |
| `CFILES` in the Makefile | your C sources, basenames only; objects are built next to them |
| `main.c` | your code |

`DEVICE` is the only thing that decides the ISA, the linker script and which
library archive is linked, so do not add `-march`/`-mabi` by hand: an
application built for a different ISA than the library it links against fails
in ways that are hard to read.  Within a family any part works — building this
for `ch582m`, `ch583m`, `ch584m` or `ch585m` needs nothing but a different
`DEVICE`.

## Layout

```
my-firmware/
├── Makefile              your project: name, part, sources
├── main.c                your code starts here
├── libopenwch/           git submodule — the library, untouched
│   ├── mk/               the build rules this Makefile includes
│   ├── ld/devices.data   the device database
│   ├── include/          the headers
│   └── lib/              the archives, built on first `make`
├── .clang-format         the house style
├── .vscode/              optional editor configuration
├── .github/workflows/    a CI job that builds this skeleton
├── README.md  NOTICE  LICENSE
└── .gitignore
```

The build rules are not copied into this repository.  `Makefile` includes
`libopenwch/mk/gcc-config.mk`, `genlink-config.mk` and their `-rules.mk`
counterparts, so a fix or a new family reaches you by updating the submodule
rather than by merging a diff into your build files.  `libopenwch/mk/README`
documents the whole contract; the variables worth knowing straight away:

| Variable | Default | Meaning |
|---|---|---|
| `PROJECT` | `my_app` | output basename |
| `DEVICE` | `ch32v003f4p6` | the part number |
| `OPENWCH_DIR` | `./libopenwch` | where libopenwch is |
| `OPT` | `-Os` | optimisation level |
| `CSTD` | `-std=c99` | C standard |
| `PREFIX` | auto-detected | toolchain prefix without the trailing `-` |
| `LIBOPENWCH_NOSTDLIB` | — | set to `1` to link the bundled mini-libc instead of newlib |
| `MINICHLINK` | `minichlink` | the flasher binary |

## Toolchain

```sh
sudo apt-get install -y gcc-riscv64-unknown-elf
```

`libopenwch/mk/gcc-config.mk` probes `riscv64-unknown-elf`, `riscv64-none-elf`,
`riscv32-unknown-elf`, `riscv-none-elf`, `riscv64-elf` and `riscv32-elf`, in
that order, and stops with an explanation if none is found.  Override it with:

```sh
make PREFIX=/opt/xpack-riscv-none-elf-gcc/bin/riscv-none-elf
```

`riscv64-linux-gnu-` is not probed: its crt and libc conventions break
bare-metal builds.

Some distributions build this toolchain without newlib for the smaller
multilibs.  If the link fails on `-lc`, build with the library's freestanding
mini-libc instead:

```sh
make LIBOPENWCH_NOSTDLIB=1
```

## Flashing

[minichlink](https://github.com/cnlohr/ch32fun) drives the WCH-Link and the
built-in USB ISP bootloader.  It needs no vendor driver and works on Linux,
Windows and macOS.

```sh
make flash                      # write the internal flash
make monitor                    # printf over the single-wire debug channel
make unbrick                    # recover a part that stopped answering
make size                       # section sizes of the ELF
```

Point it at the binary if it is not on `PATH`:

```sh
make flash MINICHLINK=~/src/ch32fun/minichlink/minichlink
```

A companion flasher written for this project, `wchlink` from
[libopenwch-tools](https://github.com/LrkSeraph/libopenwch-tools), is on the
way; it is not wired into this Makefile yet because it cannot flash at its
current milestone.

## Where to go next

* **Worked examples of every implemented peripheral** —
  [libopenwch-examples](https://github.com/LrkSeraph/libopenwch-examples) has
  five complete programs (GPIO, UART, Bluetooth LE advertising) with the same
  build rules this skeleton uses.  Reading one is faster than deriving a clock
  tree from the reference manual.
* **The library API** — `libopenwch/include/libopenwch/`, and the per-family
  READMEs under `libopenwch/lib/`.
* **How the library itself is organised** — `libopenwch/project.md`.

`main()` is the only symbol you have to provide.  The reset vector, the vector
table, `.data`/`.bss` initialisation and the entry point all come from
libopenwch's QingKe core layer, which is why there is no startup assembly in
this repository.

## Licence

The Makefile is derived from
[libopencm3-template](https://github.com/bonedaddy/libopencm3-template) and is
LGPL-3.0-or-later, like libopenwch; see `LICENSE` and `NOTICE`.

**Your project is yours.**  Code you write here is your own work under whatever
terms you choose — the LGPL covers the skeleton, not what you build with it.
This is the same intent as libopencm3's usual clarification about applications
that link the library.

Nothing here is affiliated with or endorsed by Nanjing Qinheng Microelectronics.
