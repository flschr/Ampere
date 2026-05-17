/*@file
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

#ifndef _BTPreprocessor_h_
#define _BTPreprocessor_h_

#include <Foundation/NSString.h>

__BEGIN_DECLS

/// The Ampere bundle identifier.
extern const NSString *const BT_APP_ID;

/// The Ampere Service identifier.
extern const NSString *const BT_SERVICE_ID;

/// The Ampere daemon identifier.
extern const NSString *const BT_DAEMON_ID;

/// The Ampere daemon connection name.
extern const NSString *const BT_DAEMON_CONN;

/// The Ampere Autostart identifier.
extern const NSString *const BT_AUTOSTART_ID;

/// The Ampere codesign Common Name.
extern const NSString *const BT_CODESIGN_CN;

__END_DECLS

#endif
