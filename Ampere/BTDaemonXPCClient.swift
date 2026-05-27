//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation
import os.log

@BTBackgroundActor
internal enum BTDaemonXPCClient {
    private static var connect: NSXPCConnection? = nil

    private enum AuthorizationRequirement {
        case none
        case manage
    }

    static func disconnectDaemon() {
        guard let connect = self.connect else {
            return
        }

        self.connect = nil
        connect.invalidate()
    }

    static func getUniqueId() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            self.executeDaemonRetry(continuation: continuation) { daemon in
                daemon.getUniqueId { data in
                    guard let data = data else {
                        continuation.resume(throwing: BTError.malformedData)
                        return
                    }

                    continuation.resume(returning: data)
                }
            }
        }
    }

    static func getState() async throws -> [String: NSObject & Sendable] {
        try await withCheckedThrowingContinuation { continuation in
            self.executeDaemonRetry(continuation: continuation) { daemon in
                daemon.getState { state in
                    continuation.resume(returning: state)
                }
            }
        }
    }

    static func disablePowerAdapter() async throws {
        try await self.run(command: .disablePowerAdapter, authorization: .manage)
    }

    static func enablePowerAdapter() async throws {
        try await self.run(command: .enablePowerAdapter, authorization: .none)
    }

    static func chargeToLimit() async throws {
        try await self.run(command: .chargeToLimit, authorization: .none)
    }

    static func chargeToFull() async throws {
        try await self.run(command: .chargeToFull, authorization: .none)
    }

    static func disableCharging() async throws {
        try await self.run(command: .disableCharging, authorization: .manage)
    }

    static func pauseActivity() async throws {
        try await self.run(command: .pauseActivity, authorization: .manage)
    }

    static func resumeActivity() async throws {
        try await self.run(command: .resumeActivity, authorization: .manage)
    }

    static func enableLowPowerMode() async throws {
        try await self.run(command: .enableLowPowerMode, authorization: .manage)
    }

    static func disableLowPowerMode() async throws {
        try await self.run(command: .disableLowPowerMode, authorization: .manage)
    }

    static func getSettings() async throws -> [String: NSObject & Sendable] {
        try await withCheckedThrowingContinuation { continuation in
            self.executeDaemonRetry(continuation: continuation) { daemon in
                daemon.getSettings { settings in
                    continuation.resume(returning: settings)
                }
            }
        }
    }

    static func setSettings(settings: [String: NSObject & Sendable]) async throws {
        let authData = try await BTAppXPCClient.getManageAuthorization()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            self.executeDaemonManageRetry(continuation: continuation) { daemon in
                daemon.setSettings(
                    authData: authData,
                    settings: settings,
                    reply: self.continuationStatusHandler(continuation: continuation)
                )
            }
        }
    }

    static func prepareUpdate() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            self.executeDaemonRetry(continuation: continuation) { daemon in
                daemon.execute(
                    authData: nil,
                    command: BTDaemonCommCommand.prepareUpdate.rawValue,
                    reply: self.continuationStatusHandler(continuation: continuation)
                )
            }
        }
    }

    static func finishUpdate() {
        Task {
            do {
                try await self.run(command: .finishUpdate, authorization: .none)
            } catch {
                //
                // Deliberately ignore errors as this is an optional notification.
                //
            }
        }
    }

    static func removeLegacyHelperFiles(authData: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            self.executeDaemonRetry(continuation: continuation) { daemon in
                daemon.execute(
                    authData: authData,
                    command: BTDaemonCommCommand.removeLegacyHelperFiles.rawValue,
                    reply: self.continuationStatusHandler(continuation: continuation)
                )
            }
        }
    }

    static func prepareDisable(authData: Data) async throws {
        try await self.run(command: .prepareDisable, authData: authData)
    }

    static func isSupported() async throws {
        try await self.run(command: .isSupported, authorization: .none)
    }

    private static func run(
        command: BTDaemonCommCommand,
        authorization: AuthorizationRequirement
    ) async throws {
        let authData: Data?
        switch authorization {
        case .none:
            authData = nil
        case .manage:
            authData = try await BTAppXPCClient.getManageAuthorization()
        }

        try await self.run(command: command, authData: authData)
    }

    private static func run(
        command: BTDaemonCommCommand,
        authData: Data?
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            self.runExecute(continuation: continuation, authData: authData, command: command)
        }
    }

    private static func continuationStatusHandler(continuation: CheckedContinuation<Void, any Error>) -> (@Sendable (BTError.RawValue) -> Void) {
        return { error in
            guard error == BTError.success.rawValue else {
                continuation.resume(
                    throwing: BTError(daemonRawValue: error)
                )
                return
            }
            continuation.resume()
        }
    }

    private static func connectDaemon() -> NSXPCConnection {
        if let connect = self.connect {
            return connect
        }

        let connect = NSXPCConnection(
            machServiceName: BT_DAEMON_CONN,
            options: .privileged
        )
        connect.remoteObjectInterface = NSXPCInterface(
            with: BTDaemonCommProtocol.self
        )

        BTXPCValidation.protectDaemon(connection: connect)

        connect.resume()
        self.connect = connect

        os_log("XPC client connected")

        return connect
    }

    private static func executeDaemon(
        command: @BTBackgroundActor @Sendable (BTDaemonCommProtocol) -> Void,
        errorHandler: @escaping @Sendable (any Error) -> Void
    ) {
        let connect = self.connectDaemon()
        let daemon = connect.remoteObjectProxyWithErrorHandler(
            errorHandler
        ) as! BTDaemonCommProtocol
        command(daemon)
    }

    private static func executeDaemonRetry<T>(
        continuation: CheckedContinuation<T, any Error>,
        command: @BTBackgroundActor @escaping @Sendable (BTDaemonCommProtocol) -> Void
    ) {
        self.executeDaemon(command: command) { error in
            os_log("XPC client remote error: \(error, privacy: .public)")
            os_log("Retrying...")
            Task { @BTBackgroundActor in
                self.disconnectDaemon()
                self.executeDaemon(command: command) { error in
                    os_log("XPC client remote error: \(error, privacy: .public)")
                    continuation.resume(throwing: BTError.commFailed)
                }
            }
        }
    }

    private static func executeDaemonManageRetry<T>(
        continuation: CheckedContinuation<T, any Error>,
        command: @BTBackgroundActor @escaping @Sendable (BTDaemonCommProtocol) -> Void
    ) {
        self.executeDaemonRetry(continuation: continuation, command: command)
    }

    private static func runExecute(
        continuation: CheckedContinuation<Void, any Error>,
        authData: Data?,
        command: BTDaemonCommCommand
    ) {
        self.executeDaemonManageRetry(continuation: continuation) { daemon in
            daemon.execute(
                authData: authData,
                command: command.rawValue,
                reply: self.continuationStatusHandler(continuation: continuation)
            )
        }
    }
}
