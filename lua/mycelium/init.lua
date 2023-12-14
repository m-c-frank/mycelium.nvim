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
            local result = json.decode(j:result())
            if result and result.response then
                callback(result.response)
            else
                callback(j:result()) -- Return the entire text if 'response' field does not exist
            end
        end
    }):start()
end

-- Namespace ID for extmarks
local ns_id = vim.api.nvim_create_namespace('mycelium_namespace')

-- Function to create or update an extmark with virtual text
function mycelium.createOrUpdateExtMark(buffer, line, text, highlight_group, virt_text_pos)
    local virt_text = {{text, highlight_group}}
    local opts = { virt_text = virt_text, virt_text_pos = virt_text_pos or "eol" }
    vim.api.nvim_buf_set_extmark(buffer, ns_id, line, 0, opts)
end

-- Function to display the response as virtual text
function mycelium.displayResponse(response)
    if response then
        vim.schedule(function()
            local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Current line (0-based index)
            mycelium.createOrUpdateExtMark(0, line, response, 'Comment', 'eol')
        end)
    end
end

-- Main function to generate text
function mycelium.generateText()
    local prompt = mycelium.getPrompt()
    mycelium.makeCurlRequest(prompt, mycelium.displayResponse)
end

-- Command to trigger the text generation
vim.api.nvim_create_user_command('Gen', mycelium.generateText, {})

return mycelium

