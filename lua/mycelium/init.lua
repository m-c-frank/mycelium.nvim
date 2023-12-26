local mycelium = {}

local Job = require('plenary.job')
local json = vim.json

mycelium.config = {
    max_prompt_length = 512,
    generate_url = 'http://localhost:11434/api/chat',
    model = "mistral",
    stream = false,
    max_tokens = 8,
}

function mycelium.getBufferContext()
    local buffer = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    local full_text = table.concat(lines, "\n")
    local start_pos = math.max(1, string.len(full_text) - 511)
    return string.sub(full_text, start_pos)
end

function mycelium.makeCurlRequest(url, requestData, callback)
    local jsonData = json.encode(requestData)
    print("json requestData")
    print(jsonData)
    local curlJob = Job:new({
        command = 'curl',
        args = { url, '-d', jsonData, '-H', 'Content-Type: application/json' },
        on_exit = function(j)
            local rawResponse = table.concat(j:result(), "")
            if rawResponse == "" or not rawResponse then
                print("Empty or invalid response received")
                return
            end
            if callback then
                callback(rawResponse)
            end
        end
    })

    -- Start the job
    curlJob:start()
end

local ns_id = vim.api.nvim_create_namespace('mycelium_namespace')

function mycelium.displayResponse(rawResponse)
    print("json response")
    print(rawResponse)
    local response = json.decode(rawResponse)
    local message = response.message.content or "No response"
    vim.schedule(function()
        local buffer = vim.api.nvim_get_current_buf()
        local line = vim.api.nvim_win_get_cursor(0)[1] - 1
        mycelium.createOrUpdateExtMark(buffer, line, message)
    end)
end

function mycelium.createOrUpdateExtMark(buffer, line, text)
    local virt_text = {{text, 'Comment'}}
    local opts = { virt_text = virt_text, virt_text_pos = "eol" }
    vim.api.nvim_buf_set_extmark(buffer, ns_id, line, 0, opts)
end

function mycelium.spaceTrigger()
    local last_char = vim.api.nvim_get_vvar("char")
    print("Space Triggered") -- Debug print
    if last_char == ' ' then
        mycelium.generateText()
    end
end

function mycelium.generatePrompt(bufferContext)
    local prompt = string.format([[
you complete sentences.

you try to follow the users' thoughts.

you always try to predict exactly 8 tokens.

nothing more.

but to compensate for the short prediction tokens,

you have to be extremely precise.

you are a large language model and I am just a bunch of cells.

so let's try to get something started.

it's the start of something huge.

so here is the text you should predict with only 8 tokens:

---
%s
---


so keep in mind that you have to directly respond with the continuation

don't waste any tokens in attempting a chain of thought

or tree of thought methods. do them silently

and just respond with the correct prediction

and remember its just plain text you have to respond with

so now continue this string without any fuss:

%s
]], bufferContext, bufferContext)
    return prompt
end

function mycelium.generateText()
    local bufferContext = mycelium.getBufferContext()
    local prompt = mycelium.generatePrompt(bufferContext)
    local config = mycelium.config
    mycelium.clearResponse()
    mycelium.makeCurlRequest(config.generate_url, {
        model = config.model,
        messages = {
            {
                role = "user",
                content = prompt
            }
        },
        stream = config.stream,
        options = { num_predict = config.max_tokens }
    }, mycelium.displayResponse)
end

function mycelium.clearResponse()
    local buffer = 0 -- Current buffer
    vim.api.nvim_buf_clear_namespace(buffer, ns_id, 0, -1)
end

vim.api.nvim_create_autocmd('InsertCharPre', {
    callback = mycelium.spaceTrigger
})

vim.api.nvim_create_user_command('MClear', mycelium.clearResponse, {})
vim.api.nvim_create_user_command('MGen', mycelium.generateText, {})

return mycelium

