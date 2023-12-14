# mycelium.nvim

this lets you tap into your private mesh

similar to github copilot

ultra minimal and using ollama

have all the information at your fingertips

## roadmap

- [x] curl to local ollama
- [x] display response as virtual text
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
    require("mycelium")
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

