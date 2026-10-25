-- caption.lua
-- "Ábra 1:" → "1. ábra." és "Táblázat 1:" → "1. táblázat."
-- A strukturált captionökben a címke félkövér, a cím dőlt lesz:
-- **1. táblázat.** *A táblázat címe*
-- Rekurzívan bejárja az összes elemet, így a mélyen beágyazott
-- Quarto Div-struktúrákban is megtalálja a caption szöveget.
-- Használat: filters: [{at: post-render, path: szurok/caption.lua}]

-- === 1. RawBlock HTML kezelése (Quarto HTML output) ===
-- A Quarto HTML-ben gyakran RawBlock-ként rendereli a caption-t
function RawBlock(raw)
  if raw.format ~= "html" then return nil end
  local changed = false

  -- "Ábra 1:" vagy "Ábra 1" → "1. ábra."
  -- Kezeli a &nbsp; (nem törhető szóköz) variánst is
  local new = raw.text:gsub('([Áá]bra)[\194\160&nbsp;]*(%d+)%s*:?', '%2. ábra.')
  if new ~= raw.text then raw.text = new; changed = true end

  -- "Táblázat 1:" vagy "Táblázat 1" → "1. táblázat."
  new = raw.text:gsub('([Tt]áblázat)[\194\160&nbsp;]*(%d+)%s*:?', '%2. táblázat.')
  if new ~= raw.text then raw.text = new; changed = true end

  -- "Figure 1:" → "1. ábra." (angol fallback)
  new = raw.text:gsub('(Figure)[\194\160&nbsp;]*(%d+)%s*:?', '%2. ábra.')
  if new ~= raw.text then raw.text = new; changed = true end

  -- "Table 1:" → "1. táblázat." (angol fallback)
  new = raw.text:gsub('(Table)[\194\160&nbsp;]*(%d+)%s*:?', '%2. táblázat.')
  if new ~= raw.text then raw.text = new; changed = true end

  if changed then return raw end
end

-- === 2. RawInline HTML kezelése ===
function RawInline(raw)
  if raw.format ~= "html" then return nil end
  local changed = false
  local new = raw.text:gsub('([Áá]bra)[\194\160&nbsp;]*(%d+)%s*:?', '%2. ábra.')
  if new ~= raw.text then raw.text = new; changed = true end
  new = raw.text:gsub('([Tt]áblázat)[\194\160&nbsp;]*(%d+)%s*:?', '%2. táblázat.')
  if new ~= raw.text then raw.text = new; changed = true end
  new = raw.text:gsub('(Figure)[\194\160&nbsp;]*(%d+)%s*:?', '%2. ábra.')
  if new ~= raw.text then raw.text = new; changed = true end
  new = raw.text:gsub('(Table)[\194\160&nbsp;]*(%d+)%s*:?', '%2. táblázat.')
  if new ~= raw.text then raw.text = new; changed = true end
  if changed then return raw end
end

-- === 3. Strukturált inline elemek kezelése (Plain/Para) ===
-- Ha a Quarto strukturált Pandoc elemeket használ a caption-höz

local title_map = {
  ["Ábra"]      = "ábra",
  ["ábra"]      = "ábra",
  ["Figure"]    = "ábra",
  ["Táblázat"]  = "táblázat",
  ["táblázat"]  = "táblázat",
  ["Table"]     = "táblázat",
}

local function try_reorder(inlines)
  -- DOCX-ben a caption elején nyers OpenXML (bekezdésformázás) állhat,
  -- ezt változatlanul megtartjuk, és mögötte keressük a címkét
  local raw_prefix = pandoc.List()
  while #inlines > 0 and inlines[1].t == "RawInline" do
    raw_prefix:insert(inlines[1])
    inlines = pandoc.List({table.unpack(inlines, 2)})
  end

  if #inlines < 2 then return nil end

  local first = inlines[1]
  if first.t ~= "Str" then return nil end

  local hu = title_map[first.text]
  if not hu then return nil end

  -- Keressük a számot (NBSP/Space után)
  local num_idx, num_val
  for k = 2, math.min(8, #inlines) do
    local el = inlines[k]
    if el.t == "Str" then
      local n = el.text:match("^(%d+)$")
      if n then
        num_idx = k
        num_val = n
        break
      end
      -- NBSP mint Str karakter
      if el.text:match("^[\194\160]+$") then
        -- skip
      else
        break
      end
    elseif el.t ~= "Space" and el.t ~= "SoftBreak" then
      break
    end
  end

  if not num_val then return nil end

  -- Hol kezdődik a felhasználó eredeti caption szövege?
  local rest_start = num_idx + 1
  -- Átugorjuk a delimiter-t (: vagy .) és az utána lévő szóközt
  while rest_start <= #inlines do
    local el = inlines[rest_start]
    if el.t == "Str" and (el.text == ":" or el.text == ".") then
      rest_start = rest_start + 1
    elseif el.t == "Space" then
      rest_start = rest_start + 1
      break
    else
      break
    end
  end

  -- Összerakjuk: félkövér "N. típus." + dőlt eredeti caption
  local rest = pandoc.List()
  for k = rest_start, #inlines do
    rest:insert(inlines[k])
  end
  return raw_prefix .. pandoc.List({
    pandoc.Strong({pandoc.Str(num_val .. "."), pandoc.Space(), pandoc.Str(hu .. ".")}),
    pandoc.Space(),
    pandoc.Emph(rest),
  })
end

function Plain(el)
  if el.content then
    local new = try_reorder(el.content)
    if new then el.content = new; return el end
  end
end

function Para(el)
  if el.content then
    local new = try_reorder(el.content)
    if new then el.content = new; return el end
  end
end

-- === 4. Figure és Table elemek közvetlen kezelése (Pandoc 3.x) ===
function Figure(fig)
  if fig.caption and fig.caption.long and #fig.caption.long > 0 then
    local block = fig.caption.long[1]
    if block and block.content then
      local new = try_reorder(block.content)
      if new then block.content = new; return fig end
    end
  end
end

function Table(tbl)
  if tbl.caption and tbl.caption.long and #tbl.caption.long > 0 then
    local block = tbl.caption.long[1]
    if block and block.content then
      local new = try_reorder(block.content)
      if new then block.content = new; return tbl end
    end
  end
end

-- === 5. Inline kereszthivatkozások: "Ábra 1" → "1. ábra" ===
function Link(link)
  if not link.content or #link.content < 2 then return nil end
  local first = link.content[1]
  if first.t ~= "Str" then return nil end
  local hu = title_map[first.text]
  if not hu then return nil end

  for k = 2, #link.content do
    if link.content[k].t == "Str" then
      local n = link.content[k].text:match("^(%d+)$")
      if n then
        link.content = pandoc.List({
          pandoc.Str(n .. "."),
          pandoc.Space(),
          pandoc.Str(hu),
        })
        return link
      end
    end
  end
end
