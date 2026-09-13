unit Ft.Widget.Switches;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Ft.Canvas.Agg, Ft.Widget, Ft.Theme;

type
  TFtSwitchCallback = procedure(Sender: Pointer; Checked: cint32; UserData: Pointer); cdecl;
  TFtSwitchHoverCallback = procedure(Sender: Pointer; Hovered: cint32; UserData: Pointer); cdecl;

  TFtSwitch = class(TFtWidget)
  private
    FChecked: Boolean;
    FState: TFtButtonState;
    FIsMouseDown: Boolean;
    FCornerRadius: Double;
    FEnableShadow: Integer;
    FOnToggle: TFtSwitchCallback;
    FOnHover: TFtSwitchHoverCallback;
    FUserData: Pointer;
    procedure SetChecked(AValue: Boolean);
    procedure SetCornerRadius(AValue: Double);
    procedure SetEnableShadow(AValue: Integer);
  public
    Caption: string;
    constructor Create(AParent: TFtWidget); override;

    procedure Draw(Canvas: TFtCanvasAgg); override;
    procedure Click(); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;

    procedure Toggle();

    property Checked: Boolean read FChecked write SetChecked;
    property State: TFtButtonState read FState;
    property CornerRadius: Double read FCornerRadius write SetCornerRadius;
    property EnableShadow: Integer read FEnableShadow write SetEnableShadow;
    property OnToggle: TFtSwitchCallback read FOnToggle write FOnToggle;
    property OnHover: TFtSwitchHoverCallback read FOnHover write FOnHover;
    property UserData: Pointer read FUserData write FUserData;
  end;

implementation

{ TFtSwitch }

constructor TFtSwitch.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FChecked := False;
  FState := bsNormal;
  FIsMouseDown := False;
  FCornerRadius := -1.0;
  FEnableShadow := -1;
  FOnToggle := nil;
  FOnHover := nil;
  FUserData := nil;
  Caption := '';
  Width := 48;
  Height := 24;
end;

procedure TFtSwitch.SetCornerRadius(AValue: Double);
begin
  if FCornerRadius <> AValue then
  begin
    FCornerRadius := AValue;
    Invalidate();
  end;
end;

procedure TFtSwitch.SetEnableShadow(AValue: Integer);
begin
  if FEnableShadow <> AValue then
  begin
    FEnableShadow := AValue;
    Invalidate();
  end;
end;

procedure TFtSwitch.SetChecked(AValue: Boolean);
begin
  if FChecked <> AValue then
  begin
    FChecked := AValue;
    Invalidate();
    if Assigned(FOnToggle) then
    begin
      if FChecked then
        FOnToggle(Self, 1, FUserData)
      else
        FOnToggle(Self, 0, FUserData);
    end;
  end;
end;

procedure TFtSwitch.Toggle();
begin
  SetChecked(not FChecked);
end;

procedure TFtSwitch.MouseEnter();
begin
  if FIsMouseDown then
    FState := bsPressed
  else
    FState := bsHovered;
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 1, FUserData);
end;

procedure TFtSwitch.MouseLeave();
begin
  FState := bsNormal;
  Invalidate();
  if Assigned(FOnHover) then
    FOnHover(Self, 0, FUserData);
end;

procedure TFtSwitch.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  if AButton = 1 then
  begin
    FIsMouseDown := True;
    FState := bsPressed;
    Invalidate();
  end;
end;

procedure TFtSwitch.MouseUp(AX, AY: Integer; AButton: Integer);
begin
  if AButton = 1 then
  begin
    FIsMouseDown := False;
    if (AX >= X) and (AX < X + Width) and (AY >= Y) and (AY < Y + Height) then
      FState := bsHovered
    else
      FState := bsNormal;
    Invalidate();
  end;
end;

procedure TFtSwitch.Click();
begin
  Toggle();
end;

procedure TFtSwitch.Draw(Canvas: TFtCanvasAgg);
begin
  if not Visible then Exit;

  FtGetTheme().DrawSwitchEx(Canvas, X, Y, Width, Height, FState, FChecked, Caption, GetFont(), FCornerRadius, FEnableShadow);

  inherited Draw(Canvas);
end;

end.
