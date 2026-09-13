unit Ft.Widget;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Ft.Canvas.Agg, Ft.Font;

type
  TFtWidget = class
  private
    FFont: TFtFont;
  protected
    FFocusable: Boolean;
    FFocused: Boolean;
    function GetFont(): TFtFont; virtual;
    procedure SetFont(AValue: TFtFont); virtual;
    function GetFontDesc(): string; virtual;
    procedure SetFontDesc(const AValue: string); virtual;
  public
    X, Y, Width, Height: Integer;
    Visible: Boolean;
    Parent: TFtWidget;
    Children: TFPList;
    constructor Create(AParent: TFtWidget); virtual;
    destructor Destroy(); override;
    procedure Draw(Canvas: TFtCanvasAgg); virtual;
    function HitTest(AX, AY: Integer): TFtWidget; virtual;
    procedure Click(); virtual;
    procedure Invalidate(); virtual;

    procedure MouseEnter(); virtual;
    procedure MouseLeave(); virtual;
    procedure MouseDown(AX, AY: Integer; AButton: Integer); virtual;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); virtual;
    procedure MouseMove(AX, AY: Integer); virtual;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); virtual;
    function GetCursor(): Integer; virtual;
    procedure WidgetDestroyed(AWidget: TFtWidget); virtual;
    function GetRootWidget(): TFtWidget; virtual;
    procedure RequestFocus(AWidget: TFtWidget); virtual;

    function CanFocus(): Boolean; virtual;
    procedure SetFocus(); virtual;
    procedure KillFocus(); virtual;
    procedure GotFocus(); virtual;
    procedure LostFocus(); virtual;
    procedure KeyUp(AKeySym: Cardinal; AState: Cardinal); virtual;

    procedure SetFocusable(AValue: Boolean); virtual;

    property Font: TFtFont read GetFont write SetFont;
    property FontDesc: string read GetFontDesc write SetFontDesc;
    property Focusable: Boolean read FFocusable write SetFocusable;
    property Focused: Boolean read FFocused;
  end;

implementation

constructor TFtWidget.Create(AParent: TFtWidget);
begin
  Parent := AParent;
  Children := TFPList.Create();
  Visible := True;
  FFocusable := False;
  FFocused := False;
  FFont := nil; { Follows parent or system font by default }
  if Assigned(Parent) then
    Parent.Children.Add(Self);
end;

destructor TFtWidget.Destroy();
var
  I: Integer;
begin
  if Assigned(Parent) then
    Parent.WidgetDestroyed(Self);
  FFont := nil;
  for I := 0 to Children.Count - 1 do
    TFtWidget(Children[I]).Free();
  Children.Free();
  inherited Destroy();
end;

function TFtWidget.GetFont(): TFtFont;
begin
  if Assigned(FFont) then
    Result := FFont
  else if Assigned(Parent) then
    Result := Parent.GetFont()
  else
    Result := FtGetSystemFont();
end;

procedure TFtWidget.SetFont(AValue: TFtFont);
begin
  FFont := AValue;
end;

function TFtWidget.GetFontDesc(): string;
var
  F: TFtFont;
begin
  F := GetFont();
  if Assigned(F) then
    Result := F.FontDesc
  else
    Result := '';
end;

procedure TFtWidget.SetFontDesc(const AValue: string);
begin
  if AValue = '' then
    FFont := nil
  else
    FFont := FtFontManager.GetFont(AValue);
end;

procedure TFtWidget.Draw(Canvas: TFtCanvasAgg);
var
  I: Integer;
begin
  if not Visible then Exit;
  for I := 0 to Children.Count - 1 do
    TFtWidget(Children[I]).Draw(Canvas);
end;

function TFtWidget.HitTest(AX, AY: Integer): TFtWidget;
var
  I: Integer;
  Target: TFtWidget;
begin
  Result := nil;
  if not Visible then Exit;

  for I := Children.Count - 1 downto 0 do
  begin
    Target := TFtWidget(Children[I]).HitTest(AX, AY);
    if Assigned(Target) then
      Exit(Target);
  end;

  if (AX >= X) and (AX <= X + Width) and (AY >= Y) and (AY <= Y + Height) then
    Result := Self;
end;

procedure TFtWidget.Click();
begin
end;

procedure TFtWidget.Invalidate();
begin
  if Assigned(Parent) then
    Parent.Invalidate();
end;

procedure TFtWidget.MouseEnter();
begin
end;

procedure TFtWidget.MouseLeave();
begin
end;

procedure TFtWidget.MouseDown(AX, AY: Integer; AButton: Integer);
begin
  if (AButton in [4, 5, 6, 7]) and Assigned(Parent) then
    Parent.MouseDown(AX, AY, AButton);
end;

procedure TFtWidget.MouseUp(AX, AY: Integer; AButton: Integer);
begin
end;

procedure TFtWidget.MouseMove(AX, AY: Integer);
begin
end;

procedure TFtWidget.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
end;

function TFtWidget.GetCursor(): Integer;
begin
  Result := 0;
end;

procedure TFtWidget.WidgetDestroyed(AWidget: TFtWidget);
begin
  if Assigned(Parent) then
    Parent.WidgetDestroyed(AWidget);
end;

function TFtWidget.GetRootWidget(): TFtWidget;
var
  w: TFtWidget;
begin
  w := Self;
  while Assigned(w.Parent) do
    w := w.Parent;
  Result := w;
end;

procedure TFtWidget.RequestFocus(AWidget: TFtWidget);
begin
  if Assigned(Parent) then
    Parent.RequestFocus(AWidget);
end;

function TFtWidget.CanFocus(): Boolean;
begin
  Result := Visible and FFocusable;
end;

procedure TFtWidget.SetFocus();
begin
  if CanFocus() then
    RequestFocus(Self);
end;

procedure TFtWidget.KillFocus();
begin
  if FFocused then
    RequestFocus(nil);
end;

procedure TFtWidget.GotFocus();
begin
  FFocused := True;
  Invalidate();
end;

procedure TFtWidget.LostFocus();
begin
  FFocused := False;
  Invalidate();
end;

procedure TFtWidget.KeyUp(AKeySym: Cardinal; AState: Cardinal);
begin
end;

procedure TFtWidget.SetFocusable(AValue: Boolean);
begin
  if FFocusable <> AValue then
  begin
    FFocusable := AValue;
    if not FFocusable and FFocused then
      KillFocus();
    Invalidate();
  end;
end;

end.