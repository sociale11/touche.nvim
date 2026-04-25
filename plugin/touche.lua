vim.api.nvim_create_user_command("Touche", function()
	require("touche").open()
end, {})

vim.keymap.set("n", "<leader>t", "<cmd>Touche<cr>", { desc = "Touch new file" })
