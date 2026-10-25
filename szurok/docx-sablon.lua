-- docx-sablon.lua
-- A sablon/tudomanyos_sablon.docx Word-sablont kiegészítő szűrő (csak DOCX kimenethez).
-- Használat: filters: [{at: post-render, path: szurok/docx-sablon.lua}]
--
-- 1. Szakaszszámok: "3.1 Cím" → "3.1. Cím" (az első szintet a Quarto már ponttal írja)
-- 2. Táblázatok: az utolsó sort a táblázat láblécébe tesszük, így a Word bekapcsolja
--    rá a sablon "utolsó sor" formázását, ami az APA-stílusú záróvonalat rajzolja.
--    A Quarto ábrákat és táblázatokat körülvevő (fejléc nélküli) kerettáblázatait
--    nem érintjük, ezek így vonal nélkül maradnak.

function Header(h)
  local first, second = h.content[1], h.content[2]
  if first and first.t == "Str" and first.text:match("^%d+%.%d[%d.]*$")
     and not first.text:match("%.$") and second and second.t == "Space" then
    first.text = first.text .. "."
    return h
  end
end

function Table(tbl)
  if #tbl.head.rows == 0 or #tbl.foot.rows > 0 then return nil end
  local body = tbl.bodies[1]
  if not body or #body.body < 2 then return nil end
  tbl.foot.rows:insert(body.body:remove(#body.body))
  return tbl
end
