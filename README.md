# EmfPreview — EMF / Unicode report previewer for Clarion 12 Unicode

A drop-in replacement for the ABC `PrintPreviewClass`, delivered as a class library plus an
AppGen template, written for **Clarion 12 Unicode** (`C:\Clarion12unicode`, build 12.0.14234+).

| | Stock ABC previewer | EmfPreview |
|---|---|---|
| Page files | shows the `.emf` / `.wmf` page in an IMAGE | same engine, plus a rendered twin with highlights baked in |
| Navigation | spin / thumbnails-as-tiles | **page thumbnail sidebar** (click, wheel, marked pages framed) + first/prev/next/last, Ctrl+Home/End, PgUp/PgDn flips pages at the edges |
| Zoom | menu | fit width / fit page / 25‥500 %, Ctrl+wheel, Ctrl +/− |
| Search | – | **full-text search** over every page (Unicode, case option), F3 / Shift+F3, hit counter per page, exact **highlight of the matched text** with the current hit framed |
| Marks | – | **mark text** (click a line, or "Mark hits"), **mark pages** (Ctrl+M, right-click a thumbnail), print only the marked pages, print pages **with their text marks** |
| Wheel | – | scrolls the page, flips pages at the ends, **Ctrl+wheel = zoom**, over the sidebar = thumbnails (per-thread `WH_GETMESSAGE` hook — Windows sends the wheel to the control under the cursor and Clarion's control procs swallow it) |
| Save As / target selector | yes | yes (inherited) |

## What was learned about the new report engine (Clarion 12 Unicode)

* `REPORT,…,UNICODE` (the *Unicode* property in the report designer) prints wide text end to end and writes the
  `PREVIEW` page files as **enhanced metafiles (`.emf`)** — the test app confirmed 8 pages of 600-dpi EMF
  (`CLA…emf`, `EMR_HEADER` + `' EMF'` signature, ~3 000 records per page). Non-UNICODE reports still write placeable `.wmf`.
* Colour emoji are recorded as `EMR_ALPHABLEND` 32-bpp stamps *in addition to* the UTF-16 text run, so text search still finds them.
* The shipped `WMFDocumentParser`/`WMFParser` (`ABWMFPAR.*`) has a full EMF lane. Register a wide target through
  `SetWideGenerator(IReportGeneratorW)` and every text item arrives as a `USTRING` with its page rectangle in 1/1000".
  **Parser coordinates include the printer's physical offset** (`(frame − printable)/2`, ≈158 mils here) that GDI playback
  does *not* apply — subtract it (see `EmfTextIndexClass.ProbePage`) before overlaying anything on the displayed page.
* The `IMAGE` control shows an EMF at 96 dpi of its frame; its `HVSCROLL` scroll range is the image's *natural* size.
  EmfPreview therefore renders each page into a wrapper EMF whose frame equals the zoomed display size, so
  `GetScrollInfo` positions are pixels and click-to-text mapping is exact.
* Highlights are drawn with `SetROP2(R2_MASKPEN)` — a real marker-pen effect that keeps black text black.
* Unicode gotchas: `TOANSI(u, 0FDE9h)` (UTF-8) must be *assigned* to a STRING first — inside a `&` concatenation the
  expression is evaluated wide and narrowed through the ANSI code page. `UPPER`/`INSTRING` are Unicode-aware on `USTRING`.
* Runtime gotchas: `THREAD`ed module-level data in a class module crashes at start-up in this build; classes with
  `LINK(…,_xLinkMode_),DLL(_xDllMode_)` **must** get both defines from the project (`%AddCategory` does it for
  generated apps; hand-coded projects need `_EmfPrvLinkMode_=>1;_EmfPrvDllMode_=>0` in `DefineConstants`).

## Layout

```
src/EmfPreview.inc      class declarations  (!ABCIncludeFile(EMFPRV))
src/EmfPreview.clw      EmfTextIndexClass + EmfPreviewClass
src/EmfPreview.tpl      template chain: global activate + per-report options
install.ps1             copies the three files into <Clarion>\accessory\{libsrc,template}\win and registers the template
test/EmfRptTest.*       hand-coded probe: REPORT,UNICODE -> EMF pages, header probe, text index dump, scripted UI autotest
testapp/EmfPrvTest.*    AppGen test: TXD dictionary + TXA with one ABC Report procedure, generated & built headlessly
```

## Install

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1            # default C:\Clarion12unicode
```
Restart the IDE if it was open (the registry is only read at start-up).

## Use in an application

1. Global Extensions → **EMF Unicode Previewer – Global (activate)**. With *Replace the previewer in every report
   procedure* (default on) the ABC `Previewer` object of every Report procedure becomes `EmfPreviewClass`
   (the template sets the global *Print Previewer* class). Defaults for sidebar, zoom, colours, wheel, marks live here.
2. Optional, per report: extension **EMF Unicode Previewer – Report options** — window title, override the global
   options, or *uncheck Use* to fall back to the classic ABC preview window for that report (`ClassicMode`).
3. Give the report the **Unicode** attribute for exact wide text (`REPORT,…,UNICODE`). Classic `.wmf` reports work too
   (their pages are converted with `SetWinMetaFileBits` for highlighting).

Hand-coded programs: `INCLUDE('EmfPreview.INC')`, declare `Prev EmfPreviewClass`, `Prev.Init(PreviewQueue)`,
`Prev.Errors &= GlobalErrors`, then `IF Prev.Display() THEN Report{PROP:FlushPreview} = TRUE.` — see `test/EmfRptTest.clw`.

### Keyboard / mouse

| | |
|---|---|
| Ctrl+F / Enter | focus search / find next |
| F3 / Shift+F3 | next / previous hit |
| Ctrl+PgUp / Ctrl+PgDn, Ctrl+Home / Ctrl+End | page navigation |
| PgUp / PgDn, wheel | scroll, flips pages at the edges |
| Ctrl+wheel, Ctrl+ + / − | zoom |
| left click on a text line | toggle a text mark |
| right click | menu (mark, page mark, zoom, fit) |
| Ctrl+M | mark / unmark page |
| Ctrl+P / Esc | print / close |

## Class API (excerpt)

`EmfPreviewClass` (derives `PrintPreviewClass`): options `Title`, `ShowSidebar`, `SidebarWidth`, `InitialZoom`
(`EmfPrv:Zoom:FitWidth`, `EmfPrv:Zoom:FitPage` or a percent), `HighlightColor`, `MarkColor`, `CurrentColor`,
`PageMarkColor`, `AccentColor`, `PaperShadow`, `SidebarColor`, `SearchMatchCase`, `SearchWholeWord`, `PrintMarks`,
`ClickMarks`, `WheelLines`, `ClassicMode`. Virtual hooks: `Find`, `NextHit`, `MarkAllHits`, `ClearMarks`,
`ToggleMarkAt`, `TogglePageMark`, `GotoPage`, `SetZoom`, `RenderPage`, `TakeWheel`, `TakeTimer`.

`EmfTextIndexClass`: `Build(PreviewQueue)` fills `Pages` (frame, offsets, marks, hit counts) and `Texts`
(page, rectangle, text start x, font, `USTRING` text) for every page — reusable for any other page-text tooling.

## Tests

* `test\EmfRptTest.exe autotest` — prints a Unicode report, probes the page files, dumps `pages\textindex.txt`, then
  drives the previewer through search / marks / zoom / click-mark and writes screenshots to `test\shots\`.
* `testapp\` — `ClarionCL -di` (dictionary), `-ai` (import TXA into a new app), `-ag` (generate), MSBuild with the
  `.cwproj` derived from the app's project section. Notes for hand-written TXAs: header order is
  `VERSION`, `TODO`, `DICTIONARY`, `PROCEDURE`; `[ADDITION]` blocks have no `[END]`; supply `%ClassItem`/`%ClassLines`
  for the derived objects; progress controls need `#ORIG(...)`.

## Known limits / next steps

* A hit's rectangle is measured with the item's font on the screen DC (`GetTextExtentPoint32W`); exotic fonts or
  justified TEXT controls may be a few pixels off.
* Whole-word search treats only spaces as word boundaries.
* Text marks are kept for the preview session only (no persistence yet).
* Search runs over a report's own pages only; PDF/HTML export still goes through the ABC target selector (Save As).
