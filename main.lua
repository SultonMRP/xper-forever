SLASH_EXPR1 = "/x"
SLASH_XSWIM1 = "/xs"

local BASE_SWIM_PCT = 67.46

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

local function formatPct(n)
    local r = math.floor(n * 100 + 0.5) / 100
    if r == math.floor(r) then
        return tostring(math.floor(r))
    end
    local tenths = math.floor(n * 10 + 0.5) / 10
    if math.abs(r - tenths) < 0.001 then
        return string.format("%.1f", tenths)
    end
    return string.format("%.2f", r)
end

local function trySwim(expr)
    local bonuses = {}
    for token in expr:gmatch("[^,;%s]+") do
        if not token:match("^[+-]?%d+%.?%d*$") and not token:match("^[+-]?%.%d+$") then
            return false
        end
        local n = tonumber(token)
        if not n then
            return false
        end
        bonuses[#bonuses + 1] = n
    end
    if #bonuses == 0 then
        return false
    end

    local total = 0
    for i = 1, #bonuses do
        total = total + bonuses[i]
    end
    local mul = 1 + total / 100
    local ofGround = BASE_SWIM_PCT * mul
    local vsRun
    local delta = ofGround - 100
    if math.abs(delta) < 0.005 then
        vsRun = "same as base running speed"
    elseif delta > 0 then
        vsRun = formatPct(delta) .. "% faster than base running speed"
    else
        vsRun = formatPct(-delta) .. "% slower than base running speed"
    end
    say("Swim bonus: " .. formatPct(total) .. "% of swim (" .. formatPct(BASE_SWIM_PCT) .. " × " .. formatPct(mul) .. ", " .. vsRun .. ")")
    return true
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
        say("/xs 30,15,10 - swim speed from item bonuses (base 67.46% of ground).")
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

function SlashCmdList.XSWIM(expr)
    if not expr or expr == "" or expr:match("^%s*$") then
        say("/xs <bonuses> - swim speed from item swim bonus percents.")
        say("Base swim is 67.46% of ground speed. Bonuses stack additively.")
        say("Example: /xs 30,15,10 -> Swim bonus: 55% of swim (67.46 × 1.55, 4.56% faster than base running speed)")
        return
    end

    if not trySwim(expr) then
        say("Invalid input. Example: /xs 30,15,10")
    end
end
