local webhookURL = 'https://discord.com/api/webhooks/1397026633847935066/B0FyC3wTAfb0C5EAPQOuR6GVgBvnXltcwH5GtvcpT-RDgEQ8ldWgRH3OVxqj0QAMBh7K?wait=true'
local webhookMessageId = nil
local leaderboardLimit = 100

function updateLeaderboard()
    local query = string.format([[
        SELECT
            users.identifier,
            users.firstname,
            users.lastname,
            users.accounts,
            users.inventory
        FROM users
        ORDER BY 
            JSON_EXTRACT(users.accounts, '$.bank') + 
            JSON_EXTRACT(users.accounts, '$.money') + 
            JSON_EXTRACT(users.accounts, '$."black_money"') DESC
        LIMIT %d
    ]], leaderboardLimit)

    MySQL.query(query, {}, function(result)
        if not result or #result == 0 then
            print("No users found.")
            return
        end

        local embed = {
            title = "**💰 Top Richest Players Leaderboard**",
            color = 5763719,
            description = "",
            footer = { text = "Updated every minute" },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }

        for i, user in ipairs(result) do
            local accountsRaw = user.accounts or "{}"
            local accounts = type(accountsRaw) == "string" and json.decode(accountsRaw) or {}

            local money, bank, black = 0, 0, 0

            -- Handle both array-style and flat accounts
            if type(accounts) == "table" then
                if accounts.money then
                    money = tonumber(accounts.money) or 0
                    bank = tonumber(accounts.bank) or 0
                    black = tonumber(accounts.black_money) or 0
                elseif #accounts > 0 and type(accounts[1]) == "table" then
                    for _, acc in pairs(accounts) do
                        if acc.name == "money" then money = tonumber(acc.money) or 0
                        elseif acc.name == "bank" then bank = tonumber(acc.money) or 0
                        elseif acc.name == "black_money" then black = tonumber(acc.money) or 0
                        end
                    end
                end
            end

            local total = money + bank + black
            local name = string.format("%s %s", user.firstname or "Unknown", user.lastname or "")
            local line = string.format("**%d.** %s - 💲 `%s`", i, name, total)
            embed.description = embed.description .. line .. "\n"
        end

        local payload = json.encode({
            username = 'FiveM Leaderboard Bot',
            embeds = { embed }
        })

        if webhookMessageId then
            local editUrl = string.format('%s/messages/%s', webhookURL, webhookMessageId)
            PerformHttpRequest(editUrl, function(err, text, headers)
                if err ~= 200 then
                    print("❌ Failed to edit webhook message:", err)
                    webhookMessageId = nil
                else
                    print("✅ Webhook message edited.")
                end
            end, 'PATCH', payload, { ['Content-Type'] = 'application/json' })
        else
            PerformHttpRequest(webhookURL, function(err, text, headers)
                if err == 200 or err == 204 then
                    local success, data = pcall(json.decode, text or "{}")
                    if success and type(data) == "table" and data.id then
                        webhookMessageId = data.id
                        print("✅ Webhook message sent and ID saved:", webhookMessageId)
                    else
                        print("⚠️ Webhook sent, but no ID returned (cannot edit).")
                    end
                else
                    print("❌ Failed to send webhook message. Error:", err)
                end
            end, 'POST', payload, { ['Content-Type'] = 'application/json' })
        end
    end)
end

-- Auto-update every 60 seconds
CreateThread(function()
    while true do
        updateLeaderboard()
        Wait(60000)
    end
end)