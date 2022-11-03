_G.LobbyObjective = {}
LobbyObjective.mod_path = ModPath
LobbyObjective.save_path = SavePath
LobbyObjective.settings = {}

function LobbyObjective:set_objective(objective, silent)
	if Network:is_server() and managers.chat and not silent then
		local message
		if not objective then
			message = managers.localization:text("LO_objective_remove")
		else
			local visual = tweak_data.achievement.visual[objective] or {}
			message = managers.localization:text("LO_objective_set", {
				NAME = managers.localization:to_upper_text(visual.name_id),
				DESCRIPTION = managers.localization:text(visual.desc_id)
			})
		end
		managers.chat:send_message(ChatManager.GAME, "System", message)
	end

	self.settings.objective = objective
	self:save()
end

function LobbyObjective:save()
	local file = io.open(self.save_path .. "lobby_objective.txt", "w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

function LobbyObjective:load()
	local file = io.open(self.save_path .. "lobby_objective.txt", "r")
	if file then
		self.settings = json.decode(file:read("*all")) or {}
		file:close()
	end
end

Hooks:PostHook(AchievementDetailGui, "init", "init_lo", function (self)
	if Network:is_server() then
		local placer = self:placer()
		placer:set_at(self._detail:left(), self._detail:bottom())
		placer:add_bottom(TextButton:new(self, {
			input = true,
			text = managers.localization:to_upper_text(LobbyObjective.settings.objective == self._id and "LO_menu_objective_remove" or "LO_menu_objective_set"),
			font = tweak_data.menu.pd2_medium_font,
			font_size = tweak_data.menu.pd2_medium_font_size
		}, function ()
			LobbyObjective:set_objective(LobbyObjective.settings.objective ~= self._id and self._id or nil)
			managers.menu:force_back()
		end))
	end
end)

Hooks:PostHook(MenuManager, "on_leave_active_job", "on_leave_active_job_lo", function ()
	LobbyObjective:set_objective(nil, true)
end)

Hooks:PostHook(MenuManager, "on_leave_lobby", "on_leave_lobby_lo", function ()
	LobbyObjective:set_objective(nil, true)
end)

Hooks:Add("BaseNetworkSessionOnPeerEnteredLobby", "BaseNetworkSessionOnPeerEnteredLobbyLO", function (peer, peer_id)
	if Network:is_server() and LobbyObjective.settings.objective then
		local visual = tweak_data.achievement.visual[LobbyObjective.settings.objective] or {}
		local message = managers.localization:text("LO_objective", {
			NAME = managers.localization:to_upper_text(visual.name_id),
			DESCRIPTION = managers.localization:text(visual.desc_id)
		})
		DelayedCalls:Add("LO_notification_peer" .. peer_id, 1, function ()
			local p = managers.network:session():peer(peer_id)
			return p and p:send("send_chat_message", ChatManager.GAME, message)
		end)
	end
end)

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitLO", function (loc)
	HopLib:load_localization(LobbyObjective.mod_path .. "loc/", loc)
end)

LobbyObjective:load()
