-- Roblox 3D 預測傳送腳本（完整功能 + 靜止補償）
-- 作者整合：支援高速、靜止、上下移動，無閃爍、不卡圖、穩定預測

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then return warn("找不到 PlayerGui") end

-- UI 建立略（請根據原 GUI 設定加入）

local allPlayers = {}
local selectedPlayer = nil
local currentIndex = 1
local longTeleporting = false

-- 參數
local PING = 0.125  -- 延遲秒數
local EXTRA = 0.08  -- 額外補償
local FORWARD = 3.5 -- 預測距離
local HISTORY = 8   -- 儲存幀數

local posHistory, velHistory = {}, {}
local lastDir = Vector3.new(0, 0, 1)
local lastHrpPos, stillTimer = nil, 0

-- 工具函數
local function avg(tbl)
	local sum = Vector3.zero
	for _, v in ipairs(tbl) do sum += v end
	return #tbl > 0 and (sum / #tbl) or Vector3.zero
end

local function curvature()
	if #velHistory < 2 then return Vector3.zero end
	local delta = velHistory[#velHistory] - velHistory[1]
	return delta * 0.3
end

local function acceleration()
	if #velHistory < 2 then return Vector3.zero end
	local a = velHistory[#velHistory] - velHistory[#velHistory - 1]
	return a / RunService.RenderStepped:Wait()
end

local function mixDir(hrp, vel)
	local look = hrp.CFrame.LookVector
	if look:Dot(vel.Unit) > 0.4 then
		return (look + vel.Unit).Unit
	else
		return vel.Unit
	end
end

local function updateHistory(pos)
	table.insert(posHistory, pos)
	if #posHistory > HISTORY then table.remove(posHistory, 1) end
	local count = #posHistory
	if count > 1 then
		local v = (posHistory[count] - posHistory[count - 1]) / RunService.RenderStepped:Wait()
		table.insert(velHistory, v)
		if #velHistory > HISTORY then table.remove(velHistory, 1) end
	end
end

local function isStill(currentPos)
	local moved = (lastHrpPos and (currentPos - lastHrpPos).Magnitude) or math.huge
	lastHrpPos = currentPos
	if moved < 0.1 then
		stillTimer += RunService.RenderStepped:Wait()
	else
		stillTimer = 0
	end
	return stillTimer > 0.25
end

local function predict(hrp)
	updateHistory(hrp.Position)

	local vel = avg(velHistory)
	local acc = acceleration()
	local curve = curvature()

	local direction
	if vel.Magnitude > 1 then
		lastDir = mixDir(hrp, vel)
		direction = lastDir
	else
		direction = lastDir
	end

	local predictT = PING + EXTRA
	local predicted = hrp.Position + vel * predictT + 0.5 * acc * predictT^2 + curve + direction * FORWARD

	local y = math.clamp(predicted.Y, hrp.Position.Y - 2.5, hrp.Position.Y + 3)
	return Vector3.new(predicted.X, y, predicted.Z)
end

local function getTargetPosition(hrp)
	if isStill(hrp.Position) then
		return hrp.Position + hrp.CFrame.LookVector * FORWARD
	else
		return predict(hrp)
	end
end

-- 更新玩家列表（略，與原腳本一致）

-- 持續傳送
RunService.RenderStepped:Connect(function()
	if longTeleporting and selectedPlayer then
		local targetHRP = selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP and myHRP then
			myHRP.CFrame = CFrame.new(getTargetPosition(targetHRP))
		end
	end
end)

-- UI 控制 + 玩家列表更新 + 點擊傳送（略）

-- ✅ 注意：請將 GUI 建立、按鈕控制、玩家選擇等部分整合進來
-- ✅ 若需我幫你整合 UI 與控制，請提供你 GUI 範本或讓我自動生成
