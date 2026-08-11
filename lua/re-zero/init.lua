local M = {}
local SECTION_ACTIVE = "## Active"
local SECTION_PENDING = "## Pending"
local SECTION_FINISHED = "## Finished"
local HEADER_MARK = {
	[SECTION_ACTIVE] = "*",
	[SECTION_PENDING] = " ",
	[SECTION_FINISHED] = "X"
}
local FILE_DIR = vim.fn.expand("~") .. "/re-zero/"
local FILE_PATH = FILE_DIR .. "todo.md"
local ARCHIVE_DIR = FILE_DIR .. "archive/"

-- return the line and parent task if exists
-- task:   - task1 (parent task)
-- output: - task1, parent task
local function unformat_task(task)
	local sub_task = task:match("^(- %[.%] .-) %(.+%)$")
	local parent_task = task:match("^- %[.%] .-%((.+)%)$")

	return sub_task, parent_task
end

-- return task with appended parent task
-- task:   - task1
-- parent: (parent task)
-- output: - task1 (parent task)
local function format_task(task, parent)
	local parent_text = parent:gsub("^- %[.%] ", "")
	local new_task = "- [ ] " .. task .. " (" .. parent_text .. ")"

	return new_task
end

-- adds a specified header to end of file
local function create_header(buf, header)
	local file_text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local last_line = file_text[#file_text]

	if last_line == "" then
		vim.api.nvim_buf_set_lines(buf, #file_text, #file_text, false, { header })
		return #file_text + 1
	else
		vim.api.nvim_buf_set_lines(buf, #file_text, #file_text, false, { "", header })
		return #file_text + 2
	end
end

-- returns the line number of a header
local function find_header_lnum(buf, header)
	local header_lnum = nil
	local file_text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- run through todo.md file
	-- find matching header line number
	for index, line in ipairs(file_text) do
		if line == header then
			header_lnum = index
			break
		end
	end

	if header_lnum == nil then
		header_lnum = create_header(buf, header)
	end

	return header_lnum
end

-- returns the line number of the last task a list
local function next_task_lnum(buf, header)
	local header_lnum = find_header_lnum(buf, header)
	local end_lnum = header_lnum
	local file_text = vim.api.nvim_buf_get_lines(buf, header_lnum, -1, false)

	-- run through tasks after heading
	-- find last space before next header
	for index, line in ipairs(file_text) do
		if line == "" then
			end_lnum = end_lnum + index - 1
			break
		end

		if index == #file_text then
			end_lnum = end_lnum + index
			break
		end
	end

	return end_lnum
end

-- move the currently hovered task to another list
local function move_task(buf, curr_lnum, section, mark)
	local curr_line = vim.api.nvim_buf_get_lines(buf, curr_lnum - 1, curr_lnum, false)[1]
	local sub_task, parent_task = nil, nil

	-- determine if task has parent task and reformat
	if curr_line:match("^- %[.%] (.-) %((.+)%)$") ~= nil and section ~= SECTION_ACTIVE then
		sub_task, parent_task = unformat_task(curr_line)
	else
		sub_task = curr_line
	end

	-- move task to finished
	if sub_task:match("^- %[ %]") or sub_task:match("^- %[%*%]") then
		vim.api.nvim_buf_set_lines(buf, curr_lnum - 1, curr_lnum, false, {})

		local fin_header_lnum = next_task_lnum(buf, section)
		local new_line = sub_task:gsub("^(- %[).(%])", "%1" .. mark .. "%2", 1)
		vim.api.nvim_buf_set_lines(buf, fin_header_lnum, fin_header_lnum, false, { new_line })
	end

	-- move parent task to pending
	if parent_task ~= nil and section == SECTION_FINISHED then
		parent_task = "- [ ] " .. parent_task
		local pending_lnum = next_task_lnum(buf, SECTION_PENDING)
		vim.api.nvim_buf_set_lines(buf, pending_lnum, pending_lnum, false, { parent_task })
	end
end

-- add new task in pending list
-- enter insert mode at end of line
-- active:    - [*]
-- pending:   - [ ]
-- finished:  - [X]
local function enter_task(buf)
	local pending_lnum = next_task_lnum(buf, SECTION_PENDING)

	vim.api.nvim_buf_set_lines(buf, pending_lnum, pending_lnum, false, { "- [ ] " })
	vim.api.nvim_win_set_cursor(0, { pending_lnum + 1, 0 })
	vim.cmd("startinsert!")
end

-- deletes the temporary keymaps
local function delete_keymaps(buf)
	for _, lhs in ipairs({ "h", "j", "k", "u", "<Esc>" }) do
		vim.keymap.del("n", lhs, { buffer = buf })
	end
end

-- clears the list under specific header
local function clear_list(buf, header)
	local header_lnum = find_header_lnum(buf, header)
	local end_lnum = next_task_lnum(buf, header)

	vim.api.nvim_buf_set_lines(buf, header_lnum, end_lnum, false, {})
end

-- if new day, archive the current file
-- clear finished list for a new day
function M.daily_check()
	local buf = vim.fn.bufadd(FILE_PATH)
	vim.fn.bufload(buf)
	local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
	local file_date = first_line:match("(%d%d%d%d%-%d%d%-%d%d)")
	local curr_date = os.date("%Y-%m-%d")

	if file_date == curr_date then return end

	if file_date then
		vim.fn.mkdir(ARCHIVE_DIR, "p")
		local file_name = ARCHIVE_DIR .. file_date .. ".md"
		vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), file_name)
		clear_list(buf, SECTION_FINISHED)
	end

	vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "# TODO " .. curr_date })
	vim.cmd("write")
end

-- open or create tasks.md
-- position the cursor at the end of the list
function M.open()
	vim.fn.mkdir(FILE_DIR, "p")

	-- create the file if doesn't exist
	-- add three empty list headers
	if vim.fn.filereadable(FILE_PATH) == 0 then
		vim.fn.writefile({
			"# TODO",
			"",
			"## Active",
			"",
			"## Pending",
			"",
			"## Finished"},
			FILE_PATH)
	end

	vim.cmd.edit(FILE_PATH)
	local buf = vim.api.nvim_get_current_buf()
	M.daily_check()

	-- if current line is a header line
	local function header_check(line)
		local header_mark = HEADER_MARK[line]

		if header_mark then
			return "- [" .. header_mark .. "] "
		end
	end

	-- if the task line is blank
	local function blank_check(line)
		if line:match("^- %[.%] $") then
			return string.rep("\b", #line)
		end
	end

	-- if the current line is a task
	local function task_check(line)
		local mark = line:match("^- %[(.)%] .+")
		if mark then
			return "- [" .. mark .. "] "
		end
	end

	-- makes nessecary line checks to create "smart" enter functionality
	local function smart_enter(line)
		local check = task_check(line) or header_check(line)

		return blank_check(line) or (check and "\r" .. check) or "\r"
	end

	-- makes nessecary line checks ot create "smart" o functionality
	local function smart_open(line)
		return "o" .. (header_check(line) or task_check(line) or "")
	end

	-- enter to mark finished
	vim.keymap.set("n", "<CR>", function()
		local curr_lnum = vim.api.nvim_win_get_cursor(0)[1]
		move_task(buf, curr_lnum, SECTION_FINISHED, "X")
	end, { buffer = buf })

	-- open input for new task in pending list
	vim.keymap.set("n", "<leader>td", function()
		enter_task(buf)
	end, { buffer = buf })

	-- enters review mode
	vim.keymap.set("n", "<leader>tr", function()
		require("re-zero").review()
	end, { buffer = buf })

	-- insert mode "smart" enter
	vim.keymap.set("i", "<CR>", function()
		return smart_enter(vim.api.nvim_get_current_line())
	end, { buffer = buf, expr = true })

	-- remap "o" in normal mode to be "smart"
	vim.keymap.set("n", "o", function()
		return smart_open(vim.api.nvim_get_current_line())
	end, { buffer = buf, expr = true })

	-- run daily check
	vim.keymap.set("n", "<leader>tu", function()
		M.daily_check()
	end, { buffer = buf })
end

-- iterative over pending tasks in reverse
function M.review()
	local buf = vim.api.nvim_get_current_buf()
	M.daily_check()
	local header_lnum = find_header_lnum(buf, SECTION_PENDING)
	local pending_lnum = next_task_lnum(buf, SECTION_PENDING)
	local task_list = vim.api.nvim_buf_get_lines(buf, header_lnum, pending_lnum, false)
	local index = #task_list

	local function show_next_task()
		-- recursive stop
		if index == 0 then return end

		local new_header_lnum = find_header_lnum(buf, SECTION_PENDING)
		local last_task_lnum = new_header_lnum + index

		local curr_task = task_list[index]
		local review_buf = vim.api.nvim_create_buf(false, true)
 		vim.api.nvim_buf_set_lines(review_buf, 1, -1, false, { curr_task })

		local review_win = vim.api.nvim_open_win(review_buf, false, {
			relative = "editor",
			width = 60,
			height = 3,
			row = (vim.o.lines - 3) / 2,
			col = (vim.o.columns - 60) / 2,
			border = "rounded",
			title = " Review Mode ",
			title_pos = "center",
			footer = " [h] resistance  [j] re-zero  [k] complete  [u] undo ",
			footer_pos = "center",
			style = "minimal"
		})

		-- performs the subtask action set
		local function exe_subtask(input_text)
			index = index - 1
			vim.api.nvim_buf_call(buf, function()
				vim.api.nvim_buf_set_lines(buf, last_task_lnum - 1, last_task_lnum, false, {})
			end)

			local target_lnum = next_task_lnum(buf, SECTION_PENDING)
			local _, existing_parent = unformat_task(curr_task)
			local new_task = format_task(input_text, existing_parent or curr_task)

			vim.api.nvim_buf_call(buf, function()
				vim.api.nvim_buf_set_lines(buf, target_lnum, target_lnum, false, { new_task })
			end)
			delete_keymaps(buf)
		end

		-- opens input window for user subtask
		local function some_re_action()
			local input_buf = vim.api.nvim_create_buf(false, true)
			vim.bo[input_buf].buftype = "prompt"
			vim.fn.prompt_setprompt(input_buf, "> ")

			local input_win = vim.api.nvim_open_win(input_buf, true, {
				relative = "editor",
				width = 60,
				height = 1,
				row = (vim.o.lines - 3) / 2 + 6,
				col = (vim.o.columns - 60) / 2,
				border = "rounded",
				title = " Enter Subtask ",
				title_pos = "center",
				style = "minimal"
			})

			vim.cmd("startinsert!")
			vim.fn.prompt_setcallback(input_buf, function(text)
				if text == "" then return end

				vim.schedule(function()
					exe_subtask(text)

					-- close input buffer
					vim.api.nvim_win_close(input_win, true)
					vim.api.nvim_buf_delete(input_buf, { force = true })

					-- close review buffer
					vim.api.nvim_win_close(review_win, true)
					vim.api.nvim_buf_delete(review_buf, { force = true })

					show_next_task()
				end)
			end)

			-- [Esc] escape
			vim.keymap.set("n", "<Esc>", function()
				-- close input buffer
				vim.api.nvim_win_close(input_win, true)
				vim.api.nvim_buf_delete(input_buf, { force = true })
			end, { buffer = input_buf })
		end

		-- performs the same four steps on every keymap
		-- remove last task from list, perform action on task, close win and buffer, next task
		local function close_buffers()
			vim.api.nvim_win_close(review_win, true)
			vim.api.nvim_buf_delete(review_buf, { force = true })
			delete_keymaps(buf)
			show_next_task()
		end

		-- executes inner function and adjusts index
		local function task_action(action)
			return function()
				index = index - 1
				action(curr_task)
				close_buffers()
			end
		end

		-- [h] some resistance
		vim.keymap.set("n", "h", some_re_action, { buffer = buf })

		-- [j] no resistance
		vim.keymap.set("n", "j", task_action(function()
			move_task(buf, last_task_lnum, SECTION_ACTIVE, "*")
		end), { buffer = buf })

		-- [k] completed
		vim.keymap.set("n", "k", task_action(function()
			move_task(buf, last_task_lnum, SECTION_FINISHED, "X")
		end), { buffer = buf })

		-- [u] undo
		vim.keymap.set("n", "u", function()
			if index == #task_list then return end
			index = index + 1
			vim.cmd("undo")
			close_buffers()
		end, { buffer = buf })

		-- [Esc] escape
		vim.keymap.set("n", "<Esc>", function()
			vim.api.nvim_win_close(review_win, true)
			vim.api.nvim_buf_delete(review_buf, { force = true })
			delete_keymaps(buf)
		end, { buffer = buf })
	end

	show_next_task()
end

return M
