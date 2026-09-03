!==============================================================================
! EmfPreview.clw - EMF / Unicode report previewer for Clarion 12 Unicode
! See EmfPreview.inc for the class overview.
!==============================================================================
  MEMBER
  MAP
    EmfPrv_WndProc(UNSIGNED hWnd, UNSIGNED wMsg, UNSIGNED wParam, LONG lParam),LONG,PASCAL
    EmfPrv_RegFind(LONG hWnd),BYTE
    EmfPrv_LoWord(LONG Value),LONG
    EmfPrv_HiWord(LONG Value),LONG
    EmfPrv_Dir(STRING FileName),STRING
    MODULE('EmfPrvAPI')
      EmfPrv_GetEnhMetaFileW(LONG),LONG,PASCAL,NAME('GetEnhMetaFileW')
      EmfPrv_GetEnhMetaFileHeader(LONG,ULONG,LONG),ULONG,PASCAL,NAME('GetEnhMetaFileHeader')
      EmfPrv_CreateEnhMetaFileW(LONG,LONG,LONG,LONG),LONG,PASCAL,NAME('CreateEnhMetaFileW')
      EmfPrv_PlayEnhMetaFile(LONG,LONG,LONG),LONG,PASCAL,PROC,NAME('PlayEnhMetaFile')
      EmfPrv_CloseEnhMetaFile(LONG),LONG,PASCAL,NAME('CloseEnhMetaFile')
      EmfPrv_DeleteEnhMetaFile(LONG),LONG,PASCAL,PROC,NAME('DeleteEnhMetaFile')
      EmfPrv_SetWinMetaFileBits(ULONG,LONG,LONG,LONG),LONG,PASCAL,NAME('SetWinMetaFileBits')
      EmfPrv_SetROP2(LONG,LONG),LONG,PASCAL,PROC,NAME('SetROP2')
      EmfPrv_Rectangle(LONG,LONG,LONG,LONG,LONG),LONG,PASCAL,PROC,NAME('Rectangle')
      EmfPrv_CreateSolidBrush(LONG),LONG,PASCAL,NAME('CreateSolidBrush')
      EmfPrv_CreatePen(LONG,LONG,LONG),LONG,PASCAL,NAME('CreatePen')
      EmfPrv_SelectObject(LONG,LONG),LONG,PASCAL,PROC,NAME('SelectObject')
      EmfPrv_DeleteObject(LONG),LONG,PASCAL,PROC,NAME('DeleteObject')
      EmfPrv_GetStockObject(LONG),LONG,PASCAL,NAME('GetStockObject')
      EmfPrv_GetDC(LONG),LONG,PASCAL,NAME('GetDC')
      EmfPrv_ReleaseDC(LONG,LONG),LONG,PASCAL,PROC,NAME('ReleaseDC')
      EmfPrv_GetDeviceCaps(LONG,LONG),LONG,PASCAL,NAME('GetDeviceCaps')
      EmfPrv_CreateFontW(LONG,LONG,LONG,LONG,LONG,ULONG,ULONG,ULONG,ULONG,ULONG,ULONG,ULONG,ULONG,LONG),LONG,PASCAL,NAME('CreateFontW')
      EmfPrv_GetTextExtentPoint32W(LONG,LONG,LONG,LONG),LONG,PASCAL,PROC,NAME('GetTextExtentPoint32W')
      EmfPrv_GetScrollInfo(LONG,LONG,LONG),LONG,PASCAL,PROC,NAME('GetScrollInfo')
      EmfPrv_SendMessage(LONG,ULONG,LONG,LONG),LONG,PASCAL,PROC,NAME('SendMessageA')
      EmfPrv_CallWindowProc(LONG,UNSIGNED,UNSIGNED,UNSIGNED,LONG),LONG,PASCAL,NAME('CallWindowProcA')
      EmfPrv_GetSystemMetrics(LONG),LONG,PASCAL,NAME('GetSystemMetrics')
      EmfPrv_ScreenToClient(LONG,LONG),LONG,PASCAL,PROC,NAME('ScreenToClient')
      EmfPrv_CreateFileW(LONG,ULONG,ULONG,LONG,ULONG,ULONG,LONG),LONG,PASCAL,NAME('CreateFileW')
      EmfPrv_GetFileSize(LONG,LONG),ULONG,PASCAL,NAME('GetFileSize')
      EmfPrv_ReadFile(LONG,LONG,ULONG,LONG,LONG),LONG,PASCAL,PROC,NAME('ReadFile')
      EmfPrv_CloseHandle(LONG),LONG,PASCAL,PROC,NAME('CloseHandle')
      EmfPrv_GetCurrentThreadId(),ULONG,PASCAL,NAME('GetCurrentThreadId')
    END
  END
  INCLUDE('EmfPreview.INC'),ONCE
  INCLUDE('EQUATES.CLW'),ONCE
  INCLUDE('KEYCODES.CLW'),ONCE
  INCLUDE('CWSYNCHM.INC'),ONCE

! Win32 constants
WM_HSCROLL            EQUATE(0114H)
WM_VSCROLL            EQUATE(0115H)
WM_MOUSEWHEEL         EQUATE(020AH)
SB_HORZ               EQUATE(0)
SB_VERT               EQUATE(1)
SB_THUMBPOSITION      EQUATE(4)
SIF_ALL               EQUATE(17H)
SM_CXVSCROLL          EQUATE(2)
SM_CYHSCROLL          EQUATE(3)
R2_MASKPEN            EQUATE(9)
R2_COPYPEN            EQUATE(13)
NULL_BRUSH            EQUATE(5)
NULL_PEN              EQUATE(8)
SYSTEM_FONT           EQUATE(13)
DC_HORZSIZE           EQUATE(4)
DC_VERTSIZE           EQUATE(6)
DC_HORZRES            EQUATE(8)
DC_VERTRES            EQUATE(10)
MK_CONTROL            EQUATE(8)
EmfPrv:ThumbBase      EQUATE(1000)        ! first FEQ of the dynamically created thumbnail controls
EmfPrv:DefaultDpi     EQUATE(96)          ! the IMAGE control shows a metafile frame at 96 dpi
EmfPrv:MaxHits        EQUATE(5000)

ScrollInfoGrp         GROUP,TYPE
cbSize                  ULONG
fMask                   ULONG
nMin                    LONG
nMax                    LONG
nPage                   ULONG
nPos                    LONG
nTrackPos               LONG
                      END

EnhHeaderGrp          GROUP,TYPE          ! ENHMETAHEADER (the part we need)
RecType                 ULONG
RecSize                 ULONG
BoundsL                 LONG
BoundsT                 LONG
BoundsR                 LONG
BoundsB                 LONG
FrameL                  LONG
FrameT                  LONG
FrameR                  LONG
FrameB                  LONG
Signature               ULONG
Version                 ULONG
NBytes                  ULONG
NRecords                ULONG
NHandles                USHORT
Reserved                USHORT
DescSize                ULONG
DescOff                 ULONG
PalEntries              ULONG
DevPxX                  LONG
DevPxY                  LONG
DevMMX                  LONG
DevMMY                  LONG
cbPixelFormat           ULONG
offPixelFormat          ULONG
bOpenGL                 ULONG
MicroX                  LONG
MicroY                  LONG
                      END

RectGrp               GROUP,TYPE
L                       LONG
T                       LONG
R                       LONG
B                       LONG
                      END

! registry of open preview windows (frame + client hwnd -> previewer), used by
! the window subclass to route WM_MOUSEWHEEL.  Plain module data guarded by a
! critical section - THREADed module data crashes the C12U runtime at startup.
EmfPrvRegQ            QUEUE
Hwnd                    LONG
ClientHwnd              LONG
OldProc                 LONG
OldClientProc           LONG
Prv                     &EmfPreviewClass
                      END
EmfPrvRegCS           &ICriticalSection

!==============================================================================
! helpers
!==============================================================================
EmfPrv_LoWord PROCEDURE(LONG Value)
  CODE
  RETURN BAND(Value, 0FFFFH)

EmfPrv_HiWord PROCEDURE(LONG Value)
H  LONG,AUTO
  CODE
  H = BAND(BSHIFT(Value, -16), 0FFFFH)
  IF H >= 8000H THEN H -= 10000H.
  RETURN H

EmfPrv_Dir PROCEDURE(STRING FileName)
i  LONG,AUTO
  CODE
  LOOP i = LEN(CLIP(FileName)) TO 1 BY -1
    IF FileName[i] = '\' OR FileName[i] = '/' THEN RETURN FileName[1 : i].
  END
  RETURN ''

! registry lookup by frame or client hwnd; fills the EmfPrvRegQ buffer
EmfPrv_RegFind PROCEDURE(LONG hWnd)
i   LONG,AUTO
  CODE
  IF EmfPrvRegCS &= NULL THEN RETURN FALSE.
  EmfPrvRegCS.Wait()
  LOOP i = 1 TO RECORDS(EmfPrvRegQ)
    GET(EmfPrvRegQ, i)
    IF EmfPrvRegQ.Hwnd = hWnd OR EmfPrvRegQ.ClientHwnd = hWnd
      EmfPrvRegCS.Release()
      RETURN TRUE
    END
  END
  EmfPrvRegCS.Release()
  CLEAR(EmfPrvRegQ)
  RETURN FALSE

! window subclass: mouse wheel -> the previewer that owns the window
EmfPrv_WndProc PROCEDURE(UNSIGNED hWnd, UNSIGNED wMsg, UNSIGNED wParam, LONG lParam)
Pt   GROUP
X      LONG
Y      LONG
     END
Old  LONG,AUTO
Prv  &EmfPreviewClass
Cli  LONG,AUTO
  CODE
  IF NOT EmfPrv_RegFind(hWnd) THEN RETURN 0.
  Prv &= EmfPrvRegQ.Prv
  Cli = EmfPrvRegQ.ClientHwnd
  IF hWnd = Cli
    Old = EmfPrvRegQ.OldClientProc
  ELSE
    Old = EmfPrvRegQ.OldProc
  END
  IF wMsg = WM_MOUSEWHEEL AND NOT Prv &= NULL
    Pt.X = EmfPrv_LoWord(lParam)
    IF Pt.X >= 8000H THEN Pt.X -= 10000H.
    Pt.Y = EmfPrv_HiWord(lParam)
    EmfPrv_ScreenToClient(Cli, ADDRESS(Pt))
    IF Prv.TakeWheel(EmfPrv_HiWord(wParam), EmfPrv_LoWord(wParam), Pt.X, Pt.Y)
      RETURN 0
    END
  END
  IF Old = 0 THEN RETURN 0.
  RETURN EmfPrv_CallWindowProc(Old, hWnd, wMsg, wParam, lParam)

!==============================================================================
! EmfTextIndexClass
!==============================================================================
EmfTextIndexClass.CONSTRUCT PROCEDURE()
  CODE
  SELF.Pages &= NEW EmfPageQueue
  SELF.Texts &= NEW EmfTextQueue

EmfTextIndexClass.DESTRUCT PROCEDURE()
  CODE
  SELF.Kill()

EmfTextIndexClass.Init PROCEDURE(<ErrorClass EC>)
  CODE
  IF NOT OMITTED(EC) THEN SELF.Errors &= EC.
  SELF.ClearIndex()

EmfTextIndexClass.Kill PROCEDURE()
  CODE
  IF NOT SELF.Pages &= NULL
    FREE(SELF.Pages)
    DISPOSE(SELF.Pages)
  END
  IF NOT SELF.Texts &= NULL
    FREE(SELF.Texts)
    DISPOSE(SELF.Texts)
  END

EmfTextIndexClass.ClearIndex PROCEDURE()
  CODE
  FREE(SELF.Pages)
  FREE(SELF.Texts)
  SELF.CurPage = 0
  SELF.Seq = 0
  SELF.WideRun = 0

! Run the shipped metafile parser over every page and collect the text.
EmfTextIndexClass.Build PROCEDURE(PrintPreviewFileQueue Q)
Parser   WMFDocumentParser
i        LONG,AUTO
rc       BYTE
  CODE
  SELF.ClearIndex()
  ! register the pages first so the previewer works even when parsing fails
  LOOP i = 1 TO RECORDS(Q)
    GET(Q, i)
    CLEAR(SELF.Pages)
    SELF.Pages.PageNo = i
    SELF.Pages.FileName = Q.Filename
    SELF.ProbePage(Q.Filename, SELF.Pages)
    ADD(SELF.Pages)
  END
  IF SELF.Errors &= NULL
    Parser.Init(Q, SELF.IReportGenerator)
  ELSE
    Parser.Init(Q, SELF.IReportGenerator, SELF.Errors)
  END
  Parser.SetWideGenerator(SELF.IReportGeneratorW)
  rc = Parser.GenerateReport(FALSE)
  RETURN rc

! Read the metafile header: frame size and the physical print offset that the
! shipped parser adds to every EMF coordinate (GDI playback does not add it).
EmfTextIndexClass.ProbePage PROCEDURE(STRING FileName, *EmfPageQueue Pg)
Hdr      LIKE(EnhHeaderGrp)
UPath    USTRING(FILE:MaxFileName+1)
hemf     LONG,AUTO
DpiX     REAL,AUTO
DpiY     REAL,AUTO
DpiR     REAL,AUTO
OffPx    LONG,AUTO
  CODE
  Pg.IsEMF = 0
  Pg.OffX = 0
  Pg.OffY = 0
  IF Pg.FrameW = 0 THEN Pg.FrameW = 8500.
  IF Pg.FrameH = 0 THEN Pg.FrameH = 11000.
  UPath = CLIP(FileName)
  hemf = EmfPrv_GetEnhMetaFileW(ADDRESS(UPath))
  IF hemf = 0 THEN RETURN.
  CLEAR(Hdr)
  IF EmfPrv_GetEnhMetaFileHeader(hemf, SIZE(Hdr), ADDRESS(Hdr)) = 0 OR Hdr.Signature <> 464D4520H
    EmfPrv_DeleteEnhMetaFile(hemf)
    RETURN
  END
  EmfPrv_DeleteEnhMetaFile(hemf)
  Pg.IsEMF = 1
  Pg.FrameW = (Hdr.FrameR - Hdr.FrameL) * 1000 / 2540
  Pg.FrameH = (Hdr.FrameB - Hdr.FrameT) * 1000 / 2540
  IF Hdr.DevPxX > 0 AND Hdr.DevMMX > 0 AND Hdr.DevPxY > 0 AND Hdr.DevMMY > 0
    ! same dpi snapping as WMFParser.ProcessHeader
    DpiX = Hdr.DevPxX * 25.4 / Hdr.DevMMX
    DpiR = ROUND(DpiX / 4, 1) * 4
    IF ABS(DpiR - DpiX) <= DpiX * 0.02 THEN DpiX = DpiR.
    DpiY = Hdr.DevPxY * 25.4 / Hdr.DevMMY
    DpiR = ROUND(DpiY / 4, 1) * 4
    IF ABS(DpiR - DpiY) <= DpiY * 0.02 THEN DpiY = DpiR.
    OffPx = ROUND((Hdr.FrameR * DpiX / 2540 - Hdr.DevPxX) / 2, 1)
    IF OffPx < 0 THEN OffPx = 0.
    Pg.OffX = OffPx * 1000 / DpiX
    OffPx = ROUND((Hdr.FrameB * DpiY / 2540 - Hdr.DevPxY) / 2, 1)
    IF OffPx < 0 THEN OffPx = 0.
    Pg.OffY = OffPx * 1000 / DpiY
  END

EmfTextIndexClass.AddText PROCEDURE(*StringFormatGrp F, USTRING Text)
i    LONG,AUTO
Blank BYTE
  CODE
  IF LEN(Text) = 0 THEN RETURN.
  Blank = TRUE
  LOOP i = 1 TO LEN(Text)
    IF Text[i] <> U' ' THEN Blank = FALSE; BREAK.
  END
  IF Blank THEN RETURN.
  CLEAR(SELF.Texts)
  SELF.Seq += 1
  SELF.Texts.PageNo = SELF.CurPage
  SELF.Texts.Seq = SELF.Seq
  SELF.Texts.Left = F.Pos.Left - SELF.CurBoxL - SELF.CurOffX
  SELF.Texts.Top = F.Pos.Top - SELF.CurBoxT - SELF.CurOffY
  SELF.Texts.Right = F.Pos.Right - SELF.CurBoxL - SELF.CurOffX
  SELF.Texts.Bottom = F.Pos.Bottom - SELF.CurBoxT - SELF.CurOffY
  SELF.Texts.TextX = F.leftText - SELF.CurBoxL - SELF.CurOffX
  IF SELF.Texts.TextX < SELF.Texts.Left OR SELF.Texts.TextX > SELF.Texts.Right THEN SELF.Texts.TextX = SELF.Texts.Left.
  SELF.Texts.TextW = 0
  SELF.Texts.Face = F.Face
  SELF.Texts.Size = F.Size
  SELF.Texts.Style = F.Style
  SELF.Texts.Text = Text
  SELF.Texts.Upper = UPPER(Text)
  ADD(SELF.Texts)

! ---- IOutputGeneratorTarget --------------------------------------------------
EmfTextIndexClass.IReportGenerator.AskProperties PROCEDURE(BYTE Force=0)
  CODE
  RETURN Level:Benign
EmfTextIndexClass.IReportGenerator.WhoAmI PROCEDURE()
  CODE
  RETURN 'EMFIDX'
EmfTextIndexClass.IReportGenerator.DisplayName PROCEDURE()
  CODE
  RETURN 'Text index'
EmfTextIndexClass.IReportGenerator.DisplayIcon PROCEDURE()
  CODE
  RETURN ''
EmfTextIndexClass.IReportGenerator.GetFileName PROCEDURE()
  CODE
  RETURN ''
! ---- IReportGenerator ------------------------------------------------------------
EmfTextIndexClass.IReportGenerator.Init PROCEDURE(<ErrorClass EC>)
  CODE
EmfTextIndexClass.IReportGenerator.OpenDocument PROCEDURE(UNSIGNED TotalPages)
  CODE
  SELF.CurPage = 0
  RETURN Level:Benign
EmfTextIndexClass.IReportGenerator.CloseDocument PROCEDURE()
  CODE
  RETURN Level:Benign
EmfTextIndexClass.IReportGenerator.OpenPage PROCEDURE(STRING PageName)
  CODE
  SELF.CurPage += 1
  RETURN Level:Benign
EmfTextIndexClass.IReportGenerator.ClosePage PROCEDURE()
  CODE
  RETURN Level:Benign
EmfTextIndexClass.IReportGenerator.SetResultQueue PROCEDURE(OutputFileQueue OutputFile)
  CODE
EmfTextIndexClass.IReportGenerator.SupportResultQueue PROCEDURE()
  CODE
  RETURN FALSE
EmfTextIndexClass.IReportGenerator.SupportPageProcessing PROCEDURE()
  CODE
  RETURN TRUE
EmfTextIndexClass.IReportGenerator.SupportPageParsing PROCEDURE()
  CODE
  RETURN TRUE
EmfTextIndexClass.IReportGenerator.StartPageProcess PROCEDURE(SHORT BoxLeft,SHORT BoxTop,SHORT BoxRight,SHORT BoxBottom,STRING PageName)
  CODE
  SELF.Pages.PageNo = SELF.CurPage
  GET(SELF.Pages, SELF.Pages.PageNo)
  IF ERRORCODE()
    CLEAR(SELF.Pages)
    SELF.Pages.PageNo = SELF.CurPage
    SELF.Pages.FileName = PageName
    SELF.ProbePage(PageName, SELF.Pages)
    ADD(SELF.Pages, SELF.Pages.PageNo)
  END
  SELF.Pages.BoxL = BoxLeft
  SELF.Pages.BoxT = BoxTop
  IF NOT SELF.Pages.IsEMF
    SELF.Pages.FrameW = BoxRight - BoxLeft
    SELF.Pages.FrameH = BoxBottom - BoxTop
  END
  PUT(SELF.Pages)
  SELF.CurBoxL = BoxLeft
  SELF.CurBoxT = BoxTop
  SELF.CurOffX = SELF.Pages.OffX
  SELF.CurOffY = SELF.Pages.OffY
  RETURN Level:Benign
EmfTextIndexClass.IReportGenerator.ProcessArc PROCEDURE(*ArcFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessBand PROCEDURE(STRING type, BYTE start)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessCheck PROCEDURE(*CheckFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp.Prompt, Text)
EmfTextIndexClass.IReportGenerator.ProcessChord PROCEDURE(*ChordFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessEllipse PROCEDURE(*EllipseFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessImage PROCEDURE(*ImageFormatGrp pFormatGrp, STRING iName, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessLine PROCEDURE(*LineFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessGroup PROCEDURE(*GroupFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp.header, Text)
EmfTextIndexClass.IReportGenerator.ProcessPie PROCEDURE(SliceFormatQueue pSliceFormatQueue, *PosGrp pPosGroup, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessPolygon PROCEDURE(PointQueue pPointQueue, *StyleGrp pStyleGrp, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessRadio PROCEDURE(*RadioFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp.Prompt, Text)
EmfTextIndexClass.IReportGenerator.ProcessRectangle PROCEDURE(*RectFormatGrp pFormatGrp, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGenerator.ProcessString PROCEDURE(*StringFormatGrp pFormatGrp, STRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp, Text)
EmfTextIndexClass.IReportGenerator.ProcessText PROCEDURE(TextFormatQueue pTextFormatQueue, STRING pExtendControlAttr)
i  LONG,AUTO
  CODE
  LOOP i = 1 TO RECORDS(pTextFormatQueue)
    GET(pTextFormatQueue, i)
    SELF.AddText(pTextFormatQueue.Format, pTextFormatQueue.Text)
  END
! ---- IReportGeneratorW (the wide lane of a REPORT,UNICODE) -----------------------
EmfTextIndexClass.IReportGeneratorW.OpenDocumentW PROCEDURE(UNSIGNED TotalPages)
  CODE
  SELF.CurPage = 0
  SELF.WideRun = 1
  RETURN Level:Benign
EmfTextIndexClass.IReportGeneratorW.ProcessCheckW PROCEDURE(*CheckFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp.Prompt, Text)
EmfTextIndexClass.IReportGeneratorW.ProcessGroupW PROCEDURE(*GroupFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp.header, Text)
EmfTextIndexClass.IReportGeneratorW.ProcessImageW PROCEDURE(*ImageFormatGrp pFormatGrp, STRING iName, STRING pExtendControlAttr)
  CODE
EmfTextIndexClass.IReportGeneratorW.ProcessRadioW PROCEDURE(*RadioFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp.Prompt, Text)
EmfTextIndexClass.IReportGeneratorW.ProcessStringW PROCEDURE(*StringFormatGrp pFormatGrp, USTRING Text, STRING pExtendControlAttr)
  CODE
  SELF.AddText(pFormatGrp, Text)
EmfTextIndexClass.IReportGeneratorW.ProcessTextW PROCEDURE(TextFormatWQueue pTextFormatQueue, STRING pExtendControlAttr)
i  LONG,AUTO
  CODE
  LOOP i = 1 TO RECORDS(pTextFormatQueue)
    GET(pTextFormatQueue, i)
    SELF.AddText(pTextFormatQueue.Format, pTextFormatQueue.Text)
  END

!==============================================================================
! EmfPreviewClass
!==============================================================================
EmfPreviewClass.CONSTRUCT PROCEDURE()
  CODE
  SELF.Index &= NEW EmfTextIndexClass
  SELF.Marks &= NEW EmfMarkQueue
  SELF.Hits &= NEW EmfMarkQueue
  SELF.Temps &= NEW EmfTempQueue
  SELF.Title = 'Report Preview'

EmfPreviewClass.DESTRUCT PROCEDURE()
  CODE
  IF NOT SELF.Index &= NULL
    SELF.Index.Kill()
    DISPOSE(SELF.Index)
  END
  IF NOT SELF.Marks &= NULL THEN DISPOSE(SELF.Marks).
  IF NOT SELF.Hits &= NULL THEN DISPOSE(SELF.Hits).
  IF NOT SELF.Temps &= NULL THEN DISPOSE(SELF.Temps).

EmfPreviewClass.SetINIManager PROCEDURE(*INIClass INI)
  CODE
  SELF.INI &= INI

EmfPreviewClass.Kill PROCEDURE()
  CODE
  SELF.DeleteTemps()
  IF NOT SELF.Index &= NULL THEN SELF.Index.ClearIndex().
  IF NOT SELF.Marks &= NULL THEN FREE(SELF.Marks).
  IF NOT SELF.Hits &= NULL THEN FREE(SELF.Hits).
  RETURN PARENT.Kill()

!------------------------------------------------------------------------------
! Display - the preview window.  Returns TRUE when the user chose to print.
!------------------------------------------------------------------------------
EmfPreviewClass.Display PROCEDURE(SHORT InitZoomFactor, LONG InitCurrentPage, USHORT InitPagesAcross, USHORT InitPagesDown)
Pages   LONG,AUTO

PreviewWindow WINDOW('Report Preview'),AT(,,700,440),CENTER,ICON(ICON:Print),GRAY,SYSTEM,MAX,RESIZE, |
        STATUS(-1,150,120,160),FONT('Segoe UI',9,,FONT:regular,CHARSET:DEFAULT), |
        ALRT(PgUpKey),ALRT(PgDnKey),ALRT(CtrlPgUp),ALRT(CtrlPgDn),ALRT(CtrlHome),ALRT(CtrlEnd), |
        ALRT(F3Key),ALRT(ShiftF3),ALRT(CtrlF),ALRT(CtrlP),ALRT(EscKey),ALRT(CtrlPlus),ALRT(CtrlMinus),ALRT(CtrlM)
      TOOLBAR,AT(,,,38),USE(?Toolbar)
        BUTTON('&Print'),AT(2,2,40,14),USE(?BtnPrint),ICON(ICON:Print),LEFT,TIP('Print the report  (Ctrl+P)')
        BUTTON('Print mar&ked'),AT(44,2,54,14),USE(?BtnPrintMarked),ICON(ICON:Print1),LEFT,TIP('Print only the marked pages')
        BUTTON,AT(100,2,14,14),USE(?BtnSaveAs),ICON(ICON:Save),TIP('Save the report as ...')
        BUTTON,AT(116,2,14,14),USE(?BtnClose),ICON(ICON:NoPrint),TIP('Close without printing  (Esc)')
        BUTTON,AT(140,2,12,14),USE(?BtnFirst),ICON(ICON:VCRtop),TIP('First page  (Ctrl+Home)'),FLAT
        BUTTON,AT(154,2,12,14),USE(?BtnPrev),ICON(ICON:VCRrewind),TIP('Previous page  (Ctrl+PgUp)'),FLAT
        SPIN(@n5),AT(168,3,28,12),USE(SELF.CurrentPage,,?PageSpin),RANGE(1,99999),STEP(1),RIGHT,TIP('Current page')
        STRING(@s24),AT(198,4,40,10),USE(SELF.PageOfText,,?PageOf),TRN
        BUTTON,AT(240,2,12,14),USE(?BtnNext),ICON(ICON:VCRfastforward),TIP('Next page  (Ctrl+PgDn)'),FLAT
        BUTTON,AT(254,2,12,14),USE(?BtnLast),ICON(ICON:VCRbottom),TIP('Last page  (Ctrl+End)'),FLAT
        BUTTON('-'),AT(276,2,12,14),USE(?BtnZoomOut),TIP('Zoom out  (Ctrl+-, Ctrl+wheel)'),FLAT
        COMBO(@s16),AT(290,3,50,12),USE(SELF.ZoomText,,?ZoomCombo),DROP(12),TIP('Zoom'), |
              FROM('Fit width|Fit page|50%|75%|100%|125%|150%|200%|300%|400%')
        BUTTON('+'),AT(342,2,12,14),USE(?BtnZoomIn),TIP('Zoom in  (Ctrl++, Ctrl+wheel)'),FLAT
        CHECK('&Sidebar'),AT(364,4,40,10),USE(SELF.ShowSidebar,,?ChkSidebar),TIP('Show the page thumbnails')
        PROMPT('&Find:'),AT(2,22,20,10),USE(?FindPrompt)
        ENTRY(@s120),AT(24,20,90,12),USE(SELF.SearchText,,?SearchEntry),TIP('Text to find - Enter searches  (Ctrl+F)')
        BUTTON('Find'),AT(116,19,26,14),USE(?BtnFind),TIP('Find the text')
        BUTTON,AT(144,19,12,14),USE(?BtnFindPrev),ICON(ICON:VCRback),TIP('Previous hit  (Shift+F3)'),FLAT
        BUTTON,AT(158,19,12,14),USE(?BtnFindNext),ICON(ICON:VCRplay),TIP('Next hit  (F3)'),FLAT
        STRING(@s40),AT(172,22,70,10),USE(SELF.HitText,,?HitText),TRN
        CHECK('&Aa'),AT(244,22,24,10),USE(SELF.SearchMatchCase,,?ChkCase),TIP('Match case')
        BUTTON('Mark &hits'),AT(276,19,40,14),USE(?BtnMarkAll),TIP('Turn every hit into a text mark')
        BUTTON('Clear mar&ks'),AT(318,19,44,14),USE(?BtnClearMarks),TIP('Remove all text marks')
        BUTTON('&Mark page'),AT(364,19,44,14),USE(?BtnMarkPage),TIP('Mark or unmark the current page  (Ctrl+M)')
      END
      BOX,AT(0,0,10,10),USE(?SideBack),FILL(0F5F1EEH),COLOR(0F5F1EEH)
      BUTTON('^'),AT(0,0,20,10),USE(?ThumbUp),FLAT,TIP('Previous pages')
      BUTTON('v'),AT(0,0,20,10),USE(?ThumbDown),FLAT,TIP('Next pages')
      BOX,AT(0,0,10,10),USE(?Paper),COLOR(0808080H)
      IMAGE,AT(0,0,10,10),USE(?PageImg),HVSCROLL
    END

  CODE
  IF SELF.ClassicMode THEN RETURN PARENT.Display(InitZoomFactor, InitCurrentPage, InitPagesAcross, InitPagesDown).
  SELF.PrintOK = FALSE
  Pages = RECORDS(SELF.ImageQueue)
  IF Pages = 0 THEN RETURN FALSE.

  SELF.CurrentPage = InitCurrentPage
  IF SELF.CurrentPage < 1 THEN SELF.CurrentPage = 1.
  IF SELF.CurrentPage > Pages THEN SELF.CurrentPage = Pages.
  SELF.FirstPage = SELF.CurrentPage
  SELF.PagesAcross = 1
  SELF.PagesDown = 1
  SELF.SetDefaultPages()

  CASE InitZoomFactor
  OF 0
    SELF.ZoomMode = SELF.InitialZoom
  OF NoZoom                                     ! ABC 'tile pages' -> whole page
    SELF.ZoomMode = EmfPrv:Zoom:FitPage
  ELSE
    SELF.ZoomMode = InitZoomFactor
  END
  IF NOT SELF.INI &= NULL
    SELF.ZoomMode = SELF.INI.TryFetch('_EmfPreview_', 'Zoom')
    IF SELF.ZoomMode = 0 THEN SELF.ZoomMode = SELF.InitialZoom.
    IF SELF.INI.TryFetch('_EmfPreview_', 'Sidebar') <> ''
      SELF.ShowSidebar = SELF.INI.TryFetch('_EmfPreview_', 'Sidebar')
    END
  END

  ! build the text index (every page, every text item)
  SELF.Index.Init(SELF.Errors)
  SELF.Index.Build(SELF.ImageQueue)
  FREE(SELF.Hits)
  FREE(SELF.Marks)
  SELF.CurHit = 0
  SELF.ThumbFirst = 1
  SELF.ThumbCreated = 0
  SELF.ShownFile = ''

  IF SELF.RTLLayout THEN SETLAYOUT(PreviewWindow, 1).
  OPEN(PreviewWindow)
  SELF.Win &= PreviewWindow
  SELF.Win{PROP:Text} = SELF.Title
  IF NOT SELF.INI &= NULL
    SELF.INI.Fetch('_EmfPreview_', PreviewWindow)
  ELSIF SELF.Maximize
    SELF.Win{PROP:Maximize} = TRUE
  END
  IF NOT SELF.Translator &= NULL THEN SELF.Translator.TranslateWindow(PreviewWindow).

  SELF.FeqToolbar     = ?Toolbar
  SELF.FeqPrint       = ?BtnPrint
  SELF.FeqPrintMarked = ?BtnPrintMarked
  SELF.FeqSaveAs      = ?BtnSaveAs
  SELF.FeqClose       = ?BtnClose
  SELF.FeqFirst       = ?BtnFirst
  SELF.FeqPrev        = ?BtnPrev
  SELF.FeqPageSpin    = ?PageSpin
  SELF.FeqPageOf      = ?PageOf
  SELF.FeqNext        = ?BtnNext
  SELF.FeqLast        = ?BtnLast
  SELF.FeqZoomOut     = ?BtnZoomOut
  SELF.FeqZoomCombo   = ?ZoomCombo
  SELF.FeqZoomIn      = ?BtnZoomIn
  SELF.FeqFindPrompt  = ?FindPrompt
  SELF.FeqSearch      = ?SearchEntry
  SELF.FeqFind        = ?BtnFind
  SELF.FeqFindPrev    = ?BtnFindPrev
  SELF.FeqFindNext    = ?BtnFindNext
  SELF.FeqHitText     = ?HitText
  SELF.FeqCase        = ?ChkCase
  SELF.FeqMarkAll     = ?BtnMarkAll
  SELF.FeqClearMarks  = ?BtnClearMarks
  SELF.FeqMarkPage    = ?BtnMarkPage
  SELF.FeqSidebar     = ?ChkSidebar
  SELF.FeqSideBack    = ?SideBack
  SELF.FeqThumbUp     = ?ThumbUp
  SELF.FeqThumbDown   = ?ThumbDown
  SELF.FeqPaper       = ?Paper
  SELF.FeqPage        = ?PageImg

  SELF.Ask()

  ! un-subclass and forget the window
  IF EmfPrv_RegFind(SELF.Win{PROP:Handle})
    IF EmfPrvRegQ.OldProc THEN SELF.Win{PROP:WndProc} = EmfPrvRegQ.OldProc.
    IF EmfPrvRegQ.OldClientProc THEN SELF.Win{PROP:ClientWndProc} = EmfPrvRegQ.OldClientProc.
    EmfPrvRegCS.Wait()
    DELETE(EmfPrvRegQ)
    EmfPrvRegCS.Release()
  END
  CLOSE(PreviewWindow)
  SELF.Win &= NULL

  IF SELF.PrintOK
    SELF.PrepareMarkedPrint()
    SELF.SyncImageQueue()
  END
  SELF.DeleteTemps()
  RETURN SELF.PrintOK

!------------------------------------------------------------------------------
EmfPreviewClass.Open PROCEDURE()
  CODE
  IF SELF.ClassicMode THEN PARENT.Open(); RETURN.
  SELF.Win{PROP:Pixels} = TRUE
  SELF.Win{PROP:Color} = SELF.PaperShadow
  SELF.FeqSideBack{PROP:Fill} = SELF.SidebarColor
  SELF.FeqSideBack{PROP:Color} = SELF.SidebarColor
  SELF.FeqPage{PROP:Alrt, 250} = MouseLeft
  SELF.FeqPage{PROP:Alrt, 251} = MouseRight
  SELF.FeqPage{PROP:Alrt, 252} = MouseLeft2
  SELF.FeqPage{PROP:Cursor} = CURSOR:Arrow
  SELF.FeqPageSpin{PROP:RangeHigh} = RECORDS(SELF.ImageQueue)
  IF RECORDS(SELF.ImageQueue) = 1 THEN DISABLE(SELF.FeqPageSpin).
  IF SELF.TargetSelector &= NULL OR SELF.TargetSelector.Items(TRUE) = 0
    DISABLE(SELF.FeqSaveAs)
  END
  ! reference device scale: metafile logical pixels per 1/1000 inch at 100%
  SELF.RefPxPerMilX = 0.096
  SELF.RefPxPerMilY = 0.096
  ! mouse wheel: subclass frame + client window, remember who owns them
  IF EmfPrvRegCS &= NULL THEN EmfPrvRegCS &= NewCriticalSection().
  EmfPrvRegCS.Wait()
  CLEAR(EmfPrvRegQ)
  EmfPrvRegQ.Hwnd = SELF.Win{PROP:Handle}
  EmfPrvRegQ.ClientHwnd = SELF.Win{PROP:ClientHandle}
  EmfPrvRegQ.OldProc = SELF.Win{PROP:WndProc}
  EmfPrvRegQ.OldClientProc = SELF.Win{PROP:ClientWndProc}
  EmfPrvRegQ.Prv &= SELF
  ADD(EmfPrvRegQ)
  EmfPrvRegCS.Release()
  SELF.OldWndProc = EmfPrvRegQ.OldProc
  SELF.Win{PROP:WndProc} = ADDRESS(EmfPrv_WndProc)
  SELF.Win{PROP:ClientWndProc} = ADDRESS(EmfPrv_WndProc)

  SELF.Layout()
  SELF.ShowPage()
  SELF.RefreshThumbs()
  SELF.UpdateStatus()
  SELECT(SELF.FeqSearch)
  IF SELF.InAutoTest THEN SELF.Win{PROP:Timer} = 25.

!------------------------------------------------------------------------------
! event plumbing (self-contained: the ABC PrintPreviewClass handlers are bound
! to its own window controls and must not run)
!------------------------------------------------------------------------------
EmfPreviewClass.TakeEvent PROCEDURE()
RVal  BYTE(Level:Benign)
  CODE
  IF SELF.ClassicMode THEN RETURN PARENT.TakeEvent().
  IF NOT FIELD()
    RVal = SELF.TakeWindowEvent()
    IF RVal THEN RETURN RVal.
  END
  CASE EVENT()
  OF EVENT:Accepted
    RVal = SELF.TakeAccepted()
  OF EVENT:AlertKey
    RVal = SELF.TakeFieldEvent()
    IF RVal THEN RETURN RVal.
    CASE KEYCODE()
    OF PgUpKey
      SELF.ScrollLines(-999)
    OF PgDnKey
      SELF.ScrollLines(999)
    OF CtrlPgUp
      SELF.GotoPage(SELF.CurrentPage - 1)
    OF CtrlPgDn
      SELF.GotoPage(SELF.CurrentPage + 1)
    OF CtrlHome
      SELF.GotoPage(1)
    OF CtrlEnd
      SELF.GotoPage(RECORDS(SELF.ImageQueue))
    OF F3Key
      SELF.NextHit(1)
    OF ShiftF3
      SELF.NextHit(-1)
    OF CtrlF
      SELECT(SELF.FeqSearch)
    OF CtrlP
      POST(EVENT:Accepted, SELF.FeqPrint)
    OF EscKey
      POST(EVENT:CloseWindow)
    OF CtrlPlus
      SELF.ZoomStep(1)
    OF CtrlMinus
      SELF.ZoomStep(-1)
    OF CtrlM
      SELF.TogglePageMark(SELF.CurrentPage)
    END
    RETURN Level:Benign
  OF EVENT:NewSelection
    RVal = SELF.TakeFieldEvent()
  END
  IF RVal THEN RETURN RVal.
  IF FIELD() AND EVENT() <> EVENT:Accepted AND EVENT() <> EVENT:NewSelection
    RVal = SELF.TakeFieldEvent()
  END
  RETURN RVal

EmfPreviewClass.TakeWindowEvent PROCEDURE()
  CODE
  IF SELF.ClassicMode THEN RETURN PARENT.TakeWindowEvent().
  CASE EVENT()
  OF EVENT:OpenWindow
    SELF.Open()
  OF EVENT:Sized
    IF NOT SELF.Win &= NULL AND SELF.Win{PROP:Pixels}
      SELF.Layout()
      SELF.ShowPage()
      SELF.RefreshThumbs()
    END
  OF EVENT:Timer
    SELF.TakeTimer()
  OF EVENT:CloseWindow
    IF NOT SELF.INI &= NULL AND NOT SELF.Win &= NULL
      SELF.INI.Update('_EmfPreview_', SELF.Win)
      SELF.INI.Update('_EmfPreview_', 'Zoom', SELF.ZoomMode)
      SELF.INI.Update('_EmfPreview_', 'Sidebar', SELF.ShowSidebar)
    END
  END
  RETURN Level:Benign

EmfPreviewClass.TakeFieldEvent PROCEDURE()
i     LONG,AUTO
  CODE
  IF SELF.ClassicMode THEN RETURN PARENT.TakeFieldEvent().
  CASE EVENT()
  OF EVENT:AlertKey
    IF FIELD() = SELF.FeqPage
      CASE KEYCODE()
      OF MouseLeft
        IF SELF.ClickMarks THEN SELF.ToggleMarkAt(MOUSEX(), MOUSEY()).
        RETURN Level:Notify
      OF MouseLeft2
        IF SELF.ZoomMode = EmfPrv:Zoom:FitWidth OR SELF.ZoomMode = EmfPrv:Zoom:FitPage
          SELF.SetZoom(150)
        ELSE
          SELF.SetZoom(EmfPrv:Zoom:FitWidth)
        END
        RETURN Level:Notify
      OF MouseRight
        CASE POPUP('Mark / unmark text here|Mark page|-|Zoom in|Zoom out|Fit width|Fit page|-|Mark all hits|Clear text marks')
        OF 1
          SELF.ToggleMarkAt(MOUSEX(), MOUSEY())
        OF 2
          SELF.TogglePageMark(SELF.CurrentPage)
        OF 3
          SELF.ZoomStep(1)
        OF 4
          SELF.ZoomStep(-1)
        OF 5
          SELF.SetZoom(EmfPrv:Zoom:FitWidth)
        OF 6
          SELF.SetZoom(EmfPrv:Zoom:FitPage)
        OF 7
          SELF.MarkAllHits()
        OF 8
          SELF.ClearMarks()
        END
        RETURN Level:Notify
      END
    ELSE
      LOOP i = 1 TO SELF.ThumbCreated
        IF FIELD() = SELF.ThumbImg[i]
          IF KEYCODE() = MouseLeft OR KEYCODE() = MouseLeft2
            SELF.GotoPage(SELF.ThumbFirst + i - 1)
          ELSIF KEYCODE() = MouseRight
            SELF.TogglePageMark(SELF.ThumbFirst + i - 1)
          END
          RETURN Level:Notify
        END
      END
    END
  OF EVENT:NewSelection
    CASE FIELD()
    OF SELF.FeqPageSpin
      POST(EVENT:Accepted, SELF.FeqPageSpin)
      RETURN Level:Notify
    OF SELF.FeqZoomCombo
      POST(EVENT:Accepted, SELF.FeqZoomCombo)
      RETURN Level:Notify
    END
  END
  RETURN Level:Benign

EmfPreviewClass.TakeAccepted PROCEDURE()
Zt   STRING(16)
  CODE
  IF SELF.ClassicMode THEN RETURN PARENT.TakeAccepted().
  CASE ACCEPTED()
  OF SELF.FeqPrint
    SELF.PrintOK = CHOOSE(NOT SELF.ConfirmPages OR SELF.AskPrintPages())
    IF SELF.PrintOK THEN POST(EVENT:CloseWindow).
  OF SELF.FeqPrintMarked
    IF SELF.MarkedPageList() = ''
      MESSAGE('No pages are marked.|Use "Mark page" (Ctrl+M) or right-click a thumbnail to mark pages first.', SELF.Title, ICON:Asterisk)
    ELSE
      SELF.PagesToPrint = SELF.MarkedPageList()
      SELF.PrintOK = TRUE
      POST(EVENT:CloseWindow)
    END
  OF SELF.FeqSaveAs
    RETURN SELF.OnSaveAs()
  OF SELF.FeqClose
    POST(EVENT:CloseWindow)
  OF SELF.FeqFirst
    SELF.GotoPage(1)
  OF SELF.FeqPrev
    SELF.GotoPage(SELF.CurrentPage - 1)
  OF SELF.FeqNext
    SELF.GotoPage(SELF.CurrentPage + 1)
  OF SELF.FeqLast
    SELF.GotoPage(RECORDS(SELF.ImageQueue))
  OF SELF.FeqPageSpin
    SELF.GotoPage(SELF.CurrentPage)
  OF SELF.FeqZoomOut
    SELF.ZoomStep(-1)
  OF SELF.FeqZoomIn
    SELF.ZoomStep(1)
  OF SELF.FeqZoomCombo
    Zt = UPPER(CLIP(SELF.ZoomText))
    IF Zt = 'FIT WIDTH'
      SELF.SetZoom(EmfPrv:Zoom:FitWidth)
    ELSIF Zt = 'FIT PAGE'
      SELF.SetZoom(EmfPrv:Zoom:FitPage)
    ELSE
      IF INSTRING('%', Zt, 1, 1) THEN Zt = SUB(Zt, 1, INSTRING('%', Zt, 1, 1) - 1).
      IF Zt > 0 THEN SELF.SetZoom(Zt).
    END
  OF SELF.FeqSearch
  OROF SELF.FeqFind
    IF LEN(SELF.SearchText) = 0
      FREE(SELF.Hits)
      SELF.CurHit = 0
      SELF.LastSearch = U''
      SELF.ShowPage()
      SELF.RefreshThumbs()
      SELF.UpdateStatus()
    ELSIF SELF.SearchText <> SELF.LastSearch OR RECORDS(SELF.Hits) = 0
      SELF.Find(SELF.SearchText)
      SELF.NextHit(1)
    ELSE
      SELF.NextHit(1)
    END
  OF SELF.FeqFindPrev
    IF RECORDS(SELF.Hits) = 0 AND LEN(SELF.SearchText) THEN SELF.Find(SELF.SearchText).
    SELF.NextHit(-1)
  OF SELF.FeqFindNext
    IF RECORDS(SELF.Hits) = 0 AND LEN(SELF.SearchText) THEN SELF.Find(SELF.SearchText).
    SELF.NextHit(1)
  OF SELF.FeqCase
    IF LEN(SELF.SearchText)
      SELF.Find(SELF.SearchText)
      SELF.NextHit(1)
    END
  OF SELF.FeqMarkAll
    SELF.MarkAllHits()
  OF SELF.FeqClearMarks
    SELF.ClearMarks()
  OF SELF.FeqMarkPage
    SELF.TogglePageMark(SELF.CurrentPage)
  OF SELF.FeqSidebar
    SELF.Layout()
    SELF.ShowPage()
    SELF.RefreshThumbs()
  OF SELF.FeqThumbUp
    SELF.ThumbFirst -= SELF.ThumbVisible
    IF SELF.ThumbFirst < 1 THEN SELF.ThumbFirst = 1.
    SELF.RefreshThumbs()
  OF SELF.FeqThumbDown
    SELF.ThumbFirst += SELF.ThumbVisible
    IF SELF.ThumbFirst > RECORDS(SELF.ImageQueue) - SELF.ThumbVisible + 1
      SELF.ThumbFirst = RECORDS(SELF.ImageQueue) - SELF.ThumbVisible + 1
    END
    IF SELF.ThumbFirst < 1 THEN SELF.ThumbFirst = 1.
    SELF.RefreshThumbs()
  END
  RETURN Level:Benign

EmfPreviewClass.TakeTimer PROCEDURE()
  CODE

! mouse wheel (from the window subclass); returns 1 when handled
EmfPreviewClass.TakeWheel PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix)
Notches  LONG,AUTO
  CODE
  IF Delta = 0 THEN RETURN 0.
  IF BAND(Keys, MK_CONTROL)
    SELF.ZoomStep(CHOOSE(Delta > 0, 1, -1))
    RETURN 1
  END
  IF SELF.ShowSidebar AND XPix >= 0 AND XPix < SELF.SidebarWidth
    Notches = CHOOSE(Delta > 0, -1, 1)
    SELF.ThumbFirst += Notches
    IF SELF.ThumbFirst > RECORDS(SELF.ImageQueue) - SELF.ThumbVisible + 1
      SELF.ThumbFirst = RECORDS(SELF.ImageQueue) - SELF.ThumbVisible + 1
    END
    IF SELF.ThumbFirst < 1 THEN SELF.ThumbFirst = 1.
    SELF.RefreshThumbs()
    RETURN 1
  END
  SELF.ScrollLines(CHOOSE(Delta > 0, -SELF.WheelLines, SELF.WheelLines))
  RETURN 1

!------------------------------------------------------------------------------
! navigation / view
!------------------------------------------------------------------------------
EmfPreviewClass.GotoPage PROCEDURE(LONG PageNo)
  CODE
  IF PageNo < 1 THEN PageNo = 1.
  IF PageNo > RECORDS(SELF.ImageQueue) THEN PageNo = RECORDS(SELF.ImageQueue).
  IF PageNo = SELF.CurrentPage AND SELF.ShownFile <> '' THEN RETURN.
  SELF.CurrentPage = PageNo
  SELF.ShowPage()
  SELF.ScrollTo(0, 0)
  SELF.RefreshThumbs()
  SELF.UpdateStatus()

EmfPreviewClass.SetZoom PROCEDURE(SHORT Mode)
  CODE
  IF Mode > 0
    IF Mode < 10 THEN Mode = 10.
    IF Mode > 800 THEN Mode = 800.
  END
  SELF.ZoomMode = Mode
  SELF.Layout()
  SELF.ShowPage()
  SELF.UpdateStatus()

EmfPreviewClass.ZoomStep PROCEDURE(SHORT Direction)
Steps    STRING('25,33,50,67,75,100,125,150,175,200,250,300,400,500')
Cur      LONG,AUTO
Best     LONG
i        LONG
p        LONG
v        LONG
  CODE
  Cur = SELF.ZoomPct
  IF Cur <= 0 THEN Cur = 100.
  i = 1
  LOOP
    p = INSTRING(',', Steps, 1, i)
    IF p = 0
      v = SUB(Steps, i, LEN(CLIP(Steps)) - i + 1)
    ELSE
      v = SUB(Steps, i, p - i)
    END
    IF Direction > 0
      IF v > Cur AND (Best = 0 OR v < Best) THEN Best = v.
    ELSE
      IF v < Cur AND v > Best THEN Best = v.
    END
    IF p = 0 THEN BREAK.
    i = p + 1
  END
  IF Best THEN SELF.SetZoom(Best).

! size and place everything (pixel mode)
EmfPreviewClass.Layout PROCEDURE()
CW       LONG,AUTO
CH       LONG,AUTO
SW       LONG,AUTO
PX0      LONG,AUTO
PW       LONG,AUTO
FrameW   LONG,AUTO
FrameH   LONG,AUTO
Margin   LONG(14)
PgW      LONG,AUTO
PgH      LONG,AUTO
W        LONG,AUTO
H        LONG,AUTO
X        LONG,AUTO
Y        LONG,AUTO
VScroll  BYTE
HScroll  BYTE
CXV      LONG,AUTO
CYH      LONG,AUTO
TW       LONG,AUTO
Tx       LONG,AUTO
Ty       LONG,AUTO
Row1     LONG(6)
Row2     LONG(38)
BtnH     LONG(26)
  CODE
  IF SELF.Win &= NULL THEN RETURN.
  CW = SELF.Win{PROP:ClientWidth}
  CH = SELF.Win{PROP:ClientHeight}
  CXV = EmfPrv_GetSystemMetrics(SM_CXVSCROLL)
  CYH = EmfPrv_GetSystemMetrics(SM_CYHSCROLL)

  ! ---- toolbar, two rows ----
  SELF.FeqToolbar{PROP:Height} = 70
  Tx = 6
  SETPOSITION(SELF.FeqPrint, Tx, Row1, 74, BtnH)
  Tx += 78
  SETPOSITION(SELF.FeqPrintMarked, Tx, Row1, 104, BtnH)
  Tx += 108
  SETPOSITION(SELF.FeqSaveAs, Tx, Row1, 30, BtnH)
  Tx += 34
  SETPOSITION(SELF.FeqClose, Tx, Row1, 30, BtnH)
  Tx += 46
  SETPOSITION(SELF.FeqFirst, Tx, Row1, 26, BtnH)
  Tx += 28
  SETPOSITION(SELF.FeqPrev, Tx, Row1, 26, BtnH)
  Tx += 30
  SETPOSITION(SELF.FeqPageSpin, Tx, Row1 + 2, 54, BtnH - 4)
  Tx += 58
  SETPOSITION(SELF.FeqPageOf, Tx, Row1 + 6, 60, 16)
  Tx += 62
  SETPOSITION(SELF.FeqNext, Tx, Row1, 26, BtnH)
  Tx += 28
  SETPOSITION(SELF.FeqLast, Tx, Row1, 26, BtnH)
  Tx += 40
  SETPOSITION(SELF.FeqZoomOut, Tx, Row1, 26, BtnH)
  Tx += 28
  SETPOSITION(SELF.FeqZoomCombo, Tx, Row1 + 2, 90, BtnH - 4)
  Tx += 94
  SETPOSITION(SELF.FeqZoomIn, Tx, Row1, 26, BtnH)
  Tx += 40
  SETPOSITION(SELF.FeqSidebar, Tx, Row1 + 5, 70, 16)
  Tx = 6
  SETPOSITION(SELF.FeqFindPrompt, Tx, Row2 + 5, 32, 16)
  Tx += 36
  SETPOSITION(SELF.FeqSearch, Tx, Row2 + 1, 180, BtnH - 2)
  Tx += 184
  SETPOSITION(SELF.FeqFind, Tx, Row2, 44, BtnH)
  Tx += 46
  SETPOSITION(SELF.FeqFindPrev, Tx, Row2, 26, BtnH)
  Tx += 28
  SETPOSITION(SELF.FeqFindNext, Tx, Row2, 26, BtnH)
  Tx += 30
  SETPOSITION(SELF.FeqHitText, Tx, Row2 + 5, 120, 16)
  Tx += 124
  SETPOSITION(SELF.FeqCase, Tx, Row2 + 5, 40, 16)
  Tx += 52
  SETPOSITION(SELF.FeqMarkAll, Tx, Row2, 74, BtnH)
  Tx += 78
  SETPOSITION(SELF.FeqClearMarks, Tx, Row2, 84, BtnH)
  Tx += 88
  SETPOSITION(SELF.FeqMarkPage, Tx, Row2, 90, BtnH)

  ! ---- sidebar ----
  SW = CHOOSE(SELF.ShowSidebar, SELF.SidebarWidth, 0)
  IF SW
    SETPOSITION(SELF.FeqSideBack, 0, 0, SW, CH)
    SETPOSITION(SELF.FeqThumbUp, INT(SW / 2) - 30, 4, 60, 18)
    SETPOSITION(SELF.FeqThumbDown, INT(SW / 2) - 30, CH - 22, 60, 18)
    UNHIDE(SELF.FeqSideBack)
    UNHIDE(SELF.FeqThumbUp)
    UNHIDE(SELF.FeqThumbDown)
  ELSE
    HIDE(SELF.FeqSideBack)
    HIDE(SELF.FeqThumbUp)
    HIDE(SELF.FeqThumbDown)
  END

  ! ---- page pane ----
  SELF.Index.Pages.PageNo = SELF.CurrentPage
  GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
  IF ERRORCODE() OR SELF.Index.Pages.FrameW <= 0 OR SELF.Index.Pages.FrameH <= 0
    FrameW = 8500
    FrameH = 11000
  ELSE
    FrameW = SELF.Index.Pages.FrameW
    FrameH = SELF.Index.Pages.FrameH
  END
  PX0 = SW
  PW = CW - SW
  IF PW < 100 THEN PW = 100.
  IF CH < 100 THEN CH = 100.
  ! thumbnail geometry (page aspect)
  TW = SW - 30
  IF TW < 20 THEN TW = 20.
  SELF.ThumbH = TW * FrameH / FrameW
  IF SW
    SELF.ThumbVisible = INT((CH - 52) / (SELF.ThumbH + 26))
    IF SELF.ThumbVisible < 1 THEN SELF.ThumbVisible = 1.
    IF SELF.ThumbVisible > EmfPrv:MaxThumbs THEN SELF.ThumbVisible = EmfPrv:MaxThumbs.
  ELSE
    SELF.ThumbVisible = 0
  END

  CASE SELF.ZoomMode
  OF EmfPrv:Zoom:FitWidth
    SELF.PxPerMil = (PW - 2 * Margin - CXV) / FrameW
  OF EmfPrv:Zoom:FitPage
    SELF.PxPerMil = (PW - 2 * Margin) / FrameW
    IF (CH - 2 * Margin) / FrameH < SELF.PxPerMil THEN SELF.PxPerMil = (CH - 2 * Margin) / FrameH.
  ELSE
    SELF.PxPerMil = EmfPrv:DefaultDpi / 1000 * SELF.ZoomMode / 100
  END
  IF SELF.PxPerMil <= 0 THEN SELF.PxPerMil = 0.01.
  SELF.ZoomPct = ROUND(SELF.PxPerMil * 1000 / EmfPrv:DefaultDpi * 100, 1)
  PgW = ROUND(FrameW * SELF.PxPerMil, 1)
  PgH = ROUND(FrameH * SELF.PxPerMil, 1)

  W = PgW
  H = PgH
  VScroll = FALSE
  HScroll = FALSE
  IF H > CH - 2 * Margin
    H = CH - 2 * Margin
    VScroll = TRUE
    W += CXV
  END
  IF W > PW - 2 * Margin
    W = PW - 2 * Margin
    HScroll = TRUE
    IF NOT VScroll AND H + CYH <= CH - 2 * Margin THEN H += CYH.
  END
  X = PX0 + INT((PW - W) / 2)
  Y = INT((CH - H) / 2)
  IF Y < Margin THEN Y = Margin.
  SETPOSITION(SELF.FeqPaper, X - 1, Y - 1, W + 2, H + 2)
  SETPOSITION(SELF.FeqPage, X, Y, W, H)
  SELF.WantHScroll = HScroll
  SELF.WantVScroll = VScroll
  SELF.Dirty = TRUE

! (re)render the current page and show it
EmfPreviewClass.ShowPage PROCEDURE()
F        STRING(FILE:MaxFileName)
PgW      LONG,AUTO
PgH      LONG,AUTO
SI       LIKE(ScrollInfoGrp)
PosV     LONG
PosH     LONG
i        LONG,AUTO
  CODE
  IF SELF.Win &= NULL THEN RETURN.
  SELF.Index.Pages.PageNo = SELF.CurrentPage
  GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
  IF ERRORCODE() THEN RETURN.
  ! keep the scroll position when only the content changes
  IF NOT SELF.Dirty
    SI.cbSize = SIZE(SI)
    SI.fMask = SIF_ALL
    EmfPrv_GetScrollInfo(SELF.FeqPage{PROP:Handle}, SB_VERT, ADDRESS(SI))
    PosV = SI.nPos
    SI.cbSize = SIZE(SI)
    SI.fMask = SIF_ALL
    EmfPrv_GetScrollInfo(SELF.FeqPage{PROP:Handle}, SB_HORZ, ADDRESS(SI))
    PosH = SI.nPos
  END
  PgW = ROUND(SELF.Index.Pages.FrameW * SELF.PxPerMil, 1)
  PgH = ROUND(SELF.Index.Pages.FrameH * SELF.PxPerMil, 1)
  SELF.RenderSeq += 1
  F = SELF.RenderPage(SELF.CurrentPage, TRUE, TRUE)
  IF F = '' THEN F = SELF.Index.Pages.FileName.
  SELF.FeqPage{PROP:Text} = CLIP(F)
  SELF.FeqPage{PROP:MaxWidth} = PgW
  SELF.FeqPage{PROP:MaxHeight} = PgH
  ! the scroll bars only take effect once an image is loaded
  SELF.FeqPage{PROP:HScroll} = SELF.WantHScroll
  SELF.FeqPage{PROP:VScroll} = SELF.WantVScroll
  UNHIDE(SELF.FeqPaper)
  UNHIDE(SELF.FeqPage)
  IF SELF.ShownFile <> '' AND SELF.ShownFile <> CLIP(F)
    LOOP i = RECORDS(SELF.Temps) TO 1 BY -1
      GET(SELF.Temps, i)
      IF CLIP(SELF.Temps.FileName) = SELF.ShownFile
        REMOVE(SELF.Temps.FileName)
        IF ERRORCODE() = 0 THEN DELETE(SELF.Temps).
        BREAK
      END
    END
  END
  SELF.ShownFile = CLIP(F)
  IF NOT SELF.Dirty
    IF PosV THEN EmfPrv_SendMessage(SELF.FeqPage{PROP:Handle}, WM_VSCROLL, SB_THUMBPOSITION + BSHIFT(PosV, 16), 0).
    IF PosH THEN EmfPrv_SendMessage(SELF.FeqPage{PROP:Handle}, WM_HSCROLL, SB_THUMBPOSITION + BSHIFT(PosH, 16), 0).
  END
  SELF.Dirty = FALSE
  DISPLAY(SELF.FeqPage)

EmfPreviewClass.RefreshThumbs PROCEDURE()
i        LONG,AUTO
Pg       LONG,AUTO
SW       LONG,AUTO
TW       LONG,AUTO
Y        LONG,AUTO
Lbl      STRING(40)
N        LONG,AUTO
  CODE
  IF SELF.Win &= NULL THEN RETURN.
  N = RECORDS(SELF.ImageQueue)
  IF NOT SELF.ShowSidebar OR SELF.ThumbVisible = 0
    LOOP i = 1 TO SELF.ThumbCreated
      HIDE(SELF.ThumbBox[i])
      HIDE(SELF.ThumbImg[i])
      HIDE(SELF.ThumbLbl[i])
    END
    RETURN
  END
  ! keep the current page inside the strip
  IF SELF.CurrentPage < SELF.ThumbFirst THEN SELF.ThumbFirst = SELF.CurrentPage.
  IF SELF.CurrentPage >= SELF.ThumbFirst + SELF.ThumbVisible THEN SELF.ThumbFirst = SELF.CurrentPage - SELF.ThumbVisible + 1.
  IF SELF.ThumbFirst > N - SELF.ThumbVisible + 1 THEN SELF.ThumbFirst = N - SELF.ThumbVisible + 1.
  IF SELF.ThumbFirst < 1 THEN SELF.ThumbFirst = 1.
  SW = SELF.SidebarWidth
  TW = SW - 30
  Y = 26
  LOOP i = 1 TO EmfPrv:MaxThumbs
    Pg = SELF.ThumbFirst + i - 1
    IF i > SELF.ThumbVisible OR Pg > N
      IF i <= SELF.ThumbCreated
        HIDE(SELF.ThumbBox[i])
        HIDE(SELF.ThumbImg[i])
        HIDE(SELF.ThumbLbl[i])
      END
      CYCLE
    END
    IF i > SELF.ThumbCreated
      SELF.ThumbBox[i] = EmfPrv:ThumbBase + (i - 1) * 3
      SELF.ThumbImg[i] = SELF.ThumbBox[i] + 1
      SELF.ThumbLbl[i] = SELF.ThumbBox[i] + 2
      CREATE(SELF.ThumbBox[i], CREATE:Box)
      CREATE(SELF.ThumbImg[i], CREATE:Image)
      CREATE(SELF.ThumbLbl[i], CREATE:String)
      SELF.ThumbBox[i]{PROP:Fill} = COLOR:White
      SELF.ThumbImg[i]{PROP:Alrt, 250} = MouseLeft
      SELF.ThumbImg[i]{PROP:Alrt, 251} = MouseRight
      SELF.ThumbImg[i]{PROP:Alrt, 252} = MouseLeft2
      SELF.ThumbImg[i]{PROP:Cursor} = CURSOR:Hand
      SELF.ThumbLbl[i]{PROP:Trn} = TRUE
      SELF.ThumbLbl[i]{PROP:Center} = TRUE
      SELF.ThumbLbl[i]{PROP:FontColor} = 0404040H
      SELF.ThumbCreated = i
    END
    SELF.Index.Pages.PageNo = Pg
    GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
    SETPOSITION(SELF.ThumbBox[i], 15 - 2, Y - 2, TW + 4, SELF.ThumbH + 4)
    SETPOSITION(SELF.ThumbImg[i], 15, Y, TW, SELF.ThumbH)
    SETPOSITION(SELF.ThumbLbl[i], 4, Y + SELF.ThumbH + 4, SW - 8, 16)
    IF Pg = SELF.CurrentPage
      SELF.ThumbBox[i]{PROP:Color} = SELF.AccentColor
      SELF.ThumbBox[i]{PROP:LineWidth} = 3
    ELSIF SELF.Index.Pages.Marked
      SELF.ThumbBox[i]{PROP:Color} = SELF.PageMarkColor
      SELF.ThumbBox[i]{PROP:LineWidth} = 3
    ELSE
      SELF.ThumbBox[i]{PROP:Color} = 0A0A0A0H
      SELF.ThumbBox[i]{PROP:LineWidth} = 1
    END
    IF SELF.ThumbImg[i]{PROP:Text} <> CLIP(SELF.Index.Pages.FileName)
      SELF.ThumbImg[i]{PROP:Text} = CLIP(SELF.Index.Pages.FileName)
    END
    Lbl = 'Page ' & Pg
    IF SELF.Index.Pages.Marked THEN Lbl = CLIP(Lbl) & ' *'.
    IF SELF.Index.Pages.Matches THEN Lbl = CLIP(Lbl) & ' (' & SELF.Index.Pages.Matches & ')'.
    SELF.ThumbLbl[i]{PROP:Text} = CLIP(Lbl)
    SELF.ThumbLbl[i]{PROP:FontStyle} = CHOOSE(Pg = SELF.CurrentPage, FONT:bold, FONT:regular)
    UNHIDE(SELF.ThumbBox[i])
    UNHIDE(SELF.ThumbImg[i])
    UNHIDE(SELF.ThumbLbl[i])
    Y += SELF.ThumbH + 26
  END
  SELF.FeqThumbUp{PROP:Disable} = CHOOSE(SELF.ThumbFirst <= 1)
  SELF.FeqThumbDown{PROP:Disable} = CHOOSE(SELF.ThumbFirst + SELF.ThumbVisible > N)

! scroll the page image so that (XMils,YMils) is in view (upper third)
EmfPreviewClass.ScrollTo PROCEDURE(LONG XMils, LONG YMils)
SI       LIKE(ScrollInfoGrp)
Pos      LONG,AUTO
hwnd     LONG,AUTO
  CODE
  IF SELF.Win &= NULL THEN RETURN.
  hwnd = SELF.FeqPage{PROP:Handle}
  SI.cbSize = SIZE(SI)
  SI.fMask = SIF_ALL
  EmfPrv_GetScrollInfo(hwnd, SB_VERT, ADDRESS(SI))
  IF SI.nMax > SI.nPage
    Pos = YMils * SELF.PxPerMil - INT(SI.nPage / 3)
    IF YMils = 0 THEN Pos = 0.
    IF Pos > SI.nMax - SI.nPage THEN Pos = SI.nMax - SI.nPage.
    IF Pos < 0 THEN Pos = 0.
    EmfPrv_SendMessage(hwnd, WM_VSCROLL, SB_THUMBPOSITION + BSHIFT(Pos, 16), 0)
  END
  SI.cbSize = SIZE(SI)
  SI.fMask = SIF_ALL
  EmfPrv_GetScrollInfo(hwnd, SB_HORZ, ADDRESS(SI))
  IF SI.nMax > SI.nPage
    Pos = XMils * SELF.PxPerMil
    IF Pos >= SI.nPos AND Pos < SI.nPos + SI.nPage THEN RETURN.    ! already visible
    Pos -= INT(SI.nPage / 3)
    IF XMils = 0 THEN Pos = 0.
    IF Pos > SI.nMax - SI.nPage THEN Pos = SI.nMax - SI.nPage.
    IF Pos < 0 THEN Pos = 0.
    EmfPrv_SendMessage(hwnd, WM_HSCROLL, SB_THUMBPOSITION + BSHIFT(Pos, 16), 0)
  END

! scroll by lines (40 px each, +down/-up); |Lines| >= 999 = a page; flips pages at the edges
EmfPreviewClass.ScrollLines PROCEDURE(LONG Lines)
SI       LIKE(ScrollInfoGrp)
Pos      LONG,AUTO
MaxPos   LONG,AUTO
Step     LONG,AUTO
hwnd     LONG,AUTO
  CODE
  IF SELF.Win &= NULL OR Lines = 0 THEN RETURN.
  hwnd = SELF.FeqPage{PROP:Handle}
  SI.cbSize = SIZE(SI)
  SI.fMask = SIF_ALL
  EmfPrv_GetScrollInfo(hwnd, SB_VERT, ADDRESS(SI))
  MaxPos = SI.nMax - SI.nPage
  IF MaxPos <= 0 OR NOT SELF.FeqPage{PROP:VScroll}
    ! nothing to scroll: flip pages
    SELF.GotoPage(SELF.CurrentPage + CHOOSE(Lines > 0, 1, -1))
    RETURN
  END
  IF ABS(Lines) >= 999
    Step = SI.nPage - 40
    IF Step < 40 THEN Step = 40.
    Step = CHOOSE(Lines > 0, Step, -Step)
  ELSE
    Step = Lines * 40
  END
  IF Step > 0 AND SI.nPos >= MaxPos
    IF SELF.CurrentPage < RECORDS(SELF.ImageQueue)
      SELF.GotoPage(SELF.CurrentPage + 1)
    END
    RETURN
  END
  IF Step < 0 AND SI.nPos <= 0
    IF SELF.CurrentPage > 1
      SELF.GotoPage(SELF.CurrentPage - 1)
      SI.cbSize = SIZE(SI)
      SI.fMask = SIF_ALL
      EmfPrv_GetScrollInfo(hwnd, SB_VERT, ADDRESS(SI))
      IF SI.nMax > SI.nPage
        EmfPrv_SendMessage(hwnd, WM_VSCROLL, SB_THUMBPOSITION + BSHIFT(SI.nMax - SI.nPage, 16), 0)
      END
    END
    RETURN
  END
  Pos = SI.nPos + Step
  IF Pos > MaxPos THEN Pos = MaxPos.
  IF Pos < 0 THEN Pos = 0.
  EmfPrv_SendMessage(hwnd, WM_VSCROLL, SB_THUMBPOSITION + BSHIFT(Pos, 16), 0)

EmfPreviewClass.UpdateStatus PROCEDURE()
N     LONG,AUTO
  CODE
  IF SELF.Win &= NULL THEN RETURN.
  N = RECORDS(SELF.ImageQueue)
  SELF.PageOfText = 'of ' & N
  CASE SELF.ZoomMode
  OF EmfPrv:Zoom:FitWidth
    SELF.ZoomText = 'Fit width'
  OF EmfPrv:Zoom:FitPage
    SELF.ZoomText = 'Fit page'
  ELSE
    SELF.ZoomText = SELF.ZoomMode & '%'
  END
  IF RECORDS(SELF.Hits)
    SELF.HitText = 'Hit ' & SELF.CurHit & ' of ' & RECORDS(SELF.Hits)
  ELSIF LEN(SELF.LastSearch)
    SELF.HitText = 'No hits'
  ELSE
    SELF.HitText = ''
  END
  SELF.Index.Pages.PageNo = SELF.CurrentPage
  GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
  SELF.FeqMarkPage{PROP:Text} = CHOOSE(ERRORCODE() = 0 AND SELF.Index.Pages.Marked, '&Unmark page', '&Mark page')
  SELF.FeqPrev{PROP:Disable} = CHOOSE(SELF.CurrentPage <= 1)
  SELF.FeqFirst{PROP:Disable} = CHOOSE(SELF.CurrentPage <= 1)
  SELF.FeqNext{PROP:Disable} = CHOOSE(SELF.CurrentPage >= N)
  SELF.FeqLast{PROP:Disable} = CHOOSE(SELF.CurrentPage >= N)
  SELF.FeqPrintMarked{PROP:Disable} = CHOOSE(SELF.MarkedPageList() = '')
  SELF.FeqClearMarks{PROP:Disable} = CHOOSE(RECORDS(SELF.Marks) = 0)
  SELF.FeqMarkAll{PROP:Disable} = CHOOSE(RECORDS(SELF.Hits) = 0)
  IF SELF.HintText
    SELF.Win{PROP:StatusText, 1} = SELF.HintText
  ELSE
    SELF.Win{PROP:StatusText, 1} = CHOOSE(SELF.ClickMarks, ' Click a text line to mark it  -  right-click for the menu  -  Ctrl+wheel zooms  -  F3 next hit', |
                                          ' Right-click the page for the menu  -  Ctrl+wheel zooms  -  F3 next hit')
  END
  SELF.Win{PROP:StatusText, 2} = 'Page ' & SELF.CurrentPage & ' of ' & N
  SELF.Win{PROP:StatusText, 3} = 'Zoom: ' & SELF.ZoomPct & '%'
  SELF.Win{PROP:StatusText, 4} = CHOOSE(RECORDS(SELF.Marks) = 0, '', RECORDS(SELF.Marks) & ' text mark' & CHOOSE(RECORDS(SELF.Marks) = 1, '', 's')) & |
                                 CHOOSE(SELF.MarkedPageList() = '', '', '  |  marked pages: ' & SELF.MarkedPageList())
  DISPLAY(SELF.FeqPageSpin)
  DISPLAY(SELF.FeqPageOf)
  DISPLAY(SELF.FeqZoomCombo)
  DISPLAY(SELF.FeqHitText)

!------------------------------------------------------------------------------
! search / marks
!------------------------------------------------------------------------------
EmfPreviewClass.Find PROCEDURE(USTRING Needle)
NeedleU  USTRING(EmfPrv:MaxTextUnits)
Hay      USTRING(EmfPrv:MaxTextUnits)
i        LONG,AUTO
p        LONG,AUTO
Start    LONG,AUTO
NLen     LONG,AUTO
Count    LONG
Ok       BYTE
  CODE
  FREE(SELF.Hits)
  SELF.CurHit = 0
  SELF.LastSearch = Needle
  LOOP i = 1 TO RECORDS(SELF.Index.Pages)
    GET(SELF.Index.Pages, i)
    SELF.Index.Pages.Matches = 0
    PUT(SELF.Index.Pages)
  END
  NLen = LEN(Needle)
  IF NLen = 0 THEN RETURN 0.
  IF SELF.SearchMatchCase
    NeedleU = Needle
  ELSE
    NeedleU = UPPER(Needle)
  END
  LOOP i = 1 TO RECORDS(SELF.Index.Texts)
    GET(SELF.Index.Texts, i)
    IF SELF.SearchMatchCase
      Hay = SELF.Index.Texts.Text
    ELSE
      Hay = SELF.Index.Texts.Upper
    END
    Start = 1
    LOOP
      p = INSTRING(NeedleU, Hay, 1, Start)
      IF p = 0 THEN BREAK.
      Ok = TRUE
      IF SELF.SearchWholeWord
        IF p > 1 AND Hay[p - 1] <> U' ' THEN Ok = FALSE.
        IF p + NLen <= LEN(Hay) AND Hay[p + NLen] <> U' ' THEN Ok = FALSE.
      END
      IF Ok
        CLEAR(SELF.Hits)
        SELF.SpanRect(i, p, NLen, SELF.Hits)
        GET(SELF.Index.Texts, i)
        SELF.Hits.PageNo = SELF.Index.Texts.PageNo
        SELF.Hits.Seq = SELF.Index.Texts.Seq
        SELF.Hits.Start = p
        SELF.Hits.Length = NLen
        SELF.Hits.Kind = EmfPrv:Kind:Match
        ADD(SELF.Hits)
        Count += 1
        SELF.Index.Pages.PageNo = SELF.Hits.PageNo
        GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
        IF ERRORCODE() = 0
          SELF.Index.Pages.Matches += 1
          PUT(SELF.Index.Pages)
        END
        IF Count >= EmfPrv:MaxHits THEN BREAK.
      END
      Start = p + NLen
      IF Start > LEN(Hay) THEN BREAK.
    END
    IF Count >= EmfPrv:MaxHits THEN BREAK.
  END
  RETURN Count

! step to the next / previous hit (wraps), show its page and scroll to it
EmfPreviewClass.NextHit PROCEDURE(SHORT Direction)
N   LONG,AUTO
  CODE
  N = RECORDS(SELF.Hits)
  IF N = 0
    SELF.ShowPage()
    SELF.RefreshThumbs()
    SELF.UpdateStatus()
    RETURN
  END
  IF SELF.CurHit = 0
    ! first time: start at the first hit on or after the current page
    IF Direction >= 0
      SELF.CurHit = 1
      LOOP WHILE SELF.CurHit <= N
        GET(SELF.Hits, SELF.CurHit)
        IF SELF.Hits.PageNo >= SELF.CurrentPage THEN BREAK.
        SELF.CurHit += 1
      END
      IF SELF.CurHit > N THEN SELF.CurHit = 1.
    ELSE
      SELF.CurHit = N
    END
  ELSE
    SELF.CurHit += Direction
    IF SELF.CurHit > N THEN SELF.CurHit = 1.
    IF SELF.CurHit < 1 THEN SELF.CurHit = N.
  END
  GET(SELF.Hits, SELF.CurHit)
  IF SELF.Hits.PageNo <> SELF.CurrentPage
    SELF.CurrentPage = SELF.Hits.PageNo
    SELF.Dirty = TRUE
  END
  SELF.ShowPage()
  SELF.ScrollTo(SELF.Hits.Left, SELF.Hits.Top)
  SELF.RefreshThumbs()
  SELF.UpdateStatus()

EmfPreviewClass.MarkAllHits PROCEDURE()
i   LONG,AUTO
j   LONG,AUTO
Dup BYTE
  CODE
  LOOP i = 1 TO RECORDS(SELF.Hits)
    GET(SELF.Hits, i)
    Dup = FALSE
    LOOP j = 1 TO RECORDS(SELF.Marks)
      GET(SELF.Marks, j)
      IF SELF.Marks.Seq = SELF.Hits.Seq AND SELF.Marks.Start = SELF.Hits.Start AND SELF.Marks.Length = SELF.Hits.Length
        Dup = TRUE
        BREAK
      END
    END
    IF NOT Dup
      GET(SELF.Hits, i)
      SELF.Marks :=: SELF.Hits
      SELF.Marks.Kind = EmfPrv:Kind:Mark
      ADD(SELF.Marks)
    END
  END
  SELF.ShowPage()
  SELF.UpdateStatus()

EmfPreviewClass.ClearMarks PROCEDURE()
  CODE
  FREE(SELF.Marks)
  SELF.ShowPage()
  SELF.UpdateStatus()

! window pixel -> page 1/1000 inch -> text item -> toggle a whole-item mark
EmfPreviewClass.ToggleMarkAt PROCEDURE(LONG XPix, LONG YPix)
SI       LIKE(ScrollInfoGrp)
hwnd     LONG,AUTO
OffX     LONG
OffY     LONG
XM       LONG,AUTO
YM       LONG,AUTO
Ptr      LONG,AUTO
i        LONG,AUTO
  CODE
  IF SELF.Win &= NULL OR SELF.PxPerMil <= 0 THEN RETURN.
  hwnd = SELF.FeqPage{PROP:Handle}
  SI.cbSize = SIZE(SI)
  SI.fMask = SIF_ALL
  EmfPrv_GetScrollInfo(hwnd, SB_HORZ, ADDRESS(SI))
  IF SI.nMax > SI.nPage THEN OffX = SI.nPos.
  SI.cbSize = SIZE(SI)
  SI.fMask = SIF_ALL
  EmfPrv_GetScrollInfo(hwnd, SB_VERT, ADDRESS(SI))
  IF SI.nMax > SI.nPage THEN OffY = SI.nPos.
  XM = (XPix - SELF.FeqPage{PROP:XPos} + OffX) / SELF.PxPerMil
  YM = (YPix - SELF.FeqPage{PROP:YPos} + OffY) / SELF.PxPerMil
  Ptr = SELF.ItemAt(SELF.CurrentPage, XM, YM)
  IF Ptr = 0 THEN RETURN.
  GET(SELF.Index.Texts, Ptr)
  ! an existing mark on this item (any span) is removed
  LOOP i = RECORDS(SELF.Marks) TO 1 BY -1
    GET(SELF.Marks, i)
    IF SELF.Marks.Seq = SELF.Index.Texts.Seq
      DELETE(SELF.Marks)
      SELF.ShowPage()
      SELF.UpdateStatus()
      RETURN
    END
  END
  SELF.MeasureItem(Ptr)
  CLEAR(SELF.Marks)
  SELF.SpanRect(Ptr, 1, LEN(SELF.Index.Texts.Text), SELF.Marks)
  SELF.Marks.PageNo = SELF.Index.Texts.PageNo
  SELF.Marks.Seq = SELF.Index.Texts.Seq
  SELF.Marks.Start = 1
  SELF.Marks.Length = LEN(SELF.Index.Texts.Text)
  SELF.Marks.Kind = EmfPrv:Kind:Mark
  ADD(SELF.Marks)
  SELF.ShowPage()
  SELF.UpdateStatus()

EmfPreviewClass.TogglePageMark PROCEDURE(LONG PageNo)
  CODE
  SELF.Index.Pages.PageNo = PageNo
  GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
  IF ERRORCODE() THEN RETURN.
  SELF.Index.Pages.Marked = CHOOSE(SELF.Index.Pages.Marked = 0)
  PUT(SELF.Index.Pages)
  SELF.RefreshThumbs()
  SELF.UpdateStatus()

! the text item under a page point (display 1/1000 inch); 0 = none
EmfPreviewClass.ItemAt PROCEDURE(LONG PageNo, LONG XMils, LONG YMils)
i      LONG,AUTO
Best   LONG
BestH  LONG(999999)
Rgt    LONG,AUTO
Bot    LONG,AUTO
  CODE
  LOOP i = 1 TO RECORDS(SELF.Index.Texts)
    GET(SELF.Index.Texts, i)
    IF SELF.Index.Texts.PageNo <> PageNo THEN CYCLE.
    IF SELF.Index.Texts.PageNo > PageNo THEN BREAK.
    Rgt = SELF.Index.Texts.Right
    Bot = SELF.Index.Texts.Bottom
    IF Bot - SELF.Index.Texts.Top > 400 THEN Bot = SELF.Index.Texts.Top + 400.   ! tall multi-line cells: first line only
    IF YMils >= SELF.Index.Texts.Top - 10 AND YMils <= Bot + 10 AND |
       XMils >= SELF.Index.Texts.Left - 10 AND XMils <= Rgt + 10
      IF Bot - SELF.Index.Texts.Top < BestH
        Best = i
        BestH = Bot - SELF.Index.Texts.Top
      END
    END
  END
  RETURN Best

EmfPreviewClass.MeasureItem PROCEDURE(LONG Pointer)
W   LONG
H   LONG
  CODE
  GET(SELF.Index.Texts, Pointer)
  IF SELF.Index.Texts.TextW THEN RETURN.
  SELF.MeasureText(SELF.Index.Texts.Face, SELF.Index.Texts.Size, SELF.Index.Texts.Style, SELF.Index.Texts.Text, W, H)
  SELF.Index.Texts.TextW = W
  PUT(SELF.Index.Texts)

! display rectangle of a span of a text item
EmfPreviewClass.SpanRect PROCEDURE(LONG Pointer, LONG Start, LONG Length, *EmfMarkQueue M)
Prefix   USTRING(EmfPrv:MaxTextUnits)
Span     USTRING(EmfPrv:MaxTextUnits)
W1       LONG
W2       LONG
H        LONG
  CODE
  GET(SELF.Index.Texts, Pointer)
  IF Start > 1
    Prefix = SELF.Index.Texts.Text[1 : Start - 1]
    SELF.MeasureText(SELF.Index.Texts.Face, SELF.Index.Texts.Size, SELF.Index.Texts.Style, Prefix, W1, H)
  END
  Span = SELF.Index.Texts.Text[1 : Start + Length - 1]
  SELF.MeasureText(SELF.Index.Texts.Face, SELF.Index.Texts.Size, SELF.Index.Texts.Style, Span, W2, H)
  M.Left = SELF.Index.Texts.TextX + W1 - 8
  M.Right = SELF.Index.Texts.TextX + W2 + 8
  M.Top = SELF.Index.Texts.Top - 6
  IF H = 0 THEN H = SELF.Index.Texts.Bottom - SELF.Index.Texts.Top.
  M.Bottom = SELF.Index.Texts.Top + H + 6
  IF M.Right > SELF.Index.Texts.Right + 60 AND SELF.Index.Texts.Right > M.Left THEN M.Right = SELF.Index.Texts.Right + 8.

! GDI text measurement in 1/1000 inch (font realised at 1440 units per inch)
EmfPreviewClass.MeasureText PROCEDURE(STRING Face, SHORT Size, SHORT Style, USTRING Text, *LONG WidthMils, *LONG HeightMils)
hdc     LONG,AUTO
hFont   LONG,AUTO
hOld    LONG,AUTO
FaceU   USTRING(64)
Sz      GROUP
cx        LONG
cy        LONG
        END
Weight  LONG,AUTO
  CODE
  WidthMils = 0
  HeightMils = 0
  IF LEN(Text) = 0 THEN RETURN.
  IF Size <= 0 THEN Size = 10.
  FaceU = CLIP(Face)
  IF LEN(FaceU) = 0 THEN FaceU = U'Segoe UI'.
  Weight = BAND(Style, 0FFFH)
  IF Weight = 0 THEN Weight = 400.
  hdc = EmfPrv_GetDC(0)
  hFont = EmfPrv_CreateFontW(-(Size * 1440 / 72), 0, 0, 0, Weight, CHOOSE(BAND(Style, FONT:italic) <> 0, 1, 0), |
                             CHOOSE(BAND(Style, FONT:underline) <> 0, 1, 0), CHOOSE(BAND(Style, FONT:strikeout) <> 0, 1, 0), |
                             1, 0, 0, 4, 0, ADDRESS(FaceU))
  IF hFont
    hOld = EmfPrv_SelectObject(hdc, hFont)
    IF EmfPrv_GetTextExtentPoint32W(hdc, ADDRESS(Text), LEN(Text), ADDRESS(Sz))
      WidthMils = Sz.cx * 1000 / 1440
      HeightMils = Sz.cy * 1000 / 1440
    END
    EmfPrv_SelectObject(hdc, hOld)
    EmfPrv_DeleteObject(hFont)
  END
  EmfPrv_ReleaseDC(0, hdc)

EmfPreviewClass.MarkedPageList PROCEDURE()
i     LONG,AUTO
Lo    LONG
Hi    LONG
L     STRING(1024)
  CODE
  LOOP i = 1 TO RECORDS(SELF.Index.Pages) + 1
    IF i <= RECORDS(SELF.Index.Pages)
      GET(SELF.Index.Pages, i)
    END
    IF i <= RECORDS(SELF.Index.Pages) AND SELF.Index.Pages.Marked
      IF Lo = 0 THEN Lo = i.
      Hi = i
    ELSIF Lo
      L = CLIP(L) & CHOOSE(L = '', '', ',') & Lo & CHOOSE(Hi > Lo, '-' & Hi, '')
      Lo = 0
      Hi = 0
    END
  END
  RETURN CLIP(L)

!------------------------------------------------------------------------------
! rendering: original page metafile + highlights -> a new EMF
!   display: the frame is the display size, so the IMAGE control's natural size
!            equals the zoomed size and scroll positions are pixels
!   print:   the frame is the original page frame
!------------------------------------------------------------------------------
EmfPreviewClass.RenderPage PROCEDURE(LONG PageNo, BYTE WithHits, BYTE WithMarks, BYTE ForPrint)
hemf     LONG,AUTO
hdcRef   LONG,AUTO
hdcMeta  LONG,AUTO
hOut     LONG,AUTO
hBrush   LONG
hPen     LONG
Frame    LIKE(RectGrp)
Play     LIKE(RectGrp)
P        REAL,AUTO                                   ! display px per 1/1000 inch
KX       REAL,AUTO                                   ! metafile logical px per display px
KY       REAL,AUTO
Dst      USTRING(FILE:MaxFileName+1)
DstA     STRING(FILE:MaxFileName)
i        LONG,AUTO
Any      BYTE
  CODE
  SELF.Index.Pages.PageNo = PageNo
  GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
  IF ERRORCODE() THEN RETURN ''.
  Any = FALSE
  IF WithHits
    LOOP i = 1 TO RECORDS(SELF.Hits)
      GET(SELF.Hits, i)
      IF SELF.Hits.PageNo = PageNo THEN Any = TRUE; BREAK.
    END
  END
  IF WithMarks AND NOT Any
    LOOP i = 1 TO RECORDS(SELF.Marks)
      GET(SELF.Marks, i)
      IF SELF.Marks.PageNo = PageNo THEN Any = TRUE; BREAK.
    END
  END
  IF ForPrint AND NOT Any THEN RETURN ''.        ! nothing to bake in
  hemf = SELF.LoadMetafile(SELF.Index.Pages.FileName, SELF.Index.Pages.IsEMF)
  IF hemf = 0 THEN RETURN ''.
  hdcRef = EmfPrv_GetDC(0)
  KX = EmfPrv_GetDeviceCaps(hdcRef, DC_HORZRES) / EmfPrv_GetDeviceCaps(hdcRef, DC_HORZSIZE) * 25.4 / EmfPrv:DefaultDpi
  KY = EmfPrv_GetDeviceCaps(hdcRef, DC_VERTRES) / EmfPrv_GetDeviceCaps(hdcRef, DC_VERTSIZE) * 25.4 / EmfPrv:DefaultDpi
  IF KX <= 0 THEN KX = 1.
  IF KY <= 0 THEN KY = 1.
  P = CHOOSE(ForPrint, EmfPrv:DefaultDpi / 1000, SELF.PxPerMil)
  IF P <= 0 THEN P = EmfPrv:DefaultDpi / 1000.
  ! frame in 0.01 mm such that the natural size (frame at 96 dpi) is the display size
  Frame.L = 0
  Frame.T = 0
  Frame.R = ROUND(SELF.Index.Pages.FrameW * P * 2540 / EmfPrv:DefaultDpi, 1)
  Frame.B = ROUND(SELF.Index.Pages.FrameH * P * 2540 / EmfPrv:DefaultDpi, 1)
  DstA = SELF.TempName(PageNo)
  Dst = CLIP(DstA)
  hdcMeta = EmfPrv_CreateEnhMetaFileW(hdcRef, ADDRESS(Dst), ADDRESS(Frame), 0)
  IF hdcMeta = 0
    EmfPrv_DeleteEnhMetaFile(hemf)
    EmfPrv_ReleaseDC(0, hdcRef)
    RETURN ''
  END
  Play.L = 0
  Play.T = 0
  Play.R = ROUND(SELF.Index.Pages.FrameW * P * KX, 1)
  Play.B = ROUND(SELF.Index.Pages.FrameH * P * KY, 1)
  IF NOT ForPrint
    ! opaque white paper (a page metafile has a transparent background)
    EmfPrv_SetROP2(hdcMeta, R2_COPYPEN)
    EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_PEN))
    EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(0))          ! WHITE_BRUSH
    EmfPrv_Rectangle(hdcMeta, 0, 0, Play.R + 1, Play.B + 1)
    EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_BRUSH))
  END
  EmfPrv_PlayEnhMetaFile(hdcMeta, hemf, ADDRESS(Play))
  IF Any
    EmfPrv_SetROP2(hdcMeta, R2_MASKPEN)                ! marker pen: AND the colour over the page
    EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_PEN))
    IF WithMarks
      hBrush = EmfPrv_CreateSolidBrush(SELF.MarkColor)
      EmfPrv_SelectObject(hdcMeta, hBrush)
      LOOP i = 1 TO RECORDS(SELF.Marks)
        GET(SELF.Marks, i)
        IF SELF.Marks.PageNo <> PageNo THEN CYCLE.
        EmfPrv_Rectangle(hdcMeta, SELF.Marks.Left * P * KX, SELF.Marks.Top * P * KY, SELF.Marks.Right * P * KX + 1, SELF.Marks.Bottom * P * KY + 1)
      END
      EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_BRUSH))
      EmfPrv_DeleteObject(hBrush)
    END
    IF WithHits
      hBrush = EmfPrv_CreateSolidBrush(SELF.HighlightColor)
      EmfPrv_SelectObject(hdcMeta, hBrush)
      LOOP i = 1 TO RECORDS(SELF.Hits)
        GET(SELF.Hits, i)
        IF SELF.Hits.PageNo <> PageNo THEN CYCLE.
        EmfPrv_Rectangle(hdcMeta, SELF.Hits.Left * P * KX, SELF.Hits.Top * P * KY, SELF.Hits.Right * P * KX + 1, SELF.Hits.Bottom * P * KY + 1)
      END
      EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_BRUSH))
      EmfPrv_DeleteObject(hBrush)
      ! the current hit gets a frame
      IF SELF.CurHit >= 1 AND SELF.CurHit <= RECORDS(SELF.Hits)
        GET(SELF.Hits, SELF.CurHit)
        IF SELF.Hits.PageNo = PageNo
          EmfPrv_SetROP2(hdcMeta, R2_COPYPEN)
          hPen = EmfPrv_CreatePen(0, 2, SELF.CurrentColor)
          EmfPrv_SelectObject(hdcMeta, hPen)
          EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_BRUSH))
          EmfPrv_Rectangle(hdcMeta, SELF.Hits.Left * P * KX - 2, SELF.Hits.Top * P * KY - 2, SELF.Hits.Right * P * KX + 3, SELF.Hits.Bottom * P * KY + 3)
          EmfPrv_SelectObject(hdcMeta, EmfPrv_GetStockObject(NULL_PEN))
          EmfPrv_DeleteObject(hPen)
        END
      END
    END
  END
  hOut = EmfPrv_CloseEnhMetaFile(hdcMeta)
  IF hOut THEN EmfPrv_DeleteEnhMetaFile(hOut).
  EmfPrv_DeleteEnhMetaFile(hemf)
  EmfPrv_ReleaseDC(0, hdcRef)
  IF hOut = 0 OR NOT EXISTS(DstA) THEN RETURN ''.
  SELF.Temps.FileName = DstA
  ADD(SELF.Temps)
  RETURN DstA

! HENHMETAFILE from a page file: .emf directly, placeable .wmf converted
EmfPreviewClass.LoadMetafile PROCEDURE(STRING FileName, BYTE IsEMF)
UPath    USTRING(FILE:MaxFileName+1)
hemf     LONG,AUTO
hFile    LONG,AUTO
FSize    LONG,AUTO
Got      LONG
Bits     &STRING

Placeable GROUP
Key        LONG
hmf        USHORT
L          SHORT
T          SHORT
R          SHORT
B          SHORT
Inch       USHORT
Res        LONG
Chk        USHORT
         END
Mfp      GROUP
mm         LONG
xExt       LONG
yExt       LONG
hMF        LONG
         END
hdcRef   LONG,AUTO
Skip     LONG
  CODE
  UPath = CLIP(FileName)
  IF IsEMF
    RETURN EmfPrv_GetEnhMetaFileW(ADDRESS(UPath))
  END
  hemf = EmfPrv_GetEnhMetaFileW(ADDRESS(UPath))            ! maybe it is an EMF after all
  IF hemf THEN RETURN hemf.
  hFile = EmfPrv_CreateFileW(ADDRESS(UPath), 80000000H, 1, 0, 3, 80H, 0)
  IF hFile = -1 OR hFile = 0 THEN RETURN 0.
  FSize = EmfPrv_GetFileSize(hFile, 0)
  IF FSize <= 40 OR FSize > 64000000
    EmfPrv_CloseHandle(hFile)
    RETURN 0
  END
  Bits &= NEW STRING(FSize)
  EmfPrv_ReadFile(hFile, ADDRESS(Bits), FSize, ADDRESS(Got), 0)
  EmfPrv_CloseHandle(hFile)
  IF Got <> FSize
    DISPOSE(Bits)
    RETURN 0
  END
  Placeable = Bits[1 : SIZE(Placeable)]
  hdcRef = EmfPrv_GetDC(0)
  IF Placeable.Key = 9AC6CDD7H
    Skip = 22
    Mfp.mm = 8                                             ! MM_ANISOTROPIC
    IF Placeable.Inch > 0
      Mfp.xExt = (Placeable.R - Placeable.L) * 2540 / Placeable.Inch
      Mfp.yExt = (Placeable.B - Placeable.T) * 2540 / Placeable.Inch
    END
    Mfp.hMF = 0
    hemf = EmfPrv_SetWinMetaFileBits(FSize - Skip, ADDRESS(Bits) + Skip, hdcRef, ADDRESS(Mfp))
  ELSE
    hemf = EmfPrv_SetWinMetaFileBits(FSize, ADDRESS(Bits), hdcRef, 0)
  END
  EmfPrv_ReleaseDC(0, hdcRef)
  DISPOSE(Bits)
  RETURN hemf

EmfPreviewClass.TempName PROCEDURE(LONG PageNo)
Dir   STRING(FILE:MaxFileName)
  CODE
  SELF.Index.Pages.PageNo = PageNo
  GET(SELF.Index.Pages, SELF.Index.Pages.PageNo)
  Dir = EmfPrv_Dir(SELF.Index.Pages.FileName)
  IF Dir = '' THEN Dir = LONGPATH() & '\'.
  RETURN CLIP(Dir) & 'EmfPrv_' & EmfPrv_GetCurrentThreadId() & '_' & PageNo & '_' & SELF.RenderSeq & '.emf'

EmfPreviewClass.DeleteTemps PROCEDURE()
i   LONG,AUTO
  CODE
  IF SELF.Temps &= NULL THEN RETURN.
  LOOP i = RECORDS(SELF.Temps) TO 1 BY -1
    GET(SELF.Temps, i)
    REMOVE(SELF.Temps.FileName)
    DELETE(SELF.Temps)
  END
  SELF.ShownFile = ''

! before printing: pages that carry text marks print through their rendered
! twin (original frame); the original page file is replaced in the queue
EmfPreviewClass.PrepareMarkedPrint PROCEDURE()
i     LONG,AUTO
j     LONG,AUTO
F     STRING(FILE:MaxFileName)
  CODE
  IF NOT SELF.PrintMarks OR RECORDS(SELF.Marks) = 0 THEN RETURN.
  LOOP i = 1 TO RECORDS(SELF.ImageQueue)
    GET(SELF.ImageQueue, i)
    SELF.RenderSeq += 1
    F = SELF.RenderPage(i, FALSE, TRUE, TRUE)
    IF F <> ''
      LOOP j = RECORDS(SELF.Temps) TO 1 BY -1              ! the report engine deletes it with the queue
        GET(SELF.Temps, j)
        IF CLIP(SELF.Temps.FileName) = CLIP(F) THEN DELETE(SELF.Temps); BREAK.
      END
      REMOVE(SELF.ImageQueue.Filename)
      SELF.ImageQueue.Filename = F
      PUT(SELF.ImageQueue)
    END
  END
