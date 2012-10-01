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
 *  Created on: Dec 28, 2010
 *      Author: Kamanashis Roy
 */

#ifndef SYNC_LOGGER_H_
#define SYNC_LOGGER_H_

#include "core/config.h"
//#include "types_internal.h"

C_CAPSULE_START

enum sync_logtype {
	SYNC_DEBUG,
	SYNC_VERB,
	SYNC_NOTICE,
	SYNC_WARNING,
	SYNC_ERROR,
};

C_CAPSULE_END

#ifdef NO_LOG
#define SYNC_LOG_INIT()
#define SYNC_LOG_DEINIT()
#define SYNC_DEBUG_VERB(x, ...)

#define SYNC_LOG(y, ...)
#define SYNC_LOG_OPP(x)
#else
#ifdef ASTERISK_CHANNEL
#include "ast_logger.h"
#else
#ifdef __EPOC32__
#include "symb_logger.h"
#else
#ifdef  QTGUI_LIBRARY
#include "qt_logger.h"
#else
#ifdef  WIN
#include "win_logger.h"
#else
#ifdef ANDROID_XULTB
#include "android_logger.h"
#else
#include "linux_logger.h"
#endif // ANDROID_XULTB
#endif // WIN
#endif // QT
#endif // SYMBIAN_CLIENT
#endif // ASTERISK_CHANNEL
#endif

#endif /* SYNC_LOGGER_H_ */
