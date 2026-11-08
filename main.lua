SLASH_EXPR1 = "/x"

local function say(msg)
    if SendSystemMessage then
        SendSystemMessage(msg)
        return
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end
end

local function compile(src)
    if loadstring then
        return loadstring(src)
    end
    if load then
        return load(src, "xper-forever", "t")
    end
end

local function formatTemp(n)
    local r = math.floor(n * 10 + 0.5) / 10
    if r == math.floor(r) then
        return tostring(math.floor(r))
    end
    return string.format("%.1f", r)
end

local function tryTemp(expr)
    local value, unit = expr:match("^%s*([+-]?%d+%.?%d*)%s*([cCfF])%s*$")
    if not value then
        value, unit = expr:match("^%s*([+-]?%.%d+)%s*([cCfF])%s*$")
    end
    if not value then
        return false
    end

    local n = tonumber(value)
    if not n then
        return false
    end

    unit = unit:upper()
    if unit == "C" then
        say(value .. "C = " .. formatTemp(n * 9 / 5 + 32) .. "F")
    else
        say(value .. "F = " .. formatTemp((n - 32) * 5 / 9) .. "C")
    end
    return true
end

-- Treat x as * between numbers or parentheses (5x5, 2 x (3+1)). Leave 0xFF hex alone.
local function rewriteMulX(src)
    local saved = {}
    src = src:gsub("0[xX]%x+", function(hex)
        saved[#saved + 1] = hex
        return "\1" .. #saved .. "\2"
    end)
    local prev
    repeat
        prev = src
        src = src:gsub("([%d%)])%s*[xX]%s*([%d%(])", "%1*%2")
    until src == prev
    src = src:gsub("\1(%d+)\2", function(i)
        return saved[tonumber(i)]
    end)
    return src
end

function SlashCmdList.EXPR(expr)
    if expr == "" then
        say("/x <expr> - evaluates an expression and prints the result in the chat window.")
        say("/x 5x5 - same as 5*5. /x 15c or /x 15f converts temperature.")
        return
    end

    if tryTemp(expr) then
        return
    end

    local chunk = compile("return " .. rewriteMulX(expr))
    if not chunk then
        say("Invalid input.")
        return
    end

    local ok, result = pcall(chunk)
    if not ok then
        say("Invalid input.")
        return
    end

    say(expr .. " = " .. tostring(result))
end
