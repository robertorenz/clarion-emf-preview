#TEMPLATE(EmfPreview,'EMF Unicode Previewer for Clarion 12 Unicode - v1.1'),FAMILY('ABC')
#!----------------------------------------------------------------------------
#! EmfPreview - replaces the ABC PrintPreviewClass with EmfPreviewClass:
#!   page thumbnail sidebar, full text search with highlighted hits, text
#!   marks (marker pen), page marks, zoom / fit modes, mouse wheel, print
#!   marked pages, print with marks.  Reads the .emf pages of a
#!   REPORT,UNICODE (and classic .wmf pages) through the shipped
#!   WMFDocumentParser / IReportGeneratorW wide lane.
#!
#! Requires Clarion 12 Unicode.  Class sources: EmfPreview.inc / EmfPreview.clw
#! (always linked into the module that uses them - no DLL-mode defines, so a
#! leftover reference after removing the template still compiles and runs).
#!----------------------------------------------------------------------------
#!
#!============================================================================
#EXTENSION(EmfPreviewGlobal,'EMF Unicode Previewer - Global (activate)'),APPLICATION,HLP('~EmfPreview.htm')
#!============================================================================
#SHEET
  #TAB('General')
    #DISPLAY(' EMF Unicode Previewer'),AT(3,,190),PROP(PROP:FontColor,0FFFFFFH),PROP(PROP:Color,01F6FEBH)
    #DISPLAY('')
    #PROMPT('&Disable this template',CHECK),%EmfPrvDisable,DEFAULT(0),AT(10)
    #ENABLE(NOT %EmfPrvDisable)
      #PROMPT('&Replace the previewer in every report procedure',CHECK),%EmfPrvReplaceAll,DEFAULT(1),AT(10)
      #DISPLAY('(sets Global Properties > Classes > Report > Print Previewer to')
      #DISPLAY(' EmfPreviewClass - stored in the .app, see the Removing tab; a')
      #DISPLAY(' report can opt out with its own "EMF Unicode Previewer" extension)')
      #DISPLAY('')
      #PROMPT('Show the page &sidebar',CHECK),%EmfPrvSidebar,DEFAULT(1),AT(10)
      #PROMPT('Sidebar &width (pixels):',SPIN(@n4,100,400,10)),%EmfPrvSidebarWidth,DEFAULT(190)
      #PROMPT('Initial &zoom:',DROP('Fit width|Fit page|50%|75%|100%|125%|150%|200%')),%EmfPrvZoom,DEFAULT('Fit width')
      #PROMPT('Left &click on a text line toggles a mark',CHECK),%EmfPrvClickMarks,DEFAULT(1),AT(10)
      #PROMPT('&Print text marks with the pages',CHECK),%EmfPrvPrintMarks,DEFAULT(1),AT(10)
      #PROMPT('Search matches &case by default',CHECK),%EmfPrvMatchCase,DEFAULT(0),AT(10)
      #PROMPT('Mouse wheel &lines:',SPIN(@n2,1,10,1)),%EmfPrvWheelLines,DEFAULT(3)
    #ENDENABLE
  #ENDTAB
  #TAB('Colors')
    #DISPLAY('Colors are COLORREF values (00BBGGRR).')
    #PROMPT('Search &hit highlight:',COLOR),%EmfPrvHighlightColor,DEFAULT(7795199)
    #PROMPT('Text &mark highlight:',COLOR),%EmfPrvMarkColor,DEFAULT(16770725)
    #PROMPT('&Current hit frame:',COLOR),%EmfPrvCurrentColor,DEFAULT(30975)
    #PROMPT('Marked &page frame:',COLOR),%EmfPrvPageMarkColor,DEFAULT(761589)
    #PROMPT('Current page &frame:',COLOR),%EmfPrvAccentColor,DEFAULT(15429407)
    #PROMPT('Page area &background:',COLOR),%EmfPrvPaperShadow,DEFAULT(5854802)
    #PROMPT('&Sidebar background:',COLOR),%EmfPrvSidebarColor,DEFAULT(16118254)
  #ENDTAB
  #TAB('Removing')
    #DISPLAY(' IMPORTANT - read before deleting this extension'),AT(3,,190),PROP(PROP:FontColor,0FFFFFFH),PROP(PROP:Color,00B9EF5H)
    #DISPLAY('')
    #DISPLAY('This extension changes the application''s global class default')
    #DISPLAY('Global Properties > Classes > Report > "Print Previewer" from')
    #DISPLAY('PrintPreviewClass to EmfPreviewClass, and Clarion STORES that')
    #DISPLAY('value in the .app.  If you simply delete the extension the')
    #DISPLAY('reports keep the EmfPreviewClass previewer.')
    #DISPLAY('')
    #DISPLAY('To take the template out cleanly:')
    #DISPLAY('  1. tick "Disable this template" on the General tab,')
    #DISPLAY('  2. generate once - the Print Previewer class is put back')
    #DISPLAY('     to PrintPreviewClass automatically,')
    #DISPLAY('  3. delete the extension and generate again.')
    #DISPLAY('')
    #DISPLAY('Already deleted it?  Set Global Properties > Classes > Report >')
    #DISPLAY('"Print Previewer" back to PrintPreviewClass by hand, then')
    #DISPLAY('generate all.  (Since v1.1 the class is linked into every module')
    #DISPLAY('that uses it, so a leftover reference compiles and runs.)')
  #ENDTAB
#ENDSHEET
#!
#! The class swap is the global ABC "Print Previewer" default class.  It is set
#! for generation and restored to PrintPreviewClass when the template is
#! disabled or the replacement is switched off, so the value the app keeps is
#! always consistent with the extension's settings.
#ATSTART
  #IF(NOT %EmfPrvDisable AND %EmfPrvReplaceAll)
    #SET(%PrintPreviewType,'EmfPreviewClass')
  #ELSIF(%PrintPreviewType = 'EmfPreviewClass')
    #SET(%PrintPreviewType,'PrintPreviewClass')
  #ENDIF
#ENDAT
#!
#AT(%AfterGlobalIncludes),WHERE(NOT %EmfPrvDisable)
  INCLUDE('EmfPreview.INC'),ONCE
#ENDAT
#!
#!============================================================================
#EXTENSION(EmfPreviewer,'EMF Unicode Previewer - Report options'),PROCEDURE,REQ(EmfPreviewGlobal),HLP('~EmfPreview.htm')
#!============================================================================
#RESTRICT
  #IF(UPPER(%ProcedureTemplate) = 'REPORT')
    #ACCEPT
  #ELSE
    #REJECT
  #ENDIF
#ENDRESTRICT
#DISPLAY(' EMF Unicode Previewer'),AT(3,,190),PROP(PROP:FontColor,0FFFFFFH),PROP(PROP:Color,01F6FEBH)
#DISPLAY('')
#DISPLAY('The Previewer object of every report is EmfPreviewClass when the')
#DISPLAY('global extension has "Replace the previewer" on.  Unchecking "Use"')
#DISPLAY('below makes this report fall back to the classic ABC preview window.')
#DISPLAY('')
#PROMPT('&Use the EMF previewer for this report',CHECK),%EmfPrvUse,DEFAULT(1),AT(10)
#ENABLE(%EmfPrvUse)
  #PROMPT('Window &title:',@s80),%EmfPrvTitle,DEFAULT('')
  #DISPLAY('(blank = "Report Preview")')
  #PROMPT('&Override the global options',CHECK),%EmfPrvOverride,DEFAULT(0),AT(10)
  #ENABLE(%EmfPrvOverride)
    #PROMPT('Show the page &sidebar',CHECK),%EmfPrvLSidebar,DEFAULT(1),AT(10)
    #PROMPT('Initial &zoom:',DROP('Fit width|Fit page|50%|75%|100%|125%|150%|200%')),%EmfPrvLZoom,DEFAULT('Fit width')
    #PROMPT('Left &click on a text line toggles a mark',CHECK),%EmfPrvLClickMarks,DEFAULT(1),AT(10)
    #PROMPT('&Print text marks with the pages',CHECK),%EmfPrvLPrintMarks,DEFAULT(1),AT(10)
    #PROMPT('Search matches &case by default',CHECK),%EmfPrvLMatchCase,DEFAULT(0),AT(10)
  #ENDENABLE
#ENDENABLE
#!
#ATSTART
  #DECLARE(%EmfPrvZoomValue)
  #DECLARE(%EmfPrvSidebarValue)
  #DECLARE(%EmfPrvClickValue)
  #DECLARE(%EmfPrvPrintValue)
  #DECLARE(%EmfPrvCaseValue)
  #DECLARE(%EmfPrvZoomText)
  #IF(%EmfPrvOverride)
    #SET(%EmfPrvZoomText,%EmfPrvLZoom)
    #SET(%EmfPrvSidebarValue,%EmfPrvLSidebar)
    #SET(%EmfPrvClickValue,%EmfPrvLClickMarks)
    #SET(%EmfPrvPrintValue,%EmfPrvLPrintMarks)
    #SET(%EmfPrvCaseValue,%EmfPrvLMatchCase)
  #ELSE
    #SET(%EmfPrvZoomText,%EmfPrvZoom)
    #SET(%EmfPrvSidebarValue,%EmfPrvSidebar)
    #SET(%EmfPrvClickValue,%EmfPrvClickMarks)
    #SET(%EmfPrvPrintValue,%EmfPrvPrintMarks)
    #SET(%EmfPrvCaseValue,%EmfPrvMatchCase)
  #ENDIF
  #CASE(%EmfPrvZoomText)
  #OF('Fit width')
    #SET(%EmfPrvZoomValue,'EmfPrv:Zoom:FitWidth')
  #OF('Fit page')
    #SET(%EmfPrvZoomValue,'EmfPrv:Zoom:FitPage')
  #ELSE
    #SET(%EmfPrvZoomValue,SUB(%EmfPrvZoomText,1,LEN(%EmfPrvZoomText)-1))
  #ENDCASE
#ENDAT
#!
#! The report template's Previewer object (%PreviewerObjectName) is an
#! EmfPreviewClass through the global class replacement; this only sets its
#! options.  With "Use" off the object falls back to the classic ABC window.
#AT(%WindowManagerMethodCodeSection,'Init','(),BYTE'),PRIORITY(8490),WHERE(NOT %EmfPrvDisable AND %EmfPrvReplaceAll AND %EnablePrintPreview)
  #IF(%EmfPrvUse)
! EMF Unicode Previewer options
%PreviewerObjectName.ShowSidebar = %EmfPrvSidebarValue
%PreviewerObjectName.SidebarWidth = %EmfPrvSidebarWidth
%PreviewerObjectName.InitialZoom = %EmfPrvZoomValue
%PreviewerObjectName.ClickMarks = %EmfPrvClickValue
%PreviewerObjectName.PrintMarks = %EmfPrvPrintValue
%PreviewerObjectName.SearchMatchCase = %EmfPrvCaseValue
%PreviewerObjectName.WheelLines = %EmfPrvWheelLines
%PreviewerObjectName.HighlightColor = %EmfPrvHighlightColor
%PreviewerObjectName.MarkColor = %EmfPrvMarkColor
%PreviewerObjectName.CurrentColor = %EmfPrvCurrentColor
%PreviewerObjectName.PageMarkColor = %EmfPrvPageMarkColor
%PreviewerObjectName.AccentColor = %EmfPrvAccentColor
%PreviewerObjectName.PaperShadow = %EmfPrvPaperShadow
%PreviewerObjectName.SidebarColor = %EmfPrvSidebarColor
    #IF(%EmfPrvTitle)
%PreviewerObjectName.Title = '%EmfPrvTitle'
    #ENDIF
  #ELSE
! EMF Unicode Previewer: this report uses the classic ABC preview window
%PreviewerObjectName.ClassicMode = True
  #ENDIF
#ENDAT
