##
## This file is part of the libopenwch template.
##
## Copyright (C) 2025 libopenwch contributors
##
## Derived from libopencm3-template's rules.mk (LGPL-3-or-later), reworked for
## RISC-V and for libopenwch's genlink-based linker script generation.
##
## This library is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this library.  If not, see <http://www.gnu.org/licenses/>.
##

###############################################################################
# A libopenwch application.
#
#	git submodule update --init	# fetch libopenwch and libopenwch-tools
#	make				# build my_app.elf/.bin/.hex
#	make flash			# write it with minichlink
#
# Edit PROJECT and DEVICE below, add your sources to CFILES, and put your code
# in src/.
#
# There are deliberately no build rules in this file.  The compiler, the
# -march/-mabi pair, the linker script and the library archive are all derived
# from DEVICE by $(OPENWCH_DIR)/mk/, which is included at the bottom.  What is
# left here is a description of *your* project: what it is called, which part
# it runs on, and which sources it is made of.
###############################################################################

## The basename of every output file: <PROJECT>.elf, .bin, .hex, .map, .list.
PROJECT		?= my_app

## The exact part number, not the family: ch32v003f4p6 rather than ch32v003.
## The available names are the part patterns in $(OPENWCH_DIR)/ld/devices.data.
DEVICE		?= ch32v003f4p6

## Where libopenwch is.  The default is the submodule next to this Makefile,
## which is why `git clone --recurse-submodules` is the recommended start; a
## value given on the command line or in the environment always wins.
OPENWCH_DIR	?= $(abspath libopenwch)

## Sources, as paths relative to this Makefile.  Your headers live next to them
## and are found automatically by the compiler; `-Isrc` below is there for code
## in a subdirectory that includes them by name.
CFILES		?= src/main.c
AFILES		?=
CXXFILES	?=

OPT		?= -Os
CSTD		?= -std=c99

## A clone made without --recurse-submodules leaves the directory empty.  Say
## so plainly, instead of letting the library's own build fail on a missing
## Makefile further down.
ifeq ($(wildcard $(OPENWCH_DIR)/Makefile),)
$(error libopenwch is not checked out at $(OPENWCH_DIR). If you cloned without \
    --recurse-submodules, run `git submodule update --init`; otherwise pass \
    OPENWCH_DIR=/path/to/libopenwch.)
endif

##
## Toolchain discovery (PREFIX, CC, LD, OBJCOPY, ...) and the device database
## lookup (ARCH_FLAGS, LDSCRIPT, LDLIBS, LIBDEPS).  Both must come before the
## flags below, because those append to what the modules set up.
##
include $(OPENWCH_DIR)/mk/gcc-config.mk
include $(OPENWCH_DIR)/mk/genlink-config.mk

## An included makefile's first target would otherwise become the default goal.
.DEFAULT_GOAL := all

OBJS		= $(CFILES:%.c=%.o)
OBJS		+= $(AFILES:%.S=%.o)
OBJS		+= $(CXXFILES:%.cxx=%.o)

CFLAGS		+= $(OPT) $(CSTD) -g3
CFLAGS		+= -Wall -Wextra -Wshadow -Wundef
CFLAGS		+= -fno-common -mno-relax
CFLAGS		+= -ffunction-sections -fdata-sections
CPPFLAGS	+= -MD -Isrc

##
## -nostartfiles is essential: libopenwch supplies its own reset entry and
## vector table, so the toolchain's crt0 must not be linked in.
##
LDFLAGS		+= -nostartfiles -mno-relax
LDFLAGS		+= -Wl,--gc-sections
LDFLAGS		+= -Wl,-Map=$(PROJECT).map

##
## libc.  By default the toolchain's own newlib is used.  A toolchain built
## without one -- Debian's gcc-riscv64-unknown-elf has none for every
## multilib -- works by setting LIBOPENWCH_NOSTDLIB=1, which links the
## freestanding mini-libc that libopenwch builds alongside the drivers.
##
ifeq ($(LIBOPENWCH_NOSTDLIB),1)
LDFLAGS		+= -nostdlib
LDLIBS		+= $(OPENWCH_DIR)/lib/libopenwch_mini_libc_$(genlink_family).a -lgcc
else
LDFLAGS		+= -Wl,--start-group
LDLIBS		+= -lc -lgcc -lnosys
LDFLAGS		+= -Wl,--end-group
endif

##
## Flashing.
##
## Two programmer tools can drive a WCH-LinkE:
##
##   minichlink   https://github.com/cnlohr/ch32fun -- external, found on PATH,
##                needs no vendor driver, and the default.
##   wchlink      the companion tool in tools/wchlink/, built from the
##                libopenwch-tools submodule.  Building it needs libusb, so a
##                plain clone leaves it unbuilt.
##
## The default is minichlink *on purpose*: wchlink is at milestone 1 and cannot
## flash yet -- its flash subcommand reports "not implemented".  Making it the
## default now would turn a working `make flash` into a failing one, so the
## default flips when its milestone 3 lands.
##
PROGRAMMER	?= minichlink

MINICHLINK	?= minichlink
MINICHLINK_FLAGS ?= -b
WRITE_SECTION	?= flash
WCHLINK		?= $(abspath tools/wchlink/build/wchlink)

ifeq ($(PROGRAMMER),wchlink)

## Prefer the submodule's own build; fall back to one on PATH.
WCHLINK_TOOL	?= $(if $(wildcard $(WCHLINK)),$(WCHLINK),wchlink)

ifeq ($(wildcard $(WCHLINK)),)
ifeq ($(shell command -v wchlink >/dev/null 2>&1 && echo found),)
$(error PROGRAMMER=wchlink, but no wchlink found. Fetch and build the \
    submodule (`git submodule update --init tools/wchlink && make wchlink`), \
    or leave PROGRAMMER at its default and use minichlink.)
endif
endif

## These are recursive (=) on purpose: WRITE_SECTION is defined above.
FLASH_PREFIX	= $(WCHLINK_TOOL) flash
FLASH_SUFFIX	= $(WCHLINK_FLAGS)
MONITOR_CMD	= $(WCHLINK_TOOL) terminal
UNBRICK_CMD	= $(WCHLINK_TOOL) unbrick

else

FLASH_PREFIX	= $(MINICHLINK) -w
FLASH_SUFFIX	= $(WRITE_SECTION) $(MINICHLINK_FLAGS)
MONITOR_CMD	= $(MINICHLINK) -T
UNBRICK_CMD	= $(MINICHLINK) -u

endif

all: $(PROJECT).elf $(PROJECT).bin $(PROJECT).hex

flash: $(PROJECT).bin
	@printf "  FLASH   $< ($(PROGRAMMER))\n"
	$(Q)$(FLASH_PREFIX) $< $(FLASH_SUFFIX)

## printf over the single-wire debug channel.
monitor:
	$(Q)$(MONITOR_CMD)

## Recover a part that stopped answering.
unbrick:
	$(Q)$(UNBRICK_CMD)

## Build the companion flasher from its submodule.  It needs libusb-1.0 and its
## headers; see tools/wchlink/README.
wchlink:
	$(Q)$(MAKE) -C tools/wchlink

size: $(PROJECT).elf
	@$(SIZE) $(PROJECT).elf

clean:
	$(Q)rm -f $(OBJS) $(OBJS:.o=.d) $(PROJECT).elf $(PROJECT).bin \
		$(PROJECT).hex $(PROJECT).map $(PROJECT).list
	## Every device's script, not just the selected one, so that switching
	## DEVICE does not leave a stale linker script behind.
	$(Q)rm -f generated.*.ld

.PHONY: all clean flash monitor unbrick size wchlink

-include $(OBJS:.o=.d)

##
## Build the library on demand.  $(LIBDEPS) is the archive for the part
## selected by DEVICE; when it is missing -- a fresh clone, or a family you
## have not built before -- this builds libopenwch once.  On every later build
## the archive is already there and nothing happens, so a library that has
## changed is picked up with `make -C $(OPENWCH_DIR)` rather than silently
## rebuilt underneath you.
##
$(LIBDEPS):
	@printf "  MAKE    libopenwch\n"
	$(Q)$(MAKE) -C $(OPENWCH_DIR)

##
## The generic rules: %.o from .c/.S/.cxx, %.elf from $(OBJS), and %.bin,
## %.hex, %.list, %.srec from %.elf, plus the linker script generator that
## turns ld/linker.ld.S into generated.$(DEVICE).ld.
##
include $(OPENWCH_DIR)/mk/genlink-rules.mk
include $(OPENWCH_DIR)/mk/gcc-rules.mk
