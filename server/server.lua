local webhookURL = 'https://discord.com/api/webhooks/1397026633847935066/B0FyC3wTAfb0C5EAPQOuR6GVgBvnXltcwH5GtvcpT-RDgEQ8ldWgRH3OVxqj0QAMBh7K'
local leaderboardLimit = 100

RegisterCommand('leaderboard', function(source, args, rawCommand)
    MySQL.Async.fetchAll([[
        SELECT
            users.identifier,
            users.discord,
            users.firstname,
            users.lastname,
            users.accounts,
            users.inventory
        FROM users
        ORDER BY JSON_EXTRACT(users.accounts, '$.bank') + JSON_EXTRACT(users.accounts, '$.money') + JSON_EXTRACT(users.accounts, '$."black_money"') DESC
        LIMIT @limit
    ]], {
        ['@limit'] = leaderboardLimit
    }, function(result)
        if not result or #result == 0 then return end

        local embed = {
            title = "**💰 Top Richest Players Leaderboard**",
            color = 5763719,
            description = "",
            footer = { text = "Leaderboard based on total money, bank, and black money." }
        }

        for i, user in ipairs(result) do
            local accounts = json.decode(user.accounts or '{}')
            local money = accounts.money or 0
            local bank = accounts.bank or 0
            local black = accounts.black_money or 0

            local total = money + bank + black
            local discord = user.discord or "N/A"
            local name = string.format("%s %s", user.firstname or "Unknown", user.lastname or "")
            local line = string.format("**%d.** %s (Discord: `%s`) - 💵 `%s`", i, name, discord, total)
            embed.description = embed.description .. line .. "\n"
        end

        PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({
            username = 'FiveM Leaderboard Bot',
            embeds = {embed}
        }), { ['Content-Type'] = 'application/json' })
    end)
end, true)
