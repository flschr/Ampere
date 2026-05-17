//
// Copyright (C) 2026 Marvin Haeuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation

internal struct BTAboutInfo {
    static let websiteURL = URL(string: "https://justasimple.app/ampere")!
    static let privacyURL = URL(string: "https://justasimple.app/privacy")!

    let appName: String
    let version: String

    static var current: Self {
        Self(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) {
        self.appName = Self.infoString(
            for: "CFBundleDisplayName",
            in: infoDictionary
        ) ?? Self.infoString(
            for: "CFBundleName",
            in: infoDictionary
        ) ?? "Ampere"

        self.version = Self.infoString(
            for: "CFBundleShortVersionString",
            in: infoDictionary
        ) ?? BTLocalization.Settings.About.unknownValue
    }

    var versionText: String {
        String(
            format: BTLocalization.Settings.About.versionFormat,
            self.version
        )
    }

    private static func infoString(
        for key: String,
        in infoDictionary: [String: Any]
    ) -> String? {
        guard let value = infoDictionary[key] as? String, !value.isEmpty else {
            return nil
        }

        return value
    }

    static let licenseText = """
    BSD 3-Clause License

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    Attribution

    Battery Toolkit components
    Copyright (C) 2022, Marvin H\u{00E4}user
    All rights reserved.
    """
}
