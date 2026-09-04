!UTF8
!==========================================================================
! EmfRptTest - Clarion 12 Unicode report probe
!  * prints a REPORT,UNICODE (8 pages, mixed scripts + emoji) to PREVIEW
!  * probes every page file header (EMF vs placeable WMF), copies them
!  * runs the shipped WMFDocumentParser with a text-index target that
!    implements IReportGenerator + IReportGeneratorW and dumps every text
!    item with its 1/1000" position to pages\textindex.txt (UTF-8)
!  * measures how the IMAGE control reports an EMF page's natural size
!  * optionally shows the stock ABC PrintPreviewClass (omit "nopreview")
!==========================================================================
  PROGRAM
  INCLUDE('KEYCODES.CLW'),ONCE
  INCLUDE('EQUATES.CLW'),ONCE
  INCLUDE('ERRORS.CLW'),ONCE
  INCLUDE('ABERROR.INC'),ONCE
  INCLUDE('ABREPORT.INC'),ONCE
  INCLUDE('ABWMFPAR.INC'),ONCE
  INCLUDE('ABRPTGEN.INT'),ONCE
  INCLUDE('EmfPreview.INC'),ONCE

  MAP
    Main()
    ProbePages(PrintPreviewFileQueue Q, STRING OutDir)
    IndexPages(PrintPreviewFileQueue Q, STRING OutFile)
    MeasureImage(STRING FileName)
    Log(STRING s)
    CaptureWindow(LONG hwnd, STRING BmpName)
    MODULE('TestApi')
      tp_GetDC(LONG),LONG,PASCAL,NAME('GetDC')
      tp_ReleaseDC(LONG,LONG),LONG,PASCAL,PROC,NAME('ReleaseDC')
      tp_CreateCompatibleDC(LONG),LONG,PASCAL,NAME('CreateCompatibleDC')
      tp_CreateCompatibleBitmap(LONG,LONG,LONG),LONG,PASCAL,NAME('CreateCompatibleBitmap')
      tp_SelectObject(LONG,LONG),LONG,PASCAL,PROC,NAME('SelectObject')
      tp_DeleteObject(LONG),LONG,PASCAL,PROC,NAME('DeleteObject')
      tp_DeleteDC(LONG),LONG,PASCAL,PROC,NAME('DeleteDC')
      tp_PrintWindow(LONG,LONG,ULONG),LONG,PASCAL,PROC,NAME('PrintWindow')
      tp_GetDIBits(LONG,LONG,ULONG,ULONG,LONG,LONG,ULONG),LONG,PASCAL,PROC,NAME('GetDIBits')
      tp_GetWindowRect(LONG,LONG),LONG,PASCAL,PROC,NAME('GetWindowRect')
      tp_PostMessageA(LONG,ULONG,LONG,LONG),LONG,PASCAL,PROC,NAME('PostMessageA')
      tp_GetScrollInfo(LONG,LONG,LONG),LONG,PASCAL,PROC,NAME('GetScrollInfo')
      tp_GetWindowLongA(LONG,LONG),LONG,PASCAL,NAME('GetWindowLongA')
      tp_GetClientRect(LONG,LONG),LONG,PASCAL,PROC,NAME('GetClientRect')
      tp_BitBlt(LONG,LONG,LONG,LONG,LONG,LONG,LONG,LONG,ULONG),LONG,PASCAL,PROC,NAME('BitBlt')
    END
  END

! ---- autotest driver: scripts the previewer through a timer and grabs screenshots
TestPreview CLASS(EmfPreviewClass),TYPE
Step          LONG
ShotDir       CSTRING(261)
TakeTimer     PROCEDURE(),VIRTUAL
TakeWheel     PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix),LONG,VIRTUAL
Shot          PROCEDURE(STRING Name)
            END

BmpName    CSTRING(261)
BmpFile    FILE,DRIVER('DOS'),NAME(BmpName),CREATE,PRE(BMP)
Rec          RECORD
Buf            STRING(4000000)
             END
           END

GlobalErrors  ErrorClass
GlobalErrorStatus ErrorStatusClass

LogName    CSTRING(261)
LogFile    FILE,DRIVER('DOS'),NAME(LogName),CREATE,PRE(LOG)
Rec          RECORD
Buf            STRING(4096)
             END
           END

ProbeName  CSTRING(261)
ProbeFile  FILE,DRIVER('DOS'),NAME(ProbeName),PRE(PRB)
Rec          RECORD
Buf            STRING(88)
             END
           END

!--------------------------------------------------------------------------
! Text index target: collects every text item the parser delivers.
!--------------------------------------------------------------------------
TextIndexClass CLASS,IMPLEMENTS(IReportGenerator),IMPLEMENTS(IReportGeneratorW)
Page             LONG
Items            LONG
WideRun          BYTE
Box              GROUP(PosGrp).
OutName          CSTRING(261)
Init             PROCEDURE(STRING OutFile)
Kill             PROCEDURE()
Emit             PROCEDURE(STRING s)
EmitItem         PROCEDURE(STRING Kind, *StringFormatGrp F, USTRING Text, STRING Attr)
               END

IdxName    CSTRING(261)
IdxFile    FILE,DRIVER('DOS'),NAME(IdxName),CREATE,PRE(IDX)
Rec          RECORD
Buf            STRING(8192)
             END
           END

  CODE
  GlobalErrors.Init(GlobalErrorStatus)
  Main()
  GlobalErrors.Kill()

!==========================================================================
Main PROCEDURE()
PgQ        QUEUE(PrintPreviewFileQueue).
HdrSub     USTRING(120)
DtlNo      LONG
DtlName    USTRING(80)
DtlCity    USTRING(80)
DtlAmount  DECIMAL(11,2)
Names      USTRING(80),DIM(12)
Cities     USTRING(80),DIM(12)
i          LONG
OutDir     CSTRING(261)
Prev       TestPreview
StartT     LONG

Report REPORT,AT(500,1000,7500,9000),PRE(RPT),FONT('Segoe UI',10,,FONT:regular),THOUS, |
         PREVIEW(PgQ),UNICODE
         HEADER,AT(500,250,7500,700),USE(?Header)
           STRING(U'Clarion 12 Unicode – EMF Report Probe  Ω Ж 中 😀'),AT(0,0,7500,300),USE(?HdrTitle), |
             FONT(,14,,FONT:bold),CENTER
           STRING(@s120),AT(0,350,7500,250),USE(HdrSub),CENTER
           LINE,AT(0,650,7500,0),USE(?HdrLine),COLOR(COLOR:Navy)
         END
Detail   DETAIL,AT(,,7500,300),USE(?Detail)
           STRING(@n5),AT(0,20,500,250),USE(DtlNo),RIGHT
           STRING(@s80),AT(700,20,3300,250),USE(DtlName)
           STRING(@s80),AT(4100,20,2200,250),USE(DtlCity)
           STRING(@n-11.2),AT(6400,20,1100,250),USE(DtlAmount),RIGHT
         END
         FOOTER,AT(500,10250,7500,400),USE(?Footer)
           LINE,AT(0,20,7500,0),USE(?FtrLine),COLOR(COLOR:Navy)
           STRING(U'Seite / Página / Страница / ページ'),AT(0,80,3000,250),USE(?FtrLabel)
           STRING(@n3),AT(3100,80,600,250),USE(?FtrPage),PAGENO
           STRING(U'© 2026 EMF probe – generated by Clarion 12 Unicode'),AT(4000,80,3500,250),USE(?FtrRight),RIGHT
         END
       END

  CODE
  OutDir  = LONGPATH() & '\pages'
  LogName = LONGPATH() & '\EmfRptTest.log'
  IF NOT EXISTS(OutDir) THEN RUN('cmd /c mkdir "' & OutDir & '"',1).
  REMOVE(LogFile)
  CREATE(LogFile)
  OPEN(LogFile)
  Log('EmfRptTest started ' & FORMAT(TODAY(),@d10) & ' ' & FORMAT(CLOCK(),@t4))
  Log('Clarion runtime: ' & SYSTEM{PROP:LibVersion} & '  codepage=' & SYSTEM{PROP:Codepage})

  Names[1]  = U'Ana Müller'
  Names[2]  = U'Γιώργος Παπαδόπουλος'
  Names[3]  = U'Дмитрий Иванов'
  Names[4]  = U'王小明'
  Names[5]  = U'山田 太郎'
  Names[6]  = U'김민준'
  Names[7]  = U'José Ñandú-Ibáñez'
  Names[8]  = U'Zoë Ærø Søren'
  Names[9]  = U'Łukasz Żółć'
  Names[10] = U'Aşkın Çelik'
  Names[11] = U'Emoji Tester 😀🚀🎉'
  Names[12] = U'Math ∑∫√ ≠ ≤ ≥ ∞'
  Cities[1] = U'Zürich'
  Cities[2] = U'Αθήνα'
  Cities[3] = U'Москва'
  Cities[4] = U'北京'
  Cities[5] = U'東京'
  Cities[6] = U'서울'
  Cities[7] = U'São Paulo'
  Cities[8] = U'København'
  Cities[9] = U'Łódź'
  Cities[10]= U'İstanbul'
  Cities[11]= U'🌍 Earth'
  Cities[12]= U'Ω-Town'

  HdrSub = U'Unicode ready? – Ελληνικά · Русский · 中文 · 日本語 · 한국어 · Emoji 🎯'

  StartT = CLOCK()
  OPEN(Report)
  IF ERRORCODE()
    Log('OPEN(Report) failed: ' & ERRORCODE() & ' ' & ERROR())
    CLOSE(LogFile)
    RETURN
  END
  Log('Report opened. landscape=' & Report{PROP:Landscape})

  LOOP i = 1 TO 240
    DtlNo     = i
    DtlName   = Names[(i-1) % 12 + 1] & U' #' & i
    DtlCity   = Cities[(i-1) % 12 + 1]
    DtlAmount = i * 123.45
    PRINT(RPT:Detail)
    IF ERRORCODE()
      Log('PRINT error at row ' & i & ': ' & ERRORCODE() & ' ' & ERROR())
      BREAK
    END
  END
  ENDPAGE(Report)
  Log('Printed 240 detail rows -> ' & RECORDS(PgQ) & ' page files in ' & (CLOCK()-StartT) & ' ms')

  ProbePages(PgQ, OutDir)
  IndexPages(PgQ, OutDir & '\textindex.txt')
  GET(PgQ, 1)
  IF NOT ERRORCODE() THEN MeasureImage(PgQ.Filename).

  IF NOT INSTRING('NOPREVIEW', UPPER(COMMAND()), 1, 1)
    Log('Showing EmfPreviewClass...')
    Prev.Init(PgQ)
    Prev.Errors &= GlobalErrors
    Prev.Title = 'EMF Report Probe - Unicode preview'
    IF INSTRING('AUTOTEST', UPPER(COMMAND()), 1, 1)
      Prev.InAutoTest = TRUE
      Prev.ShotDir = LONGPATH() & '\shots'
      IF NOT EXISTS(Prev.ShotDir) THEN RUN('cmd /c mkdir "' & Prev.ShotDir & '"',1).
      Log('autotest mode: screenshots -> ' & Prev.ShotDir)
    END
    StartT = CLOCK()
    IF Prev.Display()
      Log('User chose Print -> flushing preview to printer')
      Report{PROP:FlushPreview} = TRUE
    ELSE
      Log('Preview closed without printing (' & (CLOCK()-StartT) & ' ms in preview)')
    END
    Prev.Kill()
  ELSE
    Log('nopreview: skipping stock previewer')
  END

  CLOSE(Report)
  Log('Report closed. Done.')
  CLOSE(LogFile)
  RETURN

!==========================================================================
! Probe page-file headers and copy them out as .emf/.wmf
!==========================================================================
ProbePages PROCEDURE(PrintPreviewFileQueue Q, STRING OutDir)
EnhHdr     GROUP,OVER(PRB:Buf)
RecType      ULONG
RecSize      ULONG
BoundsL      LONG
BoundsT      LONG
BoundsR      LONG
BoundsB      LONG
FrameL       LONG
FrameT       LONG
FrameR       LONG
FrameB       LONG
Signature    ULONG
Version      ULONG
NBytes       ULONG
NRecords     ULONG
NHandles     USHORT
Reserved     USHORT
DescSize     ULONG
DescOff      ULONG
PalEntries   ULONG
DevPxX       LONG
DevPxY       LONG
DevMMX       LONG
DevMMY       LONG
           END
WmfKey     ULONG,OVER(PRB:Buf)
i          LONG
DotPos     LONG
Ext        STRING(8)
Dst        CSTRING(261)
nEMF       LONG
nWMF       LONG
nOther     LONG
  CODE
  Log('--- Page file probe (' & RECORDS(Q) & ' files) ---')
  LOOP i = 1 TO RECORDS(Q)
    GET(Q, i)
    ProbeName = CLIP(Q.Filename)
    Ext = ''
    DotPos = INSTRING('.', ProbeName, -1, LEN(ProbeName))
    IF DotPos THEN Ext = SUB(ProbeName, DotPos, 8).
    OPEN(ProbeFile, 40h)
    IF ERRORCODE()
      Log('  ' & i & ': cannot open ' & ProbeName & ' - ' & ERROR())
      CYCLE
    END
    GET(ProbeFile, 1, SIZE(PRB:Buf))
    IF EnhHdr.RecType = 1 AND EnhHdr.Signature = 464D4520h
      nEMF += 1
      Dst = OutDir & '\page_' & FORMAT(i,@n03) & '.emf'
      IF i <= 2 OR i = RECORDS(Q)
        Log('  ' & i & ': EMF  ' & ProbeName & '  ext=' & CLIP(Ext) & |
            '  bytes=' & EnhHdr.NBytes & ' records=' & EnhHdr.NRecords & ' handles=' & EnhHdr.NHandles & |
            '  frame(0.01mm)=' & EnhHdr.FrameL & ',' & EnhHdr.FrameT & ',' & EnhHdr.FrameR & ',' & EnhHdr.FrameB & |
            '  device px=' & EnhHdr.DevPxX & 'x' & EnhHdr.DevPxY & ' mm=' & EnhHdr.DevMMX & 'x' & EnhHdr.DevMMY & |
            '  dpi~' & ROUND(EnhHdr.DevPxX*25.4/EnhHdr.DevMMX,1) & 'x' & ROUND(EnhHdr.DevPxY*25.4/EnhHdr.DevMMY,1) & |
            '  desc=' & EnhHdr.DescSize & 'ch@' & EnhHdr.DescOff)
      END
    ELSIF WmfKey = 9AC6CDD7h
      nWMF += 1
      Dst = OutDir & '\page_' & FORMAT(i,@n03) & '.wmf'
      IF i <= 2 THEN Log('  ' & i & ': placeable WMF ' & ProbeName).
    ELSE
      nOther += 1
      Dst = OutDir & '\page_' & FORMAT(i,@n03) & '.bin'
      Log('  ' & i & ': UNKNOWN header ' & ProbeName & ' first4=' & WmfKey)
    END
    CLOSE(ProbeFile)
    REMOVE(Dst)
    COPY(ProbeName, Dst)
    IF ERRORCODE() THEN Log('  copy failed -> ' & Dst & ' : ' & ERROR()).
  END
  Log('Result: EMF=' & nEMF & '  WMF=' & nWMF & '  other=' & nOther & '  copies in ' & OutDir)
  RETURN

!==========================================================================
! Run the shipped parser with the text-index target
!==========================================================================
IndexPages PROCEDURE(PrintPreviewFileQueue Q, STRING OutFile)
Parser     WMFDocumentParser
TIdx       TextIndexClass
rc         BYTE
StartT     LONG
  CODE
  Log('--- Text index via WMFDocumentParser -> ' & OutFile & ' ---')
  StartT = CLOCK()
  TIdx.Init(OutFile)
  Parser.Init(Q, TIdx.IReportGenerator, GlobalErrors)
  Parser.SetWideGenerator(TIdx.IReportGeneratorW)
  rc = Parser.GenerateReport(FALSE)
  Log('GenerateReport rc=' & rc & '  wide-run=' & TIdx.WideRun & '  pages=' & TIdx.Page & '  text items=' & TIdx.Items & '  ' & (CLOCK()-StartT) & ' ms')
  TIdx.Kill()
  RETURN

!==========================================================================
! How does the IMAGE control see an EMF page?
!==========================================================================
MeasureImage PROCEDURE(STRING FileName)
W  WINDOW('measure'),AT(,,200,100),GRAY
     IMAGE(),AT(0,0,10,10),USE(?Img),HIDE
   END
  CODE
  OPEN(W)
  W{PROP:Pixels} = TRUE
  ?Img{PROP:Text} = CLIP(FileName)
  Log('IMAGE control on ' & CLIP(FileName) & ': PROP:MaxWidth=' & ?Img{PROP:MaxWidth} & ' PROP:MaxHeight=' & ?Img{PROP:MaxHeight} & ' (pixels mode)')
  W{PROP:Pixels} = FALSE
  Log('   dialog units: MaxWidth=' & ?Img{PROP:MaxWidth} & ' MaxHeight=' & ?Img{PROP:MaxHeight})
  CLOSE(W)
  RETURN

!==========================================================================
Log PROCEDURE(STRING s)
  CODE
  LOG:Buf = CLIP(s) & '<13,10>'
  ADD(LogFile, LEN(CLIP(s)) + 2)
  RETURN

!==========================================================================
! Autotest: one action per timer tick, screenshot after each visible change
!==========================================================================
TestPreview.TakeTimer PROCEDURE()
XPix   LONG,AUTO
YPix   LONG,AUTO
Rc     GROUP
L        LONG
T        LONG
Rt       LONG
B        LONG
       END
Cr     GROUP
L        LONG
T        LONG
Rt       LONG
B        LONG
       END
SI     GROUP
cbSize   ULONG
fMask    ULONG
nMin     LONG
nMax     LONG
nPage    ULONG
nPos     LONG
nTrack   LONG
       END
  CODE
  SELF.Step += 1
  CASE SELF.Step
  OF 1
    Log('  autotest: zoom=' & SELF.ZoomPct & '% pxpermil=' & SELF.PxPerMil & ' pages=' & RECORDS(SELF.Index.Pages) & ' texts=' & RECORDS(SELF.Index.Texts) & ' wide=' & SELF.Index.WideRun)
    SELF.Shot('01_fitwidth')
    tp_GetWindowRect(SELF.FeqPage{PROP:Handle}, ADDRESS(Rc))
    tp_GetClientRect(SELF.FeqPage{PROP:Handle}, ADDRESS(Cr))
    Log('  autotest: page image style WS_VSCROLL=' & CHOOSE(BAND(tp_GetWindowLongA(SELF.FeqPage{PROP:Handle}, -16), 00200000h) <> 0, 'yes', 'no') & ' WS_HSCROLL=' & CHOOSE(BAND(tp_GetWindowLongA(SELF.FeqPage{PROP:Handle}, -16), 00100000h) <> 0, 'yes', 'no') & ' win=' & (Rc.Rt-Rc.L) & 'x' & (Rc.B-Rc.T) & ' client=' & Cr.Rt & 'x' & Cr.B & ' want=' & SELF.WantHScroll & '/' & SELF.WantVScroll & ' prop=' & SELF.FeqPage{PROP:HScroll} & '/' & SELF.FeqPage{PROP:VScroll})
    Log('  autotest: shown=' & SELF.ShownFile & ' exists=' & EXISTS(SELF.ShownFile) & ' temps=' & RECORDS(SELF.Temps) & ' img text=' & SELF.FeqPage{PROP:Text} & ' max=' & SELF.FeqPage{PROP:MaxWidth} & 'x' & SELF.FeqPage{PROP:MaxHeight} & ' pos=' & SELF.FeqPage{PROP:XPos} & ',' & SELF.FeqPage{PROP:YPos} & ' size=' & SELF.FeqPage{PROP:Width} & 'x' & SELF.FeqPage{PROP:Height} & ' hidden=' & SELF.FeqPage{PROP:Hide})
    COPY(SELF.ShownFile, SELF.ShotDir & '\shown_01.emf')
    Log('  autotest: copy rc=' & ERRORCODE() & ' ' & ERROR())
  OF 2
    SELF.SearchText = U'Müller'
    POST(EVENT:Accepted, SELF.FeqSearch)
  OF 3
    Log('  autotest: search Müller -> ' & RECORDS(SELF.Hits) & ' hits, current ' & SELF.CurHit & ' page ' & SELF.CurrentPage)
    SELF.Shot('02_search_mueller')
  OF 4
    SELF.NextHit(1)
    SELF.NextHit(1)
  OF 5
    Log('  autotest: after 2x next -> hit ' & SELF.CurHit & ' page ' & SELF.CurrentPage)
    SELF.Shot('03_hit3')
    SELF.TogglePageMark(2)
    SELF.TogglePageMark(4)
    SELF.MarkAllHits()
  OF 6
    Log('  autotest: marks=' & RECORDS(SELF.Marks) & ' marked pages=' & SELF.MarkedPageList())
    SELF.Shot('04_marks_and_pagemarks')
    SELF.SetZoom(150)
  OF 7
    SELF.Shot('05_zoom150')
    ! Ctrl+wheel up posted to the page image (the control under the cursor) -> zoom step
    tp_GetWindowRect(SELF.FeqPage{PROP:Handle}, ADDRESS(Rc))
    tp_PostMessageA(SELF.FeqPage{PROP:Handle}, 020Ah, 8 + BSHIFT(120, 16), BAND(Rc.L + 100, 0FFFFh) + BSHIFT(Rc.T + 100, 16))
  OF 8
    Log('  autotest: Ctrl+wheel via hook -> zoom now ' & SELF.ZoomPct & '% (expected 175)')
    ! plain wheel down x2 posted to the search ENTRY (has focus) -> page scroll
    tp_PostMessageA(SELF.FeqSearch{PROP:Handle}, 020Ah, BSHIFT(-120, 16), BAND(Rc.L + 100, 0FFFFh) + BSHIFT(Rc.T + 100, 16))
    tp_PostMessageA(SELF.FeqSearch{PROP:Handle}, 020Ah, BSHIFT(-120, 16), BAND(Rc.L + 100, 0FFFFh) + BSHIFT(Rc.T + 100, 16))
  OF 9
    SI.cbSize = SIZE(SI)
    SI.fMask = 17h
    tp_GetScrollInfo(SELF.FeqPage{PROP:Handle}, 1, ADDRESS(SI))
    Log('  autotest: plain wheel x2 (same tick) via hook -> page ' & SELF.CurrentPage & ' vertical scroll pos ' & SI.nPos & ' max=' & SI.nMax & ' (expected 240 at the top of the page; a notch at the bottom edge flips to the next page)')
    tp_GetWindowRect(SELF.FeqPage{PROP:Handle}, ADDRESS(Rc))
    tp_PostMessageA(SELF.FeqPage{PROP:Handle}, 020Ah, BSHIFT(-120, 16), BAND(Rc.L + 100, 0FFFFh) + BSHIFT(Rc.T + 100, 16))
  OF 10
    SI.cbSize = SIZE(SI)
    SI.fMask = 17h
    tp_GetScrollInfo(SELF.FeqPage{PROP:Handle}, 1, ADDRESS(SI))
    Log('  autotest: one more notch next tick -> vertical scroll pos ' & SI.nPos & ' (expected 240) max=' & SI.nMax & ' (expected ~1852 at 175%)')
    SELF.GotoPage(3)
    SELF.SearchText = U'東京'
    POST(EVENT:Accepted, SELF.FeqSearch)
  OF 11
    Log('  autotest: search Tokyo (CJK) -> ' & RECORDS(SELF.Hits) & ' hits, current ' & SELF.CurHit & ' page ' & SELF.CurrentPage)
    SELF.Shot('06_search_cjk')
    ! simulate a left click on the first detail row name cell of the current page:
    ! display coordinates 1100 x 950 mils (row 1 name text starts at 1040/860)
    SELF.ScrollTo(0, 0)
    XPix = SELF.FeqPage{PROP:XPos} + 1100 * SELF.PxPerMil
    YPix = SELF.FeqPage{PROP:YPos} + 950 * SELF.PxPerMil
    SELF.ToggleMarkAt(XPix, YPix)
    Log('  autotest: click-mark at ' & XPix & ',' & YPix & ' -> marks=' & RECORDS(SELF.Marks))
  OF 12
    SELF.Shot('07_clickmark')
    SELF.ShowSidebar = 0
    POST(EVENT:Accepted, SELF.FeqSidebar)
  OF 13
    SELF.Shot('08_nosidebar_fit')
    SELF.SetZoom(EmfPrv:Zoom:FitPage)
  OF 14
    SELF.Shot('09_fitpage')
    POST(EVENT:CloseWindow)
  END

TestPreview.TakeWheel PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix)
SI     GROUP
cbSize   ULONG
fMask    ULONG
nMin     LONG
nMax     LONG
nPage    ULONG
nPos     LONG
nTrack   LONG
       END
rc     LONG
  CODE
  SI.cbSize = SIZE(SI)
  SI.fMask = 17h
  tp_GetScrollInfo(SELF.FeqPage{PROP:Handle}, 1, ADDRESS(SI))
  rc = PARENT.TakeWheel(Delta, Keys, XPix, YPix)
  Log('  wheel: delta=' & Delta & ' keys=' & Keys & ' at ' & XPix & ',' & YPix & ' pos before=' & SI.nPos & ' max=' & SI.nMax & ' page=' & SI.nPage & ' -> handled=' & rc & ' zoom=' & SELF.ZoomPct)
  RETURN rc

TestPreview.Shot PROCEDURE(STRING Name)
  CODE
  IF SELF.Win &= NULL THEN RETURN.
  DISPLAY
  CaptureWindow(SELF.Win{PROP:Handle}, SELF.ShotDir & '\' & CLIP(Name) & '.bmp')
  CaptureWindow(SELF.FeqPage{PROP:Handle}, SELF.ShotDir & '\' & CLIP(Name) & '.ctl.bmp')

! Capture a top-level window (frame included) to a 24-bit BMP via PrintWindow
CaptureWindow PROCEDURE(LONG hwnd, STRING pBmpName)
hdc      LONG
hdcMem   LONG
hbm      LONG
Wd       LONG
Ht       LONG
Rc       GROUP
L          LONG
T          LONG
Rt         LONG
B          LONG
         END
BIH      GROUP
biSize     ULONG
biWidth    LONG
biHeight   LONG
biPlanes   USHORT
biBitCount USHORT
biCompression ULONG
biSizeImage ULONG
biXPels    LONG
biYPels    LONG
biClrUsed  ULONG
biClrImp   ULONG
         END
BFH      GROUP
bfType     USHORT
bfSize     ULONG
bfRes1     USHORT
bfRes2     USHORT
bfOffBits  ULONG
         END
Stride   LONG
Pix      &STRING
prc      LONG
  CODE
  tp_GetWindowRect(hwnd, ADDRESS(Rc))
  Wd = Rc.Rt - Rc.L
  Ht = Rc.B - Rc.T
  IF Wd <= 0 OR Ht <= 0 OR Wd * Ht * 3 > 3900000 THEN Log('  capture skipped ' & Wd & 'x' & Ht); RETURN.
  hdc = tp_GetDC(hwnd)
  hdcMem = tp_CreateCompatibleDC(hdc)
  hbm = tp_CreateCompatibleBitmap(hdc, Wd, Ht)
  tp_SelectObject(hdcMem, hbm)
  IF INSTRING('.ctl.', pBmpName, 1, 1)
    prc = tp_PrintWindow(hwnd, hdcMem, 1)
  ELSE
    tp_ReleaseDC(hwnd, hdc)
    hdc = tp_GetDC(0)
    prc = tp_BitBlt(hdcMem, 0, 0, Wd, Ht, hdc, Rc.L, Rc.T, 00CC0020h)
  END
  Stride = INT((Wd * 3 + 3) / 4) * 4
  Pix &= NEW STRING(Stride * Ht)
  CLEAR(BIH)
  BIH.biSize = SIZE(BIH)
  BIH.biWidth = Wd
  BIH.biHeight = Ht
  BIH.biPlanes = 1
  BIH.biBitCount = 24
  tp_GetDIBits(hdcMem, hbm, 0, Ht, ADDRESS(Pix), ADDRESS(BIH), 0)
  BFH.bfType = 4D42h
  BFH.bfOffBits = 54
  BFH.bfSize = 54 + Stride * Ht
  BmpName = CLIP(pBmpName)
  REMOVE(BmpFile)
  CREATE(BmpFile)
  OPEN(BmpFile)
  BMP:Buf = BFH
  ADD(BmpFile, 14)
  BMP:Buf = BIH
  ADD(BmpFile, 40)
  BMP:Buf = Pix
  ADD(BmpFile, Stride * Ht)
  CLOSE(BmpFile)
  Log('  shot ' & Wd & 'x' & Ht & ' PrintWindow=' & prc & ' -> ' & CLIP(pBmpName))
  DISPOSE(Pix)
  tp_DeleteObject(hbm)
  tp_DeleteDC(hdcMem)
  tp_ReleaseDC(hwnd, hdc)
  RETURN

!==========================================================================
! TextIndexClass
!==========================================================================
TextIndexClass.Init PROCEDURE(STRING OutFile)
  CODE
  SELF.OutName = CLIP(OutFile)
  IdxName = SELF.OutName
  SELF.Page = 0
  SELF.Items = 0
  SELF.WideRun = 0
  REMOVE(IdxFile)
  CREATE(IdxFile)
  OPEN(IdxFile)
  IDX:Buf = '<239,187,191>'             ! UTF-8 BOM
  ADD(IdxFile, 3)
  RETURN

TextIndexClass.Kill PROCEDURE()
  CODE
  CLOSE(IdxFile)
  RETURN

TextIndexClass.Emit PROCEDURE(STRING s)
  CODE
  IDX:Buf = s & '<13,10>'
  ADD(IdxFile, LEN(s) + 2)
  RETURN

TextIndexClass.EmitItem PROCEDURE(STRING Kind, *StringFormatGrp F, USTRING Text, STRING Attr)
  CODE
  SELF.Items += 1
  SELF.Emit(Kind & ' p=' & SELF.Page & |
            ' L=' & F.Pos.Left & ' T=' & F.Pos.Top & ' R=' & F.Pos.Right & ' B=' & F.Pos.Bottom & |
            ' tx=' & F.leftText & ' ty=' & F.topText & |
            ' font=' & CLIP(F.Face) & '/' & F.Size & '/' & F.Style & ' cs=' & F.CharSet & ' color=' & F.Color & |
            ' units=' & LEN(Text) & ' text=[' & TOANSI(Text, 0FDE9h) & ']' & |
            CHOOSE(Attr = '', '', ' attr={{' & CLIP(Attr) & '}'))
  RETURN

! ---- IOutputGeneratorTarget part of IReportGenerator ----
TextIndexClass.IReportGenerator.AskProperties PROCEDURE(BYTE Force=0)
  CODE
  RETURN Level:Benign
TextIndexClass.IReportGenerator.WhoAmI PROCEDURE()
  CODE
  RETURN 'TIDX'
TextIndexClass.IReportGenerator.DisplayName PROCEDURE()
  CODE
  RETURN 'Text index'
TextIndexClass.IReportGenerator.DisplayIcon PROCEDURE()
  CODE
  RETURN ''
TextIndexClass.IReportGenerator.GetFileName PROCEDURE()
  CODE
  RETURN SELF.OutName

! ---- IReportGenerator ----
TextIndexClass.IReportGenerator.Init PROCEDURE(<ErrorClass EC>)
  CODE
TextIndexClass.IReportGenerator.OpenDocument PROCEDURE(UNSIGNED TotalPages)
  CODE
  SELF.Emit('DOC narrow-open pages=' & TotalPages)
  RETURN Level:Benign
TextIndexClass.IReportGenerator.CloseDocument PROCEDURE()
  CODE
  SELF.Emit('DOC close items=' & SELF.Items)
  RETURN Level:Benign
TextIndexClass.IReportGenerator.OpenPage PROCEDURE(STRING PageName)
  CODE
  SELF.Page += 1
  RETURN Level:Benign
TextIndexClass.IReportGenerator.ClosePage PROCEDURE()
  CODE
  RETURN Level:Benign
TextIndexClass.IReportGenerator.SetResultQueue PROCEDURE(OutputFileQueue OutputFile)
  CODE
TextIndexClass.IReportGenerator.SupportResultQueue PROCEDURE()
  CODE
  RETURN FALSE
TextIndexClass.IReportGenerator.SupportPageProcessing PROCEDURE()
  CODE
  RETURN TRUE
TextIndexClass.IReportGenerator.SupportPageParsing PROCEDURE()
  CODE
  RETURN TRUE
TextIndexClass.IReportGenerator.StartPageProcess PROCEDURE(SHORT BoxLeft,SHORT BoxTop,SHORT BoxRight,SHORT BoxBottom,STRING PageName)
  CODE
  SELF.Box.Left = BoxLeft
  SELF.Box.Top = BoxTop
  SELF.Box.Right = BoxRight
  SELF.Box.Bottom = BoxBottom
  SELF.Emit('PAGE ' & SELF.Page & ' box(1/1000in)=' & BoxLeft & ',' & BoxTop & ',' & BoxRight & ',' & BoxBottom & ' file=' & CLIP(PageName))
  RETURN Level:Benign
TextIndexClass.IReportGenerator.ProcessArc PROCEDURE(*ArcFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
TextIndexClass.IReportGenerator.ProcessBand PROCEDURE(STRING type, BYTE start)
  CODE
  SELF.Emit('BAND ' & CLIP(type) & CHOOSE(start = 1, ' start', ' end'))
TextIndexClass.IReportGenerator.ProcessCheck PROCEDURE(*CheckFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('CHECK(narrow)', pFormatGrp.Prompt, Text, pExtendControlAttr)
TextIndexClass.IReportGenerator.ProcessChord PROCEDURE(*ChordFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
TextIndexClass.IReportGenerator.ProcessEllipse PROCEDURE(*EllipseFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
TextIndexClass.IReportGenerator.ProcessImage PROCEDURE(*ImageFormatGrp pFormatGrp, STRING iName, STRING pExtendControlAttr)
  CODE
  SELF.Emit('IMAGE p=' & SELF.Page & ' L=' & pFormatGrp.Pos.Left & ' T=' & pFormatGrp.Pos.Top & ' R=' & pFormatGrp.Pos.Right & ' B=' & pFormatGrp.Pos.Bottom & ' name=' & CLIP(iName))
TextIndexClass.IReportGenerator.ProcessLine PROCEDURE(*LineFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
  SELF.Emit('LINE p=' & SELF.Page & ' L=' & pFormatGrp.Pos.Left & ' T=' & pFormatGrp.Pos.Top & ' R=' & pFormatGrp.Pos.Right & ' B=' & pFormatGrp.Pos.Bottom & ' color=' & pFormatGrp.Color)
TextIndexClass.IReportGenerator.ProcessGroup PROCEDURE(*GroupFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('GROUP(narrow)', pFormatGrp.header, Text, pExtendControlAttr)
TextIndexClass.IReportGenerator.ProcessPie PROCEDURE(SliceFormatQueue pSliceFormatQueue, *PosGrp pPosGroup, STRING pExtendControlAttr)
  CODE
TextIndexClass.IReportGenerator.ProcessPolygon PROCEDURE(PointQueue pPointQueue, *StyleGrp pStyleGrp, STRING pExtendControlAttr)
  CODE
TextIndexClass.IReportGenerator.ProcessRadio PROCEDURE(*RadioFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('RADIO(narrow)', pFormatGrp.Prompt, Text, pExtendControlAttr)
TextIndexClass.IReportGenerator.ProcessRectangle PROCEDURE(*RectFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
TextIndexClass.IReportGenerator.ProcessString PROCEDURE(*StringFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('STRING(narrow)', pFormatGrp, Text, pExtendControlAttr)
TextIndexClass.IReportGenerator.ProcessText PROCEDURE(TextFormatQueue pTextFormatQueue, STRING pExtendControlAttr)
i  LONG
  CODE
  LOOP i = 1 TO RECORDS(pTextFormatQueue)
    GET(pTextFormatQueue, i)
    SELF.EmitItem('TEXT(narrow)', pTextFormatQueue.Format, pTextFormatQueue.Text, pExtendControlAttr)
  END

! ---- IReportGeneratorW (wide) ----
TextIndexClass.IReportGeneratorW.OpenDocumentW PROCEDURE(UNSIGNED TotalPages)
  CODE
  SELF.WideRun = 1
  SELF.Emit('DOC WIDE-open pages=' & TotalPages)
  RETURN Level:Benign
TextIndexClass.IReportGeneratorW.ProcessCheckW PROCEDURE(*CheckFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('CHECK', pFormatGrp.Prompt, Text, pExtendControlAttr)
TextIndexClass.IReportGeneratorW.ProcessGroupW PROCEDURE(*GroupFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('GROUP', pFormatGrp.header, Text, pExtendControlAttr)
TextIndexClass.IReportGeneratorW.ProcessImageW PROCEDURE(*ImageFormatGrp pFormatGrp, STRING iName, STRING pExtendControlAttr)
  CODE
  SELF.Emit('IMAGEW(alpha/emoji stamp) p=' & SELF.Page & ' L=' & pFormatGrp.Pos.Left & ' T=' & pFormatGrp.Pos.Top & ' R=' & pFormatGrp.Pos.Right & ' B=' & pFormatGrp.Pos.Bottom & ' attr={{' & CLIP(pExtendControlAttr) & '}')
TextIndexClass.IReportGeneratorW.ProcessRadioW PROCEDURE(*RadioFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('RADIO', pFormatGrp.Prompt, Text, pExtendControlAttr)
TextIndexClass.IReportGeneratorW.ProcessStringW PROCEDURE(*StringFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.EmitItem('STRING', pFormatGrp, Text, pExtendControlAttr)
TextIndexClass.IReportGeneratorW.ProcessTextW PROCEDURE(TextFormatWQueue pTextFormatQueue, STRING pExtendControlAttr)
i  LONG
  CODE
  LOOP i = 1 TO RECORDS(pTextFormatQueue)
    GET(pTextFormatQueue, i)
    SELF.EmitItem('TEXT', pTextFormatQueue.Format, pTextFormatQueue.Text, pExtendControlAttr)
  END
