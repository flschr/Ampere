//
// Copyright (C) 2026 Rene Fischer. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Darwin
import Foundation
import ObjectiveC.runtime

extension BTSystemChargeLimitClient {
    private static let frameworkHandle = dlopen(
        "/System/Library/PrivateFrameworks/PowerUI.framework/PowerUI",
        RTLD_NOW | RTLD_LOCAL
    )

    private typealias AllocCall = @convention(c) (
        AnyClass,
        Selector
    ) -> AnyObject?
    private typealias InitCall = @convention(c) (
        AnyObject,
        Selector,
        NSString
    ) -> AnyObject?
    private typealias ErrorObjectCall = @convention(c) (
        AnyObject,
        Selector,
        AutoreleasingUnsafeMutablePointer<NSError?>
    ) -> AnyObject?

    static func loadClient() -> AnyObject? {
        guard self.frameworkHandle != nil,
              let clientClass = NSClassFromString("PowerUISmartChargeClient")
        else {
            return nil
        }

        let allocSelector = NSSelectorFromString("alloc")
        guard let allocMethod = class_getClassMethod(clientClass, allocSelector)
        else {
            return nil
        }
        let allocate = unsafeBitCast(
            method_getImplementation(allocMethod),
            to: AllocCall.self
        )
        guard let allocated = allocate(clientClass, allocSelector) else {
            return nil
        }

        let initSelector = NSSelectorFromString("initWithClientName:")
        guard let initMethod = class_getInstanceMethod(clientClass, initSelector)
        else {
            return nil
        }
        let initialize = unsafeBitCast(
            method_getImplementation(initMethod),
            to: InitCall.self
        )
        return initialize(allocated, initSelector, "Ampere")
    }

    static func readAvailableLimits(client: AnyObject) -> [UInt8] {
        let name = "availableChargeLimitsWithError:"
        let selector = NSSelectorFromString(name)
        guard let method = class_getInstanceMethod(type(of: client), selector)
        else {
            return []
        }

        let function = unsafeBitCast(
            method_getImplementation(method),
            to: ErrorObjectCall.self
        )
        var error: NSError?
        guard let values = function(client, selector, &error) as? [NSNumber],
              error == nil
        else {
            return []
        }

        return values.compactMap { value in
            let raw = value.intValue
            return (0...100).contains(raw) ? UInt8(raw) : nil
        }.sorted()
    }
}
