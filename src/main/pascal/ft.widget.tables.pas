unit Ft.Widget.Tables;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math, Types,
  Floria.Image.Core, Floria.Canvas.Agg, Floria.Font, Ft.Widget, Ft.Widget.Containers, Ft.Widget.ScrollBars, Ft.Widget.Texts, Ft.Theme, Ft.Css;

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
  TFtTableRowSelectCallback = procedure(Sender: Pointer; RowIndex: Integer; UserData: Pointer); cdecl;

  TFtTableDrawHeaderEvent = function(Sender: TObject; Canvas: TFtCanvasAgg; ColumnIndex: Integer;
    AX, AY, AW, AH: Double; ASortOrder: TFtSortOrder): Boolean of object;
  TFtTableDrawHeaderCallback = function(Sender: Pointer; Canvas: Pointer; ColumnIndex: Integer;
    AX, AY, AW, AH: Double; ASortOrder: Integer; UserData: Pointer): Integer; cdecl;

  TFtTableDrawCellEvent = function(Sender: TObject; Canvas: TFtCanvasAgg; RowIndex, ColumnIndex: Integer;
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
    FHeaderHeight: Double;
    FRowHeight: Double;
    FShowGridLines: Boolean;
    FZebraStriping: Boolean;
    FMultiSelect: Boolean;
    FOnSelectRow: TFtTableRowSelectEvent;
    FOnColumnClick: TFtTableColumnClickEvent;
    FOnSelectRowCb: TFtTableRowSelectCallback;
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
    function RowAtPosition(AY: Integer): Integer;
    function ColumnAtPosition(AX: Integer): Integer;
  protected
    procedure DrawBackground(Canvas: TFtCanvasAgg); override;
    procedure DrawContent(Canvas: TFtCanvasAgg); override;
    procedure DrawHeader(Canvas: TFtCanvasAgg); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;

    procedure RecalculateMetrics();
    function AddColumn(const ATitle: string; AWidth: Double = 100.0; AAlign: TFtTextAlign = taLeft): Integer;
    function AddRow(const AValues: array of string): Integer;
    procedure SetCell(ARow, ACol: Integer; const AValue: string);
    function GetCell(ARow, ACol: Integer): string;
    procedure SetColumnIcon(ACol: Integer; AIcon: TFloriaImage);
    function GetColumnIcon(ACol: Integer): TFloriaImage;
    procedure SetCellIcon(ARow, ACol: Integer; AIcon: TFloriaImage);
    function GetCellIcon(ARow, ACol: Integer): TFloriaImage;
    procedure SetOnDrawHeaderCb(ACallback: TFtTableDrawHeaderCallback; AUserData: Pointer);
    procedure SetOnDrawCellCb(ACallback: TFtTableDrawCellCallback; AUserData: Pointer);
    procedure DeleteRow(AIndex: Integer);
    procedure ClearRows();
    procedure ClearAll();

    procedure SelectAll();
    procedure ClearSelection();
    function IsRowSelected(AIndex: Integer): Boolean;
    procedure SetRowSelected(AIndex: Integer; ASelected: Boolean);
    function GetSelectedRowCount(): Integer;
    function GetSelectedRows(): TIntegerDynArray;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    property ColumnCount: Integer read GetColumnCount;
    property RowCount: Integer read GetRowCount;
    property Columns[AIndex: Integer]: TFtTableColumn read GetColumn;
    property Rows[AIndex: Integer]: TFtTableRow read GetRow;
    property SelectedRow: Integer read FSelectedRow write SetSelectedRow;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect;
    property HeaderHeight: Double read FHeaderHeight write SetHeaderHeight;
    property RowHeight: Double read FRowHeight write SetRowHeight;
    property ShowGridLines: Boolean read FShowGridLines write FShowGridLines;
    property ZebraStriping: Boolean read FZebraStriping write FZebraStriping;
    property OnSelectRow: TFtTableRowSelectEvent read FOnSelectRow write FOnSelectRow;
    property OnColumnClick: TFtTableColumnClickEvent read FOnColumnClick write FOnColumnClick;
    property OnSelectRowCb: TFtTableRowSelectCallback read FOnSelectRowCb write FOnSelectRowCb;
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
  FOnDrawHeader := nil;
  FOnDrawHeaderCb := nil;
  FOnDrawHeaderUserData := nil;
  FOnDrawCell := nil;
  FOnDrawCellCb := nil;
  FOnDrawCellUserData := nil;
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

procedure TFtTable.DrawBackground(Canvas: TFtCanvasAgg);
begin
  inherited DrawBackground(Canvas);
end;

procedure TFtTable.DrawHeader(Canvas: TFtCanvasAgg);
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
          iconY := hy + (hh - iconH) * 0.5;
          Canvas.DrawImageScaled(textStartX, iconY, iconW, iconH, col.Icon, 1.0);
          textStartX := textStartX + iconW + 6.0;
          textAvailW := textAvailW - (iconW + 6.0);
        end;

        // Column title text
        if textAvailW > 0.0 then
        begin
          case col.Alignment of
            taCenter:
              Canvas.DrawTextCentered(Round(textStartX), Round(hy), Round(textAvailW), Round(hh), col.Title, Font, textR, textG, textB);
            taRight:
              Canvas.DrawTextLeft(textStartX, hy + 4.0, textAvailW, hh - 8.0, col.Title, Font, textR, textG, textB);
            else
              Canvas.DrawTextLeft(textStartX, hy + 4.0, textAvailW, hh - 8.0, col.Title, Font, textR, textG, textB);
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
      if FShowGridLines and (i < FColumns.Count - 1) then
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

procedure TFtTable.DrawContent(Canvas: TFtCanvasAgg);
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
begin
  theme := FtGetTheme();
  accent := theme.GetAccentColor();
  bodyY := Y + FHeaderHeight;

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
        Canvas.DrawRoundedRect(X + 2.0, rowY + 1.0, Width - 4.0, FRowHeight - 2.0, 4.0, accent.R, accent.G, accent.B, 0.85);
        textR := 1.0; textG := 1.0; textB := 1.0;
      end
      else if isHovered then
      begin
        if theme.DarkMode then
          Canvas.DrawRoundedRect(X + 2.0, rowY + 1.0, Width - 4.0, FRowHeight - 2.0, 4.0, 0.24, 0.25, 0.32, 0.6)
        else
          Canvas.DrawRoundedRect(X + 2.0, rowY + 1.0, Width - 4.0, FRowHeight - 2.0, 4.0, 0.88, 0.90, 0.95, 0.6);
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
            Canvas.DrawRect(X + 1, Round(rowY), Width - 2, Round(FRowHeight), 0.16, 0.17, 0.22, 0.5)
          else
            Canvas.DrawRect(X + 1, Round(rowY), Width - 2, Round(FRowHeight), 0.95, 0.96, 0.98, 0.6);
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
            iconY := rowY + (FRowHeight - iconH) * 0.5;
            Canvas.DrawImageScaled(textStartX, iconY, iconW, iconH, cellIcon, 1.0);
            textStartX := textStartX + iconW + 6.0;
            textAvailW := textAvailW - (iconW + 6.0);
          end;

          if textAvailW > 0.0 then
          begin
            case col.Alignment of
              taCenter:
                Canvas.DrawTextCentered(Round(textStartX), Round(rowY), Round(textAvailW), Round(FRowHeight), cellText, Font, textR, textG, textB);
              taRight:
                Canvas.DrawTextLeft(textStartX, rowY + 3.0, textAvailW, FRowHeight - 6.0, cellText, Font, textR, textG, textB);
              else
                Canvas.DrawTextLeft(textStartX, rowY + 3.0, textAvailW, FRowHeight - 6.0, cellText, Font, textR, textG, textB);
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
          Canvas.DrawLine(X + 1, rowY + FRowHeight - 1.0, X + Width - 1, rowY + FRowHeight - 1.0, 1.0, 0.22, 0.23, 0.28, 0.4)
        else
          Canvas.DrawLine(X + 1, rowY + FRowHeight - 1.0, X + Width - 1, rowY + FRowHeight - 1.0, 1.0, 0.85, 0.86, 0.89, 0.4);
      end;
    end;
  finally
    Canvas.PopClipRect();
  end;
end;

procedure TFtTable.Draw(Canvas: TFtCanvasAgg);
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
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton = 1 then
  begin
    // Check if header clicked
    if (AY >= Y) and (AY <= Y + FHeaderHeight) then
    begin
      colIdx := ColumnAtPosition(AX);
      if colIdx >= 0 then
      begin
        if Assigned(FOnColumnClick) then
          FOnColumnClick(Self, colIdx);
      end;
    end
    else
    begin
      rowIdx := RowAtPosition(AY);
      if rowIdx >= 0 then
      begin
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
      end;
    end;
  end;
end;

procedure TFtTable.MouseMove(AX, AY: Integer);
var
  newHover: Integer;
begin
  inherited MouseMove(AX, AY);

  newHover := RowAtPosition(AY);
  if FHoveredRow <> newHover then
  begin
    FHoveredRow := newHover;
    Invalidate();
  end;
end;

procedure TFtTable.MouseLeave();
begin
  inherited MouseLeave();
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
