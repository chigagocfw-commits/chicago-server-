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


PhoneAnimations = {}

PhoneAnimations["default"] = {
    default = {
        onFoot = {
            open = {
                dict = "cellphone@",
                anim = "cellphone_text_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@",
                anim = "cellphone_text_read_base",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0,
            },
            close = {
                dict = "cellphone@",
                anim = "cellphone_text_out",
                flag = 16 | 32
            }
        },
        inVehicle = {
            open = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_read_base",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0
            },
            close = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_out",
                flag = 16 | 32
            }
        },
    },
    call = {
        onFoot = {
            open = {
                dict = "cellphone@",
                anim = "cellphone_call_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@",
                anim = "cellphone_call_listen_base",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@",
                anim = "cellphone_call_out",
                flag = 16 | 32
            }
        },
        inVehicle = {
            open = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_listen_base",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_out",
                flag = 16 | 32
            }
        },
    },
    camera = {
        onFoot = {
            open = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@self",
                anim = "selfie",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0,
                blendOutSpeed = -1000.0,
            },
            close = {
                dict = "cellphone@self",
                anim = "selfie_out",
                flag = 16 | 32
            }
        },
        inVehicle = {
            open = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@self",
                anim = "selfie",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@self",
                anim = "selfie_out",
                flag = 16 | 32
            }
        },
    }
}

PhoneAnimations["two handed"] = {
    default = {
        onFoot = {
            open = {
                dict = "amb@code_human_wander_texting@male@enter",
                anim = "enter",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "amb@code_human_wander_texting@male@base",
                anim = "static",
                flag = 1 | 16 | 32,
                blendInSpeed = 8.0,
            },
            close = {
                dict = "amb@code_human_wander_texting@male@exit",
                anim = "exit",
                flag = 16 | 32
            }
        },
        inVehicle = {
            open = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_read_base",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0
            },
            close = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_out",
                flag = 16 | 32
            }
        },
    },
    call = {
        onFoot = {
            open = {
                dict = "cellphone@",
                anim = "cellphone_call_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@",
                anim = "cellphone_call_listen_base",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@",
                anim = "cellphone_call_out",
                flag = 16 | 32
            }
        },
        inVehicle = {
            open = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_listen_base",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_out",
                flag = 16 | 32
            }
        },
    },
    camera = {
        onFoot = {
            open = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0,
                blendOutSpeed = -1000.0,
            },
            close = {
                dict = "cellphone@self",
                anim = "selfie_out",
                flag = 16 | 32
            }
        },
        inVehicle = {
            open = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@self",
                anim = "selfie",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@self",
                anim = "selfie_out",
                flag = 16 | 32
            }
        },
    }
}

