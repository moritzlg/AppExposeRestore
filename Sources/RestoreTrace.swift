import os

/// Records timing markers only. No application or window titles are logged.
enum RestoreTrace {
    static let log = Logger(subsystem: "local.moritz.AppExposeRestore", category: "restore")

    static func mark(_ phase: String) {
        log.notice("\(phase, privacy: .public)")
    }
}
