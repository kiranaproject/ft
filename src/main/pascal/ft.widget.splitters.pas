unit Ft.Widget.Splitters;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Floria.Canvas.Agg, Floria.Font, Ft.Widget, Ft.Widget.Containers, Ft.Theme, Ft.Css;

type
  TFtSplitterOrientation = (soHorizontal, soVertical);

  TFtSplitterPositionChangeEvent = procedure(Sender: TObject; Position: Double) of object;
  TFtSplitterPositionCallback = procedure(Sender: Pointer; Position: Double; UserData: Pointer); cdecl;

  TFtSplitter = class(TFtWidget)
  private
    FOrientation: TFtSplitterOrientation;
    FPane1: TFtWidget;
    FPane2: TFtWidget;
    FSplitterSize: Double;
    FSplitterPos: Double; // Absolute pixel position from left/top
    FMinPane1Size: Double;
    FMinPane2Size: Double;
    FDragging: Boolean;
    FHovered: Boolean;
    FDragStartMouse: Integer;
    FDragStartPos: Double;
    FOnPositionChange: TFtSplitterPositionChangeEvent;
    FOnPositionChangeCb: TFtSplitterPositionCallback;
    FUserData: Pointer;

    procedure SetOrientation(AValue: TFtSplitterOrientation);
    procedure SetSplitterSize(AValue: Double);
    procedure SetSplitterPos(AValue: Double);
    procedure SetMinPane1Size(AValue: Double);
    procedure SetMinPane2Size(AValue: Double);
    procedure SetPane1(AValue: TFtWidget);
    procedure SetPane2(AValue: TFtWidget);
    function GetSplitterBarRect(out BX, BY, BW, BH: Double): Boolean;
    function IsInSplitterBar(AX, AY: Integer): Boolean;
  protected
    procedure DrawSplitterBar(Canvas: TFtCanvasAgg); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;

    procedure UpdateLayout(); virtual;
    procedure SetPanes(APane1, APane2: TFtWidget);
    procedure SetSplitterRatio(ARatio: Double); // 0.0 .. 1.0

    procedure Draw(Canvas: TFtCanvasAgg); override;
    function HitTest(AX, AY: Integer): TFtWidget; override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseLeave(); override;
    function GetCursor(): Integer; override;

    property Orientation: TFtSplitterOrientation read FOrientation write SetOrientation;
    property Pane1: TFtWidget read FPane1 write SetPane1;
    property Pane2: TFtWidget read FPane2 write SetPane2;
    property SplitterSize: Double read FSplitterSize write SetSplitterSize;
    property SplitterPos: Double read FSplitterPos write SetSplitterPos;
    property MinPane1Size: Double read FMinPane1Size write SetMinPane1Size;
    property MinPane2Size: Double read FMinPane2Size write SetMinPane2Size;
    property OnPositionChange: TFtSplitterPositionChangeEvent read FOnPositionChange write FOnPositionChange;
    property OnPositionChangeCb: TFtSplitterPositionCallback read FOnPositionChangeCb write FOnPositionChangeCb;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtSplitter }

constructor TFtSplitter.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FOrientation := soHorizontal;
  FPane1 := nil;
  FPane2 := nil;
  FSplitterSize := 6.0;
  FSplitterPos := -1.0; // Default to 50% upon first layout
  FMinPane1Size := 40.0;
  FMinPane2Size := 40.0;
  FDragging := False;
  FHovered := False;
  FDragStartMouse := 0;
  FDragStartPos := 0.0;
end;

destructor TFtSplitter.Destroy();
begin
  inherited Destroy();
end;

function TFtSplitter.GetElementType(): string;
begin
  Result := 'splitter';
end;

procedure TFtSplitter.SetOrientation(AValue: TFtSplitterOrientation);
begin
  if FOrientation <> AValue then
  begin
    FOrientation := AValue;
    UpdateLayout();
  end;
end;

procedure TFtSplitter.SetSplitterSize(AValue: Double);
begin
  if AValue < 3.0 then AValue := 3.0;
  if FSplitterSize <> AValue then
  begin
    FSplitterSize := AValue;
    UpdateLayout();
  end;
end;

procedure TFtSplitter.SetSplitterPos(AValue: Double);
var
  maxPos: Double;
begin
  if FOrientation = soHorizontal then
    maxPos := Width - FSplitterSize - FMinPane2Size
  else
    maxPos := Height - FSplitterSize - FMinPane2Size;

  if AValue < FMinPane1Size then AValue := FMinPane1Size;
  if (maxPos > FMinPane1Size) and (AValue > maxPos) then AValue := maxPos;

  if FSplitterPos <> AValue then
  begin
    FSplitterPos := AValue;
    UpdateLayout();
    if Assigned(FOnPositionChange) then
      FOnPositionChange(Self, FSplitterPos);
    if Assigned(FOnPositionChangeCb) then
      FOnPositionChangeCb(Pointer(Self), FSplitterPos, FUserData);
  end;
end;

procedure TFtSplitter.SetSplitterRatio(ARatio: Double);
var
  total: Double;
begin
  if ARatio < 0.05 then ARatio := 0.05;
  if ARatio > 0.95 then ARatio := 0.95;

  if FOrientation = soHorizontal then
    total := Width
  else
    total := Height;

  SetSplitterPos((total - FSplitterSize) * ARatio);
end;

procedure TFtSplitter.SetMinPane1Size(AValue: Double);
begin
  if AValue < 10.0 then AValue := 10.0;
  FMinPane1Size := AValue;
  UpdateLayout();
end;

procedure TFtSplitter.SetMinPane2Size(AValue: Double);
begin
  if AValue < 10.0 then AValue := 10.0;
  FMinPane2Size := AValue;
  UpdateLayout();
end;

procedure TFtSplitter.SetPane1(AValue: TFtWidget);
begin
  FPane1 := AValue;
  UpdateLayout();
end;

procedure TFtSplitter.SetPane2(AValue: TFtWidget);
begin
  FPane2 := AValue;
  UpdateLayout();
end;

procedure TFtSplitter.SetPanes(APane1, APane2: TFtWidget);
begin
  FPane1 := APane1;
  FPane2 := APane2;
  UpdateLayout();
end;

function TFtSplitter.GetSplitterBarRect(out BX, BY, BW, BH: Double): Boolean;
begin
  Result := True;
  if FSplitterPos < 0.0 then
  begin
    if FOrientation = soHorizontal then
      FSplitterPos := (Width - FSplitterSize) * 0.5
    else
      FSplitterPos := (Height - FSplitterSize) * 0.5;
  end;

  if FOrientation = soHorizontal then
  begin
    BX := X + FSplitterPos;
    BY := Y;
    BW := FSplitterSize;
    BH := Height;
  end
  else
  begin
    BX := X;
    BY := Y + FSplitterPos;
    BW := Width;
    BH := FSplitterSize;
  end;
end;

function TFtSplitter.IsInSplitterBar(AX, AY: Integer): Boolean;
var
  bx, by, bw, bh: Double;
  margin: Double;
begin
  Result := False;
  if not GetSplitterBarRect(bx, by, bw, bh) then Exit;
  margin := 2.0; // hit margin for easier grab
  Result := (AX >= bx - margin) and (AX <= bx + bw + margin) and
            (AY >= by - margin) and (AY <= by + bh + margin);
end;

procedure TFtSplitter.UpdateLayout();
var
  p1W, p1H, p2X, p2Y, p2W, p2H: Integer;

  procedure UpdatePanePos(APane: TFtWidget; NewX, NewY, NewW, NewH: Integer);
  var
    dx, dy, i: Integer;
    child: TFtWidget;
  begin
    if not Assigned(APane) then Exit;
    dx := NewX - APane.X;
    dy := NewY - APane.Y;
    APane.X := NewX;
    APane.Y := NewY;
    APane.Width := NewW;
    APane.Height := NewH;
    if ((dx <> 0) or (dy <> 0)) and Assigned(APane.Children) then
    begin
      for i := 0 to APane.Children.Count - 1 do
      begin
        child := TFtWidget(APane.Children[i]);
        child.X := child.X + dx;
        child.Y := child.Y + dy;
      end;
    end;
  end;

begin
  if FSplitterPos < 0.0 then
  begin
    if FOrientation = soHorizontal then
      FSplitterPos := (Width - FSplitterSize) * 0.5
    else
      FSplitterPos := (Height - FSplitterSize) * 0.5;
  end;

  if FOrientation = soHorizontal then
  begin
    p1W := Round(FSplitterPos);
    if p1W < Round(FMinPane1Size) then p1W := Round(FMinPane1Size);

    UpdatePanePos(FPane1, X, Y, p1W, Height);

    p2X := X + p1W + Round(FSplitterSize);
    p2W := Width - (p1W + Round(FSplitterSize));
    if p2W < 0 then p2W := 0;

    UpdatePanePos(FPane2, p2X, Y, p2W, Height);
  end
  else
  begin
    p1H := Round(FSplitterPos);
    if p1H < Round(FMinPane1Size) then p1H := Round(FMinPane1Size);

    UpdatePanePos(FPane1, X, Y, Width, p1H);

    p2Y := Y + p1H + Round(FSplitterSize);
    p2H := Height - (p1H + Round(FSplitterSize));
    if p2H < 0 then p2H := 0;

    UpdatePanePos(FPane2, X, p2Y, Width, p2H);
  end;
  Invalidate();
end;

procedure TFtSplitter.DrawSplitterBar(Canvas: TFtCanvasAgg);
var
  bx, by, bw, bh: Double;
  theme: TFtTheme;
  accent: TFtRgbColor;
  dotR, dotG, dotB, dotA: Double;
  cx, cy: Double;
begin
  if not GetSplitterBarRect(bx, by, bw, bh) then Exit;
  theme := FtGetTheme();
  accent := theme.GetAccentColor();

  // Splitter background is transparent!
  // During active dragging, draw a subtle accent-tinted indicator line
  if FDragging then
  begin
    Canvas.DrawRect(Round(bx), Round(by), Round(bw), Round(bh), accent.R, accent.G, accent.B, 0.65);
  end;

  // Subtle center grip dots (transparent background preserved; low-opacity dots)
  cx := bx + bw * 0.5;
  cy := by + bh * 0.5;

  if theme.DarkMode then
  begin
    dotR := 0.7; dotG := 0.7; dotB := 0.7; dotA := 0.25;
  end
  else
  begin
    dotR := 0.3; dotG := 0.3; dotB := 0.3; dotA := 0.25;
  end;

  if FOrientation = soHorizontal then
  begin
    Canvas.DrawCircle(cx, cy - 8.0, 1.2, dotR, dotG, dotB, dotA);
    Canvas.DrawCircle(cx, cy,       1.2, dotR, dotG, dotB, dotA);
    Canvas.DrawCircle(cx, cy + 8.0, 1.2, dotR, dotG, dotB, dotA);
  end
  else
  begin
    Canvas.DrawCircle(cx - 8.0, cy, 1.2, dotR, dotG, dotB, dotA);
    Canvas.DrawCircle(cx,       cy, 1.2, dotR, dotG, dotB, dotA);
    Canvas.DrawCircle(cx + 8.0, cy, 1.2, dotR, dotG, dotB, dotA);
  end;
end;

procedure TFtSplitter.Draw(Canvas: TFtCanvasAgg);
begin
  if not Visible then Exit;

  if Assigned(FPane1) and FPane1.Visible then
    FPane1.Draw(Canvas);

  if Assigned(FPane2) and FPane2.Visible then
    FPane2.Draw(Canvas);

  DrawSplitterBar(Canvas);
end;

function TFtSplitter.HitTest(AX, AY: Integer): TFtWidget;
var
  w: TFtWidget;
begin
  Result := nil;
  if not Visible or not Enabled then Exit;

  if IsInSplitterBar(AX, AY) then
    Exit(Self);

  if Assigned(FPane1) and FPane1.Visible then
  begin
    w := FPane1.HitTest(AX, AY);
    if Assigned(w) then Exit(w);
  end;

  if Assigned(FPane2) and FPane2.Visible then
  begin
    w := FPane2.HitTest(AX, AY);
    if Assigned(w) then Exit(w);
  end;

  if (AX >= X) and (AX <= X + Width) and (AY >= Y) and (AY <= Y + Height) then
    Result := Self;
end;

procedure TFtSplitter.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);

  if (AButton = 1) and IsInSplitterBar(AX, AY) then
  begin
    FDragging := True;
    FDragStartPos := FSplitterPos;
    if FOrientation = soHorizontal then
      FDragStartMouse := AX
    else
      FDragStartMouse := AY;
    Invalidate();
  end;
end;

procedure TFtSplitter.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if FDragging then
  begin
    FDragging := False;
    Invalidate();
  end;
end;

procedure TFtSplitter.MouseMove(AX, AY: Integer);
var
  delta: Integer;
  wasHover: Boolean;
begin
  inherited MouseMove(AX, AY);

  if FDragging then
  begin
    if FOrientation = soHorizontal then
      delta := AX - FDragStartMouse
    else
      delta := AY - FDragStartMouse;

    SetSplitterPos(FDragStartPos + delta);
  end
  else
  begin
    wasHover := FHovered;
    FHovered := IsInSplitterBar(AX, AY);
    if wasHover <> FHovered then
      Invalidate();
  end;
end;

procedure TFtSplitter.MouseLeave();
begin
  inherited MouseLeave();
  if FHovered and not FDragging then
  begin
    FHovered := False;
    Invalidate();
  end;
end;

function TFtSplitter.GetCursor(): Integer;
begin
  if FHovered or FDragging then
  begin
    if FOrientation = soHorizontal then
      Result := FT_CURSOR_SIZE_H
    else
      Result := FT_CURSOR_SIZE_V;
  end
  else
    Result := inherited GetCursor();
end;

end.
