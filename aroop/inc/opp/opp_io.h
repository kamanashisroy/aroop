/*
 * This file part of aroop.
 *
 * Copyright (C) 2012  Kamanashis Roy
 *
 * Aroop is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MiniIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Aroop.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Created on: Jul 1, 2011
 *      Author: Kamanashis Roy
 */

#ifndef IO_SIGNAL_H_
#define IO_SIGNAL_H_

#ifdef __cplusplus
extern "C" {
#endif


enum {
	IO_ACTION_READ = 128,
	IO_ACTION_WRITE,
	IO_ACTION_CLOSE,
	IO_ACTION_SET,
	IO_ACTION_GET,
	IO_ACTION_DATA_AVAILABLE,
	IO_ACTION_TRAFFIC_TX,
	IO_ACTION_TRAFFIC_RX,
	IO_ACTION_MAX,
};

#ifdef __cplusplus
}
#endif

#endif /* IO_SIGNAL_H_ */
