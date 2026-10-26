# sablon_keszites.R
# Modern, tudományos Word-sablon (reference-doc) készítése a Quarto DOCX kimenetéhez.
#
# A Pandoc alapértelmezett reference.docx állományából indulunk ki, és annak
# stílusait (betűtípusok, címsorok, feliratok, táblázatstílus, margók, lábléc)
# írjuk felül. Az eredmény: sablon/tudomanyos_sablon.docx
#
# Futtatás a projekt gyökeréből:  source("sablon/sablon_keszites.R")
#
# Arculat:
#   - kenyérszöveg: Cambria 11 pt, sorkizárt, 1,15-ös sorköz
#   - címsorok, feliratok, táblázatok: Calibri, sötétkék (#1F3A5F) és acélkék (#3C6E91)
#   - táblázat: APA/booktabs jellegű, csak vízszintes vonalakkal
#   - A4, 2,5 cm-es margók, oldalszám a láblécben

kimenet <- "sablon/tudomanyos_sablon.docx"

# 1. A Pandoc alapértelmezett sablonjának kicsomagolása -------------------------
munka <- file.path(tempdir(), "tudomanyos_sablon")
unlink(munka, recursive = TRUE)
dir.create(munka)
alap <- file.path(tempdir(), "pandoc_reference.docx")
system2(quarto::quarto_path(),
        c("pandoc", "-o", shQuote(alap), "--print-default-data-file", "reference.docx"))
utils::unzip(alap, exdir = munka)

olvas <- function(f) paste(readLines(file.path(munka, f), encoding = "UTF-8", warn = FALSE),
                           collapse = "\n")
ir <- function(x, f) writeLines(enc2utf8(x), file.path(munka, f), useBytes = TRUE)

# 2. Stílusok ---------------------------------------------------------------------
sotetkek <- "1F3A5F"
acelkek  <- "3C6E91"
szurke   <- "5F6B7A"

# betűtípus és méret rövidítése (méret pontban)
rpr <- function(font = "Calibri", pt = NULL, szin = NULL, b = FALSE, i = FALSE, extra = "") {
  paste0("<w:rPr>",
         sprintf('<w:rFonts w:ascii="%1$s" w:hAnsi="%1$s" w:eastAsia="%1$s" w:cs="%1$s"/>', font),
         if (b) "<w:b/><w:bCs/>",
         if (i) "<w:i/><w:iCs/>",
         if (!is.null(szin)) sprintf('<w:color w:val="%s"/>', szin),
         if (!is.null(pt)) sprintf('<w:sz w:val="%1$d"/><w:szCs w:val="%1$d"/>', as.integer(pt * 2)),
         extra, "</w:rPr>")
}
bekezdes_stilus <- function(id, nev, alap = "Normal", ppr = "", rpr = "", kov = NULL, extra = "") {
  sprintf('<w:style w:type="paragraph" w:customStyle="%s" w:styleId="%s"><w:name w:val="%s"/>%s%s%s<w:qFormat/><w:pPr>%s</w:pPr>%s</w:style>',
          ifelse(id %in% c("Normal", "BodyText", "Title", "Subtitle", "Caption", "BlockText",
                           "FootnoteText", "Bibliography", "TOCHeading") |
                   grepl("^Heading", id), "0", "1"),
          id, nev,
          if (!is.null(alap)) sprintf('<w:basedOn w:val="%s"/>', alap) else "",
          if (!is.null(kov)) sprintf('<w:next w:val="%s"/>', kov) else "",
          extra, ppr, rpr)
}
cimsor <- function(szint, pt, szin, i = FALSE, elotte = 360, utana = 120, keret = "") {
  bekezdes_stilus(
    paste0("Heading", szint), paste("heading", szint), kov = "BodyText",
    ppr = paste0("<w:keepNext/><w:keepLines/>", keret,
                 sprintf('<w:spacing w:before="%d" w:after="%d" w:line="240" w:lineRule="auto"/>', elotte, utana),
                 '<w:jc w:val="left"/>',
                 sprintf('<w:outlineLvl w:val="%d"/>', szint - 1)),
    rpr = rpr("Calibri", pt, szin, b = TRUE, i = i))
}
also_vonal <- function(szin, vastagsag = 6)
  sprintf('<w:pBdr><w:bottom w:val="single" w:sz="%d" w:space="4" w:color="%s"/></w:pBdr>', vastagsag, szin)

uj_stilusok <- list(
  Normal = '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>',
  BodyText = bekezdes_stilus("BodyText", "Body Text",
    ppr = '<w:spacing w:before="0" w:after="140" w:line="276" w:lineRule="auto"/><w:jc w:val="both"/>',
    extra = '<w:link w:val="BodyTextChar"/>'),
  FirstParagraph = bekezdes_stilus("FirstParagraph", "First Paragraph", alap = "BodyText", kov = "BodyText"),
  Compact = bekezdes_stilus("Compact", "Compact", alap = "BodyText",
    ppr = '<w:spacing w:before="20" w:after="20" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/>'),
  Title = bekezdes_stilus("Title", "Title", kov = "Subtitle",
    ppr = paste0(also_vonal(acelkek, 12), '<w:spacing w:before="0" w:after="120" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/>'),
    rpr = rpr("Calibri Light", 26, sotetkek, extra = '<w:spacing w:val="-4"/>')),
  Subtitle = bekezdes_stilus("Subtitle", "Subtitle", kov = "Author",
    ppr = '<w:spacing w:before="120" w:after="240"/><w:jc w:val="left"/>',
    rpr = rpr("Calibri Light", 14, acelkek)),
  Author = bekezdes_stilus("Author", "Author",
    ppr = '<w:keepNext/><w:spacing w:before="0" w:after="20"/><w:jc w:val="left"/>',
    rpr = rpr("Calibri", 11, sotetkek, b = TRUE)),
  Date = bekezdes_stilus("Date", "Date",
    ppr = '<w:spacing w:before="0" w:after="360"/><w:jc w:val="left"/>',
    rpr = rpr("Calibri", 10, szurke)),
  AbstractTitle = bekezdes_stilus("AbstractTitle", "Abstract Title",
    ppr = '<w:keepNext/><w:spacing w:before="240" w:after="60"/><w:jc w:val="left"/>',
    rpr = rpr("Calibri", 10, sotetkek, b = TRUE, extra = '<w:caps/><w:spacing w:val="20"/>')),
  Abstract = bekezdes_stilus("Abstract", "Abstract",
    ppr = paste0('<w:pBdr><w:left w:val="single" w:sz="18" w:space="8" w:color="', acelkek, '"/></w:pBdr>',
                 '<w:shd w:val="clear" w:color="auto" w:fill="F2F5F9"/>',
                 '<w:spacing w:before="0" w:after="360" w:line="264" w:lineRule="auto"/><w:ind w:left="284" w:right="284"/><w:jc w:val="both"/>'),
    rpr = rpr("Calibri", 10)),
  Heading1 = cimsor(1, 16, sotetkek, elotte = 480, utana = 160, keret = also_vonal("C9D3DE", 4)),
  Heading2 = cimsor(2, 13, acelkek, elotte = 320, utana = 100),
  Heading3 = cimsor(3, 11.5, sotetkek, i = TRUE, elotte = 240, utana = 80),
  Heading4 = cimsor(4, 11, acelkek, i = TRUE, elotte = 200, utana = 60),
  Heading5 = cimsor(5, 11, szurke, elotte = 200, utana = 60),
  Heading6 = cimsor(6, 11, szurke, i = TRUE, elotte = 200, utana = 60),
  Caption = bekezdes_stilus("Caption", "caption",
    ppr = '<w:spacing w:before="0" w:after="120" w:line="240" w:lineRule="auto"/><w:jc w:val="left"/>',
    rpr = rpr("Calibri", 9.5, sotetkek)),
  TableCaption = bekezdes_stilus("TableCaption", "Table Caption", alap = "Caption",
    ppr = '<w:keepNext/><w:spacing w:before="240" w:after="80"/>'),
  ImageCaption = bekezdes_stilus("ImageCaption", "Image Caption", alap = "Caption",
    ppr = '<w:keepNext/><w:spacing w:before="240" w:after="80"/>'),
  CaptionedFigure = bekezdes_stilus("CaptionedFigure", "Captioned Figure", alap = "Figure",
    ppr = '<w:keepNext/>'),
  Figure = bekezdes_stilus("Figure", "Figure",
    ppr = '<w:spacing w:before="60" w:after="200"/><w:jc w:val="center"/>'),
  Bibliography = bekezdes_stilus("Bibliography", "Bibliography", alap = "BodyText",
    ppr = '<w:spacing w:after="100"/><w:ind w:left="567" w:hanging="567"/><w:jc w:val="left"/>'),
  BlockText = bekezdes_stilus("BlockText", "Block Text", alap = "BodyText", kov = "BodyText",
    ppr = paste0('<w:pBdr><w:left w:val="single" w:sz="12" w:space="8" w:color="', acelkek, '"/></w:pBdr>',
                 '<w:spacing w:before="120" w:after="120"/><w:ind w:left="567" w:right="567"/>'),
    rpr = rpr("Cambria", NULL, szurke, i = TRUE)),
  FootnoteText = bekezdes_stilus("FootnoteText", "footnote text", alap = "Normal",
    ppr = '<w:spacing w:before="0" w:after="40" w:line="240" w:lineRule="auto"/>',
    rpr = rpr("Cambria", 9)),
  TOCHeading = bekezdes_stilus("TOCHeading", "TOC Heading", alap = "Heading1", kov = "BodyText",
    ppr = '<w:outlineLvl w:val="9"/>'),
  SourceCode = bekezdes_stilus("SourceCode", "Source Code", alap = "Normal",
    ppr = paste0('<w:pBdr><w:left w:val="single" w:sz="12" w:space="6" w:color="C9D3DE"/></w:pBdr>',
                 '<w:shd w:val="clear" w:color="auto" w:fill="F4F6F9"/>',
                 '<w:wordWrap w:val="off"/><w:spacing w:before="0" w:after="160" w:line="240" w:lineRule="auto"/><w:ind w:left="113"/>'),
    rpr = rpr("Consolas", 8.5)),
  VerbatimChar = paste0('<w:style w:type="character" w:customStyle="1" w:styleId="VerbatimChar"><w:name w:val="Verbatim Char"/><w:basedOn w:val="DefaultParagraphFont"/>',
                        rpr("Consolas", 9.5, sotetkek), "</w:style>"),
  Hyperlink = paste0('<w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/><w:basedOn w:val="DefaultParagraphFont"/>',
                     '<w:rPr><w:color w:val="', acelkek, '"/></w:rPr></w:style>'),
  # APA/booktabs jellegű táblázat: vastag vonal a fejléc felett és az utolsó sor alatt,
  # vékony vonal a fejléc alatt. A vonalak feltételes formázások (firstRow, lastRow),
  # mert a Quarto ugyanezzel a stílussal készíti az ábrák és táblázatok fejléc nélküli
  # kerettáblázatait is, amelyeken nem szeretnénk vonalat. A lastRow formázást a
  # docx-sablon.lua szűrő kapcsolja be.
  Table = paste0(
    '<w:style w:type="table" w:default="1" w:styleId="Table"><w:name w:val="Table"/><w:basedOn w:val="TableNormal"/><w:uiPriority w:val="59"/><w:qFormat/>',
    '<w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>',
    rpr("Calibri", 9.5),
    '<w:tblPr><w:jc w:val="center"/><w:tblInd w:w="0" w:type="dxa"/>',
    '<w:tblCellMar><w:top w:w="40" w:type="dxa"/><w:left w:w="113" w:type="dxa"/>',
    '<w:bottom w:w="40" w:type="dxa"/><w:right w:w="113" w:type="dxa"/></w:tblCellMar></w:tblPr>',
    '<w:tblStylePr w:type="firstRow"><w:rPr><w:b/><w:bCs/><w:color w:val="', sotetkek, '"/></w:rPr>',
    '<w:tcPr><w:tcBorders><w:top w:val="single" w:sz="12" w:space="0" w:color="', sotetkek, '"/>',
    '<w:bottom w:val="single" w:sz="6" w:space="0" w:color="', sotetkek, '"/></w:tcBorders>',
    '<w:vAlign w:val="bottom"/></w:tcPr></w:tblStylePr>',
    '<w:tblStylePr w:type="lastRow"><w:tcPr><w:tcBorders>',
    '<w:bottom w:val="single" w:sz="12" w:space="0" w:color="', sotetkek, '"/></w:tcBorders></w:tcPr></w:tblStylePr>',
    '</w:style>')
)

stilusok <- olvas("word/styles.xml")

# alapértelmezések: Cambria 11 pt, magyar nyelv (elválasztás, helyesírás-ellenőrzés)
stilusok <- sub("<w:docDefaults>.*?</w:docDefaults>", paste0(
  "<w:docDefaults><w:rPrDefault>",
  rpr("Cambria", 11, extra = '<w:lang w:val="hu-HU" w:eastAsia="hu-HU" w:bidi="ar-SA"/>'),
  '</w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="140" w:line="276" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>'),
  stilusok, perl = TRUE)

for (id in names(uj_stilusok)) {
  minta <- sprintf('<w:style [^>]*w:styleId="%s"[^>]*>.*?</w:style>', id)
  if (grepl(minta, stilusok, perl = TRUE)) {
    stilusok <- sub(minta, uj_stilusok[[id]], stilusok, perl = TRUE)
  } else {
    stilusok <- sub("</w:styles>", paste0(uj_stilusok[[id]], "</w:styles>"), stilusok, fixed = TRUE)
  }
}
# a címsorok karakterstílusai se írják felül a fenti beállításokat
stilusok <- gsub('(<w:style [^>]*w:styleId="Heading\\dChar"[^>]*>.*?)<w:rPr>.*?</w:rPr>', "\\1",
                 stilusok, perl = TRUE)
ir(stilusok, "word/styles.xml")

# 3. Lábléc oldalszámmal ----------------------------------------------------------
ir(paste0(
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
  '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ',
  'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
  '<w:p><w:pPr><w:pBdr><w:top w:val="single" w:sz="4" w:space="6" w:color="C9D3DE"/></w:pBdr>',
  '<w:jc w:val="right"/></w:pPr>',
  '<w:r>', rpr("Calibri", 9, szurke), '<w:fldChar w:fldCharType="begin"/></w:r>',
  '<w:r>', rpr("Calibri", 9, szurke), '<w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>',
  '<w:r>', rpr("Calibri", 9, szurke), '<w:fldChar w:fldCharType="separate"/></w:r>',
  '<w:r>', rpr("Calibri", 9, szurke), '<w:t>1</w:t></w:r>',
  '<w:r>', rpr("Calibri", 9, szurke), '<w:fldChar w:fldCharType="end"/></w:r>',
  '</w:p></w:ftr>'), "word/footer1.xml")

kapcsolatok <- olvas("word/_rels/document.xml.rels")
kapcsolatok <- sub("</Relationships>", paste0(
  '<Relationship Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" ',
  'Id="rIdLablec1" Target="footer1.xml"/></Relationships>'), kapcsolatok, fixed = TRUE)
ir(kapcsolatok, "word/_rels/document.xml.rels")

tipusok <- olvas("[Content_Types].xml")
tipusok <- sub("</Types>", paste0(
  '<Override PartName="/word/footer1.xml" ',
  'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>'),
  tipusok, fixed = TRUE)
ir(tipusok, "[Content_Types].xml")

# 4. Oldalbeállítás: A4, 2,5 cm-es margók, lábléc --------------------------------
dokumentum <- olvas("word/document.xml")
dokumentum <- sub("<w:sectPr>.*?</w:sectPr>", paste0(
  '<w:sectPr><w:footerReference w:type="default" r:id="rIdLablec1"/>',
  '<w:footnotePr><w:numRestart w:val="eachSect"/></w:footnotePr>',
  '<w:pgSz w:w="11906" w:h="16838"/>',
  '<w:pgMar w:top="1418" w:right="1418" w:bottom="1418" w:left="1418" w:header="709" w:footer="709" w:gutter="0"/>',
  '</w:sectPr>'), dokumentum, perl = TRUE)
ir(dokumentum, "word/document.xml")

# 5. Visszacsomagolás -------------------------------------------------------------
fajlok <- list.files(munka, recursive = TRUE, all.files = TRUE)
fajlok <- c("[Content_Types].xml", setdiff(fajlok, "[Content_Types].xml"))
# rögzített időbélyeg: így minden futás bájtra azonos állományt ad (nincs fölösleges git-változás)
Sys.setFileTime(file.path(munka, fajlok), as.POSIXct("2025-01-01 00:00:00", tz = "UTC"))
dir.create(dirname(kimenet), showWarnings = FALSE)
unlink(kimenet)
# a root= miatt a zip() átvált a munkakönyvtárba, ezért abszolút útvonal kell
zip::zip(file.path(normalizePath(dirname(kimenet)), basename(kimenet)),
         files = fajlok, root = munka)
message("Elkészült: ", kimenet)
