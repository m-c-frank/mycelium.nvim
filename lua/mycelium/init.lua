local mycelium = {}

local Job = require('plenary.job')
local json = vim.json

local config = {
    max_prompt_length = 512,
    generate_url = 'http://localhost:11434/api/generate',
    stop_url = 'http://localhost:11434/api/stop',
    model = "mistral",
    stream = true,
    max_tokens = 8,
}

function mycelium.getPrompt()
    local full_prompt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    return string.sub(full_prompt, 1, config.max_prompt_length)
end

function mycelium.makeCurlRequest(url, requestData, callback)
    print("Making Curl Request") -- Debug print
    Job:new({
        command = 'curl',
        args = {'-X', 'POST', url, '-d', json.encode(requestData)},
        on_stdout = function(_, response)
            print("Response received: " .. response) -- Debug print
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

local ns_id = vim.api.nvim_create_namespace('mycelium_namespace')

function mycelium.createOrUpdateExtMark(buffer, line, text)
    local virt_text = {{text, 'Comment'}}
    local opts = { virt_text = virt_text, virt_text_pos = "eol" }
    vim.api.nvim_buf_set_extmark(buffer, ns_id, line, 0, opts)
end

function mycelium.displayResponse(response)
    if response then
        vim.schedule(function()
            local line = vim.api.nvim_win_get_cursor(0)[1] - 1
            mycelium.createOrUpdateExtMark(0, line, response)
        end)
    end
end

function mycelium.spaceTrigger()
    local last_char = vim.api.nvim_get_vvar("char")
    print("Space Triggered") -- Debug print
    if last_char == ' ' then
        mycelium.generateText()
    end
end

function mycelium.generateText()
    local prompt = mycelium.getPrompt()
    mycelium.clearResponse()
    mycelium.makeCurlRequest(config.generate_url, { model = config.model, prompt = prompt, stream = config.stream, options = { num_predict = config.max_tokens } }, mycelium.displayResponse)
end

function mycelium.stopOllamaGeneration()
    Job:new({
        command = 'curl',
        args = {'-X', 'POST', config.stop_url}
    }):start()
end

function mycelium.clearResponse()
    local buffer = 0 -- Current buffer
    vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)
end

vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = mycelium.spaceTrigger
})

vim.api.nvim_create_user_command('ClearGen', mycelium.clearResponse, {})
vim.api.nvim_create_user_command('Gen', mycelium.generateText, {})
vim.api.nvim_create_user_command('StopGen', mycelium.stopOllamaGeneration, {})

return mycelium

