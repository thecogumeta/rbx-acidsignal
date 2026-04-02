---
sidebar_position: 3
---

# Basic Usage

## Creating a Signal

```lua
local Signal = require(path.to.AcidSignal)

local signal = Signal.new()
```

## Connecting a Callback

```lua
local connection = signal:Connect(function(value)
    print("fired:", value)
end)
```

## Firing a Signal

```lua
signal:Fire("hello")
-- fired: hello
```

## Disconnecting

```lua
connection:Disconnect()
```

## Once

Use `Once` to connect a callback that automatically disconnects after the first fire:

```lua
signal:Once(function(value)
    print("fired once:", value)
end)

signal:Fire("hello") -- fired once: hello
signal:Fire("hello") -- nothing
```

## Wait

Use `Wait` to yield the current thread until the signal fires:

```lua
local value = signal:Wait()
print(value) -- "hello"
```

Pass a timeout in seconds to avoid yielding forever:

```lua
local value = signal:Wait(5)
if not value then
    print("timed out!")
end
```

## Bound Arguments

Pass extra arguments to `Connect` or `Once` to have them appended to every call:

```lua
signal:Connect(function(value, tag)
    print(value, tag)
end, "mytag")

signal:Fire("hello") -- hello    mytag
```

## DisconnectAll

Disconnect all connections from a signal at once:

```lua
signal:DisconnectAll()
```

## Destroy

Alias for `DisconnectAll`:

```lua
signal:Destroy()
```
