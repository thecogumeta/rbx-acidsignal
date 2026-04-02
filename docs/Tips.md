---
sidebar_position: 4
---

# Tips & Tricks

## Use Once to Avoid Manual Disconnects

If you only need to react to the first fire, use `Once` instead of manually disconnecting inside the callback:

```lua
-- instead of this
local conn
conn = signal:Connect(function(value)
    conn:Disconnect()
    print("fired:", value)
end)

-- do this
signal:Once(function(value)
    print("fired:", value)
end)
```

## Use Wait with a Timeout

Calling `Wait` without a timeout will yield the current thread forever if the signal never fires. Always pass a timeout when the signal **MIGHT** not fire:

```lua
local value = signal:Wait(5)
if not value then
    warn("signal never fired!")
    return
end
```

## Reuse Connections with Reconnect

Instead of creating a new connection every time, you can disconnect and reconnect the same one:

```lua
local connection = signal:Connect(function()
    print("fired")
end)

connection:Disconnect()

-- later...
connection:Reconnect()
```

## Avoid Firing Inside Callbacks

Calling `Fire` inside a callback causes reentrancy. AcidSignal allows up to 256 recursive fires before dropping the call with a warning. If you need to fire in response to a fire, consider deferring it:

```lua
signal:Connect(function()
    task.defer(signal.Fire, signal) -- safe, deferred to next frame
end)
```
