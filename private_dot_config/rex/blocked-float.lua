-- Float detached workers that are waiting on you.
--
-- When a detached block reports `blocked` (a Claude Code permission prompt,
-- say), move it into the active window as a floating layer and open a case
-- with the prompt's message. When it reports anything else, or exits, put it
-- back out of sight and withdraw the case. Blocks that are already placed are
-- left alone: you can see those.
--
--   rex do ~/.config/rex/blocked-float.lua --all

local BOUNDS = { 0.1, 0.08, 0.8, 0.8 }

-- block_id -> { case = id or nil, session = id }
local floated = {}

-- A block in the active window's tiled layout: the focused one if it is
-- tiled, else the first tiled block, else the focused block. Anchoring on a
-- block in a floating layer (a rex-lead roster, say) would split the worker
-- into that layer instead.
local function anchor(session_id)
  local view = rex.session.view{ session_id = session_id }
  if not view then return nil end
  for _, w in ipairs(view.windows or {}) do
    if w.window_id == view.active_window_id then
      for _, layer in ipairs(w.layers or {}) do
        if layer.kind == "tiled" and layer.blocks and layer.blocks[1] then
          for _, b in ipairs(layer.blocks) do
            if b.block_id == w.focused_block_id then return b.block_id end
          end
          return layer.blocks[1].block_id
        end
      end
      return w.focused_block_id
    end
  end
end

local function open_case(label, msg)
  local r = rex.exec({
    "cases", "open", "--json",
    "--kind", "stuck", "--urgency", "blocking",
    "--title", label .. " is waiting on a prompt",
    "--body", (msg ~= nil and msg ~= "") and msg or "Blocked with no message.",
    "--worker", label, "--label", "rex-watch",
  }, { timeout = 10 })
  if r and r.ok then return rex.json.decode(r.stdout).id end
  rex.log("warn", "cases open failed: " .. ((r and r.stderr) or "did not run"))
end

local function float(session_id, block_id, msg)
  local d = rex.session.describe_block{ session_id = session_id, block_id = block_id }
  if not d or d.block.placement ~= "detached" then return end
  local a = anchor(session_id)
  if not a then return end
  local _, err = rex.session.move_block{ session_id = session_id, block_id = block_id, anchor_block_id = a }
  if err then return rex.log("warn", "move_block: " .. err) end
  _, err = rex.session.float_block{ session_id = session_id, block_id = block_id, bounds = BOUNDS }
  if err then rex.log("warn", "float_block: " .. err) end
  local label = d.block.label or block_id
  floated[block_id] = { session = session_id, case = open_case(label, msg) }
  print("floated " .. label .. ": " .. (msg or ""))
end

local function sink(block_id, closed)
  local f = floated[block_id]
  if not f then return end
  floated[block_id] = nil
  if not closed then rex.session.detach_block{ session_id = f.session, block_id = block_id } end
  if f.case then
    rex.exec({ "cases", "withdraw", f.case, "--reason", "No longer blocked" }, { timeout = 10 })
  end
  print("sank " .. block_id)
end

rex.on("terminal.program_status_changed", function(ctx, ev)
  -- Only the program's own record (no id), not its sub-tasks.
  if type(ev.id) == "string" and ev.id ~= "" then return end
  local state = type(ev.record) == "table" and ev.record.state
  if state == "blocked" then
    if not floated[ctx.block_id] then float(ctx.session_id, ctx.block_id, ev.record.msg) end
  else
    sink(ctx.block_id, false)
  end
end)

rex.on("terminal.program_status_removed", function(ctx, _) sink(ctx.block_id, false) end)
rex.on("block_closed", function(_, ev) sink(ev.block_id, true) end)
