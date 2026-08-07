vim.api.nvim_create_user_command("ReZero", function()
	require("re-zero").open()
end, {})

vim.api.nvim_create_user_command("ReZeroReview", function()
	require("re-zero").review()
end, {})

vim.api.nvim_create_user_command("ReZeroUpdate", function()
	require("re-zero").daily_check()
end, {})

vim.keymap.set("n", "<leader>tt", function()
	if vim.bo.modified then vim.cmd("write") end
	require("re-zero").open()
end)
