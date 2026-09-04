!ABCIncludeFile(EMFPRV)
!==============================================================================
! EmfPreview - EMF / Unicode report previewer for Clarion 12 Unicode
!
!   EmfTextIndexClass  - IReportGenerator + IReportGeneratorW target that turns
!                        the report's page metafiles into a searchable text
!                        index (every text item with its page rectangle).
!   EmfPreviewClass    - drop-in replacement for the ABC PrintPreviewClass:
!                        page thumbnail sidebar, full-text search with
!                        highlighted hits, text marks (marker pen), page marks,
!                        zoom, mouse-wheel scrolling, print / print marked pages.
!
!   Requires Clarion 12 Unicode (USTRING build).  Pages of a REPORT,UNICODE are
!   .emf files; classic .wmf pages are converted on the fly for highlighting.
!==============================================================================
  OMIT('_EndOfInclude_',_EmfPreviewPresent_)
_EmfPreviewPresent_ EQUATE(1)

  OMIT('_EmfPrvUnicodeCheck_',_USTRING_)
EmfPreview_requires_Clarion_12_Unicode EQUATE(NEEDS_A_USTRING_CAPABLE_COMPILER)
  _EmfPrvUnicodeCheck_

  INCLUDE('ABREPORT.INC'),ONCE
  INCLUDE('ABWMFPAR.INC'),ONCE
  INCLUDE('ABRPTGEN.INT'),ONCE
  INCLUDE('ABUTIL.INC'),ONCE

EmfPrv:MaxTextUnits   EQUATE(260)
EmfPrv:MaxThumbs      EQUATE(24)          ! thumbnails that can be visible at once

EmfPrv:Kind:Match     EQUATE(1)           ! search hit
EmfPrv:Kind:Mark      EQUATE(2)           ! user text mark

EmfPrv:Zoom:FitWidth  EQUATE(-1)          ! same value as ABC PageWidth
EmfPrv:Zoom:FitPage   EQUATE(-3)

! one row per report page
EmfPageQueue          QUEUE,TYPE
PageNo                  LONG
FileName                STRING(FILE:MaxFileName)
IsEMF                   BYTE
FrameW                  LONG              ! page frame, 1/1000 inch
FrameH                  LONG
BoxL                    LONG              ! parser box origin (WMF bbox), 1/1000 inch
BoxT                    LONG
OffX                    LONG              ! physical print offset the parser adds to EMF
OffY                    LONG              ! coordinates and GDI playback does not (1/1000 inch)
Marked                  BYTE
Matches                 LONG
                      END

! one row per text item (STRING/TEXT line/CHECK/RADIO/GROUP caption)
! coordinates are DISPLAY coordinates: 1/1000 inch from the page frame origin
EmfTextQueue          QUEUE,TYPE
PageNo                  LONG
Seq                     LONG
Left                    LONG
Top                     LONG
Right                   LONG
Bottom                  LONG
TextX                   LONG              ! where the text itself starts
TextW                   LONG              ! measured width of the text (0 = not measured)
Face                    CSTRING(32)
Size                    SHORT
Style                   SHORT
Text                    USTRING(EmfPrv:MaxTextUnits)
Upper                   USTRING(EmfPrv:MaxTextUnits)
                      END

! search hits and user marks
EmfMarkQueue          QUEUE,TYPE
PageNo                  LONG
Seq                     LONG              ! EmfTextQueue.Seq
Start                   LONG              ! first UTF-16 unit of the marked span (1-based)
Length                  LONG              ! units
Left                    LONG              ! display rect, 1/1000 inch
Top                     LONG
Right                   LONG
Bottom                  LONG
Kind                    BYTE
                      END

EmfTempQueue          QUEUE,TYPE
FileName                STRING(FILE:MaxFileName)
                      END

!------------------------------------------------------------------------------
! Both classes are always linked into the module that uses them (no DLL-mode
! parameters): an app that still references EmfPreviewClass after the template
! was removed keeps compiling and running instead of GPFing on a missing define.
EmfTextIndexClass     CLASS,TYPE,IMPLEMENTS(IReportGenerator),IMPLEMENTS(IReportGeneratorW),MODULE('EmfPreview.CLW'),LINK('EmfPreview.CLW')
Pages                   &EmfPageQueue
Texts                   &EmfTextQueue
CurPage                 LONG,PROTECTED
Seq                     LONG,PROTECTED
CurBoxL                 LONG,PROTECTED
CurBoxT                 LONG,PROTECTED
CurOffX                 LONG,PROTECTED
CurOffY                 LONG,PROTECTED
WideRun                 BYTE
Errors                  &ErrorClass,PROTECTED

CONSTRUCT               PROCEDURE()
DESTRUCT                PROCEDURE()
Init                    PROCEDURE(<ErrorClass EC>)
Kill                    PROCEDURE()
Build                   PROCEDURE(PrintPreviewFileQueue Q),BYTE,PROC   ! index every page; returns Level:Benign / Level:Fatal
ClearIndex              PROCEDURE()
AddText                 PROCEDURE(*StringFormatGrp F, USTRING Text),VIRTUAL
ProbePage               PROCEDURE(STRING FileName, *EmfPageQueue Pg),VIRTUAL   ! read the metafile header -> frame + offsets
                      END

!------------------------------------------------------------------------------
EmfPreviewClass       CLASS(PrintPreviewClass),TYPE,MODULE('EmfPreview.CLW'),LINK('EmfPreview.CLW')
! ---- options (set before Display) ------------------------------------------
Title                   CSTRING(128)
ShowSidebar             BYTE(1)
SidebarWidth            LONG(190)         ! pixels
InitialZoom             SHORT(EmfPrv:Zoom:FitWidth)   ! percent, or EmfPrv:Zoom:FitWidth / EmfPrv:Zoom:FitPage
HighlightColor          LONG(0076F1FFH)   ! search hits    (COLORREF 00BBGGRR: soft yellow)
MarkColor               LONG(00FFE6A5H)   ! text marks     (light sky)
CurrentColor            LONG(000078FFH)   ! current hit border (orange)
PageMarkColor           LONG(000B9EF5H)   ! marked page frame (amber)
AccentColor             LONG(00EB6F1FH)   ! current page frame (blue)
PaperShadow             LONG(00595652H)   ! page area background
SidebarColor            LONG(00F5F1EEH)
SearchMatchCase         BYTE(0)
SearchWholeWord         BYTE(0)
ClassicMode             BYTE(0)           ! TRUE = behave exactly like the ABC PrintPreviewClass
PrintMarks              BYTE(1)           ! print pages with their text marks baked in
WheelLines              BYTE(3)
ClickMarks              BYTE(1)           ! left click on a text item toggles a mark
! ---- state -------------------------------------------------------------------
Index                   &EmfTextIndexClass,PROTECTED
Marks                   &EmfMarkQueue,PROTECTED
Hits                    &EmfMarkQueue,PROTECTED
Temps                   &EmfTempQueue,PROTECTED
INI                     &INIClass,PROTECTED
Win                     &WINDOW,PROTECTED
CurHit                  LONG,PROTECTED
ZoomPct                 LONG,PROTECTED    ! effective zoom percent
ZoomMode                SHORT,PROTECTED   ! percent or fit equate
SearchText              USTRING(200)
LastSearch              USTRING(200),PROTECTED
ZoomText                STRING(16)
PageOfText              STRING(24)
HitText                 STRING(40)
ThumbFirst              LONG,PROTECTED
ThumbVisible            LONG,PROTECTED
ThumbH                  LONG,PROTECTED
PxPerMil                REAL,PROTECTED    ! IMAGE pixels per 1/1000 inch at the current zoom
RefPxPerMilX            REAL,PROTECTED    ! metafile reference device pixels per 1/1000 inch
RefPxPerMilY            REAL,PROTECTED
ShownFile               CSTRING(FILE:MaxFileName+1),PROTECTED
OldWndProc              LONG,PROTECTED
RenderSeq               LONG,PROTECTED
Dirty                   BYTE,PROTECTED
WantHScroll             BYTE,PROTECTED
WantVScroll             BYTE,PROTECTED
PendV                   LONG(-1),PROTECTED   ! vertical position last requested (the IMAGE applies WM_VSCROLL lazily)
PendFromV               LONG,PROTECTED       ! ... and the position it was requested from
HintText                CSTRING(200)      ! status bar zone 1; '' = default hint
InAutoTest              BYTE
! ---- field equates (PROTECTED so a derived class can drive the window) ------
FeqToolbar              SIGNED,PROTECTED
FeqPrint                SIGNED,PROTECTED
FeqPrintMarked          SIGNED,PROTECTED
FeqSaveAs               SIGNED,PROTECTED
FeqClose                SIGNED,PROTECTED
FeqFirst                SIGNED,PROTECTED
FeqPrev                 SIGNED,PROTECTED
FeqPageSpin             SIGNED,PROTECTED
FeqPageOf               SIGNED,PROTECTED
FeqNext                 SIGNED,PROTECTED
FeqLast                 SIGNED,PROTECTED
FeqZoomOut              SIGNED,PROTECTED
FeqZoomCombo            SIGNED,PROTECTED
FeqZoomIn               SIGNED,PROTECTED
FeqFindPrompt           SIGNED,PROTECTED
FeqSearch               SIGNED,PROTECTED
FeqFind                 SIGNED,PROTECTED
FeqFindPrev             SIGNED,PROTECTED
FeqFindNext             SIGNED,PROTECTED
FeqHitText              SIGNED,PROTECTED
FeqCase                 SIGNED,PROTECTED
FeqMarkAll              SIGNED,PROTECTED
FeqClearMarks           SIGNED,PROTECTED
FeqMarkPage             SIGNED,PROTECTED
FeqSidebar              SIGNED,PROTECTED
FeqSideBack             SIGNED,PROTECTED
FeqThumbUp              SIGNED,PROTECTED
FeqThumbDown            SIGNED,PROTECTED
FeqPaper                SIGNED,PROTECTED
FeqPage                 SIGNED,PROTECTED
ThumbBox                SIGNED,DIM(EmfPrv:MaxThumbs),PROTECTED
ThumbImg                SIGNED,DIM(EmfPrv:MaxThumbs),PROTECTED
ThumbLbl                SIGNED,DIM(EmfPrv:MaxThumbs),PROTECTED
ThumbCreated            LONG,PROTECTED

! ---- ABC overrides -------------------------------------------------------------
CONSTRUCT               PROCEDURE()
DESTRUCT                PROCEDURE()
Display                 PROCEDURE(SHORT InitZoomFactor=0,LONG InitCurrentPage=1,USHORT InitPagesAcross=1,USHORT InitPagesDown=1),BYTE,VIRTUAL
Open                    PROCEDURE(),VIRTUAL
Kill                    PROCEDURE(),BYTE,PROC,VIRTUAL
TakeEvent               PROCEDURE(),BYTE,PROC,VIRTUAL
TakeWindowEvent         PROCEDURE(),BYTE,PROC,VIRTUAL
TakeAccepted            PROCEDURE(),BYTE,PROC,VIRTUAL
TakeFieldEvent          PROCEDURE(),BYTE,PROC,VIRTUAL
SetINIManager           PROCEDURE(*INIClass INI)
! ---- navigation / view -------------------------------------------------------
GotoPage                PROCEDURE(LONG PageNo),VIRTUAL
SetZoom                 PROCEDURE(SHORT Mode),VIRTUAL             ! percent or fit equate
ZoomStep                PROCEDURE(SHORT Direction),VIRTUAL
Layout                  PROCEDURE(),VIRTUAL                       ! size / place the controls
ShowPage                PROCEDURE(),VIRTUAL                       ! (re)render the current page
RefreshThumbs           PROCEDURE(),VIRTUAL
ScrollTo                PROCEDURE(LONG XMils, LONG YMils),VIRTUAL
ScrollLines             PROCEDURE(LONG Lines),VIRTUAL             ! +down / -up, flips pages at the edges
UpdateStatus            PROCEDURE(),VIRTUAL
! ---- search / marks ------------------------------------------------------------
Find                    PROCEDURE(USTRING Needle),LONG,PROC,VIRTUAL   ! fills Hits, returns count
NextHit                 PROCEDURE(SHORT Direction),VIRTUAL
MarkAllHits             PROCEDURE(),VIRTUAL
ClearMarks              PROCEDURE(),VIRTUAL
ToggleMarkAt            PROCEDURE(LONG XPix, LONG YPix),VIRTUAL    ! window pixel -> text item -> mark
TogglePageMark          PROCEDURE(LONG PageNo),VIRTUAL
ItemAt                  PROCEDURE(LONG PageNo, LONG XMils, LONG YMils),LONG,VIRTUAL  ! -> EmfTextQueue pointer or 0
MeasureItem             PROCEDURE(LONG Pointer),VIRTUAL           ! fills TextW
SpanRect                PROCEDURE(LONG Pointer, LONG Start, LONG Length, *EmfMarkQueue M),VIRTUAL
MarkedPageList          PROCEDURE(),STRING,VIRTUAL                ! '1,3,7-9'
! ---- rendering ---------------------------------------------------------------------
RenderPage              PROCEDURE(LONG PageNo, BYTE WithHits, BYTE WithMarks, BYTE ForPrint=0),STRING,VIRTUAL  ! -> rendered file ('' = failed)
LoadMetafile            PROCEDURE(STRING FileName, BYTE IsEMF),LONG,VIRTUAL   ! -> HENHMETAFILE
MeasureText             PROCEDURE(STRING Face, SHORT Size, SHORT Style, USTRING Text, *LONG WidthMils, *LONG HeightMils),VIRTUAL
TempName                PROCEDURE(LONG PageNo),STRING,VIRTUAL
DeleteTemps             PROCEDURE(),VIRTUAL
PrepareMarkedPrint      PROCEDURE(),VIRTUAL                       ! swap marked pages for their rendered twins
! ---- hooks ---------------------------------------------------------------------------
TakeTimer               PROCEDURE(),VIRTUAL                       ! EVENT:Timer on the preview window
TakeWheel               PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix),LONG,VIRTUAL  ! returns 1 when handled
                      END

  _EndOfInclude_
