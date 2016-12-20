Option Explicit
'ABOUT: This series of subs creates the Data Pack and its supplemental _
files for use in the FY 2017 COP. This sub is run via the RUN button on _
the POPrun tab of the template. The RUN button initiates the generation _
form for choosing the OUs and Data Pack products

'variables
        Public rng As Integer
        Public SelectedOpUnits
        Public OpUnit As Object
        Public OpUnit_ns As String
        Public version As String
        Public view As String
        Public tmplWkbk As Workbook
        Public dataWkbk As Workbook
        Public dpWkbk As Workbook
        Public yldWkbk As Workbook
        Public dstWkbk As Workbook
        Public ou_i As Integer
        Public path As String
        Public file As String
        Public pulls_fldr As String
        Public intr_fldr As String
        Public templ_fldr As String
        Public compl_fldr As String
        Public other_fldr As String
        Public OUpath As String
        Public OUcompl_fldr As String
        Public fname_int As String
        Public fname_dp As String
        Public tbl As ListObject
        Public pvtField As String
        Public pvtField_uid As String
        Public pvtField_ou
        Public LastColumn As Integer
        Public snuLevel As Integer
        Public siteLevel As Integer
        Public snu_unique As Integer
        Public uniqueRng
        Public uniqueTot As Integer
        Public IndicatorCount
        Public celltxt As String
        Public ctgry As String
        Public LastRow As Integer
        Public FirstRow As Integer
        Public EntryIndicatorCount As Integer
        Public i As Integer
        Public sFound As String
        Public sht As Variant
        Public shtNames As Variant
        Public LastSumColumn As Integer
        Public LastRowRC As Integer
        Public indColNum As Integer
        Public indRng As Range
        Public NUM As String
        Public DEN As String
        Public rcNUM As Integer
        Public rcDEN As Integer
        Public colIND As Integer
        Public IND
        Public INDnames
        Public priority
        Public prtype As String
        Public prtycolNum As Integer
        Public tb_val
        Public fname_csd As String
        Public outputFile As String
        Public selectedSNUs
        Public LastColumnDREAMS As Integer
        Public snu
        Public totSNUs
        Public spkGrp As SparklineGroup
        Public FirstColumn As Integer


Sub loadform()
    'prompt for form to load to choose OUs to run
    frmRunSel.Show

End Sub


Sub PopulateDataPack()
    'turn off screen updating
        Application.ScreenUpdating = False
        Debug.Print Application.ScreenUpdating
    'establish OUs on ref sheet
        Sheets("POPref").Activate
        rng = Sheets("POPref").Range("D5").Value + 1
        Set SelectedOpUnits = Sheets("POPref").Range(Cells(2, 6), Cells(rng, 6))
    'setup folders
        Call fldrSetup
    'define template workbook
        Set tmplWkbk = ActiveWorkbook
    ' whether to view or just store change forms
        view = Sheets("POPref").Range("D11")

    'loop over opunit
    ou_i = 2 ' count used to lookup SNU level for each OU (row #)

    For Each OpUnit In SelectedOpUnits

        'remove space and comma for file saving (ns = no space)
        OpUnit_ns = Replace(Replace(OpUnit, " ", ""), "'", "")
        'create OU specific folder
        OUpath = compl_fldr & OpUnit_ns & VBA.format(Now, "yyyy.mm.dd")
        If Len(Dir(OUpath, vbDirectory)) = 0 Then MkDir OUpath
        OUcompl_fldr = OUpath & "\"

        'run through all subs
        Call Initialize
        Call getData
        Call formatTable
        Call yieldFormulas
        Call setupSNUs
        Call setupHTCDistro
        Call lookupsumFormulas
        Call sparkTrends
        shtNames = Array("Indicator Table", "Entry Table", "HTC Data Entry", _
            "Summary & Targets", "IM Targeting Output", "Key Ind Trends")
        Call format
        Call formatHeaders
        Call showChanges
        shtNames = Array("Entry Table", "Summary & Targets", "HTC Data Entry", _
            "IM Targeting Output", "Key Ind Trends")
        Call filters
        Call dimDefault
        Call updateOutput
        Call saveFile
        Call imTargeting

        'keep data pack open?
        If view = "No" Then
            dstWkbk.Close
            dpWkbk.Close
        End If

        'Zip output folder
        If tmplWkbk.Sheets("POPref").Range("D14").Value = "Yes" Then
            Call Zip_All_Files_in_Folder
        End If

        ou_i = ou_i + 1 'row for OU in POPref

    Next

    'close global dataset
     dataWkbk.Close

End Sub


Sub fldrSetup()
    'for saving/opening:
        'set path
            If Sheets("POPref").Range("D17").Value = 0 Then
                'browse to folder
                    MsgBox "Browse to the DataPack folder.", vbInformation, "Find DataPack"
                    With Application.FileDialog(msoFileDialogFolderPicker)
                        .AllowMultiSelect = False
                        .Show
                        On Error Resume Next
                        path = .SelectedItems(1) & "\"
                        Err.Clear
                        On Error GoTo 0
                    End With
                'if no folder select, end sub
                    If Len(path) = 0 Then End
                'ask user if file location is correct; end if not
                    If MsgBox(path & vbCr & "Is this the location?", vbYesNo) = vbNo Then End
                'add path
                    Sheets("POPref").Range("D17").Value = path
            Else
                path = Sheets("POPref").Range("D17").Value
            End If
        ' set folder directory
            pulls_fldr = path & "DataPulls\"
            templ_fldr = path & "TemplateGeneration\"
            compl_fldr = path & "CompletedDataPacks\"
            other_fldr = path & "OtherInfo\"
        'set directory initially to the pulls folder
            ChDir (path)
End Sub

Sub Initialize()
    'snu & site level for OU
        tmplWkbk.Sheets("POPref").Activate
    'create datapack file for OU (copy sheets over to new book)
        tmplWkbk.Activate
        Sheets(Array("Home", "Entry Table", "Summary & Targets", "Indicator Table", "HTC Data Entry", "Key Ind Trends", "PBAC Output", "IM Targeting Output", "Change Form")).Copy
        Set dpWkbk = ActiveWorkbook
        ActiveWorkbook.Theme.ThemeColorScheme.Load (other_fldr & "Adjacency.xml")
    'hard code update date into home tab & insert OU name
       Sheets("Home").Range("N1").Select
       Range("N1").Copy
       Selection.PasteSpecial Paste:=xlPasteValues
       Range("O1").Value = OpUnit
       Range("AA1").Select
    'Open data file file
        Workbooks.OpenText Filename:=pulls_fldr & "Global_PSNU_*.xlsx"
        Sheets("Indicator Table").Activate
       Set dataWkbk = ActiveWorkbook

End Sub

Sub getData()
    'make sure file with data is activate
        dataWkbk.Activate
        Sheets("Indicator Table").Activate
    ' find the last column
        LastColumn = Range("A1").CurrentRegion.Columns.Count
    'copy variable names
        Range(Cells(1, 2), Cells(1, LastColumn)).Select
    'copy the data and paste in the data pack
        Selection.Copy
        dpWkbk.Activate
        Sheets("Indicator Table").Activate
        Range("B4").Select
        Selection.PasteSpecial Paste:=xlPasteValues
    'copy formula to look up variable title
        Range("E3").Copy
        Range(Cells(3, 6), Cells(3, LastColumn)).Select
        ActiveSheet.Paste
        Application.CutCopyMode = False
    'hard copy
        Range(Cells(3, 5), Cells(3, LastColumn)).Select
        Selection.Copy
        Selection.PasteSpecial Paste:=xlPasteValues
        Application.CutCopyMode = False
    'find first and last row of OU
        dataWkbk.Activate
        FirstRow = Range("A:A").Find(what:=OpUnit, After:=Range("A1")).Row
        LastRow = Range("A:A").Find(what:=OpUnit, After:=Range("A1"), searchdirection:=xlPrevious).Row
    'how many SNUs?
        uniqueTot = LastRow - FirstRow + 1
        dpWkbk.Names.Add Name:="snu_unique", RefersToR1C1:=uniqueTot
    ' find the last column
        LastColumn = Range("A1").CurrentRegion.Columns.Count
    'select OU data from global file to copy to data pack
        Range(Cells(FirstRow, 2), Cells(LastRow, LastColumn)).Select
    'copy the data and paste in the data pack
        Selection.Copy
        dpWkbk.Activate
        Sheets("Indicator Table").Activate
        Range("B7").Select
        Selection.PasteSpecial Paste:=xlPasteValues

    'get quarterly data for trends tab
        dataWkbk.Activate
        Sheets("Key Ind Trends").Activate
    'find the last column
        LastColumn = Range("A1").CurrentRegion.Columns.Count
    'find first and last row of OU
        FirstRow = Range("A:A").Find(what:=OpUnit, After:=Range("A1")).Row
        LastRow = Range("A:A").Find(what:=OpUnit, After:=Range("A1"), searchdirection:=xlPrevious).Row
    'select OU data from global file to copy to data pack
        Range(Cells(FirstRow, 4), Cells(LastRow, LastColumn)).Select
    'copy the data and paste in the data pack
        Selection.Copy
        dpWkbk.Activate
        Sheets("Key Ind Trends").Activate
        Range("C7").Select
        Selection.PasteSpecial Paste:=xlPasteValues
        Selection.NumberFormat = "#,##0"
End Sub

Sub formatTable()
    'indicator table
         Sheets("Indicator Table").Activate
    'find last row and column
        LastColumn = Range("C4").CurrentRegion.Columns.Count
        LastRow = uniqueTot + 6
    'format numbers (eg 10,000)
        Range(Cells(5, 5), Cells(LastRow, LastColumn)).Select
        Selection.NumberFormat = "#,##0"
    'add total to table
        Range(Cells(5, 2), Cells(5, LastColumn)).Select
        Range("C5").Select
        ActiveCell.Value = "Total"
        Range(Cells(5, 5), Cells(5, LastColumn)).Select
        With Selection
            .Formula = "=SUBTOTAL(109, E6:E" & LastRow & ")"
            .NumberFormat = "#,##0"
        End With
    'format prevention (eg 10.2) and delete total
        colIND = WorksheetFunction.Match("prevalence_num", dpWkbk.Sheets("Indicator Table").Range("4:4"), 0)
        Cells(5, colIND).Value = ""
        Range(Cells(5, colIND), Cells(LastRow, colIND)).Select
        Selection.NumberFormat = "#,##0.0"
    'add filter row
        Range(Cells(6, 2), Cells(6, LastColumn)).Select
        Range(Cells(6, 3), Cells(6, LastColumn)).Select
        With Selection.Interior
            .Pattern = xlSolid
            .PatternColorIndex = xlAutomatic
            .ThemeColor = xlThemeColorAccent4
            .TintAndShade = 0.399975585192419
            .PatternTintAndShade = 0
        End With
        Range(Cells(6, 3), Cells(LastRow, LastColumn)).Select
        Selection.AutoFilter
        Range("C6").Select
        With Selection
            .FormulaR1C1 = "Filter Row"
            .NumberFormat = ";;;"
        End With
    'wrap headers in table
        Range(Cells(3, 4), Cells(3, LastRow)).WrapText = True
    'add data validation for prioritization
        Range(Cells(7, 4), Cells(LastRow, 4)).Select
        Selection.Validation.Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, Operator:= _
            xlBetween, Formula1:="ScaleUp Sat, ScaleUp Agg, Sustained, Ctrl Supported, Sustained Com, Attained, NOT DEFINED, Mil"
    'add named ranges
        Range(Cells(4, 3), Cells(LastRow, LastColumn)).Select
        Application.DisplayAlerts = False
        Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
        Application.DisplayAlerts = True

End Sub

Sub yieldFormulas()
    'add in formulas for yields
        INDnames = Array("pmtct_eid_yield", "pmtct_stat_yield", "tb_stat_yield", "tx_ret_yield", "tx_ret_u15_yield", "htc_tst_u15_yield", "pre_art_yield", "pre_art_u15_yield", "htc_tst_spd_tot_pos")
        For Each IND In INDnames
            If IND = "pmtct_eid_yield" Then
                NUM = "pmtct_eid_pos_12mo"
                DEN = "pmtct_eid_12mo"
            ElseIf IND = "pmtct_stat_yield" Then
                NUM = "pmtct_stat_pos"
                DEN = "pmtct_stat_D"
            ElseIf IND = "tb_stat_yield" Then
                NUM = "tb_stat_pos"
                DEN = "tb_stat"
            ElseIf IND = "tx_ret_yield" Then
                NUM = "tx_ret"
                DEN = "tx_ret_D"
            ElseIf IND = "tx_ret_u15_yield" Then
                NUM = "tx_ret_u15"
                DEN = "tx_ret_u15_D"
            ElseIf IND = "htc_tst_u15_yield" Then
                NUM = "htc_tst_u15_pos"
                DEN = "htc_tst_u15"
            ElseIf IND = "pre_art_yield" Then
                NUM = "tx_curr"
                DEN = "care_curr"
            ElseIf IND = "pre_art_u15_yield" Then
                NUM = "tx_curr_u15"
                DEN = "care_curr_u15"
            ElseIf IND = "htc_tst_spd_tot_pos" Then
                NUM = "htc_tst_spd_tot_pos"
                DEN = "htc_tst_spd_tot_pos"
            Else
            End If
            colIND = WorksheetFunction.Match(IND, ActiveWorkbook.Sheets("Indicator Table").Range("4:4"), 0)
            rcNUM = WorksheetFunction.Match(NUM, ActiveWorkbook.Sheets("Indicator Table").Range("4:4"), 0) - colIND
            rcDEN = WorksheetFunction.Match(DEN, ActiveWorkbook.Sheets("Indicator Table").Range("4:4"), 0) - colIND
            If IND = "pmtct_eid_yield" Then
                Cells(5, colIND).FormulaR1C1 = "=IFERROR((RC[" & rcNUM & "]+RC[" & rcNUM - 1 & "])/ (RC[" & rcDEN & "]+RC[" & rcDEN + 2 & "]),"""")"
            ElseIf IND = "pre_art_yield" Or IND = "pre_art_u15_yield" Then
                Cells(5, colIND).FormulaR1C1 = "=IFERROR(IF(RC[" & rcDEN & "] - RC[" & rcNUM & "]<0,0,(RC[" & rcDEN & "] - RC[" & rcNUM & "])/ RC[" & rcDEN & "]),0)"
            ElseIf IND = "htc_tst_spd_tot_pos" Then
                rcNUM = 1 - Application.WorksheetFunction.CountIf(Range("4:4"), "htc_tst_spd*_pos")
                Cells(5, colIND).FormulaR1C1 = "=SUM(RC[" & rcNUM & "]:RC[-1])"
            Else
                Cells(5, colIND).FormulaR1C1 = "=IFERROR(RC[" & rcNUM & "]/ RC[" & rcDEN & "],"""")"
            End If
            If IND <> "htc_tst_spd_tot_pos" Then Cells(5, colIND).NumberFormat = "0.0%"
            Cells(5, colIND).Copy
            Range(Cells(7, colIND), Cells(LastRow, colIND)).Select
            ActiveSheet.Paste
        Next IND

    'add formula to count total positives in the indicator table


End Sub

Sub setupSNUs()
    'add SNU list to summary and targets and IM targeting tab
        shtNames = Array("Summary & Targets", "IM Targeting Output")
        For Each sht In shtNames
            Sheets(sht).Activate
            Range(Cells(5, 3), Cells(LastRow, 3)).FormulaR1C1 = "='Indicator Table'!RC"
            Range(Cells(4, 3), Cells(LastRow, 3)).Select
            Application.DisplayAlerts = False
            Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
            Application.DisplayAlerts = False
            Columns("C:C").ColumnWidth = 20.75
        Next sht
    'add SNU list, copy default values, and add named range to Entry Table tab
        Sheets("Entry Table").Activate
        EntryIndicatorCount = Range("A2").CurrentRegion.Columns.Count
        Range(Cells(6, 3), Cells(LastRow, 3)).FormulaR1C1 = "='Indicator Table'!RC"
        Range(Cells(7, 4), Cells(7, EntryIndicatorCount)).Select
        Selection.Copy
        Range(Cells(7, 4), Cells(LastRow, EntryIndicatorCount)).Select
        ActiveSheet.Paste
        Range(Cells(4, 3), Cells(LastRow, EntryIndicatorCount)).Select
        Application.DisplayAlerts = False
        Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
        Application.DisplayAlerts = False
        Columns("C:C").ColumnWidth = 20.75
        Range(Cells(4, 3), Cells(LastRow, EntryIndicatorCount)).Select

End Sub
Sub setupHTCDistro()
    'add SNU list to HTC distro tab
        Sheets("HTC Data Entry").Activate
        Range(Cells(5, 3), Cells(LastRow, 3)).FormulaR1C1 = "='Indicator Table'!RC"
        Range(Cells(4, 3), Cells(LastRow, 3)).Select
        Application.DisplayAlerts = False
        Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
        Application.DisplayAlerts = False
        Columns("C:C").ColumnWidth = 20.75
    'add total for ART to HTC distro tab
        Sheets("HTC Data Entry").Activate
        For i = 5 To 12
            If i = 9 Then i = i + 1
            Cells(5, i).FormulaR1C1 = "=SUBTOTAL(109, R[2]C:R[" & LastRow - 5 & "]C)"
        Next i

    'add in extra named ranges
        Sheets("HTC Data Entry").Activate
        Set indRng = Sheets("HTC Data Entry").Range(Cells(5, 5), Cells(LastRow, 5))
        ActiveWorkbook.Names.Add Name:="T_htc_need", RefersTo:=indRng
        Sheets("Summary & Targets").Activate
        indColNum = WorksheetFunction.Match("New on Treatment from other modalities", ActiveWorkbook.Sheets("Summary & Targets").Range("4:4"), 0)
        Set indRng = Sheets("Summary & Targets").Range(Cells(5, indColNum), Cells(LastRow, indColNum))
        ActiveWorkbook.Names.Add Name:="T_pos_ident", RefersTo:=indRng
        indColNum = WorksheetFunction.Match("FY18 Target TX_NEW <15", ActiveWorkbook.Sheets("Summary & Targets").Range("4:4"), 0)
        Set indRng = Sheets("Summary & Targets").Range(Cells(5, indColNum), Cells(LastRow, indColNum))
        ActiveWorkbook.Names.Add Name:="T_ped_treat", RefersTo:=indRng
End Sub

Sub lookupsumFormulas()
    Dim colStart As Integer
    'copy lookup formulas to all SNUs
        shtNames = Array("HTC Data Entry", "Summary & Targets", "IM Targeting Output")
        For Each sht In shtNames
            Sheets(sht).Select
            LastColumn = Sheets(sht).Range("A2").CurrentRegion.Columns.Count
            Range(Cells(7, 4), Cells(7, LastColumn)).Select
            Selection.Copy
            Range(Cells(8, 4), Cells(LastRow, LastColumn)).Select
            Selection.PasteSpecial Paste:=xlPasteFormulasAndNumberFormats
            Application.CutCopyMode = False
        Next sht
    'add formula to totals
        shtNames = Array("HTC Data Entry", "Summary & Targets", "IM Targeting Output", "Key Ind Trends")
        LastRowRC = LastRow - 5
        For Each sht In shtNames
            Sheets(sht).Select
            LastColumn = Sheets(sht).Range("A2").CurrentRegion.Columns.Count
            If sht = "Summary & Targets" Then
                colStart = 6
            Else
                colStart = 4
            End If
            For i = colStart To LastColumn
                If ActiveSheet.Cells(4, i).Value <> "" Then
                    Cells(5, i).Select
                    Selection.FormulaR1C1 = "=SUBTOTAL(109, R[1]C:R[" & LastRowRC & "]C)"
                    Selection.NumberFormat = "#,##0"
                End If
                If ActiveSheet.Cells(7, i).Style = "Percent" Then Cells(5, i).Value = ""
                If ActiveSheet.Cells(4, i).Value = "ART Coverage" Or ActiveSheet.Cells(4, i).Value = "ART Coverage (<15)" Then
                   Cells(7, i).Copy
                   Cells(5, i).Select
                   ActiveSheet.Paste
                End If

            Next i
        Next sht
End Sub

Sub sparkTrends()
    'tends sheet
        Sheets("Key Ind Trends").Activate
    'add named range for snulist
        Range(Cells(4, 3), Cells(LastRow, 3)).Select
        Application.DisplayAlerts = False
        Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
        Application.DisplayAlerts = True
    'delete subtotal for prioritization SNUs
        LastColumn = ActiveSheet.Range("A2").CurrentRegion.Columns.Count
        For i = 4 To LastColumn
            Cells(5, i).ClearContents
            i = i + 7
        Next i
    'add in formula to lookup prioritization
        Range(Cells(7, 4), Cells(LastRow, 4)).Select
        Selection.FormulaR1C1 = "=IFERROR(INDEX(priority_snu,MATCH(snu_qtr,snulist,0)),"""")"
     'add sparklines
         Set spkGrp = Range("L7").SparklineGroups.Add(Type:=xlSparkLine, SourceData:="F7:K7")
         With spkGrp.SeriesColor
             .ThemeColor = 9
             '.TintAndShade = -0.249977111117893
         End With
         With spkGrp.Points.Markers
             .Visible = True
             .Color.ThemeColor = 9
             '.TintAndShade = -0.249977111117893
         End With
         Range("L7").Copy

        For i = 12 To 44
             Cells(5, i).Select
             ActiveSheet.Paste
             Range(Cells(7, i), Cells(LastRow, i)).Select
             ActiveSheet.Paste
             i = i + 7
         Next i

End Sub
Sub format()
    'format
        For Each sht In shtNames
        Sheets(sht).Select
        If sht = "IM Distribution" Or sht = "IM PBAC Targets" Then
            LastRow = Range("C1").CurrentRegion.Rows.Count
            End If
        LastColumn = Sheets(sht).Range("A2").CurrentRegion.Columns.Count
        'format - color Navigation pane (column A)
            Range(Cells(5, 1), Cells(LastRow, 1)).Select
            With Selection.Interior
                .Pattern = xlSolid
                .PatternColorIndex = xlAutomatic
                .ThemeColor = xlThemeColorAccent4
                .TintAndShade = 0.399975585192419
                .PatternTintAndShade = 0
            End With
        'format - indented SNUs
            Range(Cells(6, 3), Cells(LastRow, 3)).Select
            Selection.IndentLevel = 1
        'format - banded rows
            With Range(Cells(7, 3), Cells(LastRow, LastColumn))
                .Activate
                .FormatConditions.Add xlExpression, Formula1:="=AND($C7<>"""",C$4<>"""",MOD(ROW(),2)=0)"
                With .FormatConditions(1).Interior
                    .Pattern = xlSolid
                    .PatternColorIndex = xlAutomatic
                    .ThemeColor = xlThemeColorAccent4
                    .TintAndShade = 0.799981688894314
                    .PatternTintAndShade = 0
                End With
            End With
            Range("A1").Select
        Next sht
End Sub

Sub formatHeaders()
    'format - color headers on indicator table
        Sheets("Indicator Table").Select
        IndicatorCount = Range("A4").CurrentRegion.Columns.Count 'find last column
        Range(Cells(3, 4), Cells(3, IndicatorCount)).Select
        With Selection.Interior
            .Pattern = xlSolid
            .PatternColorIndex = xlAutomatic
            .ThemeColor = xlThemeColorAccent2
            .TintAndShade = 0
            .PatternTintAndShade = 0
        End With
        Range(Cells(4, 4), Cells(4, IndicatorCount)).Select
        With Selection.Interior
            .Pattern = xlSolid
            .PatternColorIndex = xlAutomatic
            .ThemeColor = xlThemeColorAccent2
            .TintAndShade = 0.399975585192419
            .PatternTintAndShade = 0
        End With

End Sub

Sub showChanges()
    'add conditional formatting to identify changes in table
        shtNames = Array("HTC Data Entry", "Entry Table", "Indicator Table")
        For Each sht In shtNames
            Sheets(sht).Select
            Sheets(sht).Copy After:=Sheets(sht)
            If sht = "HTC Data Entry" Then Sheets(sht & " (2)").Name = "dupHTCdistTable"
            If sht = "Entry Table" Then Sheets(sht & " (2)").Name = "dupEntryTable"
            If sht = "Indicator Table" Then Sheets(sht & " (2)").Name = "dupTable"
            LastColumn = Sheets(sht).Range("A2").CurrentRegion.Columns.Count
            Range(Cells(3, 4), Cells(LastRow, LastColumn)).Select
            If sht <> "HTC Data Entry" Then
                Selection.Copy
                Selection.PasteSpecial Paste:=xlPasteValues
            End If
            Range("A1").Select
            Sheets(sht).Select
            Range("C5").Select
            If sht = "HTC Data Entry" Then
                Range(Cells(5, 19), Cells(LastRow, LastColumn)).Select
            Else
                Range(Cells(5, 4), Cells(LastRow, LastColumn)).Select
            End If
            If sht <> "Entry Table" Then
                With Selection
                    .Activate
                    If sht = "HTC Data Entry" Then .FormatConditions.Add xlExpression, Formula1:="=S5<>dupHTCdistTable!S5"
                    If sht = "Indicator Table" Then .FormatConditions.Add xlExpression, Formula1:="=D5<>dupTable!D5"
                    .FormatConditions(2).Interior.ThemeColor = xlThemeColorAccent3
                    .FormatConditions(2).priority = 1
                End With
            End If
            Range("C3").Select
        Next sht
    'hide duplicates
        Sheets(Array("dupTable", "dupEntryTable", "dupHTCdistTable")).Visible = False
End Sub

Sub filters()
    'add filter rows
        For Each sht In shtNames
            Sheets(sht).Select
            IndicatorCount = Range("A2").CurrentRegion.Columns.Count
            Range(Cells(6, 3), Cells(6, IndicatorCount)).Select
                With Selection.Interior
                    .Pattern = xlSolid
                    .PatternColorIndex = xlAutomatic
                    .ThemeColor = xlThemeColorAccent4
                    .TintAndShade = 0.399975585192419
                    .PatternTintAndShade = 0
                End With
                Range(Cells(6, 3), Cells(LastRow, IndicatorCount)).Select
                Selection.AutoFilter
                Range("C6").NumberFormat = ";;;"
                Range("D1").Select
        Next sht
End Sub

Sub dimDefault()

    'conditional formatting - hide if manual entry values equal default
        Sheets("Entry Table").Select
        IndicatorCount = Range("A2").CurrentRegion.Columns.Count
        Range(Cells(7, 6), Cells(LastRow, IndicatorCount)).Select
        With Selection
            .Activate
            .FormatConditions.Add xlExpression, Formula1:="=OR(F7=F$5,AND(F$5="""",F7=dupEntryTable!F7))"
            .FormatConditions(2).Font.ThemeColor = xlThemeColorDark1
            .FormatConditions(2).Font.TintAndShade = -0.499984740745262
            .FormatConditions(2).Interior.Pattern = xlNone
            .FormatConditions(2).Interior.TintAndShade = 0
            .FormatConditions(2).Interior.PatternTintAndShade = 0
            .FormatConditions(2).priority = 1
        End With
        With Range(Cells(7, 6), Cells(LastRow, IndicatorCount))
            .Activate
            .FormatConditions.Add xlExpression, Formula1:="=OR(AND(F7=F$5,MOD(ROW(),2)=0),AND(F$5="""",F7=dupEntryTable!F7,MOD(ROW(),2)=0))"
            With .FormatConditions(3).Font
                .ThemeColor = xlThemeColorDark1
                .TintAndShade = -0.499984740745262
            End With
            With .FormatConditions(3).Interior
                .Pattern = xlSolid
                .PatternColorIndex = xlAutomatic
                .ThemeColor = xlThemeColorAccent4
                .TintAndShade = 0.799981688894314
                .PatternTintAndShade = 0
            End With
            .FormatConditions(3).priority = 1
        End With
        Range("B1").Select
End Sub

Sub updateOutput()
'update formula with last row in PBAC output (formulas with cell references
    Dim r As Integer
    'loop over columns, check for formula, then loop over rows
        Sheets("PBAC Output").Activate
        LastColumn = Range("A2").CurrentRegion.Columns.Count
        For i = 11 To LastColumn
        If Len(Trim(Cells(5, i).Value)) > 0 Then
            For r = 5 To 11
                celltxt = ActiveSheet.Cells(r, i).Formula
                celltxt = Replace(celltxt, "20", LastRow)
                Cells(r, i).Formula = celltxt
            Next r
        End If
        Next i

'update IM targeting output
    'loop over columns, check for formula, then loop over rows
     Sheets("IM Targeting Output").Activate
     LastColumn = Range("A2").CurrentRegion.Columns.Count
        For i = 5 To LastColumn
        If Len(Trim(Cells(7, i).Value)) > 0 Then
            celltxt = ActiveSheet.Cells(7, i).Formula
            celltxt = Replace(celltxt, "20", LastRow)
            Cells(7, i).Formula = celltxt
        End If
        Next i
    Range(Cells(7, 4), Cells(7, LastColumn)).Copy
    Range(Cells(8, 4), Cells(LastRow, LastColumn)).Select
    ActiveSheet.Paste
    Application.CutCopyMode = False

End Sub

Sub saveFile()
    'save
        Sheets("Home").Activate
        Range("X1").Select
        fname_dp = OUcompl_fldr & OpUnit_ns & "COP17DataPack" & "v" & VBA.format(Now, "yyyy.mm.dd") & ".xlsx"
        Application.DisplayAlerts = False
        ActiveWorkbook.SaveAs fname_dp

        Application.DisplayAlerts = True
End Sub

Sub imTargeting()

    'copy IM output from datapack
        dpWkbk.Activate
        Sheets(Array("Home", "IM Targeting Output")).Copy

    'save and then name active sheet
        fname_dp = OUcompl_fldr & OpUnit_ns & "COP17IMTargeting" & "v" & VBA.format(Now, "yyyy.mm.dd") & ".xlsx"
        Application.DisplayAlerts = False
        ActiveWorkbook.SaveAs fname_dp
        Application.DisplayAlerts = True
        Set dstWkbk = ActiveWorkbook
    'change theme
        ActiveWorkbook.Theme.ThemeColorScheme.Load (other_fldr & "Adjacency.xml")
    'change name on home tab
        Sheets("Home").Activate
        Range("P1").Value = "IM TARGETING APPENDIX"
    'hard copy data from workbook
        Sheets("IM Targeting Output").Activate
        LastColumn = Range("B1").CurrentRegion.Columns.Count
        LastRow = Range("C1").CurrentRegion.Rows.Count
        Range(Cells(7, 3), Cells(LastRow, LastColumn)).Select
        Selection.Copy
        Selection.PasteSpecial Paste:=xlPasteValues
        Application.CutCopyMode = False
    'remove named ranges from data pack
        Dim nr As Name
        On Error Resume Next
        For Each nr In ActiveWorkbook.Names
            nr.Delete
        Next
        On Error GoTo 0
    'setup named range for im targeting tab
        Sheets("IM Targeting Output").Activate
        Range(Cells(4, 3), Cells(LastRow, LastColumn)).Select
        Application.DisplayAlerts = False
        Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
        Application.DisplayAlerts = True

    'copy tabs from template workbook
        Application.DisplayAlerts = False
        tmplWkbk.Sheets(Array("IM Distribution", "IM PBAC Targets")).Copy After:=dstWkbk.Sheets(2)
        Application.DisplayAlerts = True
    'loop over each sheet, adding in data from global_psnu
        shtNames = Array("IM Distribution", "IM PBAC Targets")
        For Each sht In shtNames
                Sheets(sht).Activate
            'find OU coordinates in IM list
                dataWkbk.Sheets(sht).Activate
                FirstRow = Range("A:A").Find(what:=OpUnit, After:=Range("A1")).Row
                LastRow = Range("A:A").Find(what:=OpUnit, After:=Range("A1"), searchdirection:=xlPrevious).Row
                LastColumn = Range("A1").CurrentRegion.Columns.Count
                If sht = "IM Distribution" Then
                    FirstColumn = 3
                Else
                    FirstColumn = 2
                End If
            'select OU data from global file to copy to data pack
                Range(Cells(FirstRow, FirstColumn), Cells(LastRow, LastColumn)).Select
                Selection.Copy
            'copy the data and paste in the data pack
                dstWkbk.Activate
                Sheets(sht).Activate
                Range("C7").Select
                Selection.PasteSpecial Paste:=xlPasteValues
                Application.CutCopyMode = False
        Next sht

    'setup/format IM distro tab
        Sheets("IM Distribution").Activate
        LastRow = Range("C1").CurrentRegion.Rows.Count
        Range(Cells(5, 6), Cells(LastRow, 23)).Select
        'format to hide zeros
        Selection.NumberFormat = "0%;-0%;;"
        LastColumn = Range("B2").CurrentRegion.Columns.Count 'TOFIX
        Range(Cells(5, 24), Cells(LastRow, LastColumn)).Select
        Selection.NumberFormat = "#,##0;-#,##0;;"
        'named range
        Range(Cells(4, 3), Cells(LastRow, LastColumn)).Select
        Application.DisplayAlerts = False
        Selection.CreateNames Top:=True, Left:=False, Bottom:=False, Right:=False
        Application.DisplayAlerts = True
        'copy formulas down for target allocation
        Range(Cells(7, 24), Cells(7, LastColumn)).Select
        Selection.Copy
        Range(Cells(8, 24), Cells(LastRow, LastColumn)).Select
        Selection.PasteSpecial Paste:=xlPasteFormulasAndNumberFormats
        Application.CutCopyMode = False
        'add total
        Range(Cells(5, 6), Cells(5, LastColumn)).Select
        Selection.Formula = "=SUBTOTAL(109, E6:E" & LastRow & ")"


    'setup/format targeting tab
        Sheets("IM PBAC Targets").Activate
        LastRow = Range("C1").CurrentRegion.Columns.Count
        LastColumn = Range("B1").CurrentRegion.Columns.Count
        'add named range
        Set indRng = Sheets("IM PBAC Targets").Range(Cells(5, 4), Cells(LastRow, 4))
        ActiveWorkbook.Names.Add Name:="P_mechid", RefersTo:=indRng
        Set indRng = Sheets("IM PBAC Targets").Range(Cells(4, 6), Cells(4, LastColumn))
        ActiveWorkbook.Names.Add Name:="P_indtype", RefersTo:=indRng
        'copy formula from first row down
        Range(Cells(7, 6), Cells(7, LastColumn)).Select
        Selection.NumberFormat = "#,##0;-#,##0;;"
        Selection.Copy
        Range(Cells(8, 6), Cells(LastRow, LastColumn)).Select
        Selection.PasteSpecial Paste:=xlPasteFormulasAndNumberFormats
        Application.CutCopyMode = False
        'add total
        Range(Cells(5, 6), Cells(5, LastColumn)).Select
        Selection.Formula = "=SUBTOTAL(109, E6:E" & LastRow & ")"

    'format
      shtNames = Array("IM Distribution", "IM PBAC Targets")
      Call format
      Call filters

    'save
        Sheets("Home").Activate
        Range("X1").Select
        fname_dp = OUcompl_fldr & OpUnit_ns & "COP17IMTargeting" & "v" & VBA.format(Now, "yyyy.mm.dd") & ".xlsx"
        Application.DisplayAlerts = False
        ActiveWorkbook.SaveAs fname_dp

End Sub

''''''''''''''''''''
''   Zip Folder   ''
''''''''''''''''''''
'Source: http://www.rondebruin.nl/win/s7/win001.htm

Sub Zip_All_Files_in_Folder()
'ABOUT: This sub zips the OU folder that contains the _
data pack and its supplementary files"

    Dim FileNameZip, FolderName
    Dim strDate As String, DefPath As String
    Dim oApp As Object

        DefPath = compl_fldr
        If Right(DefPath, 1) <> "\" Then
            DefPath = DefPath & "\"
        End If

        FolderName = OUcompl_fldr

        strDate = VBA.format(Now, "yyyy.mm.dd")
        FileNameZip = DefPath & OpUnit_ns & strDate & ".zip"

    'Create empty Zip File
        NewZip (FileNameZip)

        Set oApp = CreateObject("Shell.Application")
    'Copy the files to the compressed folder
        oApp.Namespace(FileNameZip).CopyHere oApp.Namespace(FolderName).items

    'Keep script waiting until Compressing is done
        On Error Resume Next
        Do Until oApp.Namespace(FileNameZip).items.Count = _
           oApp.Namespace(FolderName).items.Count
            Application.Wait (Now + TimeValue("0:00:01"))
        Loop
        On Error GoTo 0


End Sub

Sub NewZip(sPath)
    'Create empty Zip File
    'Changed by keepITcool Dec-12-2005
    If Len(Dir(sPath)) > 0 Then Kill sPath
        Open sPath For Output As #1
    Print #1, Chr$(80) & Chr$(75) & Chr$(5) & Chr$(6) & String(18, 0)
    Close #1
End Sub


Function bIsBookOpen(ByRef szBookName As String) As Boolean
    ' Rob Bovey
    On Error Resume Next
    bIsBookOpen = Not (Application.Workbooks(szBookName) Is Nothing)
End Function


Function Split97(sStr As Variant, sdelim As String) As Variant
    'Tom Ogilvy
    Split97 = Evaluate("{""" & _
    Application.Substitute(sStr, sdelim, """,""") & """}")
End Function
