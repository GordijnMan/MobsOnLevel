----------------------------------------------------------------
-- EVTCalendar
-- Author: Reed, idontbyte, GordijnMan
--
--
----------------------------------------------------------------

local previousMobs = {}
local killTimes = {}
local blinkInterval = .5
local blinkCounter = 0
local nextBlinkTime = 0

function M0L_OnLoad()
	this:RegisterEvent("PLAYER_LOGIN")
	this:RegisterEvent("PLAYER_XP_UPDATE")
    this:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
end

function M0L_OnEvent()

	if event == "PLAYER_LOGIN" then
		-- Hide the original frame
		if M0L_Frame then
			M0L_Frame:Hide()
		else
			M0L_print("M0L_Frame is nil", 'error')
		end

		-- Hovering Player Unit Frame
		M0L_Frame_OnHover()

		-- Console commands
		SLASH_MOBSONLEVEL1 = "/mobsonlevel"
		SLASH_MOBSONLEVEL2 = "/MOBSONLEVEL"
		SLASH_MOBSONLEVEL3 = "/MobsOnLevel"
		SLASH_MOBSONLEVEL4 = "/mol"
		SLASH_MOBSONLEVEL5 = "/MOL"

		SlashCmdList["MOBSONLEVEL"] = function(msg)
			if msg == "show" then
				M0L_Frame:Show()
			elseif msg == "hide" then
				M0L_Frame:Hide()
			elseif msg == "debug" or msg == "db" then
				if DEBUG then
					DEBUG=nil
				else
					DEBUG=true
				end

				M0L_print('Debug mode activated!', 'debug')

			elseif msg == "db2" then
				M0L_SetText(8)

				M0L_print('Debug mode 2!', 'error')
			elseif msg == "db3" then
				M0L_SetText(13)

				M0L_print('Debug mode 3!')
			elseif msg == "db4" then
				M0L_SetText(21)
				M0L_print('Debug mode 4!', 'random')
			else
				if M0L_Frame:IsShown() then
					M0L_Frame:Hide()
				else
					M0L_Frame:Show()
				end
			end
		end

	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		if string.find(arg1, "(.+) dies") then
			local _, _, killedMob, XPGain = string.find(arg1, "(.+) dies, you gain (%d+) experience.")
			if GetXPExhaustion() then
				table.insert(previousMobs, math.floor(XPGain/2))
				table.insert(killTimes,time())
			else
				table.insert(previousMobs, math.floor(XPGain))
				table.insert(killTimes,time())
			end
			if table.getn(previousMobs) > 3 then
				table.remove(previousMobs, 1)
			end
			if table.getn(killTimes) > 10 then
				table.remove(killTimes, 1)
			end
			M0L_calc(XPGain)
		end

		M0L_print("Player combat XP!", 'debug')

	elseif event == "PLAYER_XP_UPDATE" then
		M0L_calc()

		M0L_print("Player XP update!", 'debug')
	end
end

function M0L_Frame_OnHover()

	local frame = PlayerFrame

	-- Hovering over the Player UnitFrame should display the amount of kills to level
	if frame and type(frame.SetScript) == "function" then
		local old_OnEnter = frame:GetScript("OnEnter") or function() end	-- Keep old OnEnter functionality
		frame:SetScript("OnEnter", function(self, ...)
			old_OnEnter()
			M0L_Frame:Show()
			M0L_print("Entering PlayFrame!", 'debug')
		end)
		local old_OnLeave = frame:GetScript("OnLeave") or function() end	-- Keep old OnLeave functionality
		frame:SetScript("OnLeave", function(self, ...)
			old_OnLeave()
			M0L_Frame:Hide()
			M0L_print("Leaving PlayFrame!", 'debug')
		end)
	else
		M0L_print("frame doesn't have SetScript!", 'error')
	end
end

function M0L_calc(XPGain)
	local restToGo, killsToGo
	local avgXP = 0

	if not XPGain then
		XPGain = 0
	end

	local restXP = GetXPExhaustion()
	local curXP = UnitXP("player") + XPGain
	local maxXP = UnitXPMax("player")

	if restXP then
		for _,x in pairs(previousMobs) do
			avgXP = avgXP + x
		end
		avgXP = avgXP / table.getn(previousMobs)
		if restXP > (maxXP - curXP) then
			killsToGo = (maxXP - curXP)/(avgXP*2)
			killsToGo = math.floor(killsToGo + 0.5) -- Round to nearest number
			M0L_SetText(killsToGo)
		else
			restToGo = (restXP / avgXP)
			killsToGo = (maxXP - curXP - restXP)/(avgXP)
			killsToGo = math.ceil((killsToGo + restToGo))
			M0L_SetText(killsToGo)
		end
	else
		for _,x in pairs(previousMobs) do
			avgXP = avgXP + x
		end
		avgXP = avgXP / table.getn(previousMobs)
		killsToGo = math.ceil((maxXP - curXP)/avgXP)
		M0L_SetText(killsToGo)
	end

	local timeStamp = 0
	local timeDifferences = {}
	for _,x in pairs(killTimes) do
		if (table.getn(killTimes) > _) then
		table.insert(timeDifferences,((killTimes[_+1] - x)))
		end
	end
	for _,x in pairs(timeDifferences) do
		timeStamp = timeStamp + x
	end
	timeStamp = timeStamp / table.getn(timeDifferences)
	timeStamp = timeStamp * killsToGo
	M0L_TimeString:SetText(tostring(date('%H:%M:%S',timeStamp)))

	M0L_print("Mob calucation!", 'debug')
end

-- Function to blink frame
function Blink_frame(blink)

	-- CreateFrame if it does not exist
	if not BLINK_FRAME then
		M0L_print('Creating BLINK_FRAME...', 'debug')
		
		BLINK_FRAME = CreateFrame("Frame", "UniqueBlinkFrameName", UIParent)
	end

	-- Enable blink if desired
	if blink then

		local visible = true

		BLINK_FRAME:SetScript("OnUpdate", function(self)

			local uptime = GetTime()

			if uptime >= nextBlinkTime and blink then
				if visible then
					M0L_String:SetAlpha(0)
				else
					M0L_String:SetAlpha(1)
				end
				visible = not visible
				nextBlinkTime = uptime + blinkInterval
				blinkCounter = blinkCounter + 1

				M0L_debug_frame(blink, uptime)
			end
		end)
	elseif not blink then

		local uptime = GetTime()

		M0L_print('NOT BLINKING', 'debug')

		BLINK_FRAME:SetScript("OnUpdate", nil)	-- Stop blinking cleanly
		M0L_String:SetAlpha(1)					-- Make sure it's visible
		nextBlinkTime = 9000					-- Arbitrary number
		blinkCounter = blinkCounter + 1

		M0L_debug_frame(blink, uptime)
	end
end

function M0L_SetText(killsToGo)

	-- Blink frame
	function ShowBlink(self)
		M0L_print('BLINKING', 'debug')
		Blink_frame(true)
	end

	function HideBlink(self)
		M0L_print('STOP BLINKING', 'debug')
		Blink_frame(false)
	end

	M0L_print("Setting M0L_String...", 'debug')

	if killsToGo < 10 then
		M0L_String:SetFontObject(GameFontRedLarge)
		M0L_String:SetText(tostring(killsToGo))

		ShowBlink()
	elseif killsToGo < 20 then
		M0L_String:SetFontObject(GameFontNormalLarge)
		M0L_String:SetText(tostring(killsToGo))

		HideBlink()
	elseif killsToGo < 30 then
		M0L_String:SetFontObject(GameFontGreen)
		M0L_String:SetText(tostring(killsToGo))

		HideBlink()
	else
		M0L_String:SetFontObject(GameFontWhite)
		M0L_String:SetText(tostring(killsToGo))

		HideBlink()
	end
end

function M0L_print(str, err)
	if err == 'debug' and DEBUG == true then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFFF00MobsOnLevel:|r " .. "|c00FF00FF" .. 'DEBUG' .. "|r|c006969FF - " .. tostring(str) .. "|r")
	elseif err == 'error' and DEBUG == true then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFFF00MobsOnLevel:|r " .. "|c00FF0000" .. 'ERROR' .. "|r|c006969FF - " .. tostring(str) .. "|r")
	elseif err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFFF00MobsOnLevel: INFO - " .. tostring(str) .. "|r")
	elseif err and DEBUG == true then
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFFF00MobsOnLevel:|r " .. string.upper(tostring(err)) .. "|r|c006969FF - " .. tostring(str) .. "|r")
	end
end

function M0L_debug_frame(blink, uptime)
	M0L_print( '\n'
		.. 'Blink_frame: ' .. blinkCounter .. '\n'
		.. 'UpTime: '.. uptime .. '\n'
		.. 'nextBlinkTime: ' .. nextBlinkTime .. '\n'
		.. 'blinkInterval: ' .. blinkInterval .. '\n'
		.. 'blink: ' .. string.upper(tostring(blink)), 'debug')
end
