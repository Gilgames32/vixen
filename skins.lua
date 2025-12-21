local wheel = require("wheel")

local skinEntries = {
    Rebecca = {
        texture = "skin_rebecca",
        icon = "minecraft:command_block",
    },
    Mira = {
        texture = "skin_mira",
        icon = "minecraft:target",
    },
    Eva = {
        texture = "skin_eva",
        icon = "minecraft:crimson_nylium",
    },
    Rue = {
        texture = "skin_rue",
        icon = "minecraft:red_sand",
    },
    Kaya = {
        texture = "skin_kaya",
        icon = "minecraft:snow_block",
    },
}

-- skin entries
for key, value in pairs(skinEntries) do
    wheel.skinPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        models.model.root:setPrimaryTexture("CUSTOM", textures[value.texture])
    end)
end