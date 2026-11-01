-- Rex configuration
--
-- Keys follow the herdr setup (~/.config/herdr/config.toml). herdr workspaces
-- are Rex sessions, herdr tabs are Rex tabs (windows), panes are panes.

-- Panes: vim-style focus on cmd+hjkl and ctrl+hjkl. The ctrl chords are taken
-- from the terminal, as in herdr: ctrl+h (Backspace sends DEL, so fine),
-- ctrl+j (newline; Claude Code uses Shift+Enter), ctrl+k (unused),
-- ctrl+l (clear screen, cosmetic). cmd+h needs macOS "Hide Rex Beta" moved
-- off it in System Settings > Keyboard > App Shortcuts.
for key, dir in pairs{ h = "left", j = "down", k = "up", l = "right" } do
  rex.bind("cmd+" .. key, "pane.focus." .. dir)
  rex.bind("ctrl+" .. key, "pane.focus." .. dir)
end

rex.bind("cmd+d", "pane.split.right")
rex.bind("cmd+shift+d", "pane.split.down")
rex.bind("cmd+w", "pane.close")
rex.bind("cmd+shift+enter", "pane.zoom")
rex.bind("cmd+shift+e", "pane.balance")

-- Resize mode: arrows or hjkl, Escape to leave
rex.bind("cmd+ctrl+r", "client.mode.enter", { name = "resize" })
for _, k in ipairs{ { "left", "h" }, { "down", "j" }, { "up", "k" }, { "right", "l" } } do
  rex.bind("resize/" .. k[1], "pane.resize", { direction = k[1] })
  rex.bind("resize/" .. k[2], "pane.resize", { direction = k[1] })
end

-- Tabs: cmd+shift+1..9 jumps to tab N (physical digit keys, so the UK
-- layout's shifted symbols don't matter)
rex.bind("cmd+t", "client.tab.new")
rex.bind("cmd+n", "client.tab.new")
rex.bind("cmd+shift+[", "client.tab.previous")
rex.bind("cmd+shift+]", "client.tab.next")
for i = 1, 9 do
  rex.bind("cmd+shift+[Digit" .. i .. "]", "client.tab.goto", { index = i })
end

-- Sessions (herdr workspaces): cmd+1..9 jumps to session N in sidebar order,
-- ctrl+shift+k/j or up/down moves up and down the list
rex.action{
  name = "goto_session",
  title = "Go to Session N",
  args = { index = "integer" },
  run = function(ctx, args)
    local result, err = rex.call("session.list")
    if not result then return nil, err end
    local s = result.sessions[args.index]
    if s then rex.client.queue("session.select", { session_id = s.session_id }) end
  end,
}
for i = 1, 9 do
  rex.bind("cmd+" .. i, "goto_session", { index = i })
end
rex.bind("ctrl+shift+k", "session.previous")
rex.bind("ctrl+shift+up", "session.previous")
rex.bind("ctrl+shift+j", "session.next")
rex.bind("ctrl+shift+down", "session.next")
rex.bind("cmd+shift+n", "session.new")
rex.bind("cmd+g", "session.switch")

rex.bind("cmd+shift+b", "client.sidebar.toggle")
rex.bind("cmd+/", "client.sidebar.toggle")
rex.bind("cmd+p", "client.palette.toggle")

-- rex-lead roster: cmd+alt+r jumps focus between a lead and its roster, the
-- floating pane labelled roster-<last 6 of the lead's block id>, in the
-- active tab. From the lead (or any pane with no roster of its own) it goes to
-- the roster; from a roster it goes back to that roster's lead. [KeyR] binds
-- the physical key, since alt changes the character on a Mac layout.
rex.action{
  name = "roster_toggle",
  title = "Toggle Roster and Lead",
  run = function(ctx)
    local view, err = rex.session.view{ session_id = ctx.session_id }
    if not view then error(err, 0) end
    local win
    for _, w in ipairs(view.windows or {}) do
      if w.window_id == view.active_window_id then win = w end
    end
    if not win or not win.focused_block_id then return end
    local here, labels, rosters, count = win.focused_block_id, {}, {}, 0
    for _, layer in ipairs(win.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        labels[b.block_id] = b.label or ""
        local s = labels[b.block_id]:match("^roster%-(%x%x%x%x%x%x)$")
        if s then rosters[s], count = b.block_id, count + 1 end
      end
    end
    local target
    local lead = (labels[here] or ""):match("^roster%-(%x%x%x%x%x%x)$")
    if lead then
      for id in pairs(labels) do
        if id ~= here and id:sub(-6) == lead then target = id end
      end
    else
      target = rosters[here:sub(-6)]
      if not target and count == 1 then target = select(2, next(rosters)) end
    end
    if target then rex.session.focus_block{ session_id = ctx.session_id, block_id = target } end
  end,
}
rex.bind("cmd+alt+[KeyR]", "roster_toggle")
