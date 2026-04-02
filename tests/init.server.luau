local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specium = require(ReplicatedStorage.DevPackages.Specium)
local Signal = require(ReplicatedStorage.AcidSignal)

local suite = Specium.suite("Signal", function(ctx)
	ctx.describe("Connect / Fire", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should call callback", function()
			local called = false

			signal:Connect(function() called = true end)

			signal:Fire()

			Specium.expect(called).toBe(true)
		end)

		ctx.it("should pass arguments", function()
			local value

			signal:Connect(function(v) value = v end)

			signal:Fire(25)

			Specium.expect(value).toBe(25)
		end)

		ctx.it("should support multiple connections", function()
			local count = 0

			signal:Connect(function()
				count += 1
			end)

			signal:Connect(function()
				count += 1
			end)

			signal:Fire()

			Specium.expect(count).toBe(2)
		end)

		ctx.it("should preserve order", function()
			local order = {}

			signal:Connect(function() table.insert(order, "a") end)

			signal:Connect(function() table.insert(order, "b") end)

			signal:Fire()

			Specium.expect(order).toEqual({ "a", "b" })
		end)
	end)

	ctx.describe("Bound args", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should append bound args", function()
			local a, b

			signal:Connect(function(x, y)
				a = x
				b = y
			end, 20)

			signal:Fire(10)

			Specium.expect(a).toBe(10)
			Specium.expect(b).toBe(20)
		end)
	end)

	ctx.describe("Disconnect", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should disconnect callback", function()
			local called = false

			local conn = signal:Connect(function() called = true end)

			conn:Disconnect()
			signal:Fire()

			Specium.expect(called).toBe(false)
		end)

		ctx.it("should update Connected", function()
			local conn = signal:Connect(function() end)

			conn:Disconnect()

			Specium.expect(conn.Connected).toBe(false)
		end)
	end)

	ctx.describe("Reconnect", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should reconnect", function()
			local count = 0

			local conn = signal:Connect(function()
				count += 1
			end)

			conn:Disconnect()
			conn:Reconnect()

			signal:Fire()

			Specium.expect(count).toBe(1)
		end)
	end)

	ctx.describe("Once", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should fire only once", function()
			local count = 0

			signal:Once(function()
				count += 1
			end)

			signal:Fire()
			signal:Fire()

			Specium.expect(count).toBe(1)
		end)
	end)

	ctx.describe("Wait", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should resume when fired", function()
			task.defer(signal.Fire, signal, 123)

			local value = signal:Wait()

			Specium.expect(value).toBe(123)
		end, 5)

		ctx.it("should timeout", function()
			local value = signal:Wait(0.67)

			Specium.expect(value).toBeNil()
		end, 5)
	end)

	ctx.describe("DisconnectAll", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should disconnect all", function()
			local count = 0

			signal:Connect(function()
				count += 1
			end)

			signal:Connect(function()
				count += 1
			end)

			signal:DisconnectAll()
			signal:Fire()

			Specium.expect(count).toBe(0)
		end)
	end)

	ctx.describe("Destroy", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should alias DisconnectAll", function()
			local called = false

			signal:Connect(function() called = true end)

			signal:Destroy()
			signal:Fire()

			Specium.expect(called).toBe(false)
		end)
	end)

	ctx.describe("Disconnect during fire", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should not break iteration", function()
			local count = 0

			local conn
			conn = signal:Connect(function()
				count += 1
				conn:Disconnect()
			end)

			signal:Connect(function()
				count += 1
			end)

			signal:Fire()

			Specium.expect(count).toBe(2)
		end)
	end)

	ctx.describe("Connect during fire", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should not fire new connection immediately", function()
			local count = 0

			signal:Connect(function()
				count += 1

				signal:Connect(function()
					count += 1
				end)
			end)

			signal:Fire()

			Specium.expect(count).toBe(1)
		end)
	end)

	ctx.describe("Reconnect order", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should reconnect at head", function()
			local order = {}

			local a = signal:Connect(
				function() table.insert(order, "a") end
			)

			signal:Connect(function() table.insert(order, "b") end)

			a:Disconnect()
			a:Reconnect()

			signal:Fire()

			Specium.expect(order).toEqual({ "b", "a" })
		end)
	end)

	ctx.describe("Error handling", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should continue after error", function()
			local called = false

			signal:Connect(function() error("fail") end)

			signal:Connect(function() called = true end)

			signal:Fire()

			Specium.expect(called).toBe(true)
		end)
	end)

	ctx.describe("Reentrancy", function(ctx)
		local signal: Signal.Signal<...any>
		ctx.beforeEach(function() signal = Signal.new() end)
		ctx.afterEach(function() signal:Destroy() end)

		ctx.it("should allow recursive fire", function()
			local count = 0

			signal:Connect(function()
				count += 1

				if count < 3 then signal:Fire() end
			end)

			signal:Fire()

			Specium.expect(count).toBe(3)
		end)
	end)
end)

local output = Specium.run(suite)
print(output)
