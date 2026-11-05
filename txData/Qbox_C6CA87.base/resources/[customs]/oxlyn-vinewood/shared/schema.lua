

VinewoodSchema = {}

local ZERO_VECTOR = { x = 0, y = 0, z = 0 }
local AXES = { "x", "y", "z" }

local function Set(list)
  local set = {}
  for _, value in ipairs(list) do set[value] = true end
  return set
end

local function CopyList(list)
  local copy = {}
  for i, value in ipairs(list) do copy[i] = value end
  return copy
end

---------------------------------------------------------------------------
-- Catalogs
---------------------------------------------------------------------------
-- Fonts available to flat (panel) text
local PANEL_FONTS = {
  "inter", "condensed", "serif", "mono", "marker", "anton", "orbitron", "bebas",
  "oswald", "montserrat", "poppins", "playfair", "cinzel", "pacifico", "lobster",
  "righteous", "bangers", "monoton", "audiowide", "russo", "teko", "abril", "blackops",
}

-- Subset that has 3D glyph models for solid text
local SOLID_FONTS = {
  "inter", "condensed", "serif", "mono", "marker", "anton", "orbitron", "bebas",
  "oswald", "montserrat", "poppins", "cinzel", "righteous", "bangers", "audiowide",
  "russo", "blackops",
}

local FONTS               = Set(PANEL_FONTS)
local SOLID_FONT_SET      = Set(SOLID_FONTS)
local WEIGHTS             = Set({ 400, 600, 800, 900 })
local EFFECTS             = Set({ "none", "float", "spin", "floatSpin", "pulse", "sway", "orbit", "rock", "flip", "breathe" })
local ALIGNS              = Set({ "left", "center", "right" })
local FILL_MODES          = Set({ "solid", "gradient", "rainbow" })
local GRADIENT_DIRECTIONS = Set({ "vertical", "horizontal" })
local RENDER_MODES        = Set({ "panel", "solid" })
local LIGHTING_MODES      = Set({ "natural", "night", "always" })
local IMAGE_FITS          = Set({ "contain", "cover", "stretch" })
local IMAGE_EXTENSIONS    = Set({ "png", "jpg", "jpeg", "webp" })

function VinewoodSchema.FontCatalog()
  return { solid = CopyList(SOLID_FONTS), panel = CopyList(PANEL_FONTS) }
end

function VinewoodSchema.IsFont(name)
  return FONTS[name] == true
end

---------------------------------------------------------------------------
-- Primitive readers: (value, default, ..., fieldLabel) -> value | nil, errorMessage
---------------------------------------------------------------------------
local function IsNumber(value)
  return type(value) == "number" and value == value -- rejects NaN
end

-- Solid text is uppercase only. Handles Latin-1 letters, y-diaeresis and sharp s
local function UpperCase(text)
  local out = {}
  for _, code in utf8.codes(text) do
    if (code >= 97 and code <= 122) or (code >= 224 and code <= 254 and code ~= 247) then
      code = code - 32
    end
    if code == 255 then code = 376 end -- ÿ -> Ÿ
    out[#out + 1] = (code == 223) and "SS" or utf8.char(code) -- ß -> SS
  end
  return table.concat(out)
end

local function ReadNumber(value, default, min, max, field)
  if value == nil then value = default end
  if not IsNumber(value) or value < min or value > max then
    return nil, L("schema_out_of_range", { field = field, min = min, max = max })
  end
  return value
end

local function ReadBoolean(value, default, field)
  if value == nil then return default end
  if type(value) ~= "boolean" then
    return nil, L("schema_expected_boolean", { field = field })
  end
  return value
end

-- allowWhitespaceControls: permits tab, line feed and carriage return (multi-line text)
local function ReadText(value, default, maxLength, field, allowWhitespaceControls)
  if value == nil then value = default end
  if type(value) ~= "string" then
    return nil, L("schema_expected_text", { field = field })
  end

  local length = utf8.len(value)
  if not length or length > maxLength or #value > maxLength * 4 then
    return nil, L("schema_text_too_long", { field = field, max = maxLength })
  end

  local forbidden = allowWhitespaceControls and "[%z\001-\b\v\f\014-\031\127]" or "[%z\001-\031\127]"
  if value:find(forbidden) then
    return nil, L("schema_control_characters", { field = field })
  end
  return value
end

-- "#RRGGBB" only, normalized to uppercase
local function ReadColor(value, default, field)
  if value == nil then value = default end
  if type(value) ~= "string" or not value:match("^#%x%x%x%x%x%x$") then
    return nil, L("schema_color_format", { field = field })
  end
  return value:upper()
end

-- {x, y, z} of numbers; missing axes fall back to `fallback` if given
local function ReadVector(value, fallback, field)
  if type(value) ~= "table" then
    return nil, L("schema_invalid_vector", { field = field })
  end

  local vector = {}
  for _, axis in ipairs(AXES) do
    local component = value[axis]
    if component == nil and fallback then component = fallback[axis] end
    if not IsNumber(component) then
      return nil, L("schema_invalid_axis", { field = field, axis = axis })
    end
    vector[axis] = component + 0.0
  end
  return vector
end

---------------------------------------------------------------------------
-- Image URL validation
---------------------------------------------------------------------------
-- True if a dotted-quad host should be rejected (private/loopback/malformed)
local function IsBlockedIPv4(host)
  local a, b, c, d = host:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
  if not a then return false end

  a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
  if a > 255 or b > 255 or c > 255 or d > 255 then return true end
  if host ~= ("%d.%d.%d.%d"):format(a, b, c, d) then return true end -- leading zeros etc.

  -- ADDED: the original only blocked 0.x, 10.x and 127.x. The remaining private
  -- ranges (LAN, link-local, CGNAT) let a url point a player's client at their own network.
  return a == 0 or a == 10 or a == 127
      or (a == 169 and b == 254)
      or (a == 172 and b >= 16 and b <= 31)
      or (a == 192 and b == 168)
      or (a == 100 and b >= 64 and b <= 127)
end

local function LooksLocalOrMalformed(host)
  return host:sub(-1) == "."
      or host:find("%.%.") ~= nil
      or not host:find("%.")           -- single-label hosts ("intranet")
      or host == "localhost"
      or host:match("%.localhost$") ~= nil
      or host:match("%.local$") ~= nil
      or host:match("%.internal$") ~= nil
      or IsBlockedIPv4(host)
      or host:match("^%d+$") ~= nil    -- decimal IP like 2130706433
      or host:match("^0[xX]") ~= nil   -- hex IP like 0x7f000001
end

-- Accepts: uploaded images, local "images/<file>", or (if enabled) https urls.
-- Returns the normalized url, or nil + error message
local function ValidateImageUrl(url)
  local limits = Config.Limits

  if type(url) ~= "string" or #url == 0 or #url > limits.MaxUrlLength then
    return nil, L("image_url_length", { max = limits.MaxUrlLength })
  end

  -- no whitespace, control characters, DEL or backslashes
  if url:find("[%z\001- \127\\]") then
    return nil, L("image_url_invalid")
  end

  -- uploaded image: "upload:<32 hex>.png"
  if #url == 43 and url:match("^upload:%x+%.png$") then
    return url:lower()
  end

  -- image bundled with the resource
  local file = url:match("^images/([%w_%-%.]+)$")
  if file and not file:find("%.%.") then
    local extension = file:match("%.([%a]+)$")
    if extension and IMAGE_EXTENSIONS[extension:lower()] then
      return url
    end
  end

  -- remote images (enabled unless Config.AllowRemoteImages == false)
  if Config.AllowRemoteImages == false then
    return nil, L("image_remote_disabled")
  end

  -- https only, no port or credentials, no fragment
  local host, path = url:match("^https://([^/]+)(/[^#]*)$")
  if not host or host:find("[^%w%.%-]") then
    return nil, L("image_url_format")
  end
  host = host:lower()

  if LooksLocalOrMalformed(host) then
    return nil, L("image_local_address")
  end

  local allNumeric = true
  for label in host:gmatch("[^.]+") do
    if not label:match("^%d+$") and not label:match("^0x%x+$") then
      allNumeric = false
    end
    if label:sub(1, 1) == "-" or label:sub(-1) == "-" then
      return nil, L("image_invalid_domain")
    end
  end

  -- all-numeric hosts must be a plain dotted IPv4
  if allNumeric and not host:match("^%d+%.%d+%.%d+%.%d+$") then
    return nil, L("image_noncanonical_ip")
  end

  -- optional host allowlist: { "cdn.example.com" } or { ["cdn.example.com"] = true }
  local allowedHosts = Config.ImageHosts or {}
  if next(allowedHosts) then
    local allowed = allowedHosts[host] == true
    for _, entry in ipairs(allowedHosts) do
      if type(entry) == "string" and entry:lower() == host then
        allowed = true
      end
    end
    if not allowed then
      return nil, L("image_host_not_allowed", { host = host })
    end
  end

  -- extension is checked on the path without its query string
  local pathOnly = path:match("^([^?]+)")
  local extension = pathOnly and pathOnly:match("%.([%a]+)$")
  if not (extension and IMAGE_EXTENSIONS[extension:lower()]) then
    return nil, L("image_extension")
  end

  return url
end

---------------------------------------------------------------------------
-- Table-driven layer fields (validated in this order; first error wins)
---------------------------------------------------------------------------
local function NumberField(key, default, min, max, label)
  return { kind = "number", key = key, default = default, min = min, max = max, label = label }
end
local function BooleanField(key, default, label)
  return { kind = "boolean", key = key, default = default, label = label }
end
local function ColorField(key, default, label)
  return { kind = "color", key = key, default = default, label = label }
end
local function EnumField(key, default, allowed, errorKey)
  return { kind = "enum", key = key, default = default, allowed = allowed, errorKey = errorKey }
end

local FLAG_FIELDS = {
  BooleanField("visible", true, "field_visibility"),
  BooleanField("locked", false, "field_locked"),
  BooleanField("doubleSided", false, "field_double_sided"),
}

local IMAGE_FIELDS = {
  EnumField("effect", "none", EFFECTS, "scene_invalid_effect"),
  NumberField("floatAmplitude", 0.6, 0, 10, "field_float_height"),
  NumberField("floatSpeed", 0.25, 0.1, 3, "field_float_speed"),
  NumberField("spinSpeed", 12, -90, 90, "field_spin_speed"),
  NumberField("motionSpeed", 0.25, 0.05, 3, "field_motion_speed"),
  NumberField("motionAmount", 0.15, 0, 0.75, "field_motion_amount"),
  NumberField("motionRadius", 1, 0, 10, "field_motion_radius"),
  NumberField("motionAngle", 15, 0, 90, "field_motion_angle"),
  NumberField("motionPhase", 0, 0, 360, "field_motion_phase"),
  ColorField("imageTint", "#FFFFFF", "field_image_tint"),
  NumberField("imageBrightness", 1, 0.1, 3, "field_image_brightness"),
  NumberField("imageContrast", 1, 0, 3, "field_image_contrast"),
  NumberField("imageSaturation", 1, 0, 2, "field_image_saturation"),
  NumberField("imageGlow", 0, 0, 1, "field_image_glow"),
  ColorField("imageGlowColor", "#FFFFFF", "field_image_glow_color"),
  BooleanField("imageFlipX", false, "field_image_flip_x"),
  BooleanField("imageFlipY", false, "field_image_flip_y"),
}

local TEXT_FIELDS = {
  EnumField("font", "inter", FONTS, "scene_invalid_font"),
  EnumField("weight", 800, WEIGHTS, "scene_invalid_weight"),
  ColorField("color", "#FFFFFF", "field_color"),
  EnumField("fillMode", "solid", FILL_MODES, "scene_invalid_fill"),
  ColorField("gradientColor", "#6FA8FF", "field_second_color"),
  EnumField("gradientDirection", "vertical", GRADIENT_DIRECTIONS, "scene_invalid_gradient_direction"),
  ColorField("outline", "#000000", "field_outline"),
  NumberField("outlineWidth", 0, 0, 8, "field_outline_width"),
  NumberField("glow", 0, 0, 1, "field_glow"),
  NumberField("brightness", 1, 0.1, 4, "field_brightness"),
  NumberField("tracking", 0, -5, 30, "field_spacing"),
  EnumField("align", "center", ALIGNS, "scene_invalid_align"),
  NumberField("lineHeight", 1.15, 0.8, 2, "field_line_height"),
  EnumField("renderMode", "panel", RENDER_MODES, "scene_invalid_render_mode"),
  NumberField("depth", 0.6, 0.05, 8, "field_depth"),
  EnumField("lighting", "night", LIGHTING_MODES, "scene_invalid_lighting"),
  BooleanField("supports", true, "field_supports"),
  NumberField("supportDrop", 6, 0, 30, "field_support_length"),
}

-- Validates each field of `layer` into `out`. Returns an error message, or nil
local function ReadFields(layer, out, fields)
  for _, field in ipairs(fields) do
    local value, err
    if field.kind == "number" then
      value, err = ReadNumber(layer[field.key], field.default, field.min, field.max, L(field.label))
    elseif field.kind == "boolean" then
      value, err = ReadBoolean(layer[field.key], field.default, L(field.label))
    elseif field.kind == "color" then
      value, err = ReadColor(layer[field.key], field.default, L(field.label))
    else
      value = layer[field.key]
      if value == nil then value = field.default end
      if not field.allowed[value] then err = L(field.errorKey) end
    end

    if err then return err end
    out[field.key] = value
  end
end

---------------------------------------------------------------------------
-- Layer validators (each returns an error message, or nil)
---------------------------------------------------------------------------
local function ValidateCommon(layer, out, limits)
  local err

  out.name, err = ReadText(layer.name, layer.type == "text" and "Text" or "Image", 40, L("field_name"))
  if err then return err end

  err = ReadFields(layer, out, FLAG_FIELDS)
  if err then return err end

  out.position, err = ReadVector(layer.position, nil, L("field_position"))
  if err then return err end

  -- must sit inside the allowed area around the anchor
  local dx = out.position.x - Config.Anchor.x
  local dy = out.position.y - Config.Anchor.y
  local dz = out.position.z - Config.Anchor.z
  if dx * dx + dy * dy + dz * dz > limits.AreaRadius * limits.AreaRadius then
    return L("scene_outside_area", { radius = limits.AreaRadius })
  end

  out.rotation, err = ReadVector(layer.rotation == nil and { x = 0, y = 0, z = 0 } or layer.rotation, nil, L("field_rotation"))
  if err then return err end
  for _, axis in ipairs(AXES) do
    if math.abs(out.rotation[axis]) > 3600 then return L("scene_rotation_range") end
  end

  out.width, err = ReadNumber(layer.width, 40, limits.MinSize, limits.MaxSize, L("field_width"))
  if err then return err end

  out.height, err = ReadNumber(layer.height, 10, limits.MinSize, limits.MaxSize, L("field_height"))
  if err then return err end

  out.opacity, err = ReadNumber(layer.opacity, 1, 0, 1, L("field_opacity"))
  if err then return err end
end

local function ValidateImageLayer(layer, out)
  local err

  out.keepAspect, err = ReadBoolean(layer.keepAspect, true, L("field_keep_aspect"))
  if err then return err end

  out.url, err = ValidateImageUrl(layer.url)
  if err then return err end

  -- text-only fields keep neutral defaults on image layers
  out.text, out.font, out.weight = "", "inter", 800
  out.color, out.outline, out.outlineWidth, out.tracking = "#FFFFFF", "#000000", 0, 0

  err = ReadFields(layer, out, IMAGE_FIELDS)
  if err then return err end

  out.imageFit = layer.imageFit
  if out.imageFit == nil then
    out.imageFit = out.keepAspect and "contain" or "stretch"
  end
  if not IMAGE_FITS[out.imageFit] then return L("scene_invalid_fit") end
end

-- Extra rules for solid (3D letter) text. `state` carries scene-wide solid counters
local function ValidateSolidText(layer, out, state, limits)
  if not SOLID_FONT_SET[out.font] then out.font = "inter" end

  state.solidLayers = state.solidLayers + 1
  if state.solidLayers > limits.MaxSolidLayers then
    return L("scene_solid_layer_limit", { max = limits.MaxSolidLayers })
  end

  if out.outlineWidth > 0.1 then out.outlineWidth = 0 end -- solid letters can't be outlined

  out.text = UpperCase(out.text)
  if utf8.len(out.text) > limits.MaxSolidCharacters then
    return L("scene_solid_char_limit", { max = limits.MaxSolidCharacters })
  end

  local fontData = VinewoodGlyphs and VinewoodGlyphs.fonts[out.font]
  if not fontData then return L("scene_glyph_catalog") end

  -- every visible character needs a glyph. glyphAt[i] marks letters that can take overrides
  local glyphAt, position = {}, 0
  for _, code in utf8.codes(out.text) do
    position = position + 1
    if code ~= 32 and code ~= 10 then
      if not fontData.glyphs[code] then
        return L("scene_glyph_missing", { char = utf8.char(code) })
      end
      state.totalGlyphs = state.totalGlyphs + 1
      glyphAt[position] = true
    end
  end
  if state.totalGlyphs > limits.MaxSolidGlyphs then
    return L("scene_solid_glyph_limit", { max = limits.MaxSolidGlyphs })
  end

  if out.tracking < -0.1 or out.tracking > 1 then return L("scene_solid_spacing") end

  -- per-letter overrides
  local overrides = layer.letterOverrides or {}
  if type(overrides) ~= "table" then return L("scene_invalid_overrides") end

  local count = 0
  for key in pairs(overrides) do
    if not (type(key) == "number" and key >= 1 and key % 1 == 0 and key <= limits.MaxSolidCharacters) then
      return L("scene_invalid_override_list")
    end
    count = count + 1
  end

  local seen = {}
  for i = 1, count do
    local override = overrides[i]
    if not (type(override) == "table"
        and type(override.index) == "number"
        and override.index % 1 == 0
        and glyphAt[override.index]
        and not seen[override.index]) then
      return L("scene_invalid_letter_index")
    end
    seen[override.index] = true

    local clean, err = { index = override.index }, nil

    clean.offset, err = ReadVector(override.offset or { x = 0, y = 0, z = 0 }, nil, L("field_letter_offset"))
    if err then return err end

    clean.rotation, err = ReadVector(override.rotation or { x = 0, y = 0, z = 0 }, nil, L("field_letter_rotation"))
    if err then return err end

    for _, axis in ipairs(AXES) do
      if math.abs(clean.offset[axis]) > 50 or math.abs(clean.rotation[axis]) > 180 then
        return L("scene_letter_range")
      end
    end

    clean.scale, err = ReadNumber(override.scale, 1, 0.25, 3, L("field_letter_scale"))
    if err then return err end

    out.letterOverrides[i] = clean
  end

  table.sort(out.letterOverrides, function(a, b) return a.index < b.index end)
end

local function ValidateTextLayer(layer, out, state, limits)
  local err

  out.text, err = ReadText(layer.text, "VINEWOOD", limits.MaxTextLength, L("field_text"), true)
  if err then return err end

  err = ReadFields(layer, out, TEXT_FIELDS)
  if err then return err end

  out.url = ""
  out.letterOverrides = {}

  if out.renderMode == "solid" then
    return ValidateSolidText(layer, out, state, limits)
  end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
-- Validates and normalizes a whole scene. Returns a clean copy, or nil + error message.
-- Never trust client scenes: only fields listed here survive.
function VinewoodSchema.Validate(scene)
  if type(scene) ~= "table" or scene.schemaVersion ~= 1 or type(scene.layers) ~= "table" then
    return nil, L("scene_invalid")
  end

  local limits = Config.Limits

  -- layers must be a gapless list 1..n (counting keys also rejects string keys)
  local count = 0
  for key in pairs(scene.layers) do
    if not (type(key) == "number" and key >= 1 and key % 1 == 0 and key <= limits.MaxLayers) then
      return nil, L("scene_layer_list", { max = limits.MaxLayers })
    end
    count = count + 1
  end

  local hideOriginal, err = ReadBoolean(scene.hideOriginal, false, L("field_hide_original"))
  if err then return nil, err end

  local clean = { schemaVersion = 1, hideOriginal = hideOriginal, layers = {} }
  local seenIds = {}
  local state = { solidLayers = 0, totalGlyphs = 0 }

  for i = 1, count do
    local layer = scene.layers[i]
    if type(layer) ~= "table" then return nil, L("scene_layer_gaps") end

    local id = layer.id
    if not (type(id) == "string" and #id >= 1 and #id <= 40 and id:match("^[%w_%-]+$")) then
      return nil, L("scene_invalid_layer_id")
    end
    if seenIds[id] then return nil, L("scene_duplicate_layer_id") end
    seenIds[id] = true

    if layer.type ~= "text" and layer.type ~= "image" then
      return nil, L("scene_invalid_layer_type")
    end

    local out = { id = id, type = layer.type }

    err = ValidateCommon(layer, out, limits)
    if not err then
      if layer.type == "image" then
        err = ValidateImageLayer(layer, out)
      else
        err = ValidateTextLayer(layer, out, state, limits)
      end
    end
    if err then return nil, err end

    clean.layers[i] = out
  end

  return clean
end

-- Deep copy (tables only; no cycle handling, scenes are plain data)
local function DeepCopy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = DeepCopy(inner)
  end
  return copy
end

VinewoodSchema.Copy = DeepCopy

