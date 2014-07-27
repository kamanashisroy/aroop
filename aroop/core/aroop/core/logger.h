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

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/config.h"
#endif

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
#ifndef AROOP_CONCATENATED_FILE
#include "ast_logger.h"
#endif
#else
#ifdef __EPOC32__
#ifndef AROOP_CONCATENATED_FILE
#include "symb_logger.h"
#endif
#else
#ifdef  QTGUI_LIBRARY
#ifndef AROOP_CONCATENATED_FILE
#include "qt_logger.h"
#endif
#else
#ifdef  WIN
#ifndef AROOP_CONCATENATED_FILE
#include "win_logger.h"
#endif
#else
#ifdef AROOP_ANDROID
#ifndef AROOP_CONCATENATED_FILE
#include "android_logger.h"
#endif
#else
#ifndef AROOP_CONCATENATED_FILE
#include "aroop/platform/linux/inc/linux_logger.h"
#endif
#endif // ANDROID_XULTB
#endif // WIN
#endif // QT
#endif // SYMBIAN_CLIENT
#endif // ASTERISK_CHANNEL
#endif

#endif /* SYNC_LOGGER_H_ */
