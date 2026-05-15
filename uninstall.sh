#!/bin/sh

##
# Uninstalls Battery Toolkit and its settings.
#
# Copyright (C) 2022 Marvin Häuser. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
##

# Remove the Battery Toolkit daemon.
sudo rm /Library/LaunchDaemons/app.justasimple.battertoolkit.daemon.plist
sudo rm /Library/PrivilegedHelperTools/me.mhaeuser.batterytoolkitd
sudo launchctl remove app.justasimple.battertoolkit.daemon

# Remove the Battery Toolkit daemon data.
sudo defaults delete app.justasimple.battertoolkit.daemon
sudo security authorizationdb remove app.justasimple.battertoolkit.daemon.manage

# Remove the Battery Toolkit Autostart helper.
launchctl remove app.justasimple.battertoolkit.autostart

# Remove the Battery Toolkit app data.
defaults remove app.justasimple.battertoolkit
