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
    print("Sending request with data: " .. data)
    Job:new({
        command = 'curl',
        args = {'-X', 'POST', 'http://localhost:11434/api/generate', '-d', data},
        on_exit = function(j)
            callback(j:result())
        end
    }):start()
end

-- Function to display the response in the buffer
function mycelium.displayInBuffer(response)
    vim.schedule(function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_lines(0, line, line, false, response)
    end)
end

-- Main function to generate text
function mycelium.generateText()
    local prompt = mycelium.getPrompt()
    mycelium.makeCurlRequest(prompt, mycelium.displayInBuffer)
end

-- Command to trigger the text generation
vim.api.nvim_create_user_command('Gen', mycelium.generateText, {})

return mycelium

