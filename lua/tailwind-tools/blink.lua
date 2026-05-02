local M = {}

local config = require("tailwind-tools.config")
local utils = require("tailwind-tools.utils")

-- Tailwind color highlight integration for Saghen/blink.cmp.
--
-- Mirrors the behavior of `tailwind-tools.cmp.lspkind_format`:
-- when an LSP completion item is a Tailwind color, extract the RGB triple
-- from the item's documentation and create/reuse a `TailwindColor*` highlight
-- group, returning its name so blink can paint the kind icon in that color.
--
-- ## Usage
--
-- The simplest path -- replace blink's default kind_icon component:
--
--   require("blink.cmp").setup({
--     completion = {
--       menu = {
--         draw = {
--           components = {
--             kind_icon = require("tailwind-tools.blink").kind_icon,
--           },
--         },
--       },
--     },
--   })
--
-- Compose with your own component instead, falling back to the default
-- kind highlight (or any other) when the item is not a color:
--
--   kind_icon = {
--     text = function(ctx) return ctx.kind_icon .. ctx.icon_gap end,
--     highlight = function(ctx)
--       return require("tailwind-tools.blink").highlight(ctx) or ctx.kind_hl
--     end,
--   }
--
-- The `cmp.highlight` config option (`"foreground"` or `"background"`)
-- controls the styling for both nvim-cmp and blink.

---@param ctx blink.cmp.DrawItemContext
---@return string|nil hl_group `TailwindColor{Fg|Bg}<hex>` when applicable, else nil
M.highlight = function(ctx)
  if not ctx or not ctx.item then return nil end
  if ctx.kind ~= "Color" then return nil end

  local doc = ctx.item.documentation
  if not doc then return nil end

  local content = type(doc) == "string" and doc or doc.value
  if not content then return nil end

  local r, g, b = utils.extract_color(content)
  if not r then return nil end

  local style = config.options.cmp.highlight
  return utils.set_hl_from(r, g, b, style)
end

-- Drop-in `completion.menu.draw.components.kind_icon` override:
-- preserves blink's default text rendering and falls back to the default
-- kind highlight (`BlinkCmpKind<Kind>`) when the item is not a color.
---@type blink.cmp.DrawComponent
M.kind_icon = {
  text = function(ctx) return ctx.kind_icon .. ctx.icon_gap end,
  highlight = function(ctx)
    return M.highlight(ctx) or ctx.kind_hl
  end,
}

return M
