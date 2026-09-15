#!/bin/sh

##
# Uninstalls Ampere and its settings.
#
# Copyright (C) 2022 Marvin Häuser. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
##

# Remove the Ampere daemon.
sudo rm /Library/LaunchDaemons/app.justasimple.ampere.daemon.plist
sudo rm /Library/PrivilegedHelperTools/app.justasimple.ampere.daemon
sudo launchctl remove app.justasimple.ampere.daemon

# Remove the Ampere daemon data.
sudo defaults delete app.justasimple.ampere.daemon
sudo security authorizationdb remove app.justasimple.ampere.daemon.manage

# Remove the Ampere Autostart helper.
launchctl remove app.justasimple.ampere.autostart

# Remove the Ampere app data.
defaults remove app.justasimple.ampere
