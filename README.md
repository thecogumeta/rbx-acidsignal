<div align="center">
	<h1>AcidSignal</h1>
	<p>A simple and lightweight <code>signal</code> implementation for Roblox</p>
	<a href="https://thecogumeta.github.io/rbx-acidsignal/"><strong>View docs</strong></a>
</div>

<!--moonwave-hide-before-this-line-->

## Why AcidSignal?

Most signal libraries give you the basics and nothing else. **AcidSignal** keeps it simple while adding a few extra features that come in handy — without any external dependencies.

## Features

- **Connect & Fire**: Standard signal behavior you already know.
- **Once()**: Connects and automatically disconnects after the first fire.
- **Connection priority**: Control the order callbacks execute with priority levels.
- **Async fire**: Fire without blocking the current thread.
- **Clean disconnect**: Connections return a handle with `:Disconnect()` and the signal has `:DisconnectAll()`.
