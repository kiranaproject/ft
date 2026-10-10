unit Ft.Widget.Splitters;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Ft.Canvas, Floria.Font, Ft.Widget, Ft.Widget.Containers, Ft.Theme, Ft.Css;

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
    FDragStartPrevSize: Double;
    FDragStartNextSize: Double;
    FDragStartPrevGrow: Double;
    FDragStartNextGrow: Double;
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
    function FindFlexSiblings(out APrev, ANext: TFtWidget): Boolean;
  protected
    procedure DrawSplitterBar(Canvas: TFtCanvas); virtual;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;
    function IsFlexMode(): Boolean;

    procedure UpdateLayout(); virtual;
    procedure SetPanes(APane1, APane2: TFtWidget);
    procedure SetMinSizes(AMinPane1, AMinPane2: Double);
    procedure SetSplitterRatio(ARatio: Double); // 0.0 .. 1.0

    procedure Draw(Canvas: TFtCanvas); override;
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

uses
  Ft.Widget.Layouts;

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
  FDragStartPrevSize := 0.0;
  FDragStartNextSize := 0.0;
  FDragStartPrevGrow := 0.0;
  FDragStartNextGrow := 0.0;
  FFlexGrow := 0.0;
  FFlexShrink := 0.0;
  FFlexBasis := FSplitterSize;
  if Assigned(AParent) and (AParent is TFtFlexBox) then
  begin
    if TFtFlexBox(AParent).Direction = ftfdRow then
    begin
      Width := Round(FSplitterSize);
      Height := AParent.Height;
      FOrientation := soHorizontal;
    end
    else
    begin
      Width := AParent.Width;
      Height := Round(FSplitterSize);
      FOrientation := soVertical;
    end;
    FPreferredWidth := Width;
    FPreferredHeight := Height;
  end;
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

procedure TFtSplitter.SetMinSizes(AMinPane1, AMinPane2: Double);
begin
  SetMinPane1Size(AMinPane1);
  SetMinPane2Size(AMinPane2);
end;

function TFtSplitter.IsFlexMode(): Boolean;
begin
  Result := Assigned(Parent) and (Parent is TFtFlexBox) and (FPane1 = nil) and (FPane2 = nil);
end;

function TFtSplitter.FindFlexSiblings(out APrev, ANext: TFtWidget): Boolean;
var
  i, myIdx: Integer;
begin
  APrev := nil;
  ANext := nil;
  Result := False;
  if not IsFlexMode() or not Assigned(Parent) or not Assigned(Parent.Children) then Exit;

  myIdx := Parent.Children.IndexOf(Self);
  if myIdx < 0 then Exit;

  for i := myIdx - 1 downto 0 do
  begin
    if TFtWidget(Parent.Children[i]).Visible then
    begin
      APrev := TFtWidget(Parent.Children[i]);
      Break;
    end;
  end;

  for i := myIdx + 1 to Parent.Children.Count - 1 do
  begin
    if TFtWidget(Parent.Children[i]).Visible then
    begin
      ANext := TFtWidget(Parent.Children[i]);
      Break;
    end;
  end;

  Result := Assigned(APrev) and Assigned(ANext);
end;

function TFtSplitter.GetSplitterBarRect(out BX, BY, BW, BH: Double): Boolean;
begin
  Result := True;
  if IsFlexMode() then
  begin
    BX := X;
    BY := Y;
    BW := Width;
    BH := Height;
    Exit;
  end;

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
  margin := 3.0; // hit margin for easier grab
  if IsFlexMode() then
  begin
    Result := (AX >= X - margin) and (AX <= X + Width + margin) and
              (AY >= Y - margin) and (AY <= Y + Height + margin);
    Exit;
  end;
  if not GetSplitterBarRect(bx, by, bw, bh) then Exit;
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

procedure TFtSplitter.DrawSplitterBar(Canvas: TFtCanvas);
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

procedure TFtSplitter.Draw(Canvas: TFtCanvas);
begin
  if not Visible then Exit;

  if not IsFlexMode() then
  begin
    if Assigned(FPane1) and FPane1.Visible then
      FPane1.Draw(Canvas);

    if Assigned(FPane2) and FPane2.Visible then
      FPane2.Draw(Canvas);
  end;

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

  if not IsFlexMode() then
  begin
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
  end;
end;

procedure TFtSplitter.MouseDown(AX, AY: Integer; AButton: Integer);
var
  p1, p2: TFtWidget;
  isRow: Boolean;
begin
  inherited MouseDown(AX, AY, AButton);

  if (AButton = 1) and IsInSplitterBar(AX, AY) then
  begin
    FDragging := True;
    FDragStartPos := FSplitterPos;

    if IsFlexMode() then
    begin
      isRow := (TFtFlexBox(Parent).Direction = ftfdRow);
      if isRow then
        FDragStartMouse := AX
      else
        FDragStartMouse := AY;

      if FindFlexSiblings(p1, p2) then
      begin
        if isRow then
        begin
          FDragStartPrevSize := p1.Width;
          FDragStartNextSize := p2.Width;
        end
        else
        begin
          FDragStartPrevSize := p1.Height;
          FDragStartNextSize := p2.Height;
        end;
        FDragStartPrevGrow := p1.FlexGrow;
        FDragStartNextGrow := p2.FlexGrow;
      end;
    end
    else
    begin
      if FOrientation = soHorizontal then
        FDragStartMouse := AX
      else
        FDragStartMouse := AY;
    end;

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
  p1, p2: TFtWidget;
  isRow: Boolean;
  newPrev, newNext: Double;
  totalGrow, combinedSize: Double;
begin
  inherited MouseMove(AX, AY);

  if FDragging then
  begin
    if IsFlexMode() then
    begin
      isRow := (TFtFlexBox(Parent).Direction = ftfdRow);
      if isRow then
        delta := AX - FDragStartMouse
      else
        delta := AY - FDragStartMouse;

      if FindFlexSiblings(p1, p2) then
      begin
        newPrev := FDragStartPrevSize + delta;
        newNext := FDragStartNextSize - delta;

        if newPrev < FMinPane1Size then
        begin
          newPrev := FMinPane1Size;
          newNext := (FDragStartPrevSize + FDragStartNextSize) - newPrev;
        end;
        if newNext < FMinPane2Size then
        begin
          newNext := FMinPane2Size;
          newPrev := (FDragStartPrevSize + FDragStartNextSize) - newNext;
        end;

        if (FDragStartPrevGrow > 0.0) and (FDragStartNextGrow > 0.0) then
        begin
          totalGrow := FDragStartPrevGrow + FDragStartNextGrow;
          combinedSize := newPrev + newNext;
          if combinedSize > 0.0 then
          begin
            p1.FlexGrow := totalGrow * (newPrev / combinedSize);
            p2.FlexGrow := totalGrow * (newNext / combinedSize);
            p1.FlexBasis := newPrev;
            p2.FlexBasis := newNext;
            if isRow then
            begin
              p1.PreferredWidth := Round(newPrev);
              p2.PreferredWidth := Round(newNext);
            end
            else
            begin
              p1.PreferredHeight := Round(newPrev);
              p2.PreferredHeight := Round(newNext);
            end;
          end;
        end
        else if (FDragStartPrevGrow = 0.0) and (FDragStartNextGrow > 0.0) then
        begin
          if isRow then
          begin
            p1.PreferredWidth := Round(newPrev);
            p1.Width := Round(newPrev);
          end
          else
          begin
            p1.PreferredHeight := Round(newPrev);
            p1.Height := Round(newPrev);
          end;
          p1.FlexBasis := newPrev;
        end
        else if (FDragStartPrevGrow > 0.0) and (FDragStartNextGrow = 0.0) then
        begin
          if isRow then
          begin
            p2.PreferredWidth := Round(newNext);
            p2.Width := Round(newNext);
          end
          else
          begin
            p2.PreferredHeight := Round(newNext);
            p2.Height := Round(newNext);
          end;
          p2.FlexBasis := newNext;
        end
        else
        begin
          if isRow then
          begin
            p1.PreferredWidth := Round(newPrev);
            p2.PreferredWidth := Round(newNext);
          end
          else
          begin
            p1.PreferredHeight := Round(newPrev);
            p2.PreferredHeight := Round(newNext);
          end;
        end;

        TFtFlexBox(Parent).UpdateLayout();
        if Assigned(FOnPositionChange) then
          FOnPositionChange(Self, newPrev);
        if Assigned(FOnPositionChangeCb) then
          FOnPositionChangeCb(Pointer(Self), newPrev, FUserData);
        Parent.Invalidate();
      end;
    end
    else
    begin
      if FOrientation = soHorizontal then
        delta := AX - FDragStartMouse
      else
        delta := AY - FDragStartMouse;

      SetSplitterPos(FDragStartPos + delta);
    end;
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
    if IsFlexMode() then
    begin
      if TFtFlexBox(Parent).Direction = ftfdRow then
        Result := FT_CURSOR_SIZE_H
      else
        Result := FT_CURSOR_SIZE_V;
    end
    else
    begin
      if FOrientation = soHorizontal then
        Result := FT_CURSOR_SIZE_H
      else
        Result := FT_CURSOR_SIZE_V;
    end;
  end
  else
    Result := inherited GetCursor();
end;

end.
