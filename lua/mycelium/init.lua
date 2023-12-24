local mycelium = {}

-- Import required modules
local Job = require('plenary.job')
local json = vim.json

-- Configuration
local config = {
    max_prompt_length = 512,
    generate_url = 'http://localhost:11434/api/generate',
    stop_url = 'http://localhost:11434/api/stop',
    model = "mistral",
    stream = true,
}

-- Function to get the current prompt from the editor
function mycelium.getPrompt()
    local full_prompt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    return string.sub(full_prompt, 1, config.max_prompt_length)
end

-- Function to make a streaming cURL request to the server
function mycelium.makeCurlRequest(url, requestData, callback)
    Job:new({
        command = 'curl',
        args = {'-X', 'POST', url, '-d', json.encode(requestData)},
        on_stdout = function(_, response)
            if response then
                local json_response = json.decode(response)
                if json_response and json_response.response then
                    callback(json_response.response)
                end
            end
        end,
        stdout_buffered = false,
        stderr_buffered = false,
    }):start()
end

-- Namespace ID for extmarks
local ns_id = vim.api.nvim_create_namespace('mycelium_namespace')

-- Function to create or update an extmark with virtual text
function mycelium.createOrUpdateExtMark(buffer, line, text)
    local virt_text = {{text, 'Comment'}}
    local opts = { virt_text = virt_text, virt_text_pos = "eol" }
    vim.api.nvim_buf_set_extmark(buffer, ns_id, line, 0, opts)
end

-- Function to display the response as virtual text
function mycelium.displayResponse(response)
    if response then
        vim.schedule(function()
            local line = vim.api.nvim_win_get_cursor(0)[1] - 1
            mycelium.createOrUpdateExtMark(0, line, response)
        end)
    end
end

-- Function to generate text on space press
function mycelium.spaceTrigger()
    local last_char = vim.api.nvim_get_vvar("char")
    if last_char == ' ' then
        mycelium.generateText()
    end
end

-- Main function to generate text
function mycelium.generateText()
    local prompt = mycelium.getPrompt()
    mycelium.makeCurlRequest(config.generate_url, { model = config.model, prompt = prompt, stream = config.stream }, mycelium.displayResponse)
end

-- Function to stop the ongoing generation
function mycelium.stopOllamaGeneration()
    Job:new({
        command = 'curl',
        args = {'-X', 'POST', config.stop_url}
    }):start()
end

-- Autocommand to trigger text generation on pressing space
vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = mycelium.spaceTrigger
})

-- Commands to trigger the text generation and stop functions
vim.api.nvim_create_user_command('Gen', mycelium.generateText, {})
vim.api.nvim_create_user_command('StopGen', mycelium.stopOllamaGeneration, {})

return mycelium

