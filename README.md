# mycelium.nvim

part of the mycelium and hyphalnet vision

this lets you tap into your private mesh

similar to github copilot

ultra minimal and using ollama

have all the information at your fingertips

## current state

as of now it uses hints similar to copilot

but i want to make it feel more powerful

it should learn from you

and it must stay completely local and secure

## roadmap

- [x] curl to local ollama
- [x] display response as virtual text
- [x] configure ollama location
- [ ] accepting response functionality
- [ ] storing the user interactions for training data
- [ ] use every interaction as training example
- [ ] schedule async training of model and updating weights for ollama

## installation

using kickstart.nvim:

just put this .config/nvim/lua/custom/plugins/mycelium.lua

```lua
return {
  'm-c-frank/mycelium.nvim',
  config = function()
    local mycelium = require("mycelium")
    mycelium.config.generate_url="http://192.168.2.177:11434/api/generate"
  end,
}
```

run `:Lazy` check and make sure mycelium is listed somewhere

## goal

just write down what you think

in the background it will be transformed into action

the vision is that whenever you trigger mycelium

then it will start building fruiting bodies

those can range from just publishing some text on your blog

or getting a pull request with the full implementation of an idea

this must be possible

and this is my way of getting it done

we only need to connect a few dots

