# One worked line of Clarion for every property and method on
# EmfPreviewClass and EmfTextIndexClass.  Kept beside the generator rather
# than inside it so the reference volume can show how a call is actually
# used, not just its prototype.  A name missing from here is reported when
# the volumes are built.

PROPS = {
 # ---- EmfPreviewClass options (set before Display) -------------------------
 'Title':          "Prev.Title = 'Invoices - ' & CLIP(LOC:CustomerName)   ! window caption, default 'Report Preview'",
 'ShowSidebar':    "Prev.ShowSidebar = FALSE                   ! start without the thumbnail strip (the toolbar check box brings it back)",
 'SidebarWidth':   "Prev.SidebarWidth = 240                    ! pixels; the template offers 100..400",
 'InitialZoom':    "Prev.InitialZoom = EmfPrv:Zoom:FitPage     ! or EmfPrv:Zoom:FitWidth, or a percent: 125",
 'HighlightColor': "Prev.HighlightColor = 0076F1FFH            ! COLORREF 00BBGGRR - soft yellow for search hits",
 'MarkColor':      "Prev.MarkColor = 00FFE6A5H                 ! the marker pen colour of text marks",
 'CurrentColor':   "Prev.CurrentColor = COLOR:Red              ! 2 px frame around the current hit",
 'PageMarkColor':  "Prev.PageMarkColor = 000B9EF5H             ! thumbnail frame of a marked page (amber)",
 'AccentColor':    "Prev.AccentColor = 00EB6F1FH               ! thumbnail frame of the current page (blue)",
 'PaperShadow':    "Prev.PaperShadow = 00404040H               ! the area around the page",
 'SidebarColor':   "Prev.SidebarColor = COLOR:White            ! behind the thumbnails",
 'SearchMatchCase':"Prev.SearchMatchCase = TRUE                ! the 'Aa' box starts ticked",
 'SearchWholeWord':"Prev.SearchWholeWord = TRUE                ! only hits bounded by spaces (no toolbar control - set it in code)",
 'ClassicMode':    "Prev.ClassicMode = TRUE                    ! behave exactly like the ABC PrintPreviewClass for this report",
 'PrintMarks':     "Prev.PrintMarks = FALSE                    ! print the clean pages even when text marks exist",
 'WheelLines':     "Prev.WheelLines = 5                        ! 40 px lines per wheel notch",
 'ClickMarks':     "Prev.ClickMarks = FALSE                    ! a left click on the page no longer toggles a mark",
 # ---- EmfPreviewClass state -----------------------------------------------
 'Index':          "!  PROTECTED - the text index, filled by Display before the window opens\n"
                   "IF RECORDS(SELF.Index.Texts) = 0 THEN SELF.HintText = 'This report has no text to search.'.",
 'Marks':          "!  PROTECTED - the user's text marks (EmfMarkQueue, Kind = EmfPrv:Kind:Mark)\n"
                   "SELF.Win{PROP:StatusText, 4} = RECORDS(SELF.Marks) & ' marks'",
 'Hits':           "!  PROTECTED - the hits of the last Find (EmfMarkQueue, Kind = EmfPrv:Kind:Match)\n"
                   "IF RECORDS(SELF.Hits) THEN SELF.MarkAllHits().",
 'Temps':          "!  PROTECTED - the rendered twin files still on disk; DeleteTemps empties it\n"
                   "IF RECORDS(SELF.Temps) > 50 THEN SELF.DeleteTemps().",
 'INI':            "!  PROTECTED - set through SetINIManager; NULL = remember nothing\n"
                   "IF NOT SELF.INI &= NULL THEN SELF.INI.Update('_EmfPreview_', 'Zoom', SELF.ZoomMode).",
 'Win':            "!  PROTECTED - the preview WINDOW while it is open, NULL otherwise\n"
                   "IF NOT SELF.Win &= NULL THEN SELF.Win{PROP:Text} = 'Page ' & SELF.CurrentPage.",
 'CurHit':         "!  PROTECTED - 1-based pointer into Hits, 0 = no current hit\n"
                   "IF SELF.CurHit THEN GET(SELF.Hits, SELF.CurHit); SELF.GotoPage(SELF.Hits.PageNo).",
 'ZoomPct':        "!  PROTECTED - the effective percent, also when ZoomMode is a fit equate\n"
                   "SELF.Win{PROP:StatusText, 3} = 'Zoom: ' & SELF.ZoomPct & '%'",
 'ZoomMode':       "!  PROTECTED - a percent or EmfPrv:Zoom:FitWidth / EmfPrv:Zoom:FitPage\n"
                   "IF SELF.ZoomMode = EmfPrv:Zoom:FitWidth THEN SELF.SetZoom(EmfPrv:Zoom:FitPage).",
 'SearchText':     "!  the Find entry; public, so a derived class can search on open\n"
                   "SELF.SearchText = U'Müller'\n"
                   "SELF.Find(SELF.SearchText)\n"
                   "SELF.NextHit(1)",
 'LastSearch':     "!  PROTECTED - what the current Hits were built from\n"
                   "IF SELF.SearchText <> SELF.LastSearch THEN SELF.Find(SELF.SearchText).",
 'ZoomText':       "!  the zoom COMBO's text ('Fit width', '150%'); UpdateStatus rewrites it\n"
                   "SELF.ZoomText = '100%'\n"
                   "POST(EVENT:Accepted, SELF.FeqZoomCombo)",
 'PageOfText':     "!  the 'of N' STRING beside the page spin; UpdateStatus rewrites it\n"
                   "SELF.PageOfText = 'of ' & RECORDS(SELF.ImageQueue)",
 'HitText':        "!  the 'Hit 3 of 12' STRING; UpdateStatus rewrites it\n"
                   "SELF.HitText = 'No hits'",
 'ThumbFirst':     "!  PROTECTED - the page shown in the first thumbnail slot\n"
                   "SELF.ThumbFirst = 1\n"
                   "SELF.RefreshThumbs()",
 'ThumbVisible':   "!  PROTECTED - thumbnail slots that fit, computed by Layout\n"
                   "SELF.ThumbFirst += SELF.ThumbVisible               ! one strip down",
 'ThumbH':         "!  PROTECTED - thumbnail height in pixels (page aspect), computed by Layout\n"
                   "Rows = INT((SELF.Win{PROP:ClientHeight} - 52) / (SELF.ThumbH + 26))",
 'PxPerMil':       "!  PROTECTED - IMAGE pixels per 1/1000 inch at the current zoom\n"
                   "XM = (MOUSEX() - SELF.FeqPage{PROP:XPos}) / SELF.PxPerMil   ! window px -> page mils",
 'RefPxPerMilX':   "!  PROTECTED - metafile reference pixels per mil (0.096 = 96 dpi)\n"
                   "IF SELF.RefPxPerMilX <> 0.096 THEN STOP('unexpected reference scale').",
 'RefPxPerMilY':   "!  PROTECTED - see RefPxPerMilX\n"
                   "Aspect = SELF.RefPxPerMilX / SELF.RefPxPerMilY",
 'ShownFile':      "!  PROTECTED - the rendered twin the IMAGE is showing right now\n"
                   "IF SELF.ShownFile <> '' THEN COPY(SELF.ShownFile, 'page-as-shown.emf').",
 'OldWndProc':     "!  PROTECTED - the WH_GETMESSAGE hook handle of this preview window\n"
                   "IF SELF.OldWndProc = 0 THEN SELF.HintText = 'Mouse wheel unavailable'.",
 'RenderSeq':      "!  PROTECTED - bumped per render so every twin gets a fresh file name\n"
                   "SELF.RenderSeq += 1\n"
                   "F = SELF.RenderPage(SELF.CurrentPage, TRUE, TRUE)",
 'Dirty':          "!  PROTECTED - TRUE after Layout: the next ShowPage starts at the top\n"
                   "SELF.Dirty = TRUE\n"
                   "SELF.ShowPage()",
 'WantHScroll':    "!  PROTECTED - Layout decided the page is wider than the pane\n"
                   "IF SELF.WantHScroll THEN SELF.SetZoom(EmfPrv:Zoom:FitWidth).",
 'WantVScroll':    "!  PROTECTED - Layout decided the page is taller than the pane\n"
                   "IF NOT SELF.WantVScroll THEN SELF.HintText = 'Whole page in view'.",
 'PendV':          "!  PROTECTED - vertical position last asked for (-1 = none); the IMAGE applies it lazily\n"
                   "IF SELF.PendV >= 0 THEN Pos = SELF.PendV ELSE Pos = SI.nPos.",
 'PendFromV':      "!  PROTECTED - the position PendV was requested from\n"
                   "IF SI.nPos = SELF.PendFromV THEN Pos = SELF.PendV + Step.",
 'HintText':       "Prev.HintText = ' Press F3 for the next invoice number'   ! status zone 1; '' = the built-in hint",
 'InAutoTest':     "Prev.InAutoTest = TRUE                     ! the window gets a 25 ms TIMER and TakeTimer runs",
 # ---- field equates ----------------------------------------------------------------
 'FeqToolbar':     "SELF.FeqToolbar{PROP:Height} = 70",
 'FeqPrint':       "POST(EVENT:Accepted, SELF.FeqPrint)          ! same as Ctrl+P",
 'FeqPrintMarked': "SELF.FeqPrintMarked{PROP:Disable} = CHOOSE(SELF.MarkedPageList() = '')",
 'FeqSaveAs':      "HIDE(SELF.FeqSaveAs)                          ! no export from this preview",
 'FeqClose':       "SELF.FeqClose{PROP:Tip} = 'Back to the invoice'",
 'FeqFirst':       "SELF.FeqFirst{PROP:Disable} = CHOOSE(SELF.CurrentPage <= 1)",
 'FeqPrev':        "SELF.FeqPrev{PROP:Disable} = CHOOSE(SELF.CurrentPage <= 1)",
 'FeqPageSpin':    "SELF.FeqPageSpin{PROP:RangeHigh} = RECORDS(SELF.ImageQueue)",
 'FeqPageOf':      "SELF.FeqPageOf{PROP:FontColor} = COLOR:Gray",
 'FeqNext':        "SELF.FeqNext{PROP:Disable} = CHOOSE(SELF.CurrentPage >= RECORDS(SELF.ImageQueue))",
 'FeqLast':        "SELF.FeqLast{PROP:Disable} = CHOOSE(SELF.CurrentPage >= RECORDS(SELF.ImageQueue))",
 'FeqZoomOut':     "POST(EVENT:Accepted, SELF.FeqZoomOut)",
 'FeqZoomCombo':   "SELF.FeqZoomCombo{PROP:From} = 'Fit width|Fit page|100%|200%'   ! a shorter zoom list",
 'FeqZoomIn':      "POST(EVENT:Accepted, SELF.FeqZoomIn)",
 'FeqFindPrompt':  "SELF.FeqFindPrompt{PROP:Text} = '&Suchen:'",
 'FeqSearch':      "SELECT(SELF.FeqSearch)                       ! same as Ctrl+F",
 'FeqFind':        "POST(EVENT:Accepted, SELF.FeqFind)           ! search for SearchText",
 'FeqFindPrev':    "SELF.FeqFindPrev{PROP:Tip} = 'Previous hit  (Shift+F3)'",
 'FeqFindNext':    "SELF.FeqFindNext{PROP:Tip} = 'Next hit  (F3)'",
 'FeqHitText':     "SELF.FeqHitText{PROP:FontStyle} = FONT:bold",
 'FeqCase':        "HIDE(SELF.FeqCase)                            ! always case-insensitive here",
 'FeqMarkAll':     "SELF.FeqMarkAll{PROP:Disable} = CHOOSE(RECORDS(SELF.Hits) = 0)",
 'FeqClearMarks':  "SELF.FeqClearMarks{PROP:Disable} = CHOOSE(RECORDS(SELF.Marks) = 0)",
 'FeqMarkPage':    "SELF.FeqMarkPage{PROP:Text} = '&Flag page'",
 'FeqSidebar':     "HIDE(SELF.FeqSidebar)                         ! the user may not hide the strip",
 'FeqSideBack':    "SELF.FeqSideBack{PROP:Fill} = SELF.SidebarColor",
 'FeqThumbUp':     "SELF.FeqThumbUp{PROP:Disable} = CHOOSE(SELF.ThumbFirst <= 1)",
 'FeqThumbDown':   "SELF.FeqThumbDown{PROP:Disable} = CHOOSE(SELF.ThumbFirst + SELF.ThumbVisible > RECORDS(SELF.ImageQueue))",
 'FeqPaper':       "SELF.FeqPaper{PROP:Color} = COLOR:Black       ! the 1 px frame around the page",
 'FeqPage':        "hwnd = SELF.FeqPage{PROP:Handle}              ! the IMAGE that shows the rendered twin",
 'ThumbBox':       "SELF.ThumbBox[i]{PROP:Color} = SELF.AccentColor   ! frame of thumbnail slot i",
 'ThumbImg':       "IF FIELD() = SELF.ThumbImg[i] THEN SELF.GotoPage(SELF.ThumbFirst + i - 1).",
 'ThumbLbl':       "SELF.ThumbLbl[i]{PROP:Text} = 'Page ' & (SELF.ThumbFirst + i - 1)",
 'ThumbCreated':   "LOOP i = 1 TO SELF.ThumbCreated ; HIDE(SELF.ThumbImg[i]) ; END",
 # ---- EmfTextIndexClass --------------------------------------------------------------
 'Pages':          "Idx.Pages.PageNo = 3\n"
                   "GET(Idx.Pages, Idx.Pages.PageNo)              ! frame, offsets, Marked, Matches of page 3",
 'Texts':          "LOOP i = 1 TO RECORDS(Idx.Texts)\n"
                   "  GET(Idx.Texts, i)\n"
                   "  Line = TOANSI(Idx.Texts.Text, 0FDE9h)       ! assign first - do not concatenate a TOANSI()\n"
                   "  Out.WriteLine(Idx.Texts.PageNo & TAB & Idx.Texts.Left & TAB & Idx.Texts.Top & TAB & CLIP(Line))\n"
                   "END",
 'CurPage':        "!  PROTECTED - the page the parser is delivering right now (1-based)\n"
                   "SELF.Texts.PageNo = SELF.CurPage",
 'Seq':            "!  PROTECTED - running number of the last text item added\n"
                   "SELF.Seq += 1",
 'CurBoxL':        "!  PROTECTED - the parser's box origin of the current page (WMF pages)\n"
                   "SELF.Texts.Left = F.Pos.Left - SELF.CurBoxL - SELF.CurOffX",
 'CurBoxT':        "!  PROTECTED - see CurBoxL\n"
                   "SELF.Texts.Top = F.Pos.Top - SELF.CurBoxT - SELF.CurOffY",
 'CurOffX':        "!  PROTECTED - the physical print offset of the current page (EMF pages)\n"
                   "SELF.Texts.TextX = F.leftText - SELF.CurBoxL - SELF.CurOffX",
 'CurOffY':        "!  PROTECTED - see CurOffX\n"
                   "SELF.Texts.Bottom = F.Pos.Bottom - SELF.CurBoxT - SELF.CurOffY",
 'WideRun':        "IF NOT Idx.WideRun THEN MESSAGE('This report is not UNICODE - text came through the ANSI lane.').",
 'Errors':         "!  PROTECTED - the ErrorClass handed to Init; the parser reports through it\n"
                   "IF SELF.Errors &= NULL THEN Parser.Init(Q, SELF.IReportGenerator) ELSE Parser.Init(Q, SELF.IReportGenerator, SELF.Errors).",
}

USAGE = {
 # ---- EmfTextIndexClass --------------------------------------------------------------
 'EmfTextIndexClass.CONSTRUCT': "Idx  EmfTextIndexClass                       ! Pages and Texts are NEWed here",
 'EmfTextIndexClass.DESTRUCT':  "!  runs Kill - nothing to call; let the object go out of scope",
 'EmfTextIndexClass.Init':      "Idx.Init(GlobalErrors)                        ! the parser reports through it; Init() alone is fine too",
 'EmfTextIndexClass.Kill':      "Idx.Kill()                                    ! frees and disposes both queues",
 'EmfTextIndexClass.Build':     "IF Idx.Build(PgQ) = Level:Benign            ! PgQ is the report's PREVIEW queue\n"
                                "  MESSAGE(RECORDS(Idx.Texts) & ' text items on ' & RECORDS(Idx.Pages) & ' pages')\n"
                                "END",
 'EmfTextIndexClass.ClearIndex':"Idx.ClearIndex()                              ! empty, keep the queues",
 'EmfTextIndexClass.AddText':   "!  VIRTUAL - override to filter what enters the index\n"
                                "MyIndex.AddText PROCEDURE(*StringFormatGrp F, USTRING Text)\n"
                                "  CODE\n"
                                "  IF F.Size < 6 THEN RETURN.                   ! skip the fine print\n"
                                "  PARENT.AddText(F, Text)",
 'EmfTextIndexClass.ProbePage': "Idx.ProbePage(PgQ.Filename, Pg)               ! Pg.IsEMF, FrameW/H (mils), OffX/OffY filled from the header",
 # ---- EmfPreviewClass: ABC overrides -------------------------------------------------
 'CONSTRUCT':        "Prev  EmfPreviewClass                         ! Index, Marks, Hits, Temps are NEWed; Title = 'Report Preview'",
 'DESTRUCT':         "!  disposes what CONSTRUCT made - nothing to call",
 'Display':          "IF Prev.Display()                             ! TRUE = the user chose Print\n"
                     "  Report{PROP:FlushPreview} = TRUE\n"
                     "END",
 'Open':             "!  VIRTUAL - runs on EVENT:OpenWindow; add to it, never skip PARENT\n"
                     "MyPrev.Open PROCEDURE()\n"
                     "  CODE\n"
                     "  PARENT.Open()\n"
                     "  SELF.SearchText = U'TOTAL'\n"
                     "  POST(EVENT:Accepted, SELF.FeqFind)",
 'Kill':             "Prev.Kill()                                   ! deletes the temp twins, empties the index",
 'TakeEvent':        "!  the ABC dispatch; a derived class handles its own controls first\n"
                     "MyPrev.TakeEvent PROCEDURE()\n"
                     "  CODE\n"
                     "  IF FIELD() = ?MyButton AND EVENT() = EVENT:Accepted THEN DO Export; RETURN Level:Benign.\n"
                     "  RETURN PARENT.TakeEvent()",
 'TakeWindowEvent':  "!  EVENT:OpenWindow / Sized / Timer / CloseWindow\n"
                     "MyPrev.TakeWindowEvent PROCEDURE()\n"
                     "  CODE\n"
                     "  IF EVENT() = EVENT:CloseWindow THEN DO SaveMarks.\n"
                     "  RETURN PARENT.TakeWindowEvent()",
 'TakeAccepted':     "!  every toolbar control; add a CASE before PARENT for controls you created\n"
                     "MyPrev.TakeAccepted PROCEDURE()\n"
                     "  CODE\n"
                     "  IF ACCEPTED() = ?BtnExportCsv THEN DO ExportCsv; RETURN Level:Benign.\n"
                     "  RETURN PARENT.TakeAccepted()",
 'TakeFieldEvent':   "!  mouse on the page IMAGE and the thumbnails, spin / combo NewSelection\n"
                     "MyPrev.TakeFieldEvent PROCEDURE()\n"
                     "  CODE\n"
                     "  IF FIELD() = SELF.FeqPage AND EVENT() = EVENT:AlertKey AND KEYCODE() = MouseRight\n"
                     "    RETURN Level:Notify                       ! no context menu in this app\n"
                     "  END\n"
                     "  RETURN PARENT.TakeFieldEvent()",
 'SetINIManager':    "Prev.SetINIManager(INIMgr)                    ! window size, zoom and sidebar survive under [_EmfPreview_]",
 # ---- navigation / view --------------------------------------------------------------
 'GotoPage':         "Prev.GotoPage(RECORDS(Prev.ImageQueue))       ! last page, scrolled to the top",
 'SetZoom':          "Prev.SetZoom(150)                             ! 10..800, or EmfPrv:Zoom:FitWidth / FitPage",
 'ZoomStep':         "Prev.ZoomStep(1)                              ! next stop on 25,33,50,67,75,100,125,150,175,200,250,300,400,500",
 'Layout':           "SELF.Layout()                                 ! after changing SidebarWidth or ShowSidebar while open\n"
                     "SELF.ShowPage()\n"
                     "SELF.RefreshThumbs()",
 'ShowPage':         "SELF.ShowPage()                               ! re-render the current page (after marks or hits changed)",
 'RefreshThumbs':    "SELF.RefreshThumbs()                          ! after Marked or Matches changed on a page",
 'ScrollTo':         "SELF.ScrollTo(SELF.Hits.Left, SELF.Hits.Top)  ! bring a page point into the upper third",
 'ScrollLines':      "SELF.ScrollLines(999)                         ! a screenful down; flips to the next page at the bottom",
 'UpdateStatus':     "SELF.UpdateStatus()                           ! status bar, button states, the 'Hit n of m' text",
 # ---- search / marks -----------------------------------------------------------------
 'Find':             "IF Prev.Find(U'Müller') = 0 THEN MESSAGE('Not in this report.') ELSE Prev.NextHit(1).",
 'NextHit':          "Prev.NextHit(-1)                              ! Shift+F3; wraps around",
 'MarkAllHits':      "Prev.MarkAllHits()                            ! every hit becomes a text mark (duplicates skipped)",
 'ClearMarks':       "Prev.ClearMarks()",
 'ToggleMarkAt':     "SELF.ToggleMarkAt(MOUSEX(), MOUSEY())         ! window pixels; marks / unmarks the whole text item",
 'TogglePageMark':   "Prev.TogglePageMark(Prev.CurrentPage)         ! Ctrl+M",
 'ItemAt':           "Ptr = SELF.ItemAt(SELF.CurrentPage, XM, YM)   ! page mils -> EmfTextQueue pointer, 0 = nothing there\n"
                     "IF Ptr THEN GET(SELF.Index.Texts, Ptr).",
 'MeasureItem':      "SELF.MeasureItem(Ptr)                         ! fills Index.Texts.TextW once (GDI, screen DC)",
 'SpanRect':         "SELF.SpanRect(Ptr, p, LEN(Needle), SELF.Hits) ! display rect of units p..p+len-1 of item Ptr",
 'MarkedPageList':   "SELF.PagesToPrint = SELF.MarkedPageList()     ! '1,3,7-9' - what the ABC print loop understands",
 # ---- rendering ----------------------------------------------------------------------
 'RenderPage':       "F = SELF.RenderPage(PageNo, TRUE, TRUE)       ! twin EMF with hits and marks; '' = failed\n"
                     "IF F = '' THEN F = SELF.Index.Pages.FileName.",
 'LoadMetafile':     "hemf = SELF.LoadMetafile(Pg.FileName, Pg.IsEMF)   ! HENHMETAFILE; a placeable .wmf is converted",
 'MeasureText':      "SELF.MeasureText('Segoe UI', 10, FONT:bold, U'Total', W, H)   ! W, H in mils",
 'TempName':         "F = SELF.TempName(PageNo)                     ! <page dir>\\EmfPrv_<thread>_<page>_<seq>.emf",
 'DeleteTemps':      "SELF.DeleteTemps()                            ! Kill and Display call it; call it yourself after a long session",
 'PrepareMarkedPrint':"SELF.PrepareMarkedPrint()                    ! Display calls it when PrintOK and PrintMarks: marked pages print via their twins",
 # ---- hooks ----------------------------------------------------------------------------
 'TakeTimer':        "!  VIRTUAL, empty - EVENT:Timer of the preview window (InAutoTest sets a 25 ms timer)\n"
                     "MyPrev.TakeTimer PROCEDURE()\n"
                     "  CODE\n"
                     "  IF SELF.Step = 1 THEN SELF.GotoPage(2); SELF.Step += 1.",
 'TakeWheel':        "!  called from the WH_GETMESSAGE hook with WM_MOUSEWHEEL; return 1 = handled\n"
                     "MyPrev.TakeWheel PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix)\n"
                     "  CODE\n"
                     "  IF BAND(Keys, MK_SHIFT) THEN SELF.GotoPage(SELF.CurrentPage + CHOOSE(Delta > 0, -1, 1)); RETURN 1.\n"
                     "  RETURN PARENT.TakeWheel(Delta, Keys, XPix, YPix)",
}
