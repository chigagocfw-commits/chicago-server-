

VinewoodLayout = {}

local Math = VinewoodMath -- must be loaded before this file
local ZERO = { x = 0, y = 0, z = 0 }

local DEFAULT_SPACE_ADVANCE = 0.38
local MIN_LINE_HEIGHT       = 1.35
local LINE_PADDING          = 0.15
local DEFAULT_GLYPH_DEPTH   = 0.1

local function NewOverride(index)
  return {
    index    = index,
    offset   = { x = 0, y = 0, z = 0 },
    rotation = { x = 0, y = 0, z = 0 },
    scale    = 1,
  }
end

-- Per-letter tweak (offset/rotation/scale) for the letter at `index`.
-- create = false: returns a throwaway default when none exists (read-only use)
-- create = true:  stores the override on the layer (kept sorted by index)
function VinewoodLayout.Override(layer, index, create)
  for _, override in ipairs(layer.letterOverrides or {}) do
    if override.index == index then return override end
  end

  local override = NewOverride(index)
  if not create then return override end

  layer.letterOverrides = layer.letterOverrides or {}
  layer.letterOverrides[#layer.letterOverrides + 1] = override
  table.sort(layer.letterOverrides, function(a, b) return a.index < b.index end)
  return override
end

-- Expresses a world-space vector in the layer's local axes
function VinewoodLayout.WorldVectorToLocal(vector, rotation)
  return {
    x = Math.dot(vector, Math.rotate({ x = 1, y = 0, z = 0 }, rotation)),
    y = Math.dot(vector, Math.rotate({ x = 0, y = 1, z = 0 }, rotation)),
    z = Math.dot(vector, Math.rotate({ x = 0, y = 0, z = 1 }, rotation)),
  }
end

-- Model name for a glyph in a given slot (1 = "<model>", 2+ = "<model>_s<slot>").
-- kind: "emissive" (self-lit variant when the glyph has one) | "natural" | "outline"
function VinewoodLayout.Model(glyph, slot, kind)
  if kind == "outline" then return nil end -- outline models are disabled

  if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > Config.Limits.MaxSolidLayers then
    return nil
  end

  local base = (kind == "emissive" and glyph.emissiveModel) or glyph.model
  if not base then return nil end -- ADDED: original would error on concat when the glyph had no model

  if slot == 1 then return base end
  return base .. "_s" .. slot
end

-- Rotates a local axis by the letter's own rotation, then by the layer's rotation
local function RotateAxis(axis, override, layerRotation)
  return Math.rotate(Math.rotate(axis, override.rotation or ZERO), layerRotation)
end

-- Splits text into lines of positioned glyphs. Returns lines, maxLineWidth, minZ, maxZ
local function MeasureText(layer, font)
  local lines = { { items = {}, width = 0 } }
  local index = 0
  local tracking = layer.tracking or 0

  for _, code in utf8.codes(layer.text) do
    index = index + 1

    if code == 10 then -- newline
      lines[#lines + 1] = { items = {}, width = 0 }
    else
      local line  = lines[#lines]
      local glyph = font.glyphs[code]
      local advance = (glyph and glyph.advance)
                   or font.spaceAdvance
                   or VinewoodGlyphs.spaceAdvance
                   or DEFAULT_SPACE_ADVANCE

      line.items[#line.items + 1] = { index = index, glyph = glyph, code = code, x = line.width, advance = advance }
      line.width = line.width + advance + tracking
    end
  end

  local maxLineWidth, minZ, maxZ = 0, 0, 1
  for _, line in ipairs(lines) do
    if #line.items > 0 then
      line.width = math.max(0.01, line.width - tracking) -- drop trailing tracking
    end
    line.minX, line.maxX = 0, line.width

    for _, item in ipairs(line.items) do
      local glyph = item.glyph
      if glyph then
        local center = item.x + (glyph.centerOffset or item.advance / 2)
        line.minX = math.min(line.minX, center + glyph.boundsMin[1])
        line.maxX = math.max(line.maxX, center + glyph.boundsMax[1])
        minZ = math.min(minZ, glyph.boundsMin[3])
        maxZ = math.max(maxZ, glyph.boundsMax[3])
      end
    end

    maxLineWidth = math.max(maxLineWidth, line.maxX - line.minX)
  end

  return lines, maxLineWidth, minZ, maxZ
end

-- Builds one placed 3D letter per glyph of a solid text layer, for model slot `slot`
function VinewoodLayout.Build(layer, slot)
  if layer.type ~= "text" or layer.renderMode ~= "solid" then return {} end

  local font = VinewoodGlyphs.fonts[layer.font]
  if not (font and font.solid ~= false) then
    font = VinewoodGlyphs.fonts.inter -- fallback font
  end
  if not font then return {} end

  local lines, maxLineWidth, minZ, maxZ = MeasureText(layer, font)

  local lineHeight   = math.max(MIN_LINE_HEIGHT, maxZ - minZ + LINE_PADDING)
  local bottomZ      = minZ - (#lines - 1) * lineHeight
  local totalHeight  = maxZ - bottomZ
  local centerZ      = (maxZ + bottomZ) / 2

  -- uniform scale so the text fits inside the layer's width and height
  local fit = math.min(layer.width / math.max(0.1, maxLineWidth), layer.height / totalHeight)

  local emissive = layer.lighting == "always"
  local glyphDepth = VinewoodGlyphs.depth or DEFAULT_GLYPH_DEPTH
  local letters = {}

  for lineIndex, line in ipairs(lines) do
    for _, item in ipairs(line.items) do
      local glyph = item.glyph
      if glyph then
        local override = VinewoodLayout.Override(layer, item.index, false)
        local glyphMinZ, glyphMaxZ = glyph.boundsMin[3], glyph.boundsMax[3]
        local glyphMidZ = (glyphMinZ + glyphMaxZ) / 2

        -- position in layer-local space: centered horizontally per line, stacked downward
        local localPos = {
          x = (item.x + (glyph.centerOffset or item.advance / 2) - (line.minX + line.maxX) / 2) * fit,
          y = 0,
          z = (glyphMidZ - centerZ - (lineIndex - 1) * lineHeight) * fit,
        }
        localPos = Math.add(localPos, override.offset or ZERO)

        local center = Math.add(layer.position, Math.rotate(localPos, layer.rotation))

        local right   = RotateAxis({ x = 1, y = 0, z = 0 }, override, layer.rotation)
        local forward = RotateAxis({ x = 0, y = 1, z = 0 }, override, layer.rotation)
        local up      = RotateAxis({ x = 0, y = 0, z = 1 }, override, layer.rotation)

        local glyphScale = fit * (override.scale or 1)
        local width  = (glyph.width or item.advance) * glyphScale
        local height = (glyphMaxZ - glyphMinZ) * glyphScale

        letters[#letters + 1] = {
          key          = layer.id .. ":" .. item.index,
          layerId      = layer.id,
          index        = item.index,
          slot         = slot,
          model        = VinewoodLayout.Model(glyph, slot, emissive and "emissive" or "natural"),
          outlineModel = VinewoodLayout.Model(glyph, slot, "outline"), -- always nil while outlines are disabled
          origin       = Math.sub(center, Math.mul(up, glyphMidZ * glyphScale)), -- model origin (glyph base)
          center       = center,
          right        = right,
          forward      = forward,
          up           = up,
          width        = width,
          height       = height,
          scaleX       = glyphScale,
          scaleY       = layer.depth * (override.scale or 1) / glyphDepth,
          scaleZ       = glyphScale,
          opacity      = layer.opacity,
          visible      = layer.visible,
          layer        = layer,
        }
      end
    end
  end

  return letters
end

-- Four corners of a letter's face: top-left, top-right, bottom-right, bottom-left
function VinewoodLayout.Corners(letter)
  local halfRight = Math.mul(letter.right, letter.width / 2)
  local halfUp    = Math.mul(letter.up, letter.height / 2)

  return {
    Math.add(Math.sub(letter.center, halfRight), halfUp),
    Math.add(Math.add(letter.center, halfRight), halfUp),
    Math.sub(Math.add(letter.center, halfRight), halfUp),
    Math.sub(Math.sub(letter.center, halfRight), halfUp),
  }
end

-- Ray vs. letter face. Returns distance along the ray, or nil on a miss
function VinewoodLayout.Hit(origin, direction, letter)
  local normal = Math.cross(letter.right, letter.up)
  local denom  = Math.dot(direction, normal)
  if math.abs(denom) < 1e-5 then return nil end -- ray parallel to the face

  local distance = Math.dot(Math.sub(letter.center, origin), normal) / denom
  if distance < 0 then return nil end -- face is behind the ray

  local offset = Math.sub(Math.add(origin, Math.mul(direction, distance)), letter.center)

  if math.abs(Math.dot(offset, letter.right)) <= letter.width / 2
     and math.abs(Math.dot(offset, letter.up)) <= letter.height / 2 then
    return distance
  end
  return nil
end

