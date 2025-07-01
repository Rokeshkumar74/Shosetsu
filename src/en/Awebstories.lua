-- {"id":954054,"ver":"0.2.1","libVer":"1.0.0","author":"N4O","dep":["Bixbox>=1.1.1","WPCommon>=1.0.2"]}

local WPCommon = Require("WPCommon")

return Require("Bixbox")("https://awebstories.com", {
    id = 954054,
    name = "Awebstories",
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Awebstories.png",

    availableGenres = {
        "Action",
        "Adventure",
        "Comedy",
        "Drama",
        "Ecchi",
        "Fantasy",
        "Harem",
        "Historical",
        "Horror",
        "Martial Arts",
        "Mature",
        "Mystery",
        "Psychological",
        "Romance",
        "School Life",
        "Seinen",
        "Shoujo",
        "Shounen",
        "Slice of Life",
        "Supernatural",
        "Tragedy"
    },

    availableTypes = {
        "Published Novel (JP)",
        "Web Novel"
    },

    --- @param content Element
    stripMechanics = function (content)
        map(content:children(), function (child)
            local id = child:attr("id")
            if WPCommon.contains(id, "ezoic") then
                child:remove()
            end
        end)
    end
})