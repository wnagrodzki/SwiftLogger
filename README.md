# SwiftLogger

[![Build Status](https://travis-ci.org/wnagrodzki/SwiftLogger.svg?branch=master)](https://travis-ci.org/wnagrodzki/SwiftLogger)
[![codecov](https://codecov.io/gh/wnagrodzki/SwiftLogger/branch/master/graph/badge.svg)](https://codecov.io/gh/wnagrodzki/SwiftLogger)

Dependency free Logger API for Swift.

## Motivation
Beside obvious benefit for unit testing (see `NullLogger`), having loose coupling to a logging framework makes it easy to log messages into multiple logging systems at once (see `AgregateLogger`).

## Usage
`Logger` protocol provides simple interface utilizing log levels defined by [The Syslog Protocol - RFC5424](https://www.rfc-editor.org/info/rfc5424).

```swift
logger.log("message", level: .emergency)
logger.log("message", level: .alert)
logger.log("message", level: .critical)
logger.log("message", level: .error)
logger.log("message", level: .warning)
logger.log("message", level: .notice)
logger.log("message", level: .informational)
logger.log("message", level: .debug)
```

Log calls capture time, file name, method name and line number automatically. This way it is possible to compose log messages similar to the one presented below.

```
2018-08-31 18:29:34.748 <crit> SwiftFile:75 method() message
```

## Integration with logger frameworks
You need to provide implementation for one method.

```swift
final class CustomLogger: Logger {
    
    public func log(time: Date, level: LogLevel, location: String, message: @autoclosure () -> String) {
        /// compose message and forward it to a logging framework
    }
}
```

## Provided loggers
`ConsoleLogger` writes messages into the standard output.

`NullLogger` ignores all messages with the intention to minimize observer effect. Useful for unit testing.

`DiskLogger` writes messages into the file at specified URL with log rotation support.

`AgregateLogger` forwards messages to all the loggers it is initialized with.
