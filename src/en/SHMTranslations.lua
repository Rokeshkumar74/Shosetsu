-- {"id":176796,"ver":"0.1.7","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://www.shmtranslations.com"
local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    -- remove www
    url = url:gsub("www%.", ""):lower()
    -- remove shmtranslations.com
    url = url:gsub("shmtranslations%.com", "")
    -- remove https://
    url = url:gsub("https?://", "")
    return url
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

--- @param v Element
local function passageCleanup(v)
    if WPCommon.cleanupElement(v) then
        return
    end
    if WPCommon.isTocRelated(v:text()) then
        v:remove()
        return
    end
    local classData = v:attr("class")
    if WPCommon.contains(classData, "wp-post-nav-shortcode") then
        -- the new ToC nav
        v:remove()
        return
    end
    local isTocButton = classData and classData:find("wp-block-buttons", 0, true) and true or false
    if isTocButton then
        v:remove()
        return
    end
    if WPCommon.contains(classData, "ai-viewport-") then
        v:remove()
        return
    end
    -- nuke "SHMtranslation" watermark, it's fucking annoying as an actual reader
    local text = v:text()
    if WPCommon.contains(text:upper(), "SHMTRANSLATION") then
        v:remove()
        return
    end
    local adsByGoogle = v:selectFirst("ins.adsbygoogle")
    if adsByGoogle then
        adsByGoogle:remove()
    end
end

--- @param paragraph Element
local function cleanupChildStyle(paragraph)
    map(paragraph:select("span"), function (v)
        v:removeAttr("style")
    end)
    paragraph:removeAttr("style")
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("main")
    local p = content:selectFirst(".entry-content")

    WPCommon.cleanupElement(p)

    map(p:select("p"), passageCleanup)
    map(p:select("div"), passageCleanup)
    map(p:select("p"), cleanupChildStyle)

    local title = content:selectFirst(".wp-block-post-title")
    if title then
        p:child(0):before("<h2>" .. title:text() .. "</h2><hr/>")
    end

    return p
end

local function parseListings()
    local doc = GETDocument(baseURL)
    local firstBlock = doc:selectFirst("div.wp-site-blocks")
    
    local _novels = {}
    map(firstBlock:select("> .wp-block-query"), function (block)
        map(block:select("ul.wp-block-post-template > li.wp-block-post"), function (post)
            local titleBlock = post:selectFirst("a")
            local title = titleBlock:text()
            local url = shrinkURL(titleBlock:attr("href"))
            print(url)
            local _novel = Novel {
                title = title,
                link = url
            }
            local imgBlock = post:selectFirst("img")
            if imgBlock then
                _novel:setImageURL(imgBlock:attr("src"))
            end
            _novels[#_novels + 1] = _novel
        end)
    end)
    return _novels
end

local extraCss = [[
.has-text-align-center {
    text-align: center;
}

.wp-block-table td,
.wp-block-table th {
    border: 1px solid;
    padding: .5em;
}
]]

return {
    id = 176796,
    name = "SHM Translations",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/SHMTranslations.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    -- Must have at least one value
    listings = {
        Listing("Novels", false, parseListings)
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL), false, extraCss)
    end,

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(baseURL .. novelURL)
        local baseArticles = doc:selectFirst("main > .entry-content")

        local info = NovelInfo {
            title = baseArticles:selectFirst(".wp-block-heading"):text(),
        }
        if WPCommon.contains(novelURL, "/ongoing/") then
            info:setStatus(NovelStatus.PUBLISHING)
        elseif WPCommon.contains(novelURL, "/completed/") then
            info:setStatus(NovelStatus.COMPLETED)
        elseif WPCommon.contains(novelURL, "/dropped/") then
            info:setStatus(NovelStatus.PAUSED)
        end

        local imageTarget = baseArticles:selectFirst("img")
        if imageTarget then
            info:setImageURL(imageTarget:attr("src"))
        end

        -- wp-block-media-text__content
        local description = baseArticles:selectFirst(".wp-block-media-text__content")
        if description then
            info:setDescription(description:text())
        else
            local figcaption = baseArticles:selectFirst("figcaption")
            if figcaption then
                info:setDescription(figcaption:text())
            end
        end

        if loadChapters then
            local counter = 0.0
            -- wp-block-ub-content-toggle-accordion darkmysite_style_txt_border darkmysite_processed
            local _chapters = {}
            map(baseArticles:select(".wp-block-ub-content-toggle-accordion"), function (accord)
                local accordContent = accord:selectFirst(".wp-block-ub-content-toggle-accordion-content-wrap")
                if accordContent then
                    map(accordContent:select("a"), function (v)
                        local href = v:attr("href"):lower()
                        if not WPCommon.contains(href, "shmtranslations.com") then
                            return
                        end
                        local text = v:text()
                        if not text or text == "" then
                            return
                        end
                        if WPCommon.contains(text, "Quiz ") and WPCommon.contains(novelURL, "isekai-nonbiri") then
                            return
                        end
                        counter = counter + 1.0
                        _chapters[#_chapters + 1] = NovelChapter {
                            order = counter,
                            title = text,
                            link = shrinkURL(href)
                        }
                    end)
                end
            end)
            info:setChapters(AsList(_chapters))
        end

        return info
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}
