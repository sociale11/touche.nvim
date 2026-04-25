local M = {}

local function list_dirs()
	local raw = vim.fn.systemlist(
		"find . -mindepth 1 -type d -not -path '*/.git/*' | sed 's|^\\./||' | sort"
	)
	local dirs = { "./" }
	for _, d in ipairs(raw) do
		if d ~= "" then
			table.insert(dirs, d .. "/")
		end
	end
	return dirs
end

local function create_file(path)
	if not path or path == "" then
		return
	end
	path = path:gsub("^%./", "")
	if path:match("/$") then
		vim.notify("touche: path must include a filename", vim.log.levels.WARN)
		return
	end
	local dir = vim.fn.fnamemodify(path, ":h")
	if dir ~= "." then
		if vim.fn.mkdir(dir, "p") == 0 then
			vim.notify("touche: failed to create directory: " .. dir, vim.log.levels.ERROR)
			return
		end
	end
	vim.fn.system({ "touch", path })
	if vim.v.shell_error ~= 0 then
		vim.notify("touche: touch failed for: " .. path, vim.log.levels.ERROR)
		return
	end
	vim.notify("Created: " .. path)
end

function M.open()
	local dirs = list_dirs()
	local input_file = vim.fn.tempname()
	local output_file = vim.fn.tempname()
	vim.fn.writefile(dirs, input_file)

	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.5)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	local cmd = string.format(
		"cat %s | fzf --prompt='New file > ' --print-query --bind='tab:replace-query,up:up+replace-query,down:down+replace-query' > %s",
		vim.fn.shellescape(input_file),
		vim.fn.shellescape(output_file)
	)

	vim.fn.termopen(cmd, {
		on_exit = function(_, code)
			vim.schedule(function()
				pcall(vim.api.nvim_win_close, win, true)
				vim.fn.delete(input_file)

				if code == 130 then
					vim.fn.delete(output_file)
					return
				end

				local lines = vim.fn.readfile(output_file)
				vim.fn.delete(output_file)

				-- first line is always the query (--print-query)
				if #lines > 0 and lines[1] ~= "" then
					create_file(lines[1])
				end
			end)
		end,
	})

	vim.cmd("startinsert")
end

return M
