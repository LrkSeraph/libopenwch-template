/*
 * This file is part of the libopenwch template.
 *
 * Copyright (C) 2025 libopenwch contributors
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * The application entry point.
 *
 * Everything that happens before this function -- the reset vector, the vector
 * table, .data/.bss initialisation and the call into main() -- comes from
 * libopenwch's QingKe core layer, so a project of your own only has to provide
 * main().
 *
 * This file deliberately touches no peripheral, which is what makes it build
 * for any part you put in DEVICE, whatever family that part belongs to.  Write
 * your own code here and list any extra sources in CFILES in the Makefile.
 *
 * For worked examples of each peripheral -- a GPIO, a UART, a Bluetooth LE
 * advertiser -- see the libopenwch-examples repository; there is no reason to
 * rediscover the setup sequence of a clock tree from scratch.
 */

int main(void) {
	volatile unsigned int heartbeat = 0;

	while (1) {
		heartbeat++;
	}
}
