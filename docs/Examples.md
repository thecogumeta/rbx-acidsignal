---
sidebar_position: 5
---

# Examples

## Basic Signal

```lua
local Signal = require(path.to.AcidSignal)

local signal = Signal.new()

signal:Connect(function(value)
    print("received:", value)
end)

signal:Fire("hello") -- received: hello
```

## Multiple Connections

```lua
local signal = Signal.new()

signal:Connect(function(value)
    print("A:", value)
end)

signal:Connect(function(value)
    print("B:", value)
end)

signal:Fire("hello")
-- A: hello
-- B: hello
```

## Waiting for a Signal

```lua
local signal = Signal.new()

task.delay(2, function()
    signal:Fire("done")
end)

local value = signal:Wait(5)
if value then
    print("signal fired with:", value)
else
    print("timed out!")
end
```

## Using Once for One-Time Events

```lua
local signal = Signal.new()

signal:Once(function(player)
    print("first player joined:", player.Name)
end)
```

## Bound Args for Context

```lua
local signal = Signal.new()

local function onDamage(amount, source)
    print(`took {amount} damage from {source}`)
end

signal:Connect(onDamage, "fire")
signal:Connect(onDamage, "poison")

signal:Fire(10)
-- took 10 damage from fire
-- took 10 damage from poison
```

## Cleaning Up

```lua
local signal = Signal.new()

signal:Connect(function()
    print("A")
end)

signal:Connect(function()
    print("B")
end)

-- disconnect all at once
signal:DisconnectAll()
```
