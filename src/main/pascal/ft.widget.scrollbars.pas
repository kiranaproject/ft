unit Ft.Widget.ScrollBars;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Floria.Canvas.Agg, Ft.Widget, Ft.Theme, Ft.Css;

type
  { ScrollBar visibility modes for scrollable containers }
  TFtScrollBarMode = (
    ftSbModeNone,            { Hide scroll bar }
    ftSbModeHorizontalOnly,  { Only horizontal }
    ftSbModeVerticalOnly,    { Only vertical }
    ftSbModeAutoBoth         { Auto show both }
  );

  TFtScrollCallback = procedure(Sender: Pointer; Value: Double; UserData: Pointer); cdecl;
  TFtScrollEvent = procedure(Sender: TObject; Value: Double) of object;

  TFtScrollBar = class(TFtWidget)
  private
    FOrientation: TFtScrollBarOrientation;
    FMin: Double;
    FMax: Double;
    FValue: Double;
    FPageSize: Double;
    FStep: Double;
    FCornerRadius: Double;
    FDragging: Boolean;
    FHovered: Boolean;
    FDragStartMouse: Double;
    FDragStartValue: Double;
    FOnScroll: TFtScrollCallback;
    FOnScrollEvent: TFtScrollEvent;
    FUserData: Pointer;

    procedure SetOrientation(AValue: TFtScrollBarOrientation);
    procedure SetMin(AValue: Double);
    procedure SetMax(AValue: Double);
    procedure SetValue(AValue: Double);
    procedure SetPageSize(AValue: Double);
    procedure SetCornerRadius(AValue: Double);

    procedure GetThumbRect(out AX, AY, AW, AH: Double);
    function IsPointInThumb(PX, PY: Double): Boolean;
    procedure NotifyScroll();
  public
    constructor Create(AParent: TFtWidget; AOrientation: TFtScrollBarOrientation = ftSbVertical); reintroduce;
    destructor Destroy(); override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    function GetCursor(): Integer; override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;

    procedure SetRange(AMin, AMax, APageSize: Double);

    property Orientation: TFtScrollBarOrientation read FOrientation write SetOrientation;
    property Min: Double read FMin write SetMin;
    property Max: Double read FMax write SetMax;
    property Value: Double read FValue write SetValue;
    property PageSize: Double read FPageSize write SetPageSize;
    property Step: Double read FStep write FStep;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property Dragging: Boolean read FDragging;
    property Hovered: Boolean read FHovered;
    property OnScroll: TFtScrollCallback read FOnScroll write FOnScroll;
    property OnScrollEvent: TFtScrollEvent read FOnScrollEvent write FOnScrollEvent;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtScrollBar }

constructor TFtScrollBar.Create(AParent: TFtWidget; AOrientation: TFtScrollBarOrientation = ftSbVertical);
begin
  inherited Create(AParent);
  FFocusable := False;
  FOrientation := AOrientation;
  FMin := 0.0;
  FMax := 100.0;
  FValue := 0.0;
  FPageSize := 20.0;
  FStep := 10.0;
  FCornerRadius := -1.0;
  FDragging := False;
  FHovered := False;
  FDragStartMouse := 0.0;
  FDragStartValue := 0.0;
  FOnScroll := nil;
  FOnScrollEvent := nil;
  FUserData := nil;

  if FOrientation = ftSbVertical then
  begin
    Width := 9;
    Height := 100;
  end
  else
  begin
    Width := 100;
    Height := 9;
  end;
end;

destructor TFtScrollBar.Destroy();
begin
  inherited Destroy();
end;

procedure TFtScrollBar.SetOrientation(AValue: TFtScrollBarOrientation);
begin
  if FOrientation <> AValue then
  begin
    FOrientation := AValue;
    Invalidate();
  end;
end;

procedure TFtScrollBar.SetMin(AValue: Double);
begin
  if Abs(FMin - AValue) > 1e-6 then
  begin
    FMin := AValue;
    if FMax < FMin then FMax := FMin;
    SetValue(FValue);
    Invalidate();
  end;
end;

procedure TFtScrollBar.SetMax(AValue: Double);
begin
  if Abs(FMax - AValue) > 1e-6 then
  begin
    FMax := AValue;
    if FMin > FMax then FMin := FMax;
    SetValue(FValue);
    Invalidate();
  end;
end;

procedure TFtScrollBar.SetValue(AValue: Double);
var
  clamped: Double;
begin
  clamped := AValue;
  if clamped < FMin then clamped := FMin;
  if clamped > FMax then clamped := FMax;

  if Abs(FValue - clamped) > 1e-6 then
  begin
    FValue := clamped;
    Invalidate();
    NotifyScroll();
  end;
end;

procedure TFtScrollBar.SetPageSize(AValue: Double);
begin
  if Abs(FPageSize - AValue) > 1e-6 then
  begin
    FPageSize := Math.Max(0.0, AValue);
    Invalidate();
  end;
end;

procedure TFtScrollBar.SetCornerRadius(AValue: Double);
begin
  if Abs(FCornerRadius - AValue) > 1e-6 then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtScrollBar.SetRange(AMin, AMax, APageSize: Double);
var
  newMax, newPage: Double;
  changed: Boolean;
begin
  if AMax < AMin then
    newMax := AMin
  else
    newMax := AMax;
  newPage := Math.Max(0.0, APageSize);

  changed := (Abs(FMin - AMin) > 1e-6) or
             (Abs(FMax - newMax) > 1e-6) or
             (Abs(FPageSize - newPage) > 1e-6);

  if not changed then Exit;

  FMin := AMin;
  FMax := newMax;
  FPageSize := newPage;
  SetValue(FValue);
  Invalidate();
end;

procedure TFtScrollBar.GetThumbRect(out AX, AY, AW, AH: Double);
var
  trackLength, rangeVal, thumbLength, travel, normVal: Double;
begin
  rangeVal := FMax - FMin;
  if FOrientation = ftSbVertical then
  begin
    trackLength := Height;
    if (rangeVal <= 0.0) or (FPageSize <= 0.0) then
      thumbLength := trackLength
    else
      thumbLength := Math.Max(16.0, trackLength * (FPageSize / (rangeVal + FPageSize)));

    if thumbLength > trackLength then
      thumbLength := trackLength;

    travel := trackLength - thumbLength;
    if (rangeVal > 0.0) and (travel > 0.0) then
    begin
      normVal := (FValue - FMin) / rangeVal;
      if normVal < 0.0 then normVal := 0.0;
      if normVal > 1.0 then normVal := 1.0;
      AY := Y + (normVal * travel);
    end
    else
      AY := Y;

    AX := X + 1.0;
    AW := Math.Max(2.0, Width - 2.0);
    AH := thumbLength;
  end
  else
  begin
    trackLength := Width;
    if (rangeVal <= 0.0) or (FPageSize <= 0.0) then
      thumbLength := trackLength
    else
      thumbLength := Math.Max(16.0, trackLength * (FPageSize / (rangeVal + FPageSize)));

    if thumbLength > trackLength then
      thumbLength := trackLength;

    travel := trackLength - thumbLength;
    if (rangeVal > 0.0) and (travel > 0.0) then
    begin
      normVal := (FValue - FMin) / rangeVal;
      if normVal < 0.0 then normVal := 0.0;
      if normVal > 1.0 then normVal := 1.0;
      AX := X + (normVal * travel);
    end
    else
      AX := X;

    AY := Y + 1.0;
    AW := thumbLength;
    AH := Math.Max(2.0, Height - 2.0);
  end;
end;

function TFtScrollBar.IsPointInThumb(PX, PY: Double): Boolean;
var
  tx, ty, tw, th: Double;
begin
  GetThumbRect(tx, ty, tw, th);
  Result := (PX >= tx) and (PX <= tx + tw) and (PY >= ty) and (PY <= ty + th);
end;

procedure TFtScrollBar.NotifyScroll();
begin
  if Assigned(FOnScrollEvent) then
    FOnScrollEvent(Self, FValue);
  if Assigned(FOnScroll) then
    FOnScroll(Self, FValue, FUserData);
end;

function TFtScrollBar.GetElementType(): string;
begin
  Result := 'scrollbar';
end;

function TFtScrollBar.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FDragging then
    Result := ':active'
  else if FHovered then
    Result := ':hover'
  else
    Result := '';
end;

function TFtScrollBar.GetCursor(): Integer;
begin
  Result := 0; { Arrow pointer }
end;

procedure TFtScrollBar.MouseEnter();
begin
  inherited MouseEnter();
  FHovered := True;
  InvalidateStyle();
  Invalidate();
end;

procedure TFtScrollBar.MouseLeave();
begin
  inherited MouseLeave();
  FHovered := False;
  InvalidateStyle();
  Invalidate();
end;

procedure TFtScrollBar.MouseDown(AX, AY: Integer; AButton: Integer);
var
  tx, ty, tw, th: Double;
begin
  inherited MouseDown(AX, AY, AButton);

  // Mouse wheel
  if AButton = 4 then
  begin
    SetValue(FValue - FStep);
    Exit;
  end;
  if AButton = 5 then
  begin
    SetValue(FValue + FStep);
    Exit;
  end;

  if AButton = 1 then
  begin
    GetThumbRect(tx, ty, tw, th);
    if (AX >= tx) and (AX <= tx + tw) and (AY >= ty) and (AY <= ty + th) then
    begin
      FDragging := True;
      if FOrientation = ftSbVertical then
        FDragStartMouse := AY
      else
        FDragStartMouse := AX;
      FDragStartValue := FValue;
      InvalidateStyle();
      Invalidate();
    end
    else
    begin
      // Clicked on track: page up/left or page down/right
      if FOrientation = ftSbVertical then
      begin
        if AY < ty then
          SetValue(FValue - FPageSize)
        else
          SetValue(FValue + FPageSize);
      end
      else
      begin
        if AX < tx then
          SetValue(FValue - FPageSize)
        else
          SetValue(FValue + FPageSize);
      end;
    end;
  end;
end;

procedure TFtScrollBar.MouseMove(AX, AY: Integer);
var
  tx, ty, tw, th: Double;
  delta, travel, rangeVal, newVal: Double;
begin
  inherited MouseMove(AX, AY);

  if FDragging then
  begin
    GetThumbRect(tx, ty, tw, th);
    rangeVal := FMax - FMin;
    if FOrientation = ftSbVertical then
    begin
      travel := Height - th;
      delta := AY - FDragStartMouse;
    end
    else
    begin
      travel := Width - tw;
      delta := AX - FDragStartMouse;
    end;

    if (travel > 0.0) and (rangeVal > 0.0) then
    begin
      newVal := FDragStartValue + (delta / travel) * rangeVal;
      SetValue(newVal);
    end;
  end;
end;

procedure TFtScrollBar.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseUp(AX, AY, AButton);
  if AButton = 1 then
  begin
    FDragging := False;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtScrollBar.Draw(Canvas: TFtCanvasAgg);
var
  curTheme: TFtTheme;
  tx, ty, tw, th: Double;
  st: TFtWidgetStyle;
  rad: Double;
  trackR, trackG, trackB, trackA: Double;
  thumbR, thumbG, thumbB, thumbA: Double;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  GetThumbRect(tx, ty, tw, th);

  if st.HasBgColor or st.HasTextColor or st.HasBorderRadius then
  begin
    if st.HasBorderRadius then
      rad := st.BorderRadius
    else if FCornerRadius >= 0.0 then
      rad := FCornerRadius
    else
      rad := 3.0;

    if st.HasBgColor then
    begin
      trackR := st.BgColor.R; trackG := st.BgColor.G; trackB := st.BgColor.B; trackA := st.BgColor.A;
    end
    else
    begin
      trackR := 0.92; trackG := 0.93; trackB := 0.95; trackA := 1.0;
    end;

    if st.HasTextColor then
    begin
      thumbR := st.TextColor.R; thumbG := st.TextColor.G; thumbB := st.TextColor.B; thumbA := st.TextColor.A;
    end
    else
    begin
      thumbR := 0.72; thumbG := 0.75; thumbB := 0.78; thumbA := 1.0;
    end;

    Canvas.DrawRoundedRect(X, Y, Width, Height, rad, trackR, trackG, trackB, trackA);
    Canvas.DrawRoundedRect(tx, ty, tw, th, rad, thumbR, thumbG, thumbB, thumbA);
  end
  else
  begin
    curTheme := FtGetTheme();
    curTheme.DrawScrollBar(Canvas, X, Y, Width, Height, FOrientation, tx, ty, tw, th, FHovered, FDragging, FCornerRadius);
  end;

  inherited Draw(Canvas);
end;

end.
