ServerConfig = {}

-- If you want to sender the identifiers of the player in the logs
ServerConfig.UseIdentifiers = true

-- If you want to use fivemanage you can use it with this url structure:
--            https://api.fivemanage.com/api/image?apiKey=YOUR_API_TOKEN
-- Where YOUR_API_TOKEN is the token that you get from fivemanage page

-- If you want to use discord you can use it with this url structure:
--            https://discord.com/api/webhooks/WEBHOOK_ID/WEBHOOK_TOKEN
-- Where WEBHOOK_ID and WEBHOOK_TOKEN are the values that you get from discord webhook page

ServerConfig.Logs = {
    DispatchAlerts = 'https://api.fivemanage.com/api/image?apiKey=1voOMjqhJpHlcMdMAIUaGC6WY6zU8LZd',
    Shapes = 'https://api.fivemanage.com/api/image?apiKey=YYh8LnkJr4na62RePO2oBG6rRKxIj3NX',
    Notes = 'https://api.fivemanage.com/api/image?apiKey=6Muqs130qmYMsiHtc1jYIPBg95oJ2ltK',
    DutyClock = 'https://api.fivemanage.com/api/image?apiKey=qz1eLisucrN9Um2zEBciLHp5zTNgqU0y',
    Management = 'https://api.fivemanage.com/api/image?apiKey=BmUPVrtt2byroMofCRfHkFSbVVB7gZfY',
    Camera = 'https://api.fivemanage.com/api/image?apiKey=HOw31oaUlbRgaNv870zVx9k39ekRcp28',
    Federal = 'https://api.fivemanage.com/api/image?apiKey=yTHDs00nOi8GmMXoz2qEWNKF8ZEOgEIv',
    Bills = 'https://api.fivemanage.com/api/image?apiKey=PfAfSIpbp9gjiYKlghfioR7fE41Ef50H',
    Cams = 'https://api.fivemanage.com/api/image?apiKey=Zz0hZytN1DZpsAmHiwuygogdA9v9ZLZ8',
    Mugshots = 'https://api.fivemanage.com/api/image?apiKey=cBvbYUezF1nirvRyDi6x46c9jV5H1VtB',
    Ankle = 'https://api.fivemanage.com/api/image?apiKey=4iehQnFaJg11zjs9CbOvMsUEYZ1pBN1W'
}