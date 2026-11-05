--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]


Config = {}
Config.Debug = false 

Config.Logs = {}
Config.Logs.Enabled = false

Config.Logs.Service = "discord" 
Config.Logs.Avatar = false 
Config.Logs.Dataset = "default" 
Config.Logs.Actions = {
    Calls = true,
    Messages = true,
    InstaPic = true,
    Birdy = true,
    YellowPages = true,
    Marketplace = true,
    Mail = true,
    Wallet = true,
    DarkChat = true,
    Services = true,
    Crypto = true,
    Trendy = true,
    Uploads = true
}

Config.DatabaseChecker = {}
Config.DatabaseChecker.Enabled = false 
Config.DatabaseChecker.AutoFix = false

Config.Framework = "auto"

Config.CustomFramework = false 
Config.QBMailEvent = false 
Config.QBOldJobMethod = false 

Config.Item = {}

Config.Item.Require = true 
Config.Item.Name = "phone" 

Config.Item.Unique = false 
Config.Item.Inventory = "auto" 

Config.ServerSideSpawn = false 
Config.PropSpawn = "state" 

Config.PhoneModel = `lb_phone_prop` 
Config.PhoneRotation = vector3(0.0, 0.0, 180.0) 
Config.PhoneOffset = vector3(0.0, -0.005, 0.0) 
Config.LandscapeRotation = vector3(0.0, 90.0, 180.0) 
Config.LandscapeOffset = vector3(-0.03, -0.005, -0.02) 
Config.AnimationStyle = "default" 

Config.DisableOpenNUI = true 

Config.LiveTray = true
Config.SetupScreen = true 
Config.AppDownloadTime = 2000 

Config.AutoDisableSparkAccounts = true 
Config.AutoDeleteNotifications = true 
Config.MaxNotifications = 50 
Config.NotificationsUpdateZIndex = true 
Config.DisabledNotifications = { 
    
}

Config.AutoJoinDarkChat = {
    
}

Config.WhitelistApps = {
    
}

Config.BlacklistApps = {
    
}

Config.ChangePassword = {
    ["Trendy"] = true,
    ["InstaPic"] = true,
    ["Birdy"] = true,
    ["DarkChat"] = true,
    ["Mail"] = true,
}

Config.DeleteAccount = {
    ["Trendy"] = false,
    ["InstaPic"] = false,
    ["Birdy"] = false,
    ["DarkChat"] = false,
    ["Mail"] = false,
    ["Spark"] = false,
}

Config.Companies = {}
Config.Companies.Enabled = true 
Config.Companies.MessageOffline = true 
Config.Companies.DefaultCallsDisabled = false 
Config.Companies.AllowAnonymous = false 
Config.Companies.SeeEmployees = "everyone" 
Config.Companies.DeleteConversations = true 
Config.Companies.AllowNoService = false 
Config.Companies.Services = {
    {
        job = "police",
        name = "Police",
        icon = "https://cdn-icons-png.flaticon.com/512/7211/7211100.png",
        canCall = true, 
        canMessage = true, 
        bossRanks = { "boss" }, 
        location = {
            name = "Mission Row",
            coords = {
                x = 428.9,
                y = -984.5,
            }
        },
        quickReplies = {
            ["APPS.SERVICES.QUICK_REPLIES.REQUEST_LOCATION.TITLE"] = "APPS.SERVICES.QUICK_REPLIES.REQUEST_LOCATION.MESSAGE",
            ["APPS.SERVICES.QUICK_REPLIES.OFFICER_EN_ROUTE.TITLE"] = "APPS.SERVICES.QUICK_REPLIES.OFFICER_EN_ROUTE.MESSAGE",
            
        },
        
    },
    {
        job = "ambulance",
        name = "Ambulance",
        icon = "https://cdn-icons-png.flaticon.com/128/1032/1032989.png",
        canCall = true, 
        canMessage = true, 
        bossRanks = {"boss", "doctor"}, 
        location = {
            name = "Pillbox",
            coords = {
                x = 304.2,
                y = -587.0
            }
        }
    },
    {
        job = "mechanic",
        name = "Mechanic",
        icon = "https://cdn-icons-png.flaticon.com/128/10281/10281554.png",
        canCall = true, 
        canMessage = true, 
        bossRanks = {"boss", "worker"}, 
        location = {
            name = "LS Customs",
            coords = {
                x = -336.6,
                y = -134.3
            }
        }
    },
    {
        job = "taxi",
        name = "Taxi",
        icon = "https://cdn-icons-png.flaticon.com/128/433/433449.png",
        canCall = true, 
        canMessage = true, 
        bossRanks = {"boss", "driver"}, 
        location = {
            name = "Taxi HQ",
            coords = {
                x =984.2,
                y = -219.0
            }
        }
    },
}

Config.Companies.Contacts = { 
    
}

Config.Companies.Management = {
    Enabled = true, 

    Duty = true, 
    
    Deposit = true, 
    Withdraw = true, 
    Hire = true, 
    Fire = true, 
    Promote = true, 
}

Config.CustomApps = {} 

Config.Valet = {}
Config.Valet.Enabled = true 
Config.Valet.VehicleTypes = { "car", "vehicle" }
Config.Valet.Price = 100 
Config.Valet.Model = `S_M_Y_XMech_01`
Config.Valet.Drive = true 
Config.Valet.DisableDamages = false 
Config.Valet.FixTakeOut = false 

Config.HouseScript = "auto" 

Config.Voice = {}
Config.Voice.CallEffects = false 
Config.Voice.SpatialAudio = true 
Config.Voice.SpatialAudioSubmixes = 1 
Config.Voice.System = "auto"

Config.Voice.HearNearby = true 

Config.Voice.RecordNearby = true 
Config.Voice.WaitUntilNotTalking = false 

Config.Sound = {}
Config.Sound.System = "native" 
Config.Sound.Sync = true 
Config.Sound.Volume = {} 
Config.Sound.Volume.Multiplier = 1.0
Config.Sound.Volume.Static = false 
Config.Sound.Volume.Min = 0.0
Config.Sound.Volume.Max = 1.0
Config.Sound.MaxDistance = 30.0 

Config.Sound.Ringtones = {
    ["default"] = {
        name = "23",
        soundSet = "ringtone"
    },
    ["ringtone 1"] = {
        name = "1",
        soundSet = "ringtone"
    },
    ["ringtone 2"] = {
        name = "7",
        soundSet = "ringtone"
    },
    ["ringtone 3"] = {
        name = "10",
        soundSet = "ringtone"
    },
    ["ringtone 4"] = {
        name = "13",
        soundSet = "ringtone"
    },
    ["ringtone 5"] = {
        name = "15",
        soundSet = "ringtone"
    },
    ["ringtone 6"] = {
        name = "17",
        soundSet = "ringtone"
    },
    ["ringtone 7"] = {
        name = "19",
        soundSet = "ringtone"
    },
    ["ringtone 8"] = {
        name = "21",
        soundSet = "ringtone"
    },
    ["ringtone 9"] = {
        name = "24",
        soundSet = "ringtone"
    },
}

Config.Sound.Notifications = {
    ["default"] = {
        name = "1",
        soundSet = "notification"
    },
    ["notification 1"] = {
        name = "2",
        soundSet = "notification"
    },
    ["notification 2"] = {
        name = "3",
        soundSet = "notification"
    },
    ["notification 3"] = {
        name = "4",
        soundSet = "notification"
    },
    ["notification 4"] = {
        name = "5",
        soundSet = "notification"
    },
    ["notification 5"] = {
        name = "6",
        soundSet = "notification"
    },
    ["notification 6"] = {
        name = "7",
        soundSet = "notification"
    },
    ["notification 7"] = {
        name = "8",
        soundSet = "notification"
    },
}

Config.Sound.AppNotifications = {
    
}

Config.CellTowers = {}
Config.CellTowers.Enabled = true 
Config.CellTowers.Debug = false 
Config.CellTowers.MinService = 0 
Config.CellTowers.Range = {
    [4] = 250.0, 
    [3] = 500.0,
    [2] = 750.0,
    [1] = 1500.0,
}

Config.Locations = { 
    {
        position = vector2(428.9, -984.5),
        name = "LSPD",
        description = "Los Santos Police Department",
        icon = "https://cdn-icons-png.flaticon.com/512/7211/7211100.png",
    },
    {
        position = vector2(304.2, -587.0),
        name = "Pillbox",
        description = "Pillbox Medical Hospital",
        icon = "https://cdn-icons-png.flaticon.com/128/1032/1032989.png",
    },
}

Config.Locales = { 
    {
        locale = "en",
        name = "English"
    },
    {
        locale = "de",
        name = "Deutsch"
    },
    {
        locale = "fr",
        name = "Français"
    },
    {
        locale = "es",
        name = "Español"
    },
    {
        locale = "nl",
        name = "Nederlands"
    },
    {
        locale = "dk",
        name = "Dansk"
    },
    {
        locale = "no",
        name = "Norsk"
    },
    {
        locale = "th",
        name = "ไทย"
    },
    {
        locale = "ar",
        name = "عربي"
    },
    {
        locale = "ru",
        name = "Русский"
    },
    {
        locale = "cs",
        name = "Czech"
    },
    {
        locale = "sv",
        name = "Svenska"
    },
    {
        locale = "pl",
        name = "Polski"
    },
    {
        locale = "hu",
        name = "Magyar"
    },
    {
        locale = "tr",
        name = "Türkçe"
    },
    {
        locale = "pt-br",
        name = "Português (Brasil)"
    },
    {
        locale = "pt-pt",
        name = "Português"
    },
    {
        locale = "it",
        name = "Italiano"
    },
    {
        locale = "ua",
        name = "Українська"
    },
    {
        locale = "ba",
        name = "Bosanski"
    },
    {
        locale = "zh-cn",
        name = "简体中文 (Chinese Simplified)"
    },
    {
        locale = "ro",
        name = "Romana"
    },
    {
        locale = "ja",
        name = "日本語",
    },
    {
        locale = "ko",
        name = "한국어",
    },
}

Config.DefaultLocale = "en"
Config.DateLocale = "en-US" 
Config.DateFormat = "auto" 

Config.FrameColor = "#39334d" 
Config.AllowFrameColorChange = true 

Config.PhoneNumber = {}
Config.PhoneNumber.Format = "({3}) {3}-{4}" 
Config.PhoneNumber.Length = 7 
Config.PhoneNumber.Prefixes = { 
    "205",
    "907",
    "480",
    "520",
    "602"
}

Config.Battery = {} 
Config.Battery.Enabled = false 
Config.Battery.ChargeInterval = { 5, 10 } 
Config.Battery.DischargeInterval = { 50, 60 } 
Config.Battery.DischargeWhenInactiveInterval = { 80, 120 } 
Config.Battery.DischargeWhenInactive = true 

Config.CurrencyFormat = "$%s" 
Config.MaxTransferAmount = 1000000 
Config.TransferOffline = true 

Config.TransferLimits = {}
Config.TransferLimits.Daily = false 
Config.TransferLimits.Weekly = false 

Config.EnableMessagePay = true 
Config.EnableVoiceMessages = true 
Config.EnableGIFs = true
Config.GIFsFilter = "low" 

Config.CityName = "Los Santos" 
Config.RealTime = true 
Config.CustomTime = false 

Config.EmailDomain = "lbscripts.com"
Config.AutoCreateEmail = false 
Config.DeleteMail = true 
Config.ConvertMailToMarkdown = true 

Config.DeleteMessages = true 
Config.GroupMessageMemberLimit = false 

Config.SyncFlash = true 
Config.EndLiveClose = false 

Config.AllowExternal = { 
    Gallery = false, 
    Birdy = false, 
    InstaPic = false,
    Spark = false,
    Trendy = false,
    Pages = false,
    Marketplace = false,
    Mail = false,
    Messages = false,
    Other = false, 
}

Config.ExternalBlacklistedHostnames = {}

Config.ExternalBlacklistedDomains = {
    "imgur.com",
    "discord.com",
    "discordapp.com",
}

Config.ExternalWhitelistedHostnames = {
    
    "r2.qbox.re",
}

Config.ExternalWhitelistedDomains = {
    "fivemanage.com"
}

Config.UploadWhitelistedHostnames = {
    
    "r2.qbox.re", 
}

Config.UploadWhitelistedDomains = {
    "fivemanage.com",
    "fmfile.com",
    "amazonaws.com", 
}

Config.NameFilter = ".+"

Config.WordBlacklist = {}
Config.WordBlacklist.Enabled = false
Config.WordBlacklist.Apps = { 
    Birdy = true,
    InstaPic = true,
    Trendy = true,
    Spark = true,
    Messages = true,
    Pages = true,
    Marketplace = true,
    DarkChat = true,
    Mail = true,
    Other = true,
}

Config.WordBlacklist.Words = {
    
}

Config.AutoFollow = {}
Config.AutoFollow.Enabled = false

Config.AutoFollow.Birdy = {}
Config.AutoFollow.Birdy.Enabled = true
Config.AutoFollow.Birdy.Accounts = {} 

Config.AutoFollow.InstaPic = {}
Config.AutoFollow.InstaPic.Enabled = true
Config.AutoFollow.InstaPic.Accounts = {} 

Config.AutoFollow.Trendy = {}
Config.AutoFollow.Trendy.Enabled = true
Config.AutoFollow.Trendy.Accounts = {} 

Config.AutoBackup = true 

Config.Post = {} 
Config.Post.Birdy = true 
Config.Post.InstaPic = true 
Config.Post.Accounts = {
    Birdy = {
        Username = "Birdy",
        Avatar = "https://assets.loaf-scripts.com/lb-phone/icons/Birdy.png"
    },
    InstaPic = {
        Username = "InstaPic",
        Avatar = "https://assets.loaf-scripts.com/lb-phone/icons/InstaPic.png"
    }
}

Config.BirdyTrending = {}
Config.BirdyTrending.Enabled = true 
Config.BirdyTrending.Reset = 7 * 24 

Config.BirdyNotifications = false 
Config.InstaPicLiveNotifications = false 

Config.PromoteBirdy = {}
Config.PromoteBirdy.Enabled = true 
Config.PromoteBirdy.Cost = 2500 
Config.PromoteBirdy.Views = 100 

Config.Verified = {}
Config.Verified.Birdy = {
    [1] = {
        color = "#1d9af0",
        label = "APPS.TWITTER.VERIFIED.LABEL",
        description = "APPS.TWITTER.VERIFIED.DESCRIPTION"
    },
    [2] = {
        color = "#d4a017",
        label = "APPS.TWITTER.VERIFIED_GOVERNMENT.LABEL",
        description = "APPS.TWITTER.VERIFIED_GOVERNMENT.DESCRIPTION"
    }
}

Config.UsernameFilter = {
    Regex = "[a-zA-Z0-9]+", 
    LuaPattern = "^[%w]+$", 
}

Config.TrendyTTS = {
    {"English (US) - Female", "en_us_001"},
    {"English (US) - Male 1", "en_us_006"},
    {"English (US) - Male 2", "en_us_007"},
    {"English (US) - Male 3", "en_us_009"},
    {"English (US) - Male 4", "en_us_010"},

    {"English (UK) - Male 1", "en_uk_001"},
    {"English (UK) - Male 2", "en_uk_003"},

    {"English (AU) - Female", "en_au_001"},
    {"English (AU) - Male", "en_au_002"},

    {"French - Male 1", "fr_001"},
    {"French - Male 2", "fr_002"},

    {"German - Female", "de_001"},
    {"German - Male", "de_002"},

    {"Spanish - Male", "es_002"},

    {"Spanish (MX) - Male", "es_mx_002"},

    {"Portuguese (BR) - Female 2", "br_003"},
    {"Portuguese (BR) - Female 3", "br_004"},
    {"Portuguese (BR) - Male", "br_005"},

    {"Indonesian - Female", "id_001"},

    {"Japanese - Female 1", "jp_001"},
    {"Japanese - Female 2", "jp_003"},
    {"Japanese - Female 3", "jp_005"},
    {"Japanese - Male", "jp_006"},

    {"Korean - Male 1", "kr_002"},
    {"Korean - Male 2", "kr_004"},
    {"Korean - Female", "kr_003"},

    {"Singing - Alto", "en_female_f08_salut_damour"},
    {"Singing - Tenor", "en_male_m03_lobby"},
    {"Singing - Sunshine Soon", "en_male_m03_sunshine_soon"},
    {"Singing - Warmy Breeze", "en_female_f08_warmy_breeze"},
    {"Singing - Glorious", "en_female_ht_f08_glorious"},
    {"Singing - It Goes Up", "en_male_sing_funny_it_goes_up"},
    {"Singing - Chipmunk", "en_male_m2_xhxs_m03_silly"},
    {"Singing - Dramatic", "en_female_ht_f08_wonderful_world"}
}

Config.Pages = {}
Config.Pages.Cost = 0 
Config.Pages.RateLimit = 0 
Config.Pages.MaxPosts = 10 
Config.Pages.DeleteOld = false 

Config.Marketplace = {}
Config.Marketplace.Cost = 0 
Config.Marketplace.RateLimit = 0 
Config.Marketplace.MaxPosts = 10 
Config.Marketplace.DeleteOld = false 

Config.DynamicWebRTC = {}
Config.DynamicWebRTC.Enabled = false 
Config.DynamicWebRTC.Service = "cloudflare" 
Config.DynamicWebRTC.RemoveStun = false 

Config.Crypto = {}
Config.Crypto.Enabled = true
Config.Crypto.Refund = false 
Config.Crypto.UpdateInterval = 5 
Config.Crypto.Coins = {
    ["lbc"] = {
        name = "LB Coin",
        icon = "./assets/img/icons/crypto/coins/lbc.webp",
        initialValue = 50.0,
        changes = {
            {
                weight = 500,
                change = { 0.0, 2.0 } 
            },
            {
                weight = 490,
                change = { -2.0, -0.0 } 
            },
            {
                weight = 5,
                change = { 5.0, 15.0 }
            },
            {
                weight = 5,
                change = { -15.0, -5.0 }
            }
        },
        permissions = {
            buy = true,
            sell = true,
            transfer = true
        }
    }
}

Config.Crypto.QBit = true 
Config.Crypto.Limits = {}
Config.Crypto.Limits.Buy = 1000000 
Config.Crypto.Limits.Sell = 1000000 

Config.Browser = {}

Config.Browser.CX = "32dca7fc9f06341d2" 

Config.Browser.DefaultBookmarks = {
    
}

Config.Browser.WhitelistedDomains = {
    
}

Config.Browser.BlacklistedDomains = {
    
}

Config.KeyBinds = {
    
    Open = { 
        Command = "phone",
        Bind = "F1",
        Description = "Open your phone"
    },
    Focus = { 
        Command = "togglePhoneFocus",
        Bind = "LMENU",
        Description = "Toggle cursor on your phone"
    },
    StopSounds = { 
        Command = "stopSounds",
        Bind = false,
        Description = "Stop all phone sounds"
    },

    FlipCamera = {
        Command = "flipCam",
        Bind = "UP",
        Description = "Flip phone camera"
    },
    TakePhoto = {
        Command = "takePhoto",
        Bind = "RETURN",
        Description = "Take a photo / video"
    },
    ToggleFlash = {
        Command = "toggleCameraFlash",
        Bind = "E",
        Description = "Toggle flash"
    },
    LeftMode = {
        Command = "leftMode",
        Bind = "LEFT",
        Description = "Change mode"
    },
    RightMode = {
        Command = "rightMode",
        Bind = "RIGHT",
        Description = "Change mode"
    },
    RollLeft = {
        Command = "cameraRollLeft",
        Bind = "Z",
        Description = "Roll camera to the left"
    },
    RollRight = {
        Command = "cameraRollRight",
        Bind = "C",
        Description = "Roll camera to the right"
    },
    FreezeCamera = {
        Command = "cameraFreeze",
        Bind = "X",
        Description = "Freeze camera"
    },

    AnswerCall = {
        Command = "answerCall",
        Bind = "RETURN",
        Description = "Answer incoming call"
    },
    DeclineCall = {
        Command = "declineCall",
        Bind = "BACK",
        Description = "Decline incoming call"
    },
    UnlockPhone = {
        Bind = "SPACE",
        Description = "Open your phone",
    },
}

Config.KeepInput = true 
Config.DisableFocusTalking = false 

Config.Camera = {}
Config.Camera.ShowTip = true 
Config.Camera.Walkable = true 
Config.Camera.Roll = true 
Config.Camera.AllowRunning = true
Config.Camera.MaxFOV = 70.0 
Config.Camera.DefaultFOV = 60.0
Config.Camera.MinFOV = 10.0 
Config.Camera.MaxLookUp = 80.0
Config.Camera.MaxLookDown = -80.0

Config.Camera.Vehicle = {}
Config.Camera.Vehicle.Zoom = true 
Config.Camera.Vehicle.MaxFOV = 80.0
Config.Camera.Vehicle.DefaultFOV = 60.0
Config.Camera.Vehicle.MinFOV = 10.0
Config.Camera.Vehicle.MaxLookUp = 50.0
Config.Camera.Vehicle.MaxLookDown = -30.0
Config.Camera.Vehicle.MaxLeftRight = 120.0
Config.Camera.Vehicle.MinLeftRight = -120.0

Config.Camera.Selfie = {}
Config.Camera.Selfie.Offset = vector3(0.05, 0.55, 0.6)
Config.Camera.Selfie.Rotation = vector3(10.0, 0.0, -180.0)
Config.Camera.Selfie.MaxFov = 90.0
Config.Camera.Selfie.DefaultFov = 60.0
Config.Camera.Selfie.MinFov = 50.0

Config.Camera.Freeze = {}
Config.Camera.Freeze.Enabled = false 
Config.Camera.Freeze.MaxDistance = 10.0 
Config.Camera.Freeze.MaxTime = 60 

Config.UploadMethod = {}

Config.UploadMethod.Video = "Fivemanage"
Config.UploadMethod.Image = "Fivemanage"
Config.UploadMethod.Audio = "Fivemanage"

Config.Video = {}
Config.Video.VariableBitrate = true
Config.Video.Bitrate = 2000 
Config.Video.AudioBitrate = 128 
Config.Video.FrameRate = 24 
Config.Video.MaxSize = 25 
Config.Video.MaxDuration = 60 

Config.Image = {}
Config.Image.Mime = "image/webp" 
Config.Image.Quality = 0.95

