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


UploadMethods = {
    Custom = {
        Video = {
            url = "https://your-custom-url.com/upload?api=API_KEY",
            field = "file", 
            headers = { 
                ["Authorization"] = "Key API_KEY"
            },
            error = {
                path = "success", 
                value = false 
            },
            success = {
                path = "url" 
            },
        },
        Image = {
            url = "https://your-custom-url.com/upload?api=API_KEY",
            field = "file", 
            headers = { 
                ["Authorization"] = "Key API_KEY"
            },
            error = {
                path = "success", 
                value = false 
            },
            success = {
                path = "url" 
            },
        },
        Audio = {
            url = "https://your-custom-url.com/upload?api=API_KEY",
            field = "file", 
            headers = { 
                ["Authorization"] = "Key API_KEY"
            },
            error = {
                path = "success", 
                value = false 
            },
            success = {
                path = "url" 
            },
        },
    },
    Fivemanage = {
        Default = {
            url = "PRESIGNED_URL",
            field = "file",
            success = {
                path = "data.url"
            },
            sendPlayer = "metadata"
        },
    },
    LBPresigned = { 
        Default = {
            url = "PRESIGNED_URL",
            httpMethod = "PUT",
            uploadType = "binary",
        }
    },
    Qbox = {
        Default = {
            url = "PRESIGNED_URL",
            httpMethod = "POST",
            uploadType = "formdata",
            field = "file",
            success = {
                path = "data.url"
            }
        }
    }
}

