unit Ft.Buttons;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Ft.Canvas.Agg, Ft.Widget;

type
  TFtButtonState = (bsNormal, bsHovered, bsPressed);

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
    FOnClick: TFtClickCallback;
    FOnHover: TFtHoverCallback;
    FOnPress: TFtPressCallback;
    FOnToggle: TFtToggleCallback;
    FUserData: Pointer;
    procedure SetToggled(AValue: Boolean);
    procedure SetCanToggle(AValue: Boolean);
  public
    Caption: string;
    constructor Create(AParent: TFtWidget); override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;

    property State: TFtButtonState read FState;
    property CanToggle: Boolean read FCanToggle write SetCanToggle;
    property Toggled: Boolean read FToggled write SetToggled;
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
  FState := bsNormal;
  FIsMouseDown := False;
  FCanToggle := False;
  FToggled := False;
  FOnClick := nil;
  FOnHover := nil;
  FOnPress := nil;
  FOnToggle := nil;
  FUserData := nil;
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

procedure TFtButton.MouseEnter();
begin
  if FIsMouseDown then
    FState := bsPressed
  else
    FState := bsHovered;
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 1, FUserData);
end;

procedure TFtButton.MouseLeave();
begin
  FState := bsNormal;
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 0, FUserData);
end;

procedure TFtButton.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  if AButton = 1 then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
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
  plateR, plateG, plateB: Double;
  borderR, borderG, borderB: Double;
  topR, topG, topB: Double;
  botR, botG, botB: Double;
  textR, textG, textB: Double;
  textOffsetX, textOffsetY: Integer;
begin
  if not Visible then Exit;

  textOffsetX := 0;
  textOffsetY := 0;

  if FToggled then
  begin
    // Toggled (active) display state
    if FState = bsPressed then
    begin
      borderR := 0.20; borderG := 0.35; borderB := 0.55;
      plateR  := 0.68; plateG  := 0.72; plateB  := 0.78;
      topR    := 0.48; topG    := 0.52; topB    := 0.58;
      botR    := 0.82; botG    := 0.85; botB    := 0.89;
      textOffsetX := 1;
      textOffsetY := 1;
    end
    else if FState = bsHovered then
    begin
      borderR := 0.25; borderG := 0.45; borderB := 0.75;
      plateR  := 0.78; plateG  := 0.82; plateB  := 0.88;
      topR    := 0.58; topG    := 0.62; topB    := 0.68;
      botR    := 0.90; botG    := 0.92; botB    := 0.95;
      textOffsetX := 1;
      textOffsetY := 1;
    end
    else
    begin
      borderR := 0.30; borderG := 0.48; borderB := 0.70;
      plateR  := 0.74; plateG  := 0.78; plateB  := 0.84;
      topR    := 0.55; topG    := 0.59; topB    := 0.65;
      botR    := 0.88; botG    := 0.90; botB    := 0.93;
      textOffsetX := 1;
      textOffsetY := 1;
    end;
    textR := 0.10; textG := 0.15; textB := 0.25;
  end
  else
  begin
    case FState of
      bsPressed:
      begin
        borderR := 0.30; borderG := 0.34; borderB := 0.38;
        plateR  := 0.72; plateG  := 0.74; plateB  := 0.77;
        topR    := 0.52; topG    := 0.55; topB    := 0.58;
        botR    := 0.88; botG    := 0.90; botB    := 0.92;
        textR   := 0.10; textG   := 0.12; textB   := 0.15;
        textOffsetX := 1;
        textOffsetY := 1;
      end;
      bsHovered:
      begin
        borderR := 0.40; borderG := 0.48; borderB := 0.56;
        plateR  := 0.90; plateG  := 0.92; plateB  := 0.94;
        topR    := 1.00; topG    := 1.00; topB    := 1.00;
        botR    := 0.76; botG    := 0.79; botB    := 0.82;
        textR   := 0.08; textG   := 0.10; textB   := 0.14;
      end;
      else // bsNormal
      begin
        borderR := 0.50; borderG := 0.54; borderB := 0.58;
        plateR  := 0.84; plateG  := 0.86; plateB  := 0.88;
        topR    := 0.96; topG    := 0.97; topB    := 0.98;
        botR    := 0.70; botG    := 0.73; botB    := 0.76;
        textR   := 0.15; textG   := 0.18; textB   := 0.22;
      end;
    end;
  end;

  // 1. Outer border (1px)
  Canvas.DrawRect(X, Y, Width, Height, borderR, borderG, borderB);

  // 2. Button plate fill
  Canvas.DrawRect(X + 1, Y + 1, Width - 2, Height - 2, plateR, plateG, plateB);

  // 3. Inner 3D bevel (1px)
  Canvas.DrawRect(X + 1, Y + 1, Width - 2, 1, topR, topG, topB);
  Canvas.DrawRect(X + 1, Y + 1, 1, Height - 2, topR, topG, topB);
  Canvas.DrawRect(X + 1, Y + Height - 2, Width - 2, 1, botR, botG, botB);
  Canvas.DrawRect(X + Width - 2, Y + 1, 1, Height - 2, topR, topG, topB);

  // 4. If Toggled: draw an active indicator bar at the bottom
  if FToggled then
  begin
    if FState = bsHovered then
      Canvas.DrawRect(X + 2, Y + Height - 4, Width - 4, 3, 0.20, 0.55, 0.95)
    else if FState = bsPressed then
      Canvas.DrawRect(X + 2, Y + Height - 4, Width - 4, 3, 0.15, 0.45, 0.85)
    else
      Canvas.DrawRect(X + 2, Y + Height - 4, Width - 4, 3, 0.18, 0.48, 0.85);
  end;

  // 5. Button caption
  if Caption <> '' then
    Canvas.DrawTextCentered(X + textOffsetX, Y + textOffsetY, Width, Height, Caption, GetFont(), textR, textG, textB);

  inherited Draw(Canvas);
end;

{ TFtToggleButton }

constructor TFtToggleButton.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FCanToggle := True;
end;

end.
