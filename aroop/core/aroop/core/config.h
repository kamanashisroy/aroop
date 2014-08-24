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
 *      Author: Kamanashis Roy
 */

#ifndef XULTB_CORE_CONFIG_H
#define XULTB_CORE_CONFIG_H

#define COMPONENT_SCALABILITY 2

//#ifndef AROOP_CONCATENATED_FILE
#ifdef ASTERISK_CHANNEL
#include "ast_config.h"
#elif defined(QTGUI_LIBRARY)
#include "qt_config.h"
#elif defined(__EPOC32__)
#include "symb_config.h"
#elif defined(WIN)
#include "win_config.h"
#elif defined(AROOP_ANDROID)
#include "android_config.h"
#elif defined(RASPBERRY_PI_BARE_METAL)
#include "raspberry_pi_bare_metal_config.h"
#else
#include "aroop/platform/linux/linux_config.h"
#endif
//#endif // AROOP_CONCATENATED_FILE

#ifndef AROOP_CONCATENATED_FILE
#include "aroop/core/decorator.h"
#endif

#define pointer_arith_add_byte(x,y) ({((SYNC_UWORD8_T*)(x))+y;})
#define pointer_arith_sub_byte(x,y) ({((SYNC_UWORD8_T*)(x))-y;})

#ifndef AROOP_MODULE_NAME
#define AROOP_MODULE_NAME "aroop"
#endif

#ifndef AROOP_MAIN_ENTRY_POINT
#define AROOP_MAIN_ENTRY_POINT main
#endif

#endif //XULTB_CONFIG_H
