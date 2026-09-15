//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import ObjectiveC.runtime
import os.log

@MainActor
internal final class BTSystemChargeLimitClient {
    struct State: Equatable {
        let enabled: Bool
        let limit: UInt8
    }

    private typealias BoolCall = @convention(c) (AnyObject, Selector) -> Bool
    private typealias ErrorBoolCall = @convention(c) (
        AnyObject,
        Selector,
        AutoreleasingUnsafeMutablePointer<NSError?>
    ) -> Bool
    private typealias ErrorByteCall = @convention(c) (
        AnyObject,
        Selector,
        AutoreleasingUnsafeMutablePointer<NSError?>
    ) -> UInt8
    private typealias ErrorUInt64Call = @convention(c) (
        AnyObject,
        Selector,
        AutoreleasingUnsafeMutablePointer<NSError?>
    ) -> UInt64
    private typealias SetByteCall = @convention(c) (
        AnyObject,
        Selector,
        UInt8,
        AutoreleasingUnsafeMutablePointer<NSError?>
    ) -> Bool
    let availableLimits: [UInt8]

    private let client: AnyObject
    private(set) var originalState: State

    static func make() -> BTSystemChargeLimitClient? {
        guard let client = self.loadClient() else {
            return nil
        }

        guard let wrapper = BTSystemChargeLimitClient(client: client),
              wrapper.isSupported(),
              !wrapper.availableLimits.isEmpty
        else {
            return nil
        }

        return wrapper
    }

    private init?(client: AnyObject) {
        self.client = client
        self.availableLimits = Self.readAvailableLimits(client: client)
        self.originalState = State(enabled: false, limit: 100)
        guard let originalState = self.readState() else {
            return nil
        }
        self.originalState = originalState
    }

    func apply(limit: UInt8) -> Bool {
        guard self.availableLimits.contains(limit) else {
            return false
        }
        let desiredState = State(enabled: limit < 100, limit: limit)
        if self.readState() == desiredState {
            return true
        }

        guard self.callSetByte("setMCLLimit:error:", value: limit) else {
            return false
        }
        if limit == 100 {
            guard let state = self.readState() else {
                return false
            }
            return state == desiredState
        }
        guard self.callErrorBool("enableMCL:") else {
            return false
        }

        guard let state = self.readState() else {
            return false
        }
        return state == desiredState
    }

    func restoreOriginalState() -> Bool {
        if self.readState() == self.originalState {
            return true
        }
        guard self.callSetByte(
            "setMCLLimit:error:",
            value: self.originalState.limit
        ) else {
            return false
        }

        let restored = self.originalState.enabled ?
            self.callErrorBool("enableMCL:") :
            self.callErrorBool("disableMCL:")
        return restored && self.readState() == self.originalState
    }

    private func isSupported() -> Bool {
        self.callBool("isMCLSupported")
    }

    private func readState() -> State? {
        var error: NSError?
        let selectorName = "isMCLCurrentlyEnabled:"
        guard let function: ErrorUInt64Call = self.function(selectorName) else {
            return nil
        }
        let enabledRaw = function(
            self.client,
            NSSelectorFromString(selectorName),
            &error
        )
        guard error == nil else {
            self.log(error: error, operation: "read enabled state")
            return nil
        }

        let limit = self.callErrorByte("getMCLLimitWithError:")
        guard let limit else {
            return nil
        }

        return State(enabled: enabledRaw != 0 && limit < 100, limit: limit)
    }

    private func callBool(_ name: String) -> Bool {
        guard let function: BoolCall = self.function(name) else {
            return false
        }
        return function(self.client, NSSelectorFromString(name))
    }

    private func callErrorBool(_ name: String) -> Bool {
        var error: NSError?
        guard let function: ErrorBoolCall = self.function(name) else {
            return false
        }
        let result = function(self.client, NSSelectorFromString(name), &error)
        self.log(error: error, operation: name)
        return result && error == nil
    }

    private func callErrorByte(_ name: String) -> UInt8? {
        var error: NSError?
        guard let function: ErrorByteCall = self.function(name) else {
            return nil
        }
        let result = function(self.client, NSSelectorFromString(name), &error)
        self.log(error: error, operation: name)
        return error == nil ? result : nil
    }

    private func callSetByte(_ name: String, value: UInt8) -> Bool {
        var error: NSError?
        guard let function: SetByteCall = self.function(name) else {
            return false
        }
        let result = function(
            self.client,
            NSSelectorFromString(name),
            value,
            &error
        )
        self.log(error: error, operation: name)
        return result && error == nil
    }

    private func function<T>(_ name: String) -> T? {
        let selector = NSSelectorFromString(name)
        guard let method = class_getInstanceMethod(type(of: self.client), selector) else {
            return nil
        }
        return unsafeBitCast(method_getImplementation(method), to: T.self)
    }

    private func log(error: NSError?, operation: String) {
        guard let error else { return }
        os_log("System charge limit %{public}@ failed: %{public}@", operation, error)
    }
}
