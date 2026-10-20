unit Ft.Widget.Tables;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math, Types,
  Floria.Image.Core, Ft.Canvas, Floria.Font, Ft.Widget, Ft.Widget.Containers, Ft.Widget.ScrollBars, Ft.Widget.Texts, Ft.Theme, Ft.Css;

type
  TFtTextAlign = TFtTextAlignment;
  TFtSortOrder = (soNone, soAscending, soDescending);

  TFtTableColumn = class
  public
    Title: string;
    Width: Double;
    Alignment: TFtTextAlign;
    SortOrder: TFtSortOrder;
    Icon: TFloriaImage;
    Resizable: Boolean;
    MinWidth: Double;
    MaxWidth: Double;
    constructor Create(const ATitle: string; AWidth: Double = 100.0; AAlign: TFtTextAlign = taLeft);
  end;

  TFtTableRow = class
  private
    FCellIcons: TFPList; // TFloriaImage
    FSelected: Boolean;
  public
    Cells: TStringList;
    Tag: Integer;
    Data: Pointer;
    constructor Create();
    destructor Destroy(); override;
    procedure SetCellIcon(ACol: Integer; AIcon: TFloriaImage);
    function GetCellIcon(ACol: Integer): TFloriaImage;
    property Selected: Boolean read FSelected write FSelected;
  end;

  TFtTableRowSelectEvent = procedure(Sender: TObject; RowIndex: Integer) of object;
  TFtTableColumnClickEvent = procedure(Sender: TObject; ColumnIndex: Integer) of object;
  TFtTableColumnResizeEvent = procedure(Sender: TObject; ColumnIndex: Integer; NewWidth: Double) of object;
  TFtTableRowSelectCallback = procedure(Sender: Pointer; RowIndex: Integer; UserData: Pointer); cdecl;
  TFtTableColumnResizeCallback = procedure(Sender: Pointer; ColumnIndex: Integer; NewWidth: Double; UserData: Pointer); cdecl;
  TFtTableRowDoubleClickEvent = procedure(Sender: TObject; RowIndex: Integer) of object;
  TFtTableRowDoubleClickCallback = procedure(Sender: Pointer; RowIndex: Integer; UserData: Pointer); cdecl;

  TFtTableDrawHeaderEvent = function(Sender: TObject; Canvas: TFtCanvas; ColumnIndex: Integer;
    AX, AY, AW, AH: Double; ASortOrder: TFtSortOrder): Boolean of object;
  TFtTableDrawHeaderCallback = function(Sender: Pointer; Canvas: Pointer; ColumnIndex: Integer;
    AX, AY, AW, AH: Double; ASortOrder: Integer; UserData: Pointer): Integer; cdecl;

  TFtTableDrawCellEvent = function(Sender: TObject; Canvas: TFtCanvas; RowIndex, ColumnIndex: Integer;
    AX, AY, AW, AH: Double; ASelected, AHovered: Boolean): Boolean of object;
  TFtTableDrawCellCallback = function(Sender: Pointer; Canvas: Pointer; RowIndex, ColumnIndex: Integer;
    AX, AY, AW, AH: Double; ASelected, AHovered: Integer; UserData: Pointer): Integer; cdecl;

  TFtTable = class(TFtContainer)
  private
    FColumns: TFPList; // TFtTableColumn
    FRows: TFPList;    // TFtTableRow
    FSelectedRow: Integer;
    FSelAnchorRow: Integer;
    FHoveredRow: Integer;
    FLastClickTime: QWord;
    FLastClickRow: Integer;
    FHeaderHeight: Double;
    FRowHeight: Double;
    FShowGridLines: Boolean;
    FZebraStriping: Boolean;
    FMultiSelect: Boolean;
    FAllowColumnResize: Boolean;
    FResizingCol: Integer;
    FResizeStartX: Integer;
    FResizeStartW: Double;
    FResizeHoverCol: Integer;
    FLastDividerClickTime: QWord;
    FLastDividerClickCol: Integer;
    FPressedHeaderCol: Integer;
    FLastMouseX: Integer;
    FLastMouseY: Integer;
    FOnSelectRow: TFtTableRowSelectEvent;
    FOnRowDoubleClick: TFtTableRowDoubleClickEvent;
    FOnColumnClick: TFtTableColumnClickEvent;
    FOnColumnResize: TFtTableColumnResizeEvent;
    FOnSelectRowCb: TFtTableRowSelectCallback;
    FOnColumnResizeCb: TFtTableColumnResizeCallback;
    FOnColumnResizeUserData: Pointer;
    FOnRowDoubleClickCb: TFtTableRowDoubleClickCallback;
    FOnRowDoubleClickUserData: Pointer;
    FOnDrawHeader: TFtTableDrawHeaderEvent;
    FOnDrawHeaderCb: TFtTableDrawHeaderCallback;
    FOnDrawHeaderUserData: Pointer;
    FOnDrawCell: TFtTableDrawCellEvent;
    FOnDrawCellCb: TFtTableDrawCellCallback;
    FOnDrawCellUserData: Pointer;

    procedure SetSelectedRow(AValue: Integer);
    procedure SetMultiSelect(AValue: Boolean);
    procedure SetHeaderHeight(AValue: Double);
    procedure SetRowHeight(AValue: Double);
    function GetColumnCount(): Integer;
    function GetRowCount(): Integer;
    function GetColumn(AIndex: Integer): TFtTableColumn;
    function GetRow(AIndex: Integer): TFtTableRow;
  protected
    procedure DrawBackground(Canvas: TFtCanvas); override;
    procedure DrawContent(Canvas: TFtCanvas); override;
    procedure DrawHeader(Canvas: TFtCanvas); virtual;
    procedure GetRenderArea(out AX, AY, AW, AH, ARadius: Double); override;
    procedure SetScrollX(AValue: Double); override;
    procedure SetScrollY(AValue: Double); override;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;
    function GetCursor(): Integer; override;
    function GetEffectiveHint(): string; override;
    function RowAtPosition(AY: Integer): Integer;
    function ColumnAtPosition(AX: Integer): Integer;
    function GetResizeDividerAt(AX, AY: Integer): Integer;

    procedure RecalculateMetrics();
    procedure UpdateScrollBars(); override;
    procedure ScrollIntoView(ARow: Integer);
    function AddColumn(const ATitle: string; AWidth: Double = 100.0; AAlign: TFtTextAlign = taLeft): Integer;
    function AddRow(const AValues: array of string): Integer;
    procedure SetCell(ARow, ACol: Integer; const AValue: string);
    function GetCell(ARow, ACol: Integer): string;
    procedure SetColumnIcon(ACol: Integer; AIcon: TFloriaImage);
    function GetColumnIcon(ACol: Integer): TFloriaImage;
    procedure SetCellIcon(ARow, ACol: Integer; AIcon: TFloriaImage);
    function GetCellIcon(ARow, ACol: Integer): TFloriaImage;
    procedure AutoFitColumn(AColIndex: Integer);
    procedure AutoFitColumns();
    procedure SetOnDrawHeaderCb(ACallback: TFtTableDrawHeaderCallback; AUserData: Pointer);
    procedure SetOnDrawCellCb(ACallback: TFtTableDrawCellCallback; AUserData: Pointer);
    procedure SetOnRowDoubleClickCb(ACallback: TFtTableRowDoubleClickCallback; AUserData: Pointer);
    procedure SetOnColumnResizeCb(ACallback: TFtTableColumnResizeCallback; AUserData: Pointer);
    procedure DeleteRow(AIndex: Integer);
    procedure ClearRows();
    procedure ClearAll();

    procedure SelectAll();
    procedure ClearSelection();
    function IsRowSelected(AIndex: Integer): Boolean;
    procedure SetRowSelected(AIndex: Integer; ASelected: Boolean);
    function GetSelectedRowCount(): Integer;
    function GetSelectedRows(): TIntegerDynArray;

    procedure Draw(Canvas: TFtCanvas); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    property ColumnCount: Integer read GetColumnCount;
    property RowCount: Integer read GetRowCount;
    property Columns[AIndex: Integer]: TFtTableColumn read GetColumn;
    property Rows[AIndex: Integer]: TFtTableRow read GetRow;
    property SelectedRow: Integer read FSelectedRow write SetSelectedRow;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect;
    property AllowColumnResize: Boolean read FAllowColumnResize write FAllowColumnResize;
    property HeaderHeight: Double read FHeaderHeight write SetHeaderHeight;
    property RowHeight: Double read FRowHeight write SetRowHeight;
    property ShowGridLines: Boolean read FShowGridLines write FShowGridLines;
    property ZebraStriping: Boolean read FZebraStriping write FZebraStriping;
    property OnSelectRow: TFtTableRowSelectEvent read FOnSelectRow write FOnSelectRow;
    property OnRowDoubleClick: TFtTableRowDoubleClickEvent read FOnRowDoubleClick write FOnRowDoubleClick;
    property OnColumnClick: TFtTableColumnClickEvent read FOnColumnClick write FOnColumnClick;
    property OnColumnResize: TFtTableColumnResizeEvent read FOnColumnResize write FOnColumnResize;
    property OnSelectRowCb: TFtTableRowSelectCallback read FOnSelectRowCb write FOnSelectRowCb;
    property OnColumnResizeCb: TFtTableColumnResizeCallback read FOnColumnResizeCb write FOnColumnResizeCb;
    property OnRowDoubleClickCb: TFtTableRowDoubleClickCallback read FOnRowDoubleClickCb write FOnRowDoubleClickCb;
    property OnRowDoubleClickUserData: Pointer read FOnRowDoubleClickUserData write FOnRowDoubleClickUserData;
    property OnDrawHeader: TFtTableDrawHeaderEvent read FOnDrawHeader write FOnDrawHeader;
    property OnDrawHeaderCb: TFtTableDrawHeaderCallback read FOnDrawHeaderCb write FOnDrawHeaderCb;
    property OnDrawCell: TFtTableDrawCellEvent read FOnDrawCell write FOnDrawCell;
    property OnDrawCellCb: TFtTableDrawCellCallback read FOnDrawCellCb write FOnDrawCellCb;
  end;

implementation

{ TFtTableColumn }

constructor TFtTableColumn.Create(const ATitle: string; AWidth: Double = 100.0; AAlign: TFtTextAlign = taLeft);
begin
  inherited Create();
  Title := ATitle;
  Width := AWidth;
  Alignment := AAlign;
  SortOrder := soNone;
  Icon := nil;
  Resizable := True;
  MinWidth := 30.0;
  MaxWidth := 0.0;
end;

{ TFtTableRow }

constructor TFtTableRow.Create();
begin
  inherited Create();
  Cells := TStringList.Create();
  FCellIcons := TFPList.Create();
  FSelected := False;
  Tag := 0;
  Data := nil;
end;

destructor TFtTableRow.Destroy();
begin
  FCellIcons.Free();
  Cells.Free();
  inherited Destroy();
end;

procedure TFtTableRow.SetCellIcon(ACol: Integer; AIcon: TFloriaImage);
begin
  if ACol < 0 then Exit;
  while FCellIcons.Count <= ACol do
    FCellIcons.Add(nil);
  FCellIcons[ACol] := AIcon;
end;

function TFtTableRow.GetCellIcon(ACol: Integer): TFloriaImage;
begin
  if (ACol >= 0) and (ACol < FCellIcons.Count) then
    Result := TFloriaImage(FCellIcons[ACol])
  else
    Result := nil;
end;

{ TFtTable }

constructor TFtTable.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FPaddingX := 0.0;
  FPaddingY := 0.0;
  FColumns := TFPList.Create();
  FRows := TFPList.Create();
  FSelectedRow := -1;
  FSelAnchorRow := -1;
  FHoveredRow := -1;
  FHeaderHeight := 28.0;
  FRowHeight := 26.0;
  FShowGridLines := True;
  FZebraStriping := True;
  FMultiSelect := False;
  FFocusable := True;
  FDrawFrame := True;
  FScrollBarMode := ftSbModeAutoBoth;
  FAllowColumnResize := True;
  FResizingCol := -1;
  FResizeStartX := 0;
  FResizeStartW := 0.0;
  FResizeHoverCol := -1;
  FLastDividerClickTime := 0;
  FLastDividerClickCol := -1;
  FPressedHeaderCol := -1;
  FLastMouseX := -1;
  FLastMouseY := -1;
  FShowHint := True;
  FOnColumnResize := nil;
  FOnColumnResizeCb := nil;
  FOnColumnResizeUserData := nil;
  FOnDrawHeader := nil;
  FOnDrawHeaderCb := nil;
  FOnDrawHeaderUserData := nil;
  FOnDrawCell := nil;
  FOnDrawCellCb := nil;
  FOnDrawCellUserData := nil;
  FLastClickTime := 0;
  FLastClickRow := -1;
  FOnRowDoubleClick := nil;
  FOnRowDoubleClickCb := nil;
  FOnRowDoubleClickUserData := nil;
end;

destructor TFtTable.Destroy();
begin
  ClearAll();
  FRows.Free();
  FColumns.Free();
  inherited Destroy();
end;

function TFtTable.GetElementType(): string;
begin
  Result := 'table';
end;

function TFtTable.GetColumnCount(): Integer;
begin
  Result := FColumns.Count;
end;

function TFtTable.GetRowCount(): Integer;
begin
  Result := FRows.Count;
end;

function TFtTable.GetColumn(AIndex: Integer): TFtTableColumn;
begin
  if (AIndex >= 0) and (AIndex < FColumns.Count) then
    Result := TFtTableColumn(FColumns[AIndex])
  else
    Result := nil;
end;

function TFtTable.GetRow(AIndex: Integer): TFtTableRow;
begin
  if (AIndex >= 0) and (AIndex < FRows.Count) then
    Result := TFtTableRow(FRows[AIndex])
  else
    Result := nil;
end;

procedure TFtTable.RecalculateMetrics();
var
  i: Integer;
  totW: Double;
begin
  totW := 0.0;
  for i := 0 to FColumns.Count - 1 do
    totW := totW + TFtTableColumn(FColumns[i]).Width;

  ContentWidth := totW;
  ContentHeight := FRows.Count * FRowHeight;
  Invalidate();
end;

procedure TFtTable.SetHeaderHeight(AValue: Double);
begin
  if AValue < 18.0 then AValue := 18.0;
  if FHeaderHeight <> AValue then
  begin
    FHeaderHeight := AValue;
    Invalidate();
  end;
end;

procedure TFtTable.SetRowHeight(AValue: Double);
begin
  if AValue < 16.0 then AValue := 16.0;
  if FRowHeight <> AValue then
  begin
    FRowHeight := AValue;
    RecalculateMetrics();
  end;
end;

function TFtTable.AddColumn(const ATitle: string; AWidth: Double = 100.0; AAlign: TFtTextAlign = taLeft): Integer;
var
  col: TFtTableColumn;
begin
  col := TFtTableColumn.Create(ATitle, AWidth, AAlign);
  Result := FColumns.Add(col);
  RecalculateMetrics();
end;

function TFtTable.AddRow(const AValues: array of string): Integer;
var
  row: TFtTableRow;
  i: Integer;
begin
  row := TFtTableRow.Create();
  for i := Low(AValues) to High(AValues) do
    row.Cells.Add(AValues[i]);
  Result := FRows.Add(row);
  RecalculateMetrics();
end;

procedure TFtTable.SetCell(ARow, ACol: Integer; const AValue: string);
var
  row: TFtTableRow;
begin
  row := GetRow(ARow);
  if not Assigned(row) then Exit;

  while row.Cells.Count <= ACol do
    row.Cells.Add('');

  row.Cells[ACol] := AValue;
  Invalidate();
end;

function TFtTable.GetCell(ARow, ACol: Integer): string;
var
  row: TFtTableRow;
begin
  Result := '';
  row := GetRow(ARow);
  if Assigned(row) and (ACol >= 0) and (ACol < row.Cells.Count) then
    Result := row.Cells[ACol];
end;

procedure TFtTable.SetColumnIcon(ACol: Integer; AIcon: TFloriaImage);
var
  col: TFtTableColumn;
begin
  col := GetColumn(ACol);
  if Assigned(col) then
  begin
    col.Icon := AIcon;
    Invalidate();
  end;
end;

function TFtTable.GetColumnIcon(ACol: Integer): TFloriaImage;
var
  col: TFtTableColumn;
begin
  col := GetColumn(ACol);
  if Assigned(col) then
    Result := col.Icon
  else
    Result := nil;
end;

procedure TFtTable.SetCellIcon(ARow, ACol: Integer; AIcon: TFloriaImage);
var
  row: TFtTableRow;
begin
  row := GetRow(ARow);
  if Assigned(row) then
  begin
    row.SetCellIcon(ACol, AIcon);
    Invalidate();
  end;
end;

function TFtTable.GetCellIcon(ARow, ACol: Integer): TFloriaImage;
var
  row: TFtTableRow;
begin
  row := GetRow(ARow);
  if Assigned(row) then
    Result := row.GetCellIcon(ACol)
  else
    Result := nil;
end;

procedure TFtTable.SetOnDrawHeaderCb(ACallback: TFtTableDrawHeaderCallback; AUserData: Pointer);
begin
  FOnDrawHeaderCb := ACallback;
  FOnDrawHeaderUserData := AUserData;
end;

procedure TFtTable.SetOnDrawCellCb(ACallback: TFtTableDrawCellCallback; AUserData: Pointer);
begin
  FOnDrawCellCb := ACallback;
  FOnDrawCellUserData := AUserData;
end;

procedure TFtTable.SetOnRowDoubleClickCb(ACallback: TFtTableRowDoubleClickCallback; AUserData: Pointer);
begin
  FOnRowDoubleClickCb := ACallback;
  FOnRowDoubleClickUserData := AUserData;
end;

procedure TFtTable.SetOnColumnResizeCb(ACallback: TFtTableColumnResizeCallback; AUserData: Pointer);
begin
  FOnColumnResizeCb := ACallback;
  FOnColumnResizeUserData := AUserData;
end;

procedure TFtTable.AutoFitColumn(AColIndex: Integer);
var
  col: TFtTableColumn;
  fnt: TFtFont;
  maxW, titleW, cellW, iconW, iconH: Double;
  r: Integer;
  row: TFtTableRow;
  cellText: string;
  cellIcon: TFloriaImage;
begin
  if (AColIndex < 0) or (AColIndex >= FColumns.Count) then Exit;
  col := TFtTableColumn(FColumns[AColIndex]);
  if not col.Resizable then Exit;

  fnt := Font;
  if not Assigned(fnt) then fnt := FtGetSystemFont();

  maxW := 0.0;
  if Assigned(fnt) then
    titleW := fnt.GetTextWidth(col.Title)
  else
    titleW := Length(col.Title) * 8.5;

  titleW := titleW + 16.0;
  if Assigned(col.Icon) and (col.Icon.Width > 0) and (col.Icon.Height > 0) then
  begin
    iconH := Min(FHeaderHeight - 6.0, 16.0);
    iconW := (col.Icon.Width / col.Icon.Height) * iconH;
    titleW := titleW + iconW + 6.0;
  end;
  if col.SortOrder <> soNone then
    titleW := titleW + 16.0;

  if titleW > maxW then maxW := titleW;

  for r := 0 to FRows.Count - 1 do
  begin
    row := TFtTableRow(FRows[r]);
    cellText := '';
    if AColIndex < row.Cells.Count then
      cellText := row.Cells[AColIndex];

    if Assigned(fnt) then
      cellW := fnt.GetTextWidth(cellText)
    else
      cellW := Length(cellText) * 8.5;

    cellW := cellW + 16.0;
    cellIcon := row.GetCellIcon(AColIndex);
    if Assigned(cellIcon) and (cellIcon.Width > 0) and (cellIcon.Height > 0) then
    begin
      iconH := Min(FRowHeight - 6.0, 16.0);
      iconW := (cellIcon.Width / cellIcon.Height) * iconH;
      cellW := cellW + iconW + 6.0;
    end;

    if cellW > maxW then maxW := cellW;
  end;

  maxW := maxW + 4.0;
  if maxW < col.MinWidth then maxW := col.MinWidth;
  if (col.MaxWidth > 0.0) and (maxW > col.MaxWidth) then maxW := col.MaxWidth;

  if col.Width <> maxW then
  begin
    col.Width := maxW;
    RecalculateMetrics();
    UpdateScrollBars();
    Invalidate();
    if Assigned(FOnColumnResize) then
      FOnColumnResize(Self, AColIndex, maxW);
    if Assigned(FOnColumnResizeCb) then
      FOnColumnResizeCb(Pointer(Self), AColIndex, maxW, FOnColumnResizeUserData);
  end;
end;

procedure TFtTable.AutoFitColumns();
var
  i: Integer;
begin
  for i := 0 to FColumns.Count - 1 do
    AutoFitColumn(i);
end;

procedure TFtTable.DeleteRow(AIndex: Integer);
var
  row: TFtTableRow;
  i: Integer;
begin
  if (AIndex < 0) or (AIndex >= FRows.Count) then Exit;
  row := TFtTableRow(FRows[AIndex]);
  FRows.Delete(AIndex);
  row.Free();

  if FSelectedRow = AIndex then
  begin
    if not FMultiSelect then
    begin
      if FSelectedRow >= FRows.Count then
        FSelectedRow := FRows.Count - 1;
      if FSelectedRow >= 0 then
        TFtTableRow(FRows[FSelectedRow]).Selected := True;
    end
    else
    begin
      FSelectedRow := -1;
      for i := 0 to FRows.Count - 1 do
      begin
        if TFtTableRow(FRows[i]).Selected then
        begin
          FSelectedRow := i;
          Break;
        end;
      end;
    end;
  end
  else if FSelectedRow > AIndex then
    Dec(FSelectedRow);

  if FSelAnchorRow = AIndex then
    FSelAnchorRow := FSelectedRow
  else if FSelAnchorRow > AIndex then
    Dec(FSelAnchorRow);

  if FSelectedRow >= FRows.Count then
    FSelectedRow := FRows.Count - 1;
  if FSelAnchorRow >= FRows.Count then
    FSelAnchorRow := FRows.Count - 1;

  RecalculateMetrics();
end;

procedure TFtTable.ClearRows();
var
  i: Integer;
begin
  for i := 0 to FRows.Count - 1 do
    TFtTableRow(FRows[i]).Free();
  FRows.Clear();
  FSelectedRow := -1;
  FSelAnchorRow := -1;
  FHoveredRow := -1;
  RecalculateMetrics();
end;

procedure TFtTable.ClearAll();
var
  i: Integer;
begin
  ClearRows();
  for i := 0 to FColumns.Count - 1 do
    TFtTableColumn(FColumns[i]).Free();
  FColumns.Clear();
  RecalculateMetrics();
end;

procedure TFtTable.SetSelectedRow(AValue: Integer);
var
  i: Integer;
  changed: Boolean;
begin
  if (AValue < -1) or (AValue >= FRows.Count) then AValue := -1;
  changed := (FSelectedRow <> AValue);

  FSelectedRow := AValue;
  FSelAnchorRow := AValue;

  for i := 0 to FRows.Count - 1 do
    TFtTableRow(FRows[i]).Selected := (i = FSelectedRow);

  if (FSelectedRow >= 0) then
    ScrollIntoView(FSelectedRow);

  Invalidate();

  if changed then
  begin
    if (FSelectedRow >= 0) and Assigned(FOnSelectRow) then
      FOnSelectRow(Self, FSelectedRow);
    if (FSelectedRow >= 0) and Assigned(FOnSelectRowCb) then
      FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
  end;
end;

procedure TFtTable.SetMultiSelect(AValue: Boolean);
var
  i, sel: Integer;
begin
  if FMultiSelect <> AValue then
  begin
    FMultiSelect := AValue;
    if not FMultiSelect then
    begin
      if (FSelectedRow >= 0) and (FSelectedRow < FRows.Count) and TFtTableRow(FRows[FSelectedRow]).Selected then
      begin
        for i := 0 to FRows.Count - 1 do
          TFtTableRow(FRows[i]).Selected := (i = FSelectedRow);
      end
      else
      begin
        sel := -1;
        for i := 0 to FRows.Count - 1 do
        begin
          if (sel = -1) and TFtTableRow(FRows[i]).Selected then
            sel := i
          else
            TFtTableRow(FRows[i]).Selected := False;
        end;
        FSelectedRow := sel;
        FSelAnchorRow := sel;
      end;
      Invalidate();
    end;
  end;
end;

procedure TFtTable.SelectAll();
var
  i: Integer;
begin
  if not FMultiSelect or (FRows.Count = 0) then Exit;
  for i := 0 to FRows.Count - 1 do
    TFtTableRow(FRows[i]).Selected := True;
  if FSelectedRow < 0 then
    FSelectedRow := 0;
  if FSelAnchorRow < 0 then
    FSelAnchorRow := 0;
  Invalidate();
  if Assigned(FOnSelectRow) then
    FOnSelectRow(Self, FSelectedRow);
  if Assigned(FOnSelectRowCb) then
    FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
end;

procedure TFtTable.ClearSelection();
var
  i: Integer;
  hadSelection: Boolean;
begin
  hadSelection := False;
  for i := 0 to FRows.Count - 1 do
  begin
    if TFtTableRow(FRows[i]).Selected then
    begin
      TFtTableRow(FRows[i]).Selected := False;
      hadSelection := True;
    end;
  end;
  if (FSelectedRow >= 0) or hadSelection then
  begin
    FSelectedRow := -1;
    FSelAnchorRow := -1;
    Invalidate();
    if Assigned(FOnSelectRow) then
      FOnSelectRow(Self, -1);
    if Assigned(FOnSelectRowCb) then
      FOnSelectRowCb(Pointer(Self), -1, FUserData);
  end;
end;

function TFtTable.IsRowSelected(AIndex: Integer): Boolean;
var
  row: TFtTableRow;
begin
  row := GetRow(AIndex);
  if Assigned(row) then
    Result := row.Selected
  else
    Result := False;
end;

procedure TFtTable.SetRowSelected(AIndex: Integer; ASelected: Boolean);
var
  row: TFtTableRow;
  i: Integer;
begin
  row := GetRow(AIndex);
  if not Assigned(row) then Exit;

  if not FMultiSelect then
  begin
    if ASelected then
      SelectedRow := AIndex
    else if FSelectedRow = AIndex then
      SelectedRow := -1;
    Exit;
  end;

  if row.Selected <> ASelected then
  begin
    row.Selected := ASelected;
    if ASelected then
    begin
      FSelectedRow := AIndex;
      if FSelAnchorRow < 0 then
        FSelAnchorRow := AIndex;
    end
    else
    begin
      if FSelectedRow = AIndex then
      begin
        FSelectedRow := -1;
        for i := 0 to FRows.Count - 1 do
        begin
          if TFtTableRow(FRows[i]).Selected then
          begin
            FSelectedRow := i;
            Break;
          end;
        end;
      end;
      if FSelAnchorRow = AIndex then
        FSelAnchorRow := FSelectedRow;
    end;
    Invalidate();
    if Assigned(FOnSelectRow) then
      FOnSelectRow(Self, FSelectedRow);
    if Assigned(FOnSelectRowCb) then
      FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
  end;
end;

function TFtTable.GetSelectedRowCount(): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FRows.Count - 1 do
  begin
    if TFtTableRow(FRows[i]).Selected then
      Inc(Result);
  end;
end;

function TFtTable.GetSelectedRows(): TIntegerDynArray;
var
  i, cnt, idx: Integer;
begin
  cnt := GetSelectedRowCount();
  SetLength(Result, cnt);
  idx := 0;
  for i := 0 to FRows.Count - 1 do
  begin
    if TFtTableRow(FRows[i]).Selected then
    begin
      Result[idx] := i;
      Inc(idx);
    end;
  end;
end;

function TFtTable.RowAtPosition(AY: Integer): Integer;
var
  relY: Double;
begin
  Result := -1;
  relY := (AY - (Y + FHeaderHeight)) + FScrollY;
  if relY < 0.0 then Exit;

  Result := Trunc(relY / FRowHeight);
  if (Result < 0) or (Result >= FRows.Count) then
    Result := -1;
end;

function TFtTable.ColumnAtPosition(AX: Integer): Integer;
var
  i: Integer;
  curX: Double;
  col: TFtTableColumn;
begin
  Result := -1;
  curX := X - FScrollX;
  for i := 0 to FColumns.Count - 1 do
  begin
    col := TFtTableColumn(FColumns[i]);
    if (AX >= curX) and (AX <= curX + col.Width) then
      Exit(i);
    curX := curX + col.Width;
  end;
end;

function TFtTable.GetResizeDividerAt(AX, AY: Integer): Integer;
var
  i: Integer;
  colX, divX: Double;
  col: TFtTableColumn;
begin
  Result := -1;
  if not FAllowColumnResize then Exit;
  if (AY < Y) or (AY > Y + FHeaderHeight) then Exit;
  if (AX < X) or (AX > X + Width) then Exit;

  colX := (X + 1.0) - FScrollX;
  for i := 0 to FColumns.Count - 1 do
  begin
    col := TFtTableColumn(FColumns[i]);
    divX := colX + col.Width;
    if Abs(AX - divX) <= 4.0 then
    begin
      if col.Resizable then
        Exit(i);
    end;
    colX := divX;
  end;
end;

function TFtTable.GetCursor(): Integer;
begin
  if (FResizingCol >= 0) or (FResizeHoverCol >= 0) then
    Result := FT_CURSOR_SIZE_H
  else
    Result := inherited GetCursor();
end;

function TFtTable.GetEffectiveHint(): string;
var
  f: TFtFont;
  c, r: Integer;
  col: TFtTableColumn;
  row: TFtTableRow;
  textAvailW, iconW, iconH, titleW, cellW: Double;
  cellText: string;
  cellIcon: TFloriaImage;
begin
  if not FShowHint or not Visible then Exit('');
  if (FResizingCol >= 0) or (FResizeHoverCol >= 0) then Exit('');

  // 1. Column header
  if (FLastMouseY >= Y) and (FLastMouseY <= Y + FHeaderHeight) then
  begin
    c := ColumnAtPosition(FLastMouseX);
    if (c >= 0) and (c < FColumns.Count) then
    begin
      col := TFtTableColumn(FColumns[c]);
      textAvailW := col.Width - 16.0;
      if Assigned(col.Icon) and (col.Icon.Width > 0) and (col.Icon.Height > 0) then
      begin
        iconH := Min(FHeaderHeight - 6.0, 16.0);
        iconW := (col.Icon.Width / col.Icon.Height) * iconH;
        textAvailW := textAvailW - (iconW + 6.0);
      end;
      if col.SortOrder <> soNone then
        textAvailW := textAvailW - 16.0;

      f := Font;
      if not Assigned(f) then f := FtGetSystemFont();
      if Assigned(f) then
        titleW := f.GetTextWidth(col.Title)
      else
        titleW := Length(col.Title) * 8.5;

      if (textAvailW > 0.0) and (titleW > textAvailW) then
        Exit(col.Title);
    end;
  end
  // 2. Row cell
  else if FLastMouseY > Y + FHeaderHeight then
  begin
    r := RowAtPosition(FLastMouseY);
    c := ColumnAtPosition(FLastMouseX);
    if (r >= 0) and (r < FRows.Count) and (c >= 0) and (c < FColumns.Count) then
    begin
      row := TFtTableRow(FRows[r]);
      cellText := '';
      if c < row.Cells.Count then
        cellText := row.Cells[c];

      if cellText <> '' then
      begin
        col := TFtTableColumn(FColumns[c]);
        textAvailW := col.Width - 16.0;
        cellIcon := row.GetCellIcon(c);
        if Assigned(cellIcon) and (cellIcon.Width > 0) and (cellIcon.Height > 0) then
        begin
          iconH := Min(FRowHeight - 6.0, 16.0);
          iconW := (cellIcon.Width / cellIcon.Height) * iconH;
          textAvailW := textAvailW - (iconW + 6.0);
        end;

        f := Font;
        if not Assigned(f) then f := FtGetSystemFont();
        if Assigned(f) then
          cellW := f.GetTextWidth(cellText)
        else
          cellW := Length(cellText) * 8.5;

        if (textAvailW > 0.0) and (cellW > textAvailW) then
          Exit(cellText);
      end;
    end;
  end;

  Result := inherited GetEffectiveHint();
end;

procedure TFtTable.GetRenderArea(out AX, AY, AW, AH, ARadius: Double);
var
  bw: Double;
  st: TFtWidgetStyle;
begin
  bw := 0.0;
  if FDrawFrame then
  begin
    st := GetResolvedStyle();
    bw := 1.0;
    if st.HasBorderWidth then bw := st.BorderWidth;
  end;

  AX := X + bw;
  AY := Y + bw;
  AW := Math.Max(0.0, Width - (bw * 2.0));
  AH := Math.Max(0.0, Height - (bw * 2.0));
  ARadius := Math.Max(0.0, GetEffectiveCornerRadius() - bw);
end;

procedure TFtTable.SetScrollX(AValue: Double);
var
  maxScroll, viewW, barThickness: Double;
begin
  barThickness := 9.0;
  viewW := Math.Max(0.0, Width - (FPaddingX * 2.0));
  if Assigned(FVScrollBar) and FVScrollBar.Visible then
    viewW := Math.Max(0.0, viewW - barThickness - 2.0);
  maxScroll := Math.Max(0.0, FContentWidth - viewW);
  if AValue > maxScroll then AValue := maxScroll;
  if AValue < 0.0 then AValue := 0.0;
  inherited SetScrollX(AValue);
end;

procedure TFtTable.SetScrollY(AValue: Double);
var
  maxScroll, viewH: Double;
begin
  viewH := Math.Max(0.0, Height - FHeaderHeight - (FPaddingY * 2.0));
  maxScroll := Math.Max(0.0, FContentHeight - viewH);
  if AValue > maxScroll then AValue := maxScroll;
  if AValue < 0.0 then AValue := 0.0;
  inherited SetScrollY(AValue);
end;

procedure TFtTable.ScrollIntoView(ARow: Integer);
var
  rowTop, rowBottom, viewH: Double;
begin
  if (ARow < 0) or (ARow >= FRows.Count) then Exit;
  rowTop := ARow * FRowHeight;
  rowBottom := rowTop + FRowHeight;
  viewH := Math.Max(0.0, Height - FHeaderHeight - (FPaddingY * 2.0));

  if rowTop < FScrollY then
    SetScrollY(rowTop)
  else if rowBottom > FScrollY + viewH then
    SetScrollY(rowBottom - viewH);
end;

procedure TFtTable.UpdateScrollBars();
var
  barThickness: Double;
  vNeeded, hNeeded: Boolean;
  viewW, viewH: Double;
begin
  if (not Assigned(FVScrollBar)) or (not Assigned(FHScrollBar)) then Exit;

  barThickness := 9.0;
  viewW := Math.Max(0.0, Width - (FPaddingX * 2.0));
  viewH := Math.Max(0.0, Height - FHeaderHeight - (FPaddingY * 2.0));

  vNeeded := False;
  hNeeded := False;

  case FScrollBarMode of
    ftSbModeNone:
    begin
      vNeeded := False;
      hNeeded := False;
    end;
    ftSbModeHorizontalOnly:
    begin
      hNeeded := FContentWidth > viewW;
    end;
    ftSbModeVerticalOnly:
    begin
      vNeeded := FContentHeight > viewH;
    end;
    ftSbModeAutoBoth:
    begin
      vNeeded := FContentHeight > viewH;
      if vNeeded then
        hNeeded := FContentWidth > (viewW - barThickness - 2.0)
      else
        hNeeded := FContentWidth > viewW;

      if hNeeded and not vNeeded then
        vNeeded := FContentHeight > (viewH - barThickness - 2.0);
    end;
  end;

  if vNeeded then
    viewW := Math.Max(0.0, viewW - barThickness - 2.0);
  if hNeeded then
    viewH := Math.Max(0.0, viewH - barThickness - 2.0);

  // Clamp scroll positions
  if FContentHeight > viewH then
  begin
    if FScrollY > FContentHeight - viewH then
      SetScrollY(FContentHeight - viewH);
  end
  else
    SetScrollY(0.0);

  if FContentWidth > viewW then
  begin
    if FScrollX > FContentWidth - viewW then
      SetScrollX(FContentWidth - viewW);
  end
  else
    SetScrollX(0.0);

  // Configure VScrollBar
  if FVScrollBar.Visible <> vNeeded then
    FVScrollBar.Visible := vNeeded;
  if vNeeded then
  begin
    FVScrollBar.X := X + Width - Round(barThickness) - 3;
    FVScrollBar.Y := Round(Y + FHeaderHeight + 2.0);
    FVScrollBar.Width := Round(barThickness);
    if hNeeded then
      FVScrollBar.Height := Round(Height - FHeaderHeight - 4.0 - barThickness - 2.0)
    else
      FVScrollBar.Height := Round(Height - FHeaderHeight - 5.0);
    FVScrollBar.SetRange(0.0, Math.Max(0.0, FContentHeight - viewH), viewH);
    if Abs(FVScrollBar.Value - FScrollY) > 1e-4 then
      FVScrollBar.Value := FScrollY;
    FVScrollBar.Step := FRowHeight;
  end;

  // Configure HScrollBar
  if FHScrollBar.Visible <> hNeeded then
    FHScrollBar.Visible := hNeeded;
  if hNeeded then
  begin
    FHScrollBar.X := X + 3;
    FHScrollBar.Y := Y + Height - Round(barThickness) - 3;
    if vNeeded then
      FHScrollBar.Width := Width - 6 - Round(barThickness) - 2
    else
      FHScrollBar.Width := Width - 6;
    FHScrollBar.Height := Round(barThickness);
    FHScrollBar.SetRange(0.0, Math.Max(0.0, FContentWidth - viewW), viewW);
    if Abs(FHScrollBar.Value - FScrollX) > 1e-4 then
      FHScrollBar.Value := FScrollX;
    FHScrollBar.Step := 25.0;
  end;
end;

procedure TFtTable.DrawBackground(Canvas: TFtCanvas);
begin
  inherited DrawBackground(Canvas);
end;

procedure TFtTable.DrawHeader(Canvas: TFtCanvas);
var
  theme: TFtTheme;
  headR, headG, headB: Double;
  textR, textG, textB: Double;
  bd: TFtRgbColor;
  rad, hx, hy, hw, hh: Double;
  i: Integer;
  col: TFtTableColumn;
  colX: Double;
  arrowX, arrowY: Double;
  handled: Boolean;
  textStartX, textAvailW, iconW, iconH, iconY: Double;
  fitTitle: string;
  curW, curX: Double;
begin
  theme := FtGetTheme();
  if theme.DarkMode then
  begin
    headR := 0.16; headG := 0.16; headB := 0.22;
    textR := 0.75; textG := 0.78; textB := 0.85;
  end
  else
  begin
    headR := 0.88; headG := 0.89; headB := 0.92;
    textR := 0.25; textG := 0.28; textB := 0.35;
  end;

  hx := X + 1.0;
  hy := Y + 1.0;
  hw := Width - 2.0;
  hh := FHeaderHeight - 1.0;

  Canvas.PushClipRect(Round(hx), Round(hy), Round(hw), Round(hh));
  try
    // Header background (container's dynamic clip automatically rounds the top corners if container is rounded!)
    Canvas.DrawRect(Round(hx), Round(hy), Round(hw), Round(hh), headR, headG, headB, 1.0);

    colX := hx - FScrollX;
    for i := 0 to FColumns.Count - 1 do
    begin
      col := TFtTableColumn(FColumns[i]);

      // Check Owner-Draw Callback
      handled := False;
      if Assigned(FOnDrawHeader) then
        handled := FOnDrawHeader(Self, Canvas, i, colX, hy, col.Width, hh, col.SortOrder)
      else if Assigned(FOnDrawHeaderCb) then
        handled := (FOnDrawHeaderCb(Pointer(Self), Pointer(Canvas), i, colX, hy, col.Width, hh, Ord(col.SortOrder), FOnDrawHeaderUserData) <> 0);

      if not handled then
      begin
        textStartX := colX + 8.0;
        textAvailW := col.Width - 16.0;

        // Draw Column Icon if present
        if Assigned(col.Icon) and (col.Icon.Width > 0) and (col.Icon.Height > 0) then
        begin
          iconH := Min(hh - 6.0, 16.0);
          iconW := (col.Icon.Width / col.Icon.Height) * iconH;
          iconY := Round(hy + (hh - iconH) * 0.5);
          Canvas.DrawImageScaled(Round(textStartX), iconY, Round(iconW), Round(iconH), col.Icon, 1.0);
          textStartX := Round(textStartX + iconW + 6.0);
          textAvailW := textAvailW - (iconW + 6.0);
        end;

        // Column title text
        if textAvailW > 0.0 then
        begin
          fitTitle := FtFitTextWithEllipsis(col.Title, Font, textAvailW);
          case col.Alignment of
            taCenter:
              Canvas.DrawTextCentered(Round(textStartX), Round(hy), Round(textAvailW), Round(hh), fitTitle, Font, textR, textG, textB);
            taRight:
            begin
              curW := 0.0;
              if Assigned(Font) then curW := Font.GetTextWidth(fitTitle);
              curX := textStartX + Max(0.0, textAvailW - curW);
              Canvas.DrawTextLeft(curX, hy + 4.0, textAvailW, hh - 8.0, fitTitle, Font, textR, textG, textB);
            end;
            else
              Canvas.DrawTextLeft(textStartX, hy + 4.0, textAvailW, hh - 8.0, fitTitle, Font, textR, textG, textB);
          end;
        end;

        // Sort order indicator
        if col.SortOrder <> soNone then
        begin
          arrowX := colX + col.Width - 14.0;
          arrowY := hy + hh * 0.5;
          if col.SortOrder = soAscending then
          begin
            Canvas.DrawLine(arrowX - 4.0, arrowY + 2.0, arrowX, arrowY - 3.0, 1.5, textR, textG, textB, 0.9);
            Canvas.DrawLine(arrowX, arrowY - 3.0, arrowX + 4.0, arrowY + 2.0, 1.5, textR, textG, textB, 0.9);
          end
          else
          begin
            Canvas.DrawLine(arrowX - 4.0, arrowY - 2.0, arrowX, arrowY + 3.0, 1.5, textR, textG, textB, 0.9);
            Canvas.DrawLine(arrowX, arrowY + 3.0, arrowX + 4.0, arrowY - 2.0, 1.5, textR, textG, textB, 0.9);
          end;
        end;
      end;

      // Vertical column separator line
      if (i = FResizingCol) or (i = FResizeHoverCol) then
      begin
        bd := theme.GetAccentColor();
        Canvas.DrawLine(colX + col.Width, hy, colX + col.Width, hy + hh, 2.0, bd.R, bd.G, bd.B, 1.0);
      end
      else if FShowGridLines and (i < FColumns.Count - 1) then
        Canvas.DrawLine(colX + col.Width, hy + 2.0, colX + col.Width, hy + hh - 2.0, 1.0, headR * 0.8, headG * 0.8, headB * 0.8, 0.8);

      colX := colX + col.Width;
    end;
  finally
    Canvas.PopClipRect();
  end;

  // Bottom dividing line
  bd := theme.GetInputBorder();
  Canvas.DrawLine(hx, Y + FHeaderHeight, hx + hw, Y + FHeaderHeight, 1.0, bd.R, bd.G, bd.B, 0.9);
end;

procedure TFtTable.DrawContent(Canvas: TFtCanvas);
var
  theme: TFtTheme;
  accent: TFtRgbColor;
  bodyY: Double;
  r, c: Integer;
  row: TFtTableRow;
  rowY, colX: Double;
  isSelected, isHovered: Boolean;
  rowR, rowG, rowB: Double;
  textR, textG, textB: Double;
  cellText: string;
  col: TFtTableColumn;
  cellW: Double;
  cellIcon: TFloriaImage;
  handled: Boolean;
  textStartX, textAvailW, iconW, iconH, iconY: Double;
  vBarW: Double;
  fitText: string;
  curW, curX: Double;
begin
  theme := FtGetTheme();
  accent := theme.GetAccentColor();
  bodyY := Y + FHeaderHeight;

  vBarW := 0.0;
  if Assigned(FVScrollBar) and FVScrollBar.Visible then
    vBarW := FVScrollBar.Width + 2.0;

  // Clip content to table body area below header
  Canvas.PushClipRect(Round(X + 1.0), Round(bodyY), Round(Width - 2.0), Round(Height - FHeaderHeight - 1.0));
  try
    for r := 0 to FRows.Count - 1 do
    begin
      row := TFtTableRow(FRows[r]);
      rowY := bodyY + (r * FRowHeight) - FScrollY;

      // Viewport culling
      if (rowY + FRowHeight < bodyY) or (rowY > Y + Height) then
        Continue;

      isSelected := row.Selected;
      isHovered := (r = FHoveredRow);

      if isSelected then
      begin
        Canvas.DrawRoundedRect(X + 2.0, rowY + 1.0, Width - 4.0 - vBarW, FRowHeight - 2.0, 4.0, accent.R, accent.G, accent.B, 0.85);
        textR := 1.0; textG := 1.0; textB := 1.0;
      end
      else if isHovered then
      begin
        if theme.DarkMode then
          Canvas.DrawRoundedRect(X + 2.0, rowY + 1.0, Width - 4.0 - vBarW, FRowHeight - 2.0, 4.0, 0.24, 0.25, 0.32, 0.6)
        else
          Canvas.DrawRoundedRect(X + 2.0, rowY + 1.0, Width - 4.0 - vBarW, FRowHeight - 2.0, 4.0, 0.88, 0.90, 0.95, 0.6);
        if theme.DarkMode then
        begin textR := 0.9; textG := 0.9; textB := 0.9; end
        else
        begin textR := 0.1; textG := 0.1; textB := 0.1; end;
      end
      else
      begin
        if FZebraStriping and (r mod 2 = 1) then
        begin
          if theme.DarkMode then
            Canvas.DrawRect(X + 1, Round(rowY), Width - 2 - Round(vBarW), Round(FRowHeight), 0.16, 0.17, 0.22, 0.5)
          else
            Canvas.DrawRect(X + 1, Round(rowY), Width - 2 - Round(vBarW), Round(FRowHeight), 0.95, 0.96, 0.98, 0.6);
        end;

        if theme.DarkMode then
        begin textR := 0.82; textG := 0.84; textB := 0.88; end
        else
        begin textR := 0.18; textG := 0.20; textB := 0.24; end;
      end;

      // Draw Cells
      colX := X + 1.0 - FScrollX;
      for c := 0 to FColumns.Count - 1 do
      begin
        col := TFtTableColumn(FColumns[c]);
        cellW := col.Width;

        handled := False;
        if Assigned(FOnDrawCell) then
          handled := FOnDrawCell(Self, Canvas, r, c, colX, rowY, cellW, FRowHeight, isSelected, isHovered)
        else if Assigned(FOnDrawCellCb) then
          handled := (FOnDrawCellCb(Pointer(Self), Pointer(Canvas), r, c, colX, rowY, cellW, FRowHeight, Ord(isSelected), Ord(isHovered), FOnDrawCellUserData) <> 0);

        if not handled then
        begin
          if c < row.Cells.Count then
            cellText := row.Cells[c]
          else
            cellText := '';

          textStartX := colX + 8.0;
          textAvailW := cellW - 16.0;

          // Cell Icon
          cellIcon := row.GetCellIcon(c);
          if Assigned(cellIcon) and (cellIcon.Width > 0) and (cellIcon.Height > 0) then
          begin
            iconH := Min(FRowHeight - 6.0, 16.0);
            iconW := (cellIcon.Width / cellIcon.Height) * iconH;
            iconY := Round(rowY + (FRowHeight - iconH) * 0.5);
            Canvas.DrawImageScaled(Round(textStartX), iconY, Round(iconW), Round(iconH), cellIcon, 1.0);
            textStartX := Round(textStartX + iconW + 6.0);
            textAvailW := textAvailW - (iconW + 6.0);
          end;

          if textAvailW > 0.0 then
          begin
            fitText := FtFitTextWithEllipsis(cellText, Font, textAvailW);
            case col.Alignment of
              taCenter:
                Canvas.DrawTextCentered(Round(textStartX), Round(rowY), Round(textAvailW), Round(FRowHeight), fitText, Font, textR, textG, textB);
              taRight:
              begin
                curW := 0.0;
                if Assigned(Font) then curW := Font.GetTextWidth(fitText);
                curX := textStartX + Max(0.0, textAvailW - curW);
                Canvas.DrawTextLeft(curX, rowY + 3.0, textAvailW, FRowHeight - 6.0, fitText, Font, textR, textG, textB);
              end;
              else
                Canvas.DrawTextLeft(textStartX, rowY + 3.0, textAvailW, FRowHeight - 6.0, fitText, Font, textR, textG, textB);
            end;
          end;
        end;

        // Grid lines
        if FShowGridLines and not isSelected then
        begin
          if c < FColumns.Count - 1 then
          begin
            if theme.DarkMode then
              Canvas.DrawLine(colX + col.Width, rowY, colX + col.Width, rowY + FRowHeight, 1.0, 0.22, 0.23, 0.28, 0.5)
            else
              Canvas.DrawLine(colX + col.Width, rowY, colX + col.Width, rowY + FRowHeight, 1.0, 0.85, 0.86, 0.89, 0.5);
          end;
        end;

        colX := colX + col.Width;
      end;

      // Horizontal row separator
      if FShowGridLines and not isSelected then
      begin
        if theme.DarkMode then
          Canvas.DrawLine(X + 1, rowY + FRowHeight - 1.0, X + Width - 1 - vBarW, rowY + FRowHeight - 1.0, 1.0, 0.22, 0.23, 0.28, 0.4)
        else
          Canvas.DrawLine(X + 1, rowY + FRowHeight - 1.0, X + Width - 1 - vBarW, rowY + FRowHeight - 1.0, 1.0, 0.85, 0.86, 0.89, 0.4);
      end;
    end;

    // If resizing, draw subtle vertical guide line down the table content
    if FResizingCol >= 0 then
    begin
      colX := (X + 1.0) - FScrollX;
      for c := 0 to FResizingCol do
        colX := colX + TFtTableColumn(FColumns[c]).Width;
      if (colX >= X) and (colX <= X + Width) then
        Canvas.DrawLine(colX, bodyY, colX, Y + Height, 1.0, accent.R, accent.G, accent.B, 0.45);
    end;
  finally
    Canvas.PopClipRect();
  end;
end;

procedure TFtTable.Draw(Canvas: TFtCanvas);
var
  clipX, clipY, clipW, clipH, innerRad: Double;
  theme: TFtTheme;
  rad: Double;
  bd: TFtRgbColor;
begin
  if not Visible then Exit;

  // Background and content (table rows) - dynamically clipped by container
  inherited Draw(Canvas);

  // Draw fixed Header row over content, dynamically clipped to container render area
  GetRenderArea(clipX, clipY, clipW, clipH, innerRad);
  Canvas.PushClipRoundedRect(clipX, clipY, clipW, Height - (clipY - Y) * 2.0, innerRad);
  try
    DrawHeader(Canvas);
  finally
    Canvas.PopClipRoundedRect();
  end;

  // Re-stroke container border outline over header and rows
  if FDrawFrame then
  begin
    theme := FtGetTheme();
    rad := GetEffectiveCornerRadius();

    if FFocused and FDrawFocusRing then
      bd := theme.GetAccentColor()
    else
      bd := theme.GetInputBorder();

    Canvas.DrawRoundedRectOutline(X, Y, Width, Height, rad, 1.0, bd.R, bd.G, bd.B);
    if FFocused and FDrawFocusRing then
      theme.DrawFocusRing(Canvas, X, Y, Width, Height, rad);
  end;
end;

procedure TFtTable.MouseDown(AX, AY: Integer; AButton: Integer);
var
  colIdx: Integer;
  rowIdx: Integer;
  mods: Cardinal;
  hasCtrl, hasShift: Boolean;
  minIdx, maxIdx, i: Integer;
  nowTime: QWord;
  isDblClick: Boolean;
  divCol: Integer;
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton = 1 then
  begin
    // Check if divider hit for column resizing
    divCol := GetResizeDividerAt(AX, AY);
    if divCol >= 0 then
    begin
      nowTime := GetTickCount64();
      if (divCol = FLastDividerClickCol) and ((nowTime - FLastDividerClickTime) < 400) then
      begin
        FLastDividerClickTime := 0;
        FLastDividerClickCol := -1;
        FResizingCol := -1;
        AutoFitColumn(divCol);
        Exit;
      end;
      FLastDividerClickTime := nowTime;
      FLastDividerClickCol := divCol;
      FResizingCol := divCol;
      FResizeStartX := AX;
      FResizeStartW := TFtTableColumn(FColumns[divCol]).Width;
      Invalidate();
      Exit;
    end;

    // Check if header clicked (release-within-bounds will trigger OnColumnClick)
    if (AY >= Y) and (AY <= Y + FHeaderHeight) then
    begin
      FPressedHeaderCol := ColumnAtPosition(AX);
      Exit;
    end
    else
    begin
      FPressedHeaderCol := -1;
      rowIdx := RowAtPosition(AY);
      if rowIdx >= 0 then
      begin
        nowTime := GetTickCount64();
        isDblClick := (rowIdx = FLastClickRow) and ((nowTime - FLastClickTime) < 400);
        if isDblClick then
          FLastClickTime := 0
        else
          FLastClickTime := nowTime;
        FLastClickRow := rowIdx;

        mods := FtGetKeyboardModifiers();
        hasCtrl := (mods and FT_KEY_MOD_CONTROL) <> 0;
        hasShift := (mods and FT_KEY_MOD_SHIFT) <> 0;

        if not FMultiSelect then
        begin
          SelectedRow := rowIdx;
        end
        else
        begin
          if hasShift then
          begin
            if FSelAnchorRow < 0 then
            begin
              if FSelectedRow >= 0 then
                FSelAnchorRow := FSelectedRow
              else
                FSelAnchorRow := 0;
            end;

            if not hasCtrl then
            begin
              for i := 0 to FRows.Count - 1 do
                TFtTableRow(FRows[i]).Selected := False;
            end;

            minIdx := Min(FSelAnchorRow, rowIdx);
            maxIdx := Max(FSelAnchorRow, rowIdx);
            for i := minIdx to maxIdx do
              TFtTableRow(FRows[i]).Selected := True;

            FSelectedRow := rowIdx;
            Invalidate();
            if Assigned(FOnSelectRow) then
              FOnSelectRow(Self, FSelectedRow);
            if Assigned(FOnSelectRowCb) then
              FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
          end
          else if hasCtrl then
          begin
            TFtTableRow(FRows[rowIdx]).Selected := not TFtTableRow(FRows[rowIdx]).Selected;
            FSelectedRow := rowIdx;
            FSelAnchorRow := rowIdx;
            Invalidate();
            if Assigned(FOnSelectRow) then
              FOnSelectRow(Self, FSelectedRow);
            if Assigned(FOnSelectRowCb) then
              FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
          end
          else
          begin
            for i := 0 to FRows.Count - 1 do
              TFtTableRow(FRows[i]).Selected := (i = rowIdx);
            FSelectedRow := rowIdx;
            FSelAnchorRow := rowIdx;
            Invalidate();
            if Assigned(FOnSelectRow) then
              FOnSelectRow(Self, FSelectedRow);
            if Assigned(FOnSelectRowCb) then
              FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
          end;
        end;

        if isDblClick then
        begin
          if Assigned(FOnRowDoubleClick) then
            FOnRowDoubleClick(Self, rowIdx);
          if Assigned(FOnRowDoubleClickCb) then
            FOnRowDoubleClickCb(Pointer(Self), rowIdx, FOnRowDoubleClickUserData);
        end;
      end;
    end;
  end;
end;

procedure TFtTable.MouseMove(AX, AY: Integer);
var
  newHover: Integer;
  newHoverDiv: Integer;
  col: TFtTableColumn;
  newW: Double;
begin
  inherited MouseMove(AX, AY);

  FLastMouseX := AX;
  FLastMouseY := AY;

  if FResizingCol >= 0 then
  begin
    col := TFtTableColumn(FColumns[FResizingCol]);
    newW := FResizeStartW + (AX - FResizeStartX);
    if newW < col.MinWidth then
      newW := col.MinWidth;
    if (col.MaxWidth > 0.0) and (newW > col.MaxWidth) then
      newW := col.MaxWidth;

    if col.Width <> newW then
    begin
      col.Width := newW;
      RecalculateMetrics();
      UpdateScrollBars();
      Invalidate();
      if Assigned(FOnColumnResize) then
        FOnColumnResize(Self, FResizingCol, newW);
      if Assigned(FOnColumnResizeCb) then
        FOnColumnResizeCb(Pointer(Self), FResizingCol, newW, FOnColumnResizeUserData);
    end;
    Exit;
  end;

  // Track divider hover
  newHoverDiv := GetResizeDividerAt(AX, AY);
  if FResizeHoverCol <> newHoverDiv then
  begin
    FResizeHoverCol := newHoverDiv;
    Invalidate();
  end;

  // Track row hover
  newHover := RowAtPosition(AY);
  if FHoveredRow <> newHover then
  begin
    FHoveredRow := newHover;
    Invalidate();
  end;
end;

procedure TFtTable.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);

  if AButton = 1 then
  begin
    if FResizingCol >= 0 then
    begin
      FResizingCol := -1;
      FResizeHoverCol := GetResizeDividerAt(AX, AY);
      Invalidate();
      Exit;
    end;

    if FPressedHeaderCol >= 0 then
    begin
      if (AY >= Y) and (AY <= Y + FHeaderHeight) and (ColumnAtPosition(AX) = FPressedHeaderCol) then
      begin
        if Assigned(FOnColumnClick) then
          FOnColumnClick(Self, FPressedHeaderCol);
      end;
      FPressedHeaderCol := -1;
      Exit;
    end;
  end;
end;

procedure TFtTable.MouseLeave();
begin
  inherited MouseLeave();
  FLastMouseX := -1;
  FLastMouseY := -1;
  FPressedHeaderCol := -1;
  if FResizeHoverCol >= 0 then
  begin
    FResizeHoverCol := -1;
    Invalidate();
  end;
  if FHoveredRow >= 0 then
  begin
    FHoveredRow := -1;
    Invalidate();
  end;
end;

procedure TFtTable.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
var
  hasCtrl, hasShift: Boolean;
  targetRow, minIdx, maxIdx, i: Integer;
begin
  inherited KeyDown(AKeySym, AState, AChar);

  hasCtrl := (AState and FT_KEY_MOD_CONTROL) <> 0;
  hasShift := (AState and FT_KEY_MOD_SHIFT) <> 0;

  // Return / Enter ($FF0D, $FF8D): Trigger double-click on selected row
  if ((AKeySym = $FF0D) or (AKeySym = $FF8D)) and (FSelectedRow >= 0) and (FSelectedRow < FRows.Count) then
  begin
    if Assigned(FOnRowDoubleClick) then
      FOnRowDoubleClick(Self, FSelectedRow);
    if Assigned(FOnRowDoubleClickCb) then
      FOnRowDoubleClickCb(Pointer(Self), FSelectedRow, FOnRowDoubleClickUserData);
    Exit;
  end;

  // Ctrl + A: Select All (only when MultiSelect is True)
  if FMultiSelect and hasCtrl and ((AKeySym = $61) or (AKeySym = $41) or (AChar = 'a') or (AChar = 'A')) then
  begin
    SelectAll();
    Exit;
  end;

  // Escape ($FF1B): Clear selection
  if (AKeySym = $FF1B) then
  begin
    ClearSelection();
    Exit;
  end;

  // Up Arrow ($FF52): Previous Row
  if (AKeySym = $FF52) and (FRows.Count > 0) then
  begin
    if FSelectedRow > 0 then
      targetRow := FSelectedRow - 1
    else if FSelectedRow < 0 then
      targetRow := 0
    else
      targetRow := 0;

    if FMultiSelect and hasShift then
    begin
      if FSelAnchorRow < 0 then
        FSelAnchorRow := FSelectedRow;
      if FSelAnchorRow < 0 then
        FSelAnchorRow := 0;

      for i := 0 to FRows.Count - 1 do
        TFtTableRow(FRows[i]).Selected := False;

      minIdx := Min(FSelAnchorRow, targetRow);
      maxIdx := Max(FSelAnchorRow, targetRow);
      for i := minIdx to maxIdx do
        TFtTableRow(FRows[i]).Selected := True;

      FSelectedRow := targetRow;
      Invalidate();
      if Assigned(FOnSelectRow) then
        FOnSelectRow(Self, FSelectedRow);
      if Assigned(FOnSelectRowCb) then
        FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
    end
    else
    begin
      SelectedRow := targetRow;
    end;
  end
  // Down Arrow ($FF54): Next Row
  else if (AKeySym = $FF54) and (FRows.Count > 0) then
  begin
    if (FSelectedRow >= 0) and (FSelectedRow < FRows.Count - 1) then
      targetRow := FSelectedRow + 1
    else if FSelectedRow < 0 then
      targetRow := 0
    else
      targetRow := FRows.Count - 1;

    if FMultiSelect and hasShift then
    begin
      if FSelAnchorRow < 0 then
        FSelAnchorRow := FSelectedRow;
      if FSelAnchorRow < 0 then
        FSelAnchorRow := 0;

      for i := 0 to FRows.Count - 1 do
        TFtTableRow(FRows[i]).Selected := False;

      minIdx := Min(FSelAnchorRow, targetRow);
      maxIdx := Max(FSelAnchorRow, targetRow);
      for i := minIdx to maxIdx do
        TFtTableRow(FRows[i]).Selected := True;

      FSelectedRow := targetRow;
      Invalidate();
      if Assigned(FOnSelectRow) then
        FOnSelectRow(Self, FSelectedRow);
      if Assigned(FOnSelectRowCb) then
        FOnSelectRowCb(Pointer(Self), FSelectedRow, FUserData);
    end
    else
    begin
      SelectedRow := targetRow;
    end;
  end;
end;

end.
