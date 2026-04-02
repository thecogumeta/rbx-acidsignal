--[=[
	@class Signal
	A simple and lightweight signal implementation for Roblox.

	AcidSignal provides a familiar event-driven API with a thread pool,
	bound arguments, and connection management via a doubly linked list.
	```lua
	local Signal = require(path.to.AcidSignal)

	local signal = Signal.new()

	signal:Connect(function(value)
		print("fired:", value)
	end)

	signal:Fire("hello") -- fired: hello
	```
]=]
--[=[
	@class Connection
	Represents a connection to a signal.
]=]

--[=[
	@method Disconnect
	@within Connection

	Disconnects the connection from its signal.
	```lua
	local connection = signal:Connect(function()
		print("fired")
	end)

	connection:Disconnect()
	signal:Fire() -- do nothing
	```
]=]
--[=[
	@method Reconnect
	@within Connection

	Reconnects a previously disconnected connection.
	```lua
	connection:Disconnect()
	connection:Reconnect()
	```
]=]

--[=[
	@method Connect
	@within Signal
	@param fn (A..., V...) -> () -- The function to call when the signal fires
	@param ... V... -- Extra arguments appended to every call
	@return Connection<A..., V...>

	Connects a callback to the signal.
	```lua
	local connection = signal:Connect(function(value)
		print("fired:", value)
	end)

	-- With bound args
	local connection = signal:Connect(function(value, value2)
		print(value, value2)
	end, "hello")
	
	signal:Fire("world") -- hello world
	```
]=]
--[=[
	@method Once
	@within Signal
	@param fn (A..., V...) -> () -- The function to call when the signal fires
	@param ... V... -- Extra arguments appended to every call
	@return Connection<A..., V...>

	Connects a callback that automatically disconnects after the first fire.
	```lua
	signal:Once(function(value)
		print("fired once:", value)
	end)
	```
]=]
--[=[
	@method Wait
	@within Signal
	@param timeout number? -- Maximum seconds to wait. If reached, returns false.
	@return boolean -- Whether the signal fired before the timeout
	@return A... -- The arguments passed to Fire, or nil if timed out

	Yields the current thread until the signal fires.
	```lua
	-- without timeout
	task.defer(function() signal:Fire("Example") end)
	local value = signal:Wait()
	print(value) -- "Example"

	-- with timeout (returns nil if timed out)
	local value = signal:Wait(1)
	print(value) -- nil
	```
]=]
--[=[
	@method Fire
	@within Signal
	@param ... A... -- Arguments to pass to all connected callbacks

	Fires the signal, calling all connected callbacks via the thread pool.
	If reentrancy exceeds 256 recursive calls, a warning is emitted and the call is dropped.
	```lua
	signal:Fire("hello")
	```
]=]
--[=[
	@method DisconnectAll
	@within Signal

	Disconnects all connections from the signal.
	```lua
	signal:DisconnectAll()
	```
]=]
--[=[
	@method Destroy
	@within Signal

	Alias for `DisconnectAll`.
	```lua
	signal:Destroy()
	```
]=]
--[=[
	@function new
	@within Signal
	@return Signal<A...>

	Creates a new signal.
	```lua
	local signal = Signal.new()
	```
]=]

local Threads: { thread } = {}
local ThreadC = 0
local Yield = coroutine.yield
local Running = coroutine.running
local Create = coroutine.create
local Resume = coroutine.resume

local function GetExternalCaller(): string
	local level = 3
	local scriptPath = script:GetFullName()

	while true do
		local scr, line = debug.info(level, "sl")

		if not scr then return "Unknown" end

		if scr ~= scriptPath then return `{scr}:{line}` end

		level += 1
	end
end

local function RunCallback(fn, thread, ...)
	fn(...)
	ThreadC += 1
	Threads[ThreadC] = thread
end

local function Yielder()
	while true do
		RunCallback(Yield())
	end
end

local function GetThread(): thread
	if ThreadC == 0 then
		local thread = Create(Yielder)
		Resume(thread)
		return thread
	else
		local thread = Threads[ThreadC]
		Threads[ThreadC] = nil
		ThreadC -= 1
		return thread
	end
end

export type Connection<A..., V...> = {
	Connected: boolean,
	Disconnect: (self: Connection<A..., V...>) -> (),
	Reconnect: (self: Connection<A..., V...>) -> (),
}
export type Signal<A...> = {
	Connect: <V...>(self: Signal<A...>, fn: (...any) -> (), V...) -> (),
	Once: <V...>(self: Signal<A...>, fn: (...any) -> (), V...) -> (),
	Wait: (self: Signal<A...>, timeout: number?) -> A...,
	Fire: (self: Signal<A...>, A...) -> (),
	DisconnectAll: (self: Signal<A...>) -> (),
	Destroy: (self: Signal<A...>) -> (),
}

type Free<T> = T & { [any]: any }

local function ConnectionDisconnect<A..., V...>(self_: Connection<A..., V...>)
	local self: Free<typeof(self_)> = self_
	local signal: Free<Signal<A...>> = self._signal

	if not self.Connected then return end
	self.Connected = false

	if self._prev then
		self._prev._next = self._next
	else
		signal._tail = self._next
	end

	if self._next then
		self._next._prev = self._prev
	else
		signal._head = self._prev
	end
end

local function ConnectionReconnect<A..., V...>(self_: Connection<A..., V...>)
	local self: Free<typeof(self_)> = self_
	local signal: Free<Signal<A...>> = self._signal

	if self.Connected then return end
	self.Connected = true

	local head = signal._head

	if not head then
		signal._head = self
		signal._tail = self
		self._prev = nil
		self._next = nil
		return
	end

	head._next = self
	self._prev = head
	self._next = nil
	signal._head = self
end

local function MakeConnection<A..., V...>(
	signal_: Signal<A...>,
	callback: (A...) -> (),
	varags: { [number]: any, n: number }
): Connection<A..., V...>
	local signal = signal_ :: Free<typeof(signal_)>
	local self: Free<Connection<A..., V...>> = {
		_signal = signal,
		_callback = callback,
		_caller = GetExternalCaller(),
		_varags = varags.n ~= 0 and varags or nil,
		Connected = true,
	} :: any

	if not signal._tail then
		signal._tail = self
		signal._head = self
	end

	if signal._head ~= self then
		signal._head._next = self
		self._prev = signal._head
	end

	signal._head = self

	self.Disconnect = ConnectionDisconnect
	self.Reconnect = ConnectionReconnect

	return self
end

local function SignalConnect<A..., V...>(
	self_: Signal<A...>,
	callback: (A...) -> (),
	...: V...
): Connection<A..., V...>
	return MakeConnection(self_ :: any, callback, table.pack(...))
end

local function SignalOnce<A..., V...>(
	self_: Signal<A...>,
	callback: (A...) -> (),
	...: V...
): Connection<A..., V...>
	local self: Free<typeof(self_)> = self_

	local conn: Connection<...any>
	conn = SignalConnect(self, function(...)
		conn:Disconnect()
		callback(...)
	end, ...)

	return conn
end

local function SignalWait<A...>(self_: Signal<A...>, timeout: number?): A...
	local self: Free<typeof(self_)> = self_
	local thread = Running()

	local timeoutThread

	local conn: Connection<...any>
	conn = SignalConnect(self, function(...)
		conn:Disconnect()
		print(...)
		Resume(thread, ...)
		if timeoutThread then task.cancel(timeoutThread) end
	end)

	if not timeout then return Yield() end

	timeoutThread = task.delay(timeout, function()
		conn:Disconnect()
		Resume(thread)
	end)

	return Yield()
end

local function SignalFire<A...>(self_: Signal<A...>, ...)
	local self: Free<typeof(self_)> = self_
	if self._running >= 256 then
		warn(`[AcidSignal] {GetExternalCaller()}: Fire overflow`)
		return
	end
	self._running += 1

	local cur = self._tail

	while cur do
		local next = cur._next

		local thread = GetThread()
		local ok: boolean, msg: string
		if cur._varags then
			ok, msg = Resume(
				thread,
				cur._callback,
				thread,
				...,
				table.unpack(cur._varags, 1, cur._varags.n)
			)
		else
			ok, msg = Resume(thread, cur._callback, thread, ...)
		end

		if not ok then
			warn(`[AcidSignal] {cur._caller}: error in callback: {msg}`)
		end

		cur = next
	end

	self._running -= 1
end

local function SignalDisconnectAll<A...>(self_: Signal<A...>)
	local self: Free<typeof(self_)> = self_

	local cur = self._tail
	while cur do
		cur.Connected = false
		cur._next = nil
		cur._prev = nil
		cur = cur._next
	end

	self._tail = nil
	self._head = nil
end

local function MakeSignal<A...>(): Signal<A...>
	local self: Free<Signal<A...>> = { _running = 0 } :: any

	self.Connect = SignalConnect :: any
	self.Once = SignalOnce :: any
	self.Wait = SignalWait :: any
	self.Fire = SignalFire :: any
	self.DisconnectAll = SignalDisconnectAll :: any
	self.Destroy = SignalDisconnectAll :: any

	return self
end

return {
	new = MakeSignal,
}
