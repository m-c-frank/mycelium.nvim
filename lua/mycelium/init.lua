local mycelium = {}

local Job = require('plenary.job')
local json = vim.json

-- Function to get the current prompt from the editor
function mycelium.getPrompt()
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

-- Function to make a cURL request to the localhost server
function mycelium.makeCurlRequest(prompt, callback)
    local data = json.encode({ model = "llama2", prompt = prompt, stream = false })
    print("Sending request with data: " .. data)  -- Print the sent request
    Job:new({
        command = 'curl',
        args = {'-X', 'POST', 'http://localhost:11434/api/generate', '-d', data},
        on_exit = function(j)
            callback(j:result())
        end
    }):start()
end

-- Function to display the response as an overlay
function mycelium.displayOverlay(response)
    vim.schedule(function()
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, response)
        local win_id = vim.api.nvim_open_win(bufnr, false, {
            relative = 'cursor',
            width = 50,
            height = 10,
            col = 1,
            row = 1,
            style = 'minimal',
            border = 'rounded'
        })
        vim.api.nvim_win_set_option(win_id, 'winblend', 20) -- Set the window as semi-transparent
    end)
end

-- Main function to generate text
function mycelium.generateText()
    local prompt = mycelium.getPrompt()
    mycelium.makeCurlRequest(prompt, mycelium.displayOverlay)
end

-- Command to trigger the text generation
vim.api.nvim_create_user_command('Gen', mycelium.generateText, {})

return mycelium

