unit Ft.Widget.Buttons;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Theme, Ft.Css;

type
  TFtClickCallback = procedure(Sender: Pointer; UserData: Pointer); cdecl;
  TFtHoverCallback = procedure(Sender: Pointer; Hovered: cint32; UserData: Pointer); cdecl;
  TFtPressCallback = procedure(Sender: Pointer; Pressed: cint32; UserData: Pointer); cdecl;
  TFtToggleCallback = procedure(Sender: Pointer; Toggled: cint32; UserData: Pointer); cdecl;

  TFtButton = class(TFtWidget)
  private
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FCanToggle: Boolean;
    FToggled: Boolean;
    FCornerRadius: Double;
    FEnableShadow: Integer;
    FOnClick: TFtClickCallback;
    FOnHover: TFtHoverCallback;
    FOnPress: TFtPressCallback;
    FOnToggle: TFtToggleCallback;
    FUserData: Pointer;
    procedure SetToggled(AValue: Boolean);
    procedure SetCanToggle(AValue: Boolean);
    procedure SetCornerRadius(AValue: Double);
    procedure SetEnableShadow(AValue: Integer);
  public
    Caption: string;
    constructor Create(AParent: TFtWidget); override;

    function GetElementType(): string; override;
    function GetStatePseudoClass(): string; override;
    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure KeyUp(AKeySym: Cardinal; AState: Cardinal); override;
    procedure LostFocus(); override;

    property State: TFtButtonState read FState;
    property CanToggle: Boolean read FCanToggle write SetCanToggle;
    property Toggled: Boolean read FToggled write SetToggled;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property EnableShadow: Integer read FEnableShadow write SetEnableShadow;
    property OnClick: TFtClickCallback read FOnClick write FOnClick;
    property OnHover: TFtHoverCallback read FOnHover write FOnHover;
    property OnPress: TFtPressCallback read FOnPress write FOnPress;
    property OnToggle: TFtToggleCallback read FOnToggle write FOnToggle;
    property UserData: Pointer read FUserData write FUserData;
  end;

  TFtToggleButton = class(TFtButton)
  public
    constructor Create(AParent: TFtWidget); override;
  end;

implementation

{ TFtButton }

constructor TFtButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FFocusable := True;
  FState := bsNormal;
  FIsMouseDown := False;
  FCanToggle := False;
  FToggled := False;
  FCornerRadius := -1.0;
  FEnableShadow := -1;
  FOnClick := nil;
  FOnHover := nil;
  FOnPress := nil;
  FOnToggle := nil;
  FUserData := nil;
end;

procedure TFtButton.SetCornerRadius(AValue: Double);
begin
  if FCornerRadius <> AValue then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtButton.SetEnableShadow(AValue: Integer);
begin
  if FEnableShadow <> AValue then
  begin
    FEnableShadow := AValue;
    Invalidate();
  end;
end;

procedure TFtButton.SetCanToggle(AValue: Boolean);
begin
  if FCanToggle <> AValue then
  begin
    FCanToggle := AValue;
    if not FCanToggle and FToggled then
      SetToggled(False);
  end;
end;

procedure TFtButton.SetToggled(AValue: Boolean);
begin
  if FToggled <> AValue then
  begin
    FToggled := AValue;
    Invalidate();
    if Assigned(FOnToggle) then
    begin
      if FToggled then
        FOnToggle(Self, 1, FUserData)
      else
        FOnToggle(Self, 0, FUserData);
    end;
  end;
end;

function TFtButton.GetElementType(): string;
begin
  Result := 'button';
end;

function TFtButton.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FState = bsPressed then
    Result := ':active'
  else if FState = bsHovered then
    Result := ':hover'
  else if FCanToggle and FToggled then
    Result := ':checked'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

procedure TFtButton.MouseEnter();
begin
  if FIsMouseDown then
    FState := bsPressed
  else
    FState := bsHovered;
  InvalidateStyle();
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 1, FUserData);
end;

procedure TFtButton.MouseLeave();
begin
  FState := bsNormal;
  InvalidateStyle();
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 0, FUserData);
end;

procedure TFtButton.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  inherited MouseDown(AX, AY, AButton);
  if AButton = 1 then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnPress) then
      FOnPress(Self, 1, FUserData);
  end;
end;

procedure TFtButton.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  if AButton = 1 then
  begin
    FIsMouseDown := False;
    if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    InvalidateStyle();
    Invalidate();
    if Assigned(FOnPress) then
      FOnPress(Self, 0, FUserData);
  end;
end;

procedure TFtButton.Click();
begin
  if FCanToggle then
    SetToggled(not FToggled);
  if Assigned(FOnClick) then
    FOnClick(Self, FUserData);
end;

procedure TFtButton.Draw(Canvas: TFtCanvasAgg);
var
  effRadius: Double;
  st: TFtWidgetStyle;
  bw: Double;
  txtFont: TFtFont;
  txtR, txtG, txtB: Double;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  if st.HasBgColor or st.HasBorderColor or st.HasBorderRadius or st.HasTextColor then
  begin
    if st.HasBorderRadius then
      effRadius := st.BorderRadius
    else if FCornerRadius >= 0.0 then
      effRadius := FCornerRadius
    else
      effRadius := FtGetTheme().CornerRadius;

    // 1. Drop shadow
    if (st.HasShadow and st.EnableShadow) or
       (not st.HasShadow and (FEnableShadow = 1)) or
       (not st.HasShadow and (FEnableShadow = -1) and FtGetTheme().EnableShadow) then
    begin
      Canvas.DrawShadow(X, Y, Width, Height, effRadius, 0.0, 2.0, 4.0, 0.0, 0.0, 0.0, 0.18);
    end;

    // 2. Background
    if st.HasBgColor then
      Canvas.DrawRoundedRect(X, Y, Width, Height, effRadius, st.BgColor.R, st.BgColor.G, st.BgColor.B, st.BgColor.A)
    else
      Canvas.DrawRoundedRect(X, Y, Width, Height, effRadius, 0.23, 0.51, 0.96, 1.0);

    // 3. Border outline
    bw := 1.0;
    if st.HasBorderWidth then bw := st.BorderWidth;
    if bw > 0.0 then
    begin
      if st.HasBorderColor then
        Canvas.DrawRoundedRectOutline(X, Y, Width, Height, effRadius, bw, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, st.BorderColor.A)
      else if st.HasBgColor then
        Canvas.DrawRoundedRectOutline(X, Y, Width, Height, effRadius, bw, st.BgColor.R * 0.8, st.BgColor.G * 0.8, st.BgColor.B * 0.8, 1.0);
    end;

    // 4. Centered text
    if Caption <> '' then
    begin
      txtFont := GetFont();
      txtR := 1.0; txtG := 1.0; txtB := 1.0;
      if st.HasTextColor then
      begin
        txtR := st.TextColor.R;
        txtG := st.TextColor.G;
        txtB := st.TextColor.B;
      end;
      Canvas.DrawTextCentered(X, Y, Width, Height, Caption, txtFont, txtR, txtG, txtB);
    end;
  end
  else
  begin
    FtGetTheme().DrawButtonEx(Canvas, X, Y, Width, Height, FState, FToggled, Caption, GetFont(), FCornerRadius, FEnableShadow);
  end;

  if FFocused then
  begin
    if st.HasBorderRadius then
      effRadius := st.BorderRadius
    else if FCornerRadius >= 0.0 then
      effRadius := FCornerRadius
    else
      effRadius := FtGetTheme().CornerRadius;
    FtGetTheme().DrawFocusRing(Canvas, X, Y, Width, Height, effRadius);
  end;

  inherited Draw(Canvas);
end;

procedure TFtButton.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if (AKeySym = $20) then // Space
  begin
    if FState <> bsPressed then
    begin
      FState := bsPressed;
      InvalidateStyle();
      Invalidate();
    end;
  end
  else if (AKeySym = $FF0D) or (AKeySym = $FF8D) then // Return / Enter
  begin
    Click();
  end;
end;

procedure TFtButton.KeyUp(AKeySym: Cardinal; AState: Cardinal);
begin
  inherited KeyUp(AKeySym, AState);
  if (AKeySym = $20) then // Space
  begin
    if FState = bsPressed then
    begin
      FState := bsNormal;
      InvalidateStyle();
      Invalidate();
      Click();
    end;
  end;
end;

procedure TFtButton.LostFocus();
begin
  if FState = bsPressed then
  begin
    FState := bsNormal;
    InvalidateStyle();
    Invalidate();
  end;
  inherited LostFocus();
end;

{ TFtToggleButton }

constructor TFtToggleButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FCanToggle := True;
end;

end.
