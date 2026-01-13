-- Rank system (100 ranks)
local M = {}

-- Load ranks from data file
M.ranks = nil

function M.load_ranks()
  if M.ranks then
    return M.ranks
  end

  -- Find the plugin directory (go up from lua/typing_kata/core/ranks.lua)
  local source = debug.getinfo(1).source:sub(2)
  local plugin_dir = vim.fn.fnamemodify(source, ':h:h:h:h')

  -- Normalize path separators for cross-platform compatibility
  local sep = package.config:sub(1,1)  -- Get path separator (/ or \)
  local ranks_file = plugin_dir .. sep .. 'data' .. sep .. 'ranks.json'

  local file = io.open(ranks_file, 'r')
  if not file then
    vim.notify('Failed to load ranks.json from: ' .. ranks_file, vim.log.levels.ERROR)
    -- Return minimal ranks to avoid crashes
    return {{id = 0, name = 'Recruit', symbol = '🌱', xp_required = 0}}
  end

  local content = file:read('*a')
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then
    vim.notify('Failed to parse ranks.json: ' .. decoded, vim.log.levels.ERROR)
    return {{id = 0, name = 'Recruit', symbol = '🌱', xp_required = 0}}
  end

  M.ranks = decoded
  return M.ranks
end

-- Get rank by XP
function M.get_rank_by_xp(xp)
  local ranks = M.load_ranks()

  -- Find highest rank achieved
  for i = #ranks, 1, -1 do
    if xp >= ranks[i].xp_required then
      return ranks[i]
    end
  end

  -- Return first rank (Recruit) if no match
  return ranks[1]
end

-- Get rank by ID
function M.get_rank_by_id(id)
  local ranks = M.load_ranks()
  for _, rank in ipairs(ranks) do
    if rank.id == id then
      return rank
    end
  end
  return ranks[1]
end

-- Calculate progress to next rank (0-100%)
function M.progress_to_next_rank(current_xp)
  local ranks = M.load_ranks()
  local current_rank = M.get_rank_by_xp(current_xp)

  -- Max rank reached
  if current_rank.id >= #ranks - 1 then
    return 100
  end

  local next_rank = ranks[current_rank.id + 2]  -- +2 because array is 1-indexed
  local current_xp_required = current_rank.xp_required
  local next_xp_required = next_rank.xp_required

  local progress = (current_xp - current_xp_required) / (next_xp_required - current_xp_required)
  return math.min(100, math.max(0, progress * 100))
end

-- Get all ranks (for display)
function M.get_all_ranks()
  return M.load_ranks()
end

return M
