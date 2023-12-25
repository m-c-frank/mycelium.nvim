local mycelium = {}

local Job = require('plenary.job')
local json = vim.json

mycelium.config = {
    max_prompt_length = 512,
    generate_url = 'http://localhost:11434/api/generate',
    model = "mistral",
    stream = true,
    max_tokens = 8,
}

function mycelium.getBufferContext()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line, col = cursor_pos[1], cursor_pos[2]
    local lines = vim.api.nvim_buf_get_lines(0, 0, line, false)

    local full_text = table.concat(lines, "\n")
    full_text = full_text .. string.sub(lines[#lines], 1, col)
    local start_pos = math.max(1, string.len(full_text) - 512 + 1)

    return string.sub(full_text, start_pos)
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

<SPORE>
%s
</SPORE>

so keep in mind that you have to directly respond with that.

don't waste any tokens in attempting a chain of thought

or tree of thought methods. do them silently

and just respond with the correct prediction:

]], bufferContext)
    return prompt
end

function mycelium.generateText()
    local bufferContext = mycelium.getBufferContext()
    local prompt = mycelium.generatePrompt(bufferContext)
    local config = mycelium.config
    mycelium.clearResponse()
    mycelium.makeCurlRequest(config.generate_url, { model = config.model, prompt = prompt, stream = config.stream, options = { num_predict = config.max_tokens } }, mycelium.displayResponse)
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

