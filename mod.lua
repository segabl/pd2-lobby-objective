_G.LobbyObjective = {}
LobbyObjective.mod_path = ModPath
LobbyObjective.save_path = SavePath
LobbyObjective.settings = {}

function LobbyObjective:set_objective(objective)
  if not managers.chat then
    return
  end
  local message
  if not objective then
    message = "Lobby objective removed"
  else
    local visual = tweak_data.achievement.visual[objective] or {}
    message = string.format("New lobby objective: %s\n%s", managers.localization:to_upper_text(visual.name_id), managers.localization:text(visual.desc_id))
  end

  managers.chat:send_message(ChatManager.GAME, "System", message)
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
      text = LobbyObjective.settings.objective == self._id and "REMOVE OBJECTIVE" or "SET AS OBJECTIVE",
      font = tweak_data.menu.pd2_medium_font,
      font_size = tweak_data.menu.pd2_medium_font_size
    }, function ()
      LobbyObjective:set_objective(LobbyObjective.settings.objective ~= self._id and self._id or nil)
      managers.menu:force_back()
    end))
  end

end)

Hooks:PostHook(MenuManager, "on_leave_active_job", "on_leave_active_job_lo", function ()

  LobbyObjective:set_objective(nil)

end)

Hooks:Add("BaseNetworkSessionOnPeerEnteredLobby", "BaseNetworkSessionOnPeerEnteredLobbyObjective", function (peer)

  if Network:is_server() and LobbyObjective.settings.objective then
    local visual = tweak_data.achievement.visual[LobbyObjective.settings.objective] or {}
    local message = string.format("Lobby objective: %s\n%s", managers.localization:to_upper_text(visual.name_id), managers.localization:text(visual.desc_id))
    peer:send("send_chat_message", ChatManager.GAME, message)
  end

end)

LobbyObjective:load()