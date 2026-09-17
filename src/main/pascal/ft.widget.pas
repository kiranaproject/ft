unit Ft.Widget;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Ft.Canvas.Agg, Ft.Font, Ft.Css, Ft.Animation;

type
  TFtWidget = class
  private
    FFont: TFtFont;
  protected
    FFocusable: Boolean;
    FFocused: Boolean;
    FEnabled: Boolean;
    FContextMenu: TFtWidget;
    FStyleClass: string;
    FStyleId: string;
    FInlineStyle: string;
    FResolvedStyle: TFtWidgetStyle;
    FHasResolvedStyle: Boolean;
    FStyleInitialized: Boolean;
    FOpacity: Double;
    function GetFont(): TFtFont; virtual;
    procedure SetFont(AValue: TFtFont); virtual;
    function GetFontDesc(): string; virtual;
    procedure SetFontDesc(const AValue: string); virtual;
    function GetContextMenu(): TFtWidget; virtual;
    procedure SetContextMenu(AValue: TFtWidget); virtual;
    procedure SetEnabled(AValue: Boolean); virtual;
    procedure SetStyleClass(const AValue: string); virtual;
    procedure SetStyleId(const AValue: string); virtual;
    procedure SetInlineStyle(const AValue: string); virtual;
    function GetOpacity(): Double; virtual;
    procedure SetOpacity(AValue: Double); virtual;
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
    procedure InvalidateRect(AX, AY, AW, AH: Integer); virtual;

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

    function GetElementType(): string; virtual;
    function GetStatePseudoClass(): string; virtual;
    function GetResolvedStyle(): TFtWidgetStyle; virtual;
    procedure InvalidateStyle(); virtual;

    property Font: TFtFont read GetFont write SetFont;
    property FontDesc: string read GetFontDesc write SetFontDesc;
    property Focusable: Boolean read FFocusable write SetFocusable;
    property Focused: Boolean read FFocused;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property ContextMenu: TFtWidget read GetContextMenu write SetContextMenu;
    property StyleClass: string read FStyleClass write SetStyleClass;
    property StyleId: string read FStyleId write SetStyleId;
    property InlineStyle: string read FInlineStyle write SetInlineStyle;
    property Opacity: Double read GetOpacity write SetOpacity;
  end;

implementation

uses
  Ft.Theme;

constructor TFtWidget.Create(AParent: TFtWidget);
begin
  Parent := AParent;
  Children := TFPList.Create();
  Visible := True;
  FFocusable := False;
  FFocused := False;
  FEnabled := True;
  FContextMenu := nil;
  FFont := nil; { Follows parent or system font by default }
  FStyleClass := '';
  FStyleId := '';
  FInlineStyle := '';
  FHasResolvedStyle := False;
  FStyleInitialized := False;
  FResolvedStyle.Init();
  FOpacity := 1.0;
  if Assigned(Parent) then
    Parent.Children.Add(Self);
end;

destructor TFtWidget.Destroy();
var
  w: TFtWidget;
begin
  FtGetAnimator().StopTransitions(Self);
  FtGetAnimator().UnregisterContinuous(Self);
  if Assigned(Parent) then
  begin
    if Assigned(Parent.Children) then
      Parent.Children.Remove(Self);
    Parent.WidgetDestroyed(Self);
    Parent := nil;
  end;
  FContextMenu := nil;
  FFont := nil;
  if Assigned(Children) then
  begin
    while Children.Count > 0 do
    begin
      w := TFtWidget(Children[Children.Count - 1]);
      w.Parent := nil;
      Children.Delete(Children.Count - 1);
      w.Free();
    end;
    FreeAndNil(Children);
  end;
  inherited Destroy();
end;

function TFtWidget.GetOpacity(): Double;
var
  st: TFtWidgetStyle;
begin
  st := GetResolvedStyle();
  if st.HasOpacity then
    Result := st.Opacity * FOpacity
  else
    Result := FOpacity;
end;

procedure TFtWidget.SetOpacity(AValue: Double);
begin
  if AValue < 0.0 then AValue := 0.0;
  if AValue > 1.0 then AValue := 1.0;
  if Abs(FOpacity - AValue) > 1e-4 then
  begin
    FOpacity := AValue;
    Invalidate();
  end;
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
begin
  Result := GetFont().FontDesc;
end;

procedure TFtWidget.SetFontDesc(const AValue: string);
begin
  if AValue = '' then
    FFont := nil
  else
    FFont := FtFontManager().GetFont(AValue);
end;

function TFtWidget.GetContextMenu(): TFtWidget;
begin
  Result := FContextMenu;
end;

procedure TFtWidget.SetContextMenu(AValue: TFtWidget);
begin
  FContextMenu := AValue;
end;

procedure TFtWidget.Draw(Canvas: TFtCanvasAgg);
var
  I: Integer;
  child: TFtWidget;
  chOpac: Double;
begin
  if not Visible then Exit;
  for I := 0 to Children.Count - 1 do
  begin
    child := TFtWidget(Children[I]);
    if child.Visible and Canvas.IntersectsClip(child.X - 4, child.Y - 4, child.Width + 8, child.Height + 8) then
    begin
      chOpac := child.Opacity;
      if chOpac <= 0.0 then Continue;
      if chOpac < 0.999 then
      begin
        Canvas.PushAlpha(chOpac);
        try
          child.Draw(Canvas);
        finally
          Canvas.PopAlpha();
        end;
      end
      else
        child.Draw(Canvas);
    end;
  end;
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
  if not Visible then Exit;
  InvalidateRect(X - 4, Y - 4, Width + 8, Height + 8);
end;

procedure TFtWidget.InvalidateRect(AX, AY, AW, AH: Integer);
begin
  if not Visible then Exit;
  if Assigned(Parent) then
    Parent.InvalidateRect(AX, AY, AW, AH);
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
  if FContextMenu = AWidget then
    FContextMenu := nil;
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
  InvalidateStyle();
  Invalidate();
end;

procedure TFtWidget.LostFocus();
begin
  FFocused := False;
  InvalidateStyle();
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

procedure TFtWidget.SetEnabled(AValue: Boolean);
begin
  if FEnabled <> AValue then
  begin
    FEnabled := AValue;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtWidget.SetStyleClass(const AValue: string);
begin
  if FStyleClass <> AValue then
  begin
    FStyleClass := AValue;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtWidget.SetStyleId(const AValue: string);
begin
  if FStyleId <> AValue then
  begin
    FStyleId := AValue;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtWidget.SetInlineStyle(const AValue: string);
begin
  if FInlineStyle <> AValue then
  begin
    FInlineStyle := AValue;
    InvalidateStyle();
    Invalidate();
  end;
end;

procedure TFtWidget.InvalidateStyle();
var
  I: Integer;
begin
  FHasResolvedStyle := False;
  for I := 0 to Children.Count - 1 do
    TFtWidget(Children[I]).InvalidateStyle();
end;

function TFtWidget.GetElementType(): string;
begin
  Result := 'widget';
end;

function TFtWidget.GetStatePseudoClass(): string;
begin
  if not FEnabled then
    Result := ':disabled'
  else if FFocused then
    Result := ':focus'
  else
    Result := '';
end;

function TFtWidget.GetResolvedStyle(): TFtWidgetStyle;
var
  newStyle, animStyle: TFtWidgetStyle;
  transProp, transTiming: string;
  transDur: Integer;
  effectiveClasses: string;
begin
  if not FHasResolvedStyle then
  begin
    effectiveClasses := FStyleClass;
    if FtGetDarkMode() then
    begin
      if effectiveClasses <> '' then
        effectiveClasses := effectiveClasses + ' dark'
      else
        effectiveClasses := 'dark';
    end;
    newStyle := FtGetStyleSheet().ResolveStyle(GetElementType(), FStyleId, effectiveClasses, GetStatePseudoClass(), FInlineStyle);

    if FStyleInitialized then
    begin
      transProp := '';
      transDur := 0;
      transTiming := 'ease';

      if newStyle.HasTransition and (newStyle.TransitionDurationMs > 0) then
      begin
        transProp := newStyle.TransitionProp;
        transDur := newStyle.TransitionDurationMs;
        transTiming := newStyle.TransitionTiming;
      end
      else if FResolvedStyle.HasTransition and (FResolvedStyle.TransitionDurationMs > 0) then
      begin
        transProp := FResolvedStyle.TransitionProp;
        transDur := FResolvedStyle.TransitionDurationMs;
        transTiming := FResolvedStyle.TransitionTiming;
      end;

      if (transDur > 0) and not FtStylesEqual(FResolvedStyle, newStyle) then
      begin
        FtGetAnimator().StartTransition(Self, FResolvedStyle, newStyle, transProp, transDur, transTiming);
      end;
    end
    else
      FStyleInitialized := True;

    FResolvedStyle := newStyle;
    FHasResolvedStyle := True;
  end;

  if FtGetAnimator().GetAnimatedStyle(Self, animStyle) then
    Result := animStyle
  else
    Result := FResolvedStyle;
end;

procedure InvalidateWidgetAnim(AWidget: Pointer);
begin
  if Assigned(AWidget) and (TObject(AWidget) is TFtWidget) then
  begin
    if TFtWidget(AWidget).Visible then
      TFtWidget(AWidget).Invalidate();
  end;
end;

initialization
  FtSetInvalidateWidgetProc(@InvalidateWidgetAnim);

end.