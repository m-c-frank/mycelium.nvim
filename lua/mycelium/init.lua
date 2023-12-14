local mycelium = {}

local Job = require('plenary.job')
local json = vim.json
local cmp = require('cmp')

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

-- Completion source for nvim-cmp
local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.complete = function(self, request, callback)
  local prompt = mycelium.getPrompt()
  mycelium.makeCurlRequest(prompt, function(result)
    local items = vim.tbl_map(function(item)
      return { label = item }
    end, result)
    callback({ items = items, isIncomplete = true })
  end)
end

-- Register the completion source
cmp.register_source('mycelium', source.new())

-- Main function to generate text
function mycelium.generateText()
    local prompt = mycelium.getPrompt()
    mycelium.makeCurlRequest(prompt, function(result) end)
end

-- Command to trigger the text generation
vim.api.nvim_create_user_command('Gen', mycelium.generateText, {})

return mycelium

