-- username teramiasu PID VA8VZPOxWJ93DHhnuFTsmG49EgLFfsYylEd7utLMHAw
_0RBIT = "WSXUI2JjYUldJ7CKq9wE1MGwXs-ldzlUlHOQszwQe0s"
BASE_URL = "<https://api.coingecko.com/api/v3/simple/price>"
TOKEN_PRICES = TOKEN_PRICES or {
	BTC = {
		coingecko_id = "bitcoin",
		price = 0,
		last_update_timestamp = 0
	},
	ETH = {
		coingecko_id = "ethereum",
		price = 0,
		last_update_timestamp = 0
	},
	SOL = {
		coingecko_id = "solana",
		price = 0,
		last_update_timestamp = 0
	}
}
REQUESTED_TOKENS = REQUESTED_TOKENS or {}
LOGS = LOGS or {}

Handlers.add(
    "AddToken",
    Handlers.utils.hasMatchingTag("Action", "Add-Token"),
    function(msg)
        if msg.From == ao.id then
            local token = msg.Tags.Token
            local coingecko_id = msg.Tags.CoingeckoId

            if not TOKEN_PRICES[token] then
                TOKEN_PRICES[token].price = 0
                TOKEN_PRICES[token].coingecko_id = coingecko_id
                ao.send({
                    Target = msg.From,
                    Tags = {
                        Action = 'Add Token Success',
                        ['Message-Id'] = msg.Id,
                        Token = token
                    }
                })
            else
                ao.send({
                    Target = msg.From,
                    Tags = {
                        Action = 'Add Token Error',
                        ['Message-Id'] = msg.Id,
                        Error = 'Token already exists'
                    }
                })
            end

            -- For Debugging
            table.insert(
                LOGS,
                {
                    From = msg.From,
                    Tag = "Add-Token",
                    Data = {
                        Token = token,
                        Message = "Success"
                    }
                }
            )
        else
            ao.send({
                Target = msg.From,
                Tags = {
                    Action = 'Add Token Error',
                    ['Message-Id'] = msg.Id,
                    Error = 'Only the Process Owner can add tokens'
                }
            })

            -- For Debugging
            table.insert(
                LOGS,
                {
                    From = msg.From,
                    Tag = "Add-Token",
                    Data = {
                        Message = "Not Owner"
                    }
                }
            )
        end
    end
)
Handlers.add(
    "GetPrice",
    Handlers.utils.hasMatchingTag("Action", "Get-Price"),
    function(msg)
        local token = msg.Tags.Token
        local price = TOKEN_PRICES[token].price
        if price == 0 then
            ao.send({
                Target = msg.From,
                Tags = {
                    Action = 'Get-Price Error',
                    ['Message-Id'] = msg.Id,
                    Error = 'Price not available! Please contact @0rbitco on X'
                }
            })
            return
        else
            ao.send({
                Target = msg.From,
                Tags = {
                    Action = 'Get-Price',
                    ['Message-Id'] = msg.Id,
                    Price = tostring(price)
                }
            })
        end
        table.insert(
            LOGS,
            {
                From = msg.From,
                Tag = "Request-Add-Token",
                Data = {
                    Token = token,
                    Message = "Success"
                }
            }
        )
    end
)
Handlers.add(
    "CronTick",
    Handlers.utils.hasMatchingTag("Action", "Cron"),
    function()
        local url;
        local token_ids;

        for _, v in pairs(TOKEN_PRICES) do
            token_ids = token_ids .. v.coingecko_id .. ","
        end

        url = BASE_URL .. "?ids=" .. token_ids .. "&vs_currencies=usd"

        ao.send({
            Target = _0RBIT,
            Action = "Get-Real-Data",
            Url = url
        })
    end
)
Handlers.add(
    "ReceivingData",
    Handlers.utils.hasMatchingTag("Action", "Receive-data-feed"),
    function(msg)
        local res = json.decode(msg.Data)
        for k, v in pairs(res) do
            TOKEN_PRICES[k].price = v
            TOKEN_PRICES[k].last_update_timestamp = msg.Timestamp
        end
    end
)