unit Ft.Theme;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Ft.Canvas.Agg, Ft.Font;

type
  { Button interactive states }
  TFtButtonState = (bsNormal, bsHovered, bsPressed);

  { ScrollBar orientation }
  TFtScrollBarOrientation = (ftSbHorizontal, ftSbVertical);

  { RGB Color representation (0.0 .. 1.0) }
  TFtRgbColor = record
    R, G, B: Double;
  end;

  { Forward declarations }
  TFtTheme = class;
  TFtThemeManager = class;

  TFtThemeChangeNotify = procedure() of object;

  { Modern Vector Theme representation and fallback renderer }
  TFtTheme = class
  private
    FName: string;
    FDarkMode: Boolean;
    FCornerRadius: Double;
    FEnableShadow: Boolean;
    FShadowOffsetY: Double;
    FShadowBlur: Double;
    FShadowOpacity: Double;
  public
    constructor Create(const AName: string = 'default'); virtual;
    destructor Destroy(); override;

    function GetName(): string; virtual;
    procedure SetName(const AValue: string); virtual;
    function GetDarkMode(): Boolean; virtual;
    procedure SetDarkMode(AValue: Boolean); virtual;

    function GetCornerRadius(): Double; virtual;
    procedure SetCornerRadius(AValue: Double); virtual;
    function GetEnableShadow(): Boolean; virtual;
    procedure SetEnableShadow(AValue: Boolean); virtual;

    function HasDarkMode(): Boolean; virtual;
    procedure DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer; AOpacity: Double = 1.0); virtual;
    procedure DrawButton(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                         State: TFtButtonState; Toggled: Boolean; 
                         const Caption: string; Font: TFtFont); virtual;
    procedure DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Toggled: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); virtual;
    procedure DrawSwitch(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                         State: TFtButtonState; Checked: Boolean; 
                         const Caption: string; Font: TFtFont); virtual;
    procedure DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Checked: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); virtual;
    function GetAccentColor(): TFtRgbColor; virtual;
    function GetTextColor(): TFtRgbColor; virtual;
    function GetInputBackground(): TFtRgbColor; virtual;
    function GetInputBorder(): TFtRgbColor; virtual;
    function GetInputPlaceholderColor(): TFtRgbColor; virtual;
    procedure DrawFocusRing(Canvas: TFtCanvasAgg; X, Y, W, H: Double; Radius: Double); virtual;
    procedure DrawInputPlate(Canvas: TFtCanvasAgg; X, Y, W, H: Double; Focused: Boolean; CustomRadius: Double = -1.0); virtual;
    function GetScrollBarTrackColor(): TFtRgbColor; virtual;
    function GetScrollBarThumbColor(): TFtRgbColor; virtual;
    procedure DrawScrollBar(Canvas: TFtCanvasAgg; X, Y, W, H: Double; 
                            Orientation: TFtScrollBarOrientation; 
                            ThumbX, ThumbY, ThumbW, ThumbH: Double;
                            Hovered, Dragging: Boolean;
                            CustomRadius: Double = -1.0); virtual;
    function GetMenuBackground(): TFtRgbColor; virtual;
    function GetMenuBorder(): TFtRgbColor; virtual;
    function GetMenuHoverBackground(): TFtRgbColor; virtual;
    function GetMenuHoverTextColor(): TFtRgbColor; virtual;
    function GetMenuDisabledTextColor(): TFtRgbColor; virtual;
    function GetMenuSeparatorColor(): TFtRgbColor; virtual;
    procedure DrawMenuBar(Canvas: TFtCanvasAgg; X, Y, W, H: Integer); virtual;
    procedure DrawMenuBarItem(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                              const Caption: string; Font: TFtFont; 
                              Hovered, Active: Boolean); virtual;
    procedure DrawPopupMenuPlate(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; CustomRadius: Double = -1.0); virtual;
    procedure DrawPopupMenuItem(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                                const Caption, Shortcut: string; Font: TFtFont; 
                                Hovered, Enabled, Checked, HasSubMenu: Boolean); virtual;
    procedure DrawMenuSeparator(Canvas: TFtCanvasAgg; X, Y, W: Integer); virtual;

    property Name: string read GetName write SetName;
    property DarkMode: Boolean read GetDarkMode write SetDarkMode;
    property CornerRadius: Double read GetCornerRadius write SetCornerRadius;
    property EnableShadow: Boolean read GetEnableShadow write SetEnableShadow;
    property ShadowOffsetY: Double read FShadowOffsetY write FShadowOffsetY;
    property ShadowBlur: Double read FShadowBlur write FShadowBlur;
    property ShadowOpacity: Double read FShadowOpacity write FShadowOpacity;
  end;

  { Default theme class alias }
  TFtThemeDefault = TFtTheme;

  { CSS Theme Manager: scans themes/*.css and applies stylesheets dynamically }
  TFtThemeManager = class
  private
    FCurrentTheme: TFtTheme;
    FDarkMode: Boolean;
    FThemes: TStringList;
    FOnThemeChange: TFtThemeChangeNotify;
    procedure ScanThemeDirectories();
    function FindThemePath(const AName: string): string;
    procedure SetDarkMode(AValue: Boolean);
  public
    constructor Create();
    destructor Destroy(); override;

    function SetTheme(const AName: string): Boolean;
    function GetThemeName(): string;
    function GetAvailableThemes(): string;
    function HasDarkMode(const AName: string): Boolean;
    function LoadThemeFile(const AFilePath: string): Boolean;
    function LoadThemeDir(const ADirPath: string): Integer;

    function GetCornerRadius(): Double;
    procedure SetCornerRadius(AValue: Double);
    function GetEnableShadow(): Boolean;
    procedure SetEnableShadow(AValue: Boolean);

    property CurrentTheme: TFtTheme read FCurrentTheme;
    property DarkMode: Boolean read FDarkMode write SetDarkMode;
    property CornerRadius: Double read GetCornerRadius write SetCornerRadius;
    property EnableShadow: Boolean read GetEnableShadow write SetEnableShadow;
    property OnThemeChange: TFtThemeChangeNotify read FOnThemeChange write FOnThemeChange;
  end;

function FtThemeManager(): TFtThemeManager;
function FtGetTheme(): TFtTheme;
function FtSetTheme(const AName: string): Boolean;
function FtGetThemeName(): string;
function FtGetAvailableThemes(): string;
function FtGetDarkMode(): Boolean;
procedure FtSetDarkMode(AValue: Boolean);
function FtThemeHasDarkMode(const AName: string): Boolean;
function FtThemeLoadFile(const AFilePath: string): Boolean;
function FtThemeLoadDir(const ADirPath: string): Integer;
function FtGetCornerRadius(): Double;
procedure FtSetCornerRadius(AValue: Double);
function FtGetEnableShadow(): Boolean;
procedure FtSetEnableShadow(AValue: Boolean);
function MakeRgbColor(R, G, B: Double): TFtRgbColor;

implementation

uses
  Ft.Css;

const
  DEFAULT_THEME_CSS =
    'window {' + LineEnding +
    '    background-color: #f0f2f5;' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '}' + LineEnding +
    'window.dark {' + LineEnding +
    '    background-color: #18181b;' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '}' + LineEnding +
    'button {' + LineEnding +
    '    background-color: #f5f7fa;' + LineEnding +
    '    color: #334155;' + LineEnding +
    '    border-color: #ccd1d9;' + LineEnding +
    '    border-width: 1px;' + LineEnding +
    '    border-radius: 7px;' + LineEnding +
    '    box-shadow: 1;' + LineEnding +
    '    transition: all 150ms ease;' + LineEnding +
    '}' + LineEnding +
    'button:hover {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    border-color: #3b82f6;' + LineEnding +
    '    color: #1d4ed8;' + LineEnding +
    '}' + LineEnding +
    'button:active {' + LineEnding +
    '    background-color: #e2e8f0;' + LineEnding +
    '    border-color: #2563eb;' + LineEnding +
    '    color: #0f172a;' + LineEnding +
    '}' + LineEnding +
    'button.dark {' + LineEnding +
    '    background-color: #25282e;' + LineEnding +
    '    color: #d9dee6;' + LineEnding +
    '    border-color: #3b4048;' + LineEnding +
    '}' + LineEnding +
    'button.dark:hover {' + LineEnding +
    '    background-color: #2d323b;' + LineEnding +
    '    border-color: #60a5fa;' + LineEnding +
    '    color: #ffffff;' + LineEnding +
    '}' + LineEnding +
    'button.dark:active {' + LineEnding +
    '    background-color: #1b1d22;' + LineEnding +
    '    border-color: #3b82f6;' + LineEnding +
    '    color: #e2e8f0;' + LineEnding +
    '}' + LineEnding +
    'windowbutton {' + LineEnding +
    '    transition: all 180ms ease-out;' + LineEnding +
    '}' + LineEnding +
    'entry, textarea {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    color: #0f172a;' + LineEnding +
    '    border-color: #cbd5e1;' + LineEnding +
    '    border-width: 1px;' + LineEnding +
    '    border-radius: 5px;' + LineEnding +
    '    box-shadow: 0;' + LineEnding +
    '    transition: border-color 150ms ease;' + LineEnding +
    '}' + LineEnding +
    'entry:focus, textarea:focus {' + LineEnding +
    '    border-color: #3b82f6;' + LineEnding +
    '}' + LineEnding +
    'entry.dark, textarea.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    color: #f4f4f5;' + LineEnding +
    '    border-color: #3f3f46;' + LineEnding +
    '}' + LineEnding +
    'entry.dark:focus, textarea.dark:focus {' + LineEnding +
    '    border-color: #60a5fa;' + LineEnding +
    '}' + LineEnding +
    'switch {' + LineEnding +
    '    background-color: #cbd5e1;' + LineEnding +
    '    border-color: #94a3b8;' + LineEnding +
    '    border-radius: 12px;' + LineEnding +
    '    transition: all 200ms ease;' + LineEnding +
    '}' + LineEnding +
    'switch:checked {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    border-color: #2563eb;' + LineEnding +
    '}' + LineEnding +
    'switch.dark {' + LineEnding +
    '    background-color: #3f3f46;' + LineEnding +
    '    border-color: #52525b;' + LineEnding +
    '}' + LineEnding +
    'switch.dark:checked {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    border-color: #60a5fa;' + LineEnding +
    '}' + LineEnding +
    'label {' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '}' + LineEnding +
    'label.dark {' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '}' + LineEnding +
    'scrollbar {' + LineEnding +
    '    background-color: #f0f2f5;' + LineEnding +
    '    color: #cbd5e1;' + LineEnding +
    '    border-radius: 3px;' + LineEnding +
    '    transition: all 150ms ease;' + LineEnding +
    '}' + LineEnding +
    'scrollbar:hover {' + LineEnding +
    '    color: #94a3b8;' + LineEnding +
    '}' + LineEnding +
    'scrollbar:active {' + LineEnding +
    '    color: #64748b;' + LineEnding +
    '}' + LineEnding +
    'scrollbar.dark {' + LineEnding +
    '    background-color: #18181b;' + LineEnding +
    '    color: #3f3f46;' + LineEnding +
    '}' + LineEnding +
    'scrollbar.dark:hover {' + LineEnding +
    '    color: #52525b;' + LineEnding +
    '}' + LineEnding +
    'menu {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    border-color: #cbd5e1;' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '}' + LineEnding +
    'menu:hover {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    color: #ffffff;' + LineEnding +
    '}' + LineEnding +
    'menu.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border-color: #3f3f46;' + LineEnding +
    '    color: #f4f4f5;' + LineEnding +
    '}' + LineEnding +
    'menu.dark:hover {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    color: #ffffff;' + LineEnding +
    '}' + LineEnding +
    'container {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    border-color: #cbd5e1;' + LineEnding +
    '    border-width: 1px;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '}' + LineEnding +
    'container.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border-color: #3f3f46;' + LineEnding +
    '}' + LineEnding +
    'checkbox, radio {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    border-color: #94a3b8;' + LineEnding +
    '    border-width: 1px;' + LineEnding +
    '    color: #1e293b;' + LineEnding +
    '    transition: all 150ms ease;' + LineEnding +
    '}' + LineEnding +
    'checkbox:checked, radio:checked {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    border-color: #2563eb;' + LineEnding +
    '}' + LineEnding +
    'checkbox.dark, radio.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border-color: #52525b;' + LineEnding +
    '    color: #f1f5f9;' + LineEnding +
    '}' + LineEnding +
    'checkbox.dark:checked, radio.dark:checked {' + LineEnding +
    '    background-color: #3b82f6;' + LineEnding +
    '    border-color: #60a5fa;' + LineEnding +
    '}' + LineEnding +
    'combobox {' + LineEnding +
    '    background-color: #ffffff;' + LineEnding +
    '    border-color: #cbd5e1;' + LineEnding +
    '    border-width: 1px;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '    color: #0f172a;' + LineEnding +
    '    box-shadow: 1;' + LineEnding +
    '    transition: border-color 150ms ease;' + LineEnding +
    '}' + LineEnding +
    'combobox:focus {' + LineEnding +
    '    border-color: #3b82f6;' + LineEnding +
    '}' + LineEnding +
    'combobox.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border-color: #3f3f46;' + LineEnding +
    '    color: #f4f4f5;' + LineEnding +
    '}' + LineEnding +
    'combobox.dark:focus {' + LineEnding +
    '    border-color: #60a5fa;' + LineEnding +
    '}' + LineEnding +
    'slider {' + LineEnding +
    '    background-color: #cbd5e1;' + LineEnding +
    '    color: #3b82f6;' + LineEnding +
    '}' + LineEnding +
    'slider.dark {' + LineEnding +
    '    background-color: #3f3f46;' + LineEnding +
    '    color: #60a5fa;' + LineEnding +
    '}' + LineEnding +
    'progressbar {' + LineEnding +
    '    background-color: #e2e8f0;' + LineEnding +
    '    border-color: #cbd5e1;' + LineEnding +
    '    border-width: 1px;' + LineEnding +
    '    border-radius: 6px;' + LineEnding +
    '    color: #3b82f6;' + LineEnding +
    '}' + LineEnding +
    'progressbar.dark {' + LineEnding +
    '    background-color: #27272a;' + LineEnding +
    '    border-color: #3f3f46;' + LineEnding +
    '    color: #60a5fa;' + LineEnding +
    '}';

var
  uThemeManager: TFtThemeManager = nil;

function MakeRgb(R, G, B: Double): TFtRgbColor;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
end;

function MakeRgbColor(R, G, B: Double): TFtRgbColor;
begin
  Result := MakeRgb(R, G, B);
end;

{ TFtTheme }

constructor TFtTheme.Create(const AName: string);
begin
  inherited Create();
  FName := AName;
  FDarkMode := False;
  FCornerRadius := 6.0;
  FEnableShadow := True;
  FShadowOffsetY := 2.0;
  FShadowBlur := 4.0;
  FShadowOpacity := 0.18;
end;

destructor TFtTheme.Destroy();
begin
  inherited Destroy();
end;

function TFtTheme.GetName(): string;
begin
  Result := FName;
end;

procedure TFtTheme.SetName(const AValue: string);
begin
  FName := AValue;
end;

function TFtTheme.GetDarkMode(): Boolean;
begin
  Result := FDarkMode;
end;

procedure TFtTheme.SetDarkMode(AValue: Boolean);
begin
  FDarkMode := AValue;
end;

function TFtTheme.GetCornerRadius(): Double;
begin
  Result := FCornerRadius;
end;

procedure TFtTheme.SetCornerRadius(AValue: Double);
begin
  FCornerRadius := AValue;
end;

function TFtTheme.GetEnableShadow(): Boolean;
begin
  Result := FEnableShadow;
end;

procedure TFtTheme.SetEnableShadow(AValue: Boolean);
begin
  FEnableShadow := AValue;
end;

function TFtTheme.HasDarkMode(): Boolean;
begin
  Result := True;
end;

procedure TFtTheme.DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer; AOpacity: Double = 1.0);
var
  st: TFtWidgetStyle;
  cls: string;
  effA: Double;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('window', '', cls, '', '');
  if st.HasBgColor then
  begin
    effA := st.BgColor.A * AOpacity;
    Canvas.DrawRect(0, 0, W, H, st.BgColor.R, st.BgColor.G, st.BgColor.B, effA);
  end
  else if FDarkMode then
    Canvas.DrawRect(0, 0, W, H, 0.09, 0.09, 0.11, AOpacity)
  else
    Canvas.DrawRect(0, 0, W, H, 0.94, 0.95, 0.96, AOpacity);
end;

procedure TFtTheme.DrawButton(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                              State: TFtButtonState; Toggled: Boolean; 
                              const Caption: string; Font: TFtFont);
begin
  DrawButtonEx(Canvas, X, Y, W, H, State, Toggled, Caption, Font, -1.0, -1);
end;

procedure TFtTheme.DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                                State: TFtButtonState; Toggled: Boolean; 
                                const Caption: string; Font: TFtFont;
                                CustomRadius: Double; CustomShadow: Integer);
var
  actualFont: TFtFont;
  rad, textR, textG, textB, plateR, plateG, plateB, borderR, borderG, borderB: Double;
  haloR, haloG, haloB: Double;
  textY: Integer;
  shOffY, shBlur, shOpac: Double;
  hasShadow: Boolean;
begin
  if CustomRadius >= 0.0 then
    rad := CustomRadius
  else
    rad := FCornerRadius;

  if CustomShadow >= 0 then
    hasShadow := (CustomShadow = 1)
  else
    hasShadow := FEnableShadow;

  shOffY := FShadowOffsetY;
  shBlur := FShadowBlur;
  shOpac := FShadowOpacity;
  haloR := 0.23; haloG := 0.51; haloB := 0.96;

  if FDarkMode then
  begin
    case State of
      bsNormal:
      begin
        plateR := 0.22; plateG := 0.24; plateB := 0.26;
        borderR := 0.32; borderG := 0.35; borderB := 0.38;
        textR := 0.85; textG := 0.87; textB := 0.90;
      end;
      bsHovered:
      begin
        plateR := 0.28; plateG := 0.31; plateB := 0.34;
        borderR := 0.38; borderG := 0.65; borderB := 0.98;
        textR := 1.00; textG := 1.00; textB := 1.00;
        haloR := 0.38; haloG := 0.65; haloB := 0.98;
      end;
      bsPressed:
      begin
        plateR := 0.16; plateG := 0.18; plateB := 0.20;
        borderR := 0.23; borderG := 0.51; borderB := 0.96;
        textR := 0.85; textG := 0.86; textB := 0.88;
      end;
    end;
  end
  else
  begin
    case State of
      bsNormal:
      begin
        plateR := 0.96; plateG := 0.97; plateB := 0.98;
        borderR := 0.80; borderG := 0.82; borderB := 0.85;
        textR := 0.20; textG := 0.25; textB := 0.33;
      end;
      bsHovered:
      begin
        plateR := 1.00; plateG := 1.00; plateB := 1.00;
        borderR := 0.23; borderG := 0.51; borderB := 0.96;
        textR := 0.11; textG := 0.30; textB := 0.85;
        haloR := 0.23; haloG := 0.51; haloB := 0.96;
      end;
      bsPressed:
      begin
        plateR := 0.88; plateG := 0.91; plateB := 0.94;
        borderR := 0.15; borderG := 0.39; borderB := 0.92;
        textR := 0.06; textG := 0.09; textB := 0.16;
      end;
    end;
  end;

  if Toggled then
  begin
    plateR := 0.23; plateG := 0.51; plateB := 0.96;
    borderR := 0.18; borderG := 0.42; borderB := 0.85;
    textR := 1.0; textG := 1.0; textB := 1.0;
  end;

  // 1. Signature Floria squircle hover halo bloom
  if (State = bsHovered) and (rad > 0.0) then
    Canvas.DrawRoundedRect(X - 1.5, Y - 1.5, W + 3.0, H + 3.0, rad + 1.0, haloR, haloG, haloB, 0.20);

  // 2. Drop shadow
  if hasShadow and (State <> bsPressed) then
    Canvas.DrawShadow(X, Y, W, H, rad, 0.0, shOffY, shBlur, 0.0, 0.0, 0.0, shOpac);

  // 3. Button plate
  Canvas.DrawRoundedRect(X, Y, W, H, rad, plateR, plateG, plateB);

  // 4. Border outline
  Canvas.DrawRoundedRectOutline(X, Y, W, H, rad, 1.0, borderR, borderG, borderB);

  // 5. Centered text with tactile pressed shift
  if Caption <> '' then
  begin
    if not Assigned(Font) then
      actualFont := FtGetSystemFont()
    else
      actualFont := Font;
    textY := Y;
    if State = bsPressed then
      Inc(textY);
    Canvas.DrawTextCentered(X, textY, W, H, Caption, actualFont, textR, textG, textB);
  end;
end;

procedure TFtTheme.DrawSwitch(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                              State: TFtButtonState; Checked: Boolean; 
                              const Caption: string; Font: TFtFont);
begin
  DrawSwitchEx(Canvas, X, Y, W, H, State, Checked, Caption, Font, -1.0, -1);
end;

procedure TFtTheme.DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                                State: TFtButtonState; Checked: Boolean; 
                                const Caption: string; Font: TFtFont;
                                CustomRadius: Double; CustomShadow: Integer);
var
  trackW, trackH: Integer;
  rad, thumbD, thumbX, thumbY, labelX, labelY: Double;
  trackR, trackG, trackB, borderR, borderG, borderB, thumbR, thumbG, thumbB: Double;
  textR, textG, textB: Double;
  actualFont: TFtFont;
begin
  if (Caption <> '') and (W >= Round(H * 2.2)) then
  begin
    trackH := H;
    trackW := Round(H * 1.85);
    if trackW < 36 then trackW := 36;
    labelX := X + trackW + 8;
  end
  else
  begin
    trackH := H;
    trackW := W;
    labelX := X + W + 8;
  end;

  rad := trackH / 2.0;
  thumbD := trackH - 4.0;
  thumbY := Y + 2.0;

  if Checked then
    thumbX := X + trackW - thumbD - 2.0
  else
    thumbX := X + 2.0;

  if Checked then
  begin
    trackR := 0.23; trackG := 0.51; trackB := 0.96;
    borderR := 0.18; borderG := 0.42; borderB := 0.85;
    thumbR := 1.0; thumbG := 1.0; thumbB := 1.0;
  end
  else
  begin
    if FDarkMode then
    begin
      trackR := 0.25; trackG := 0.27; trackB := 0.30;
      borderR := 0.35; borderG := 0.38; borderB := 0.42;
      thumbR := 0.90; thumbG := 0.92; thumbB := 0.94;
    end
    else
    begin
      trackR := 0.85; trackG := 0.87; trackB := 0.90;
      borderR := 0.75; borderG := 0.77; borderB := 0.80;
      thumbR := 1.0; thumbG := 1.0; thumbB := 1.0;
    end;
  end;

  if FDarkMode then
  begin
    textR := 0.95; textG := 0.96; textB := 0.97;
  end
  else
  begin
    textR := 0.15; textG := 0.18; textB := 0.22;
  end;

  // Track plate
  Canvas.DrawRoundedRect(X, Y, trackW, trackH, rad, trackR, trackG, trackB);
  Canvas.DrawRoundedRectOutline(X, Y, trackW, trackH, rad, 1.0, borderR, borderG, borderB);

  // Thumb plate
  Canvas.DrawRoundedRect(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, thumbR, thumbG, thumbB);

  // Caption text
  if Caption <> '' then
  begin
    if not Assigned(Font) then
      actualFont := FtGetSystemFont()
    else
      actualFont := Font;
    labelY := Y + (H / 2.0) + (actualFont.Ascent - actualFont.Descent) / 2.0;
    Canvas.DrawText(labelX, labelY, Caption, actualFont, textR, textG, textB);
  end;
end;

function TFtTheme.GetAccentColor(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('switch', '', cls, ':checked', '');
  if st.HasBgColor then
    Result := MakeRgb(st.BgColor.R, st.BgColor.G, st.BgColor.B)
  else
    Result := MakeRgb(0.23, 0.51, 0.96);
end;

function TFtTheme.GetTextColor(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('label', '', cls, '', '');
  if not st.HasTextColor then
    st := FtGetStyleSheet().ResolveStyle('window', '', cls, '', '');
  if st.HasTextColor then
    Result := MakeRgb(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.95, 0.96, 0.97)
  else
    Result := MakeRgb(0.12, 0.15, 0.18);
end;

function TFtTheme.GetInputBackground(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('entry', '', cls, '', '');
  if st.HasBgColor then
    Result := MakeRgb(st.BgColor.R, st.BgColor.G, st.BgColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.15, 0.17, 0.20)
  else
    Result := MakeRgb(1.0, 1.0, 1.0);
end;

function TFtTheme.GetInputBorder(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('entry', '', cls, '', '');
  if st.HasBorderColor then
    Result := MakeRgb(st.BorderColor.R, st.BorderColor.G, st.BorderColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.30, 0.33, 0.38)
  else
    Result := MakeRgb(0.80, 0.82, 0.85);
end;

function TFtTheme.GetInputPlaceholderColor(): TFtRgbColor;
begin
  if FDarkMode then
    Result := MakeRgb(0.50, 0.53, 0.58)
  else
    Result := MakeRgb(0.60, 0.63, 0.68);
end;

procedure TFtTheme.DrawFocusRing(Canvas: TFtCanvasAgg; X, Y, W, H: Double; Radius: Double);
begin
  Canvas.DrawRoundedRectOutline(X - 1.5, Y - 1.5, W + 3.0, H + 3.0, Radius + 1.5, 2.0, 0.23, 0.51, 0.96, 0.6);
end;

procedure TFtTheme.DrawInputPlate(Canvas: TFtCanvasAgg; X, Y, W, H: Double; Focused: Boolean; CustomRadius: Double);
var
  rad: Double;
  bg, bd: TFtRgbColor;
begin
  if CustomRadius >= 0.0 then rad := CustomRadius else rad := 5.0;
  bg := GetInputBackground();
  if Focused then
    bd := GetAccentColor()
  else
    bd := GetInputBorder();

  Canvas.DrawRoundedRect(X, Y, W, H, rad, bg.R, bg.G, bg.B);
  Canvas.DrawRoundedRectOutline(X, Y, W, H, rad, 1.0, bd.R, bd.G, bd.B);
  if Focused then
    DrawFocusRing(Canvas, X, Y, W, H, rad);
end;

function TFtTheme.GetScrollBarTrackColor(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('scrollbar', '', cls, '', '');
  if st.HasBgColor then
    Result := MakeRgb(st.BgColor.R, st.BgColor.G, st.BgColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.16, 0.18, 0.20)
  else
    Result := MakeRgb(0.92, 0.93, 0.95);
end;

function TFtTheme.GetScrollBarThumbColor(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('scrollbar', '', cls, '', '');
  if st.HasTextColor then
    Result := MakeRgb(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.35, 0.38, 0.42)
  else
    Result := MakeRgb(0.72, 0.75, 0.78);
end;

procedure TFtTheme.DrawScrollBar(Canvas: TFtCanvasAgg; X, Y, W, H: Double; 
                                Orientation: TFtScrollBarOrientation; 
                                ThumbX, ThumbY, ThumbW, ThumbH: Double;
                                Hovered, Dragging: Boolean;
                                CustomRadius: Double);
var
  trackCol, thumbCol: TFtRgbColor;
  rad: Double;
begin
  if CustomRadius >= 0.0 then rad := CustomRadius else rad := 3.0;
  trackCol := GetScrollBarTrackColor();
  thumbCol := GetScrollBarThumbColor();

  if Dragging then
  begin
    thumbCol.R := thumbCol.R * 0.8;
    thumbCol.G := thumbCol.G * 0.8;
    thumbCol.B := thumbCol.B * 0.8;
  end
  else if Hovered then
  begin
    thumbCol.R := thumbCol.R * 0.9;
    thumbCol.G := thumbCol.G * 0.9;
    thumbCol.B := thumbCol.B * 0.9;
  end;

  Canvas.DrawRect(Round(X), Round(Y), Round(W), Round(H), trackCol.R, trackCol.G, trackCol.B);
  Canvas.DrawRoundedRect(ThumbX, ThumbY, ThumbW, ThumbH, rad, thumbCol.R, thumbCol.G, thumbCol.B);
end;

function TFtTheme.GetMenuBackground(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('menu', '', cls, '', '');
  if st.HasBgColor then
    Result := MakeRgb(st.BgColor.R, st.BgColor.G, st.BgColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.18, 0.20, 0.23)
  else
    Result := MakeRgb(0.98, 0.99, 1.00);
end;

function TFtTheme.GetMenuBorder(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('menu', '', cls, '', '');
  if st.HasBorderColor then
    Result := MakeRgb(st.BorderColor.R, st.BorderColor.G, st.BorderColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.30, 0.33, 0.38)
  else
    Result := MakeRgb(0.85, 0.87, 0.90);
end;

function TFtTheme.GetMenuHoverBackground(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('menu', '', cls, ':hover', '');
  if st.HasBgColor then
    Result := MakeRgb(st.BgColor.R, st.BgColor.G, st.BgColor.B)
  else
    Result := MakeRgb(0.23, 0.51, 0.96);
end;

function TFtTheme.GetMenuHoverTextColor(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('menu', '', cls, ':hover', '');
  if st.HasTextColor then
    Result := MakeRgb(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else
    Result := MakeRgb(1.0, 1.0, 1.0);
end;

function TFtTheme.GetMenuDisabledTextColor(): TFtRgbColor;
var
  st: TFtWidgetStyle;
  cls: string;
begin
  if FDarkMode then cls := 'dark' else cls := '';
  st := FtGetStyleSheet().ResolveStyle('menu', '', cls, ':disabled', '');
  if st.HasTextColor then
    Result := MakeRgb(st.TextColor.R, st.TextColor.G, st.TextColor.B)
  else if FDarkMode then
    Result := MakeRgb(0.44, 0.44, 0.48) // zinc-500 #71717a
  else
    Result := MakeRgb(0.58, 0.64, 0.72); // slate-400 #94a3b8
end;

function TFtTheme.GetMenuSeparatorColor(): TFtRgbColor;
begin
  if FDarkMode then
    Result := MakeRgb(0.26, 0.28, 0.32)
  else
    Result := MakeRgb(0.88, 0.90, 0.92);
end;

procedure TFtTheme.DrawMenuBar(Canvas: TFtCanvasAgg; X, Y, W, H: Integer);
var
  bg, bd: TFtRgbColor;
begin
  bg := GetMenuBackground();
  bd := GetMenuBorder();
  Canvas.DrawRect(X, Y, W, H, bg.R, bg.G, bg.B);
  Canvas.DrawRect(X, Y + H - 1, W, 1, bd.R, bd.G, bd.B);
end;

procedure TFtTheme.DrawMenuBarItem(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                                  const Caption: string; Font: TFtFont; 
                                  Hovered, Active: Boolean);
var
  bg, txt: TFtRgbColor;
  actualFont: TFtFont;
begin
  if Active or Hovered then
  begin
    bg := GetMenuHoverBackground();
    txt := GetMenuHoverTextColor();
    Canvas.DrawRoundedRect(X + 2, Y + 2, W - 4, H - 4, 4.0, bg.R, bg.G, bg.B);
  end
  else
    txt := GetTextColor();

  if Caption <> '' then
  begin
    if not Assigned(Font) then actualFont := FtGetSystemFont() else actualFont := Font;
    Canvas.DrawTextCentered(X, Y, W, H, Caption, actualFont, txt.R, txt.G, txt.B);
  end;
end;

procedure TFtTheme.DrawPopupMenuPlate(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; CustomRadius: Double);
var
  bg, bd: TFtRgbColor;
  rad: Double;
begin
  if CustomRadius >= 0.0 then rad := CustomRadius else rad := 6.0;
  bg := GetMenuBackground();
  bd := GetMenuBorder();
  Canvas.DrawShadow(X, Y, W, H, rad, 0.0, 3.0, 8.0, 0.0, 0.0, 0.0, 0.25);
  Canvas.DrawRoundedRect(X, Y, W, H, rad, bg.R, bg.G, bg.B);
  Canvas.DrawRoundedRectOutline(X, Y, W, H, rad, 1.0, bd.R, bd.G, bd.B);
end;

procedure TFtTheme.DrawPopupMenuItem(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                                    const Caption, Shortcut: string; Font: TFtFont; 
                                    Hovered, Enabled, Checked, HasSubMenu: Boolean);
var
  bg, txt: TFtRgbColor;
  actualFont: TFtFont;
  txtY: Double;
begin
  if Hovered and Enabled then
  begin
    bg := GetMenuHoverBackground();
    txt := GetMenuHoverTextColor();
    Canvas.DrawRoundedRect(X + 3, Y + 1, W - 6, H - 2, 4.0, bg.R, bg.G, bg.B);
  end
  else if not Enabled then
  begin
    txt := GetMenuDisabledTextColor();
  end
  else
  begin
    txt := GetTextColor();
  end;

  if not Assigned(Font) then actualFont := FtGetSystemFont() else actualFont := Font;
  txtY := Y + (H / 2.0) + (actualFont.Ascent - actualFont.Descent) / 2.0;

  if Checked then
    Canvas.DrawText(X + 6, txtY, #$E2#$9C#$93, actualFont, txt.R, txt.G, txt.B);

  if Caption <> '' then
    Canvas.DrawText(X + 24, txtY, Caption, actualFont, txt.R, txt.G, txt.B);

  if Shortcut <> '' then
  begin
    if not Enabled then
      Canvas.DrawText(X + W - Round(actualFont.GetTextWidth(Shortcut)) - 16, txtY, Shortcut, actualFont, txt.R, txt.G, txt.B)
    else
      Canvas.DrawText(X + W - Round(actualFont.GetTextWidth(Shortcut)) - 16, txtY, Shortcut, actualFont, txt.R * 0.8, txt.G * 0.8, txt.B * 0.8);
  end;

  if HasSubMenu then
  begin
    if Hovered and Enabled then
      Canvas.DrawSubMenuArrow(X + W - 14.0, Y + H * 0.5, txt.R, txt.G, txt.B, 1.0)
    else if not Enabled then
      Canvas.DrawSubMenuArrow(X + W - 14.0, Y + H * 0.5, txt.R, txt.G, txt.B, 0.5)
    else
      Canvas.DrawSubMenuArrow(X + W - 14.0, Y + H * 0.5, txt.R, txt.G, txt.B, 0.75);
  end;
end;

procedure TFtTheme.DrawMenuSeparator(Canvas: TFtCanvasAgg; X, Y, W: Integer);
var
  sep: TFtRgbColor;
begin
  sep := GetMenuSeparatorColor();
  Canvas.DrawRect(X + 6, Y, W - 12, 1, sep.R, sep.G, sep.B);
end;

{ TFtThemeManager }

constructor TFtThemeManager.Create();
begin
  inherited Create();
  FCurrentTheme := TFtTheme.Create('default');
  FDarkMode := False;
  FThemes := TStringList.Create();
  FOnThemeChange := nil;

  ScanThemeDirectories();
  SetTheme('default');
end;

procedure TFtThemeManager.SetDarkMode(AValue: Boolean);
begin
  if FDarkMode <> AValue then
  begin
    FDarkMode := AValue;
    FtSetCssDarkMode(AValue);
    if Assigned(FCurrentTheme) then
      FCurrentTheme.DarkMode := AValue;
    if Assigned(FOnThemeChange) then
      FOnThemeChange();
  end;
end;

destructor TFtThemeManager.Destroy();
begin
  FThemes.Free();
  FCurrentTheme.Free();
  inherited Destroy();
end;

function TFtThemeManager.FindThemePath(const AName: string): string;
var
  lower: string;
begin
  lower := LowerCase(Trim(AName));
  Result := FThemes.Values[lower];
  if (Result = '') or not FileExists(Result) then
  begin
    if FileExists('themes/' + lower + '.css') then
      Result := 'themes/' + lower + '.css'
    else if FileExists('../themes/' + lower + '.css') then
      Result := '../themes/' + lower + '.css';
  end;
end;

function TFtThemeManager.SetTheme(const AName: string): Boolean;
var
  lowerName, path: string;
begin
  lowerName := LowerCase(Trim(AName));
  if lowerName = '' then lowerName := 'default';

  path := FindThemePath(lowerName);
  if (path <> '') and FileExists(path) then
  begin
    Result := FtGetStyleSheet().LoadFromFile(path);
  end
  else if lowerName = 'default' then
  begin
    Result := FtGetStyleSheet().LoadFromString(DEFAULT_THEME_CSS);
  end
  else
    Result := False;

  if Result then
  begin
    FCurrentTheme.Name := lowerName;
    FCurrentTheme.DarkMode := FDarkMode;
    if Assigned(FOnThemeChange) then
      FOnThemeChange();
  end;
end;

function TFtThemeManager.GetThemeName(): string;
begin
  if Assigned(FCurrentTheme) then
    Result := FCurrentTheme.Name
  else
    Result := 'default';
end;

function TFtThemeManager.GetAvailableThemes(): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FThemes.Count - 1 do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + FThemes.Names[i];
  end;
  if (Result = '') or (Pos('default', Result) = 0) then
  begin
    if Result <> '' then Result := 'default,' + Result else Result := 'default';
  end;
end;

function TFtThemeManager.HasDarkMode(const AName: string): Boolean;
begin
  Result := True;
end;

function TFtThemeManager.LoadThemeFile(const AFilePath: string): Boolean;
var
  cleanPath, baseName: string;
begin
  Result := False;
  cleanPath := Trim(AFilePath);
  if not FileExists(cleanPath) then Exit;

  baseName := LowerCase(ChangeFileExt(ExtractFileName(cleanPath), ''));
  if baseName <> '' then
  begin
    FThemes.Values[baseName] := cleanPath;
    Result := True;
  end;
end;

function TFtThemeManager.LoadThemeDir(const ADirPath: string): Integer;
var
  sr: TSearchRec;
  cleanDir: string;
begin
  Result := 0;
  cleanDir := ExcludeTrailingPathDelimiter(ADirPath);
  if not DirectoryExists(cleanDir) then Exit;

  if FindFirst(cleanDir + '/*.css', faAnyFile, sr) = 0 then
  begin
    repeat
      if (sr.Attr and faDirectory = 0) then
      begin
        if LoadThemeFile(cleanDir + '/' + sr.Name) then
          Inc(Result);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

procedure TFtThemeManager.ScanThemeDirectories();
var
  homeDir, customPath, dirItem: string;
  posDelim: Integer;
begin
  // Built-in themes in themes/ directory
  LoadThemeDir('themes');
  LoadThemeDir('../themes');
  LoadThemeDir('../../themes');

  homeDir := GetEnvironmentVariable('HOME');
  customPath := GetEnvironmentVariable('FT_THEME_PATH');
  while customPath <> '' do
  begin
    posDelim := Pos(':', customPath);
    if posDelim > 0 then
    begin
      dirItem := Copy(customPath, 1, posDelim - 1);
      Delete(customPath, 1, posDelim);
    end
    else
    begin
      dirItem := customPath;
      customPath := '';
    end;
    if dirItem <> '' then
      LoadThemeDir(Trim(dirItem));
  end;

  if homeDir <> '' then
  begin
    LoadThemeDir(homeDir + '/.config/floria/themes');
    LoadThemeDir(homeDir + '/.local/share/floria/themes');
  end;

  LoadThemeDir('/usr/share/floria/themes');
  LoadThemeDir('/etc/floria/themes');
end;

function TFtThemeManager.GetCornerRadius(): Double;
begin
  if Assigned(FCurrentTheme) then
    Result := FCurrentTheme.CornerRadius
  else
    Result := 6.0;
end;

procedure TFtThemeManager.SetCornerRadius(AValue: Double);
begin
  if Assigned(FCurrentTheme) then
  begin
    FCurrentTheme.CornerRadius := AValue;
    if Assigned(FOnThemeChange) then
      FOnThemeChange();
  end;
end;

function TFtThemeManager.GetEnableShadow(): Boolean;
begin
  if Assigned(FCurrentTheme) then
    Result := FCurrentTheme.EnableShadow
  else
    Result := True;
end;

procedure TFtThemeManager.SetEnableShadow(AValue: Boolean);
begin
  if Assigned(FCurrentTheme) then
  begin
    FCurrentTheme.EnableShadow := AValue;
    if Assigned(FOnThemeChange) then
      FOnThemeChange();
  end;
end;

function FtThemeManager(): TFtThemeManager;
begin
  if not Assigned(uThemeManager) then
    uThemeManager := TFtThemeManager.Create();
  Result := uThemeManager;
end;

function FtGetTheme(): TFtTheme;
begin
  Result := FtThemeManager().CurrentTheme;
end;

function FtSetTheme(const AName: string): Boolean;
begin
  Result := FtThemeManager().SetTheme(AName);
end;

function FtGetThemeName(): string;
begin
  Result := FtThemeManager().GetThemeName();
end;

function FtGetAvailableThemes(): string;
begin
  Result := FtThemeManager().GetAvailableThemes();
end;

function FtGetDarkMode(): Boolean;
begin
  Result := FtThemeManager().DarkMode;
end;

procedure FtSetDarkMode(AValue: Boolean);
begin
  FtThemeManager().DarkMode := AValue;
  if Assigned(FtThemeManager().OnThemeChange) then
    FtThemeManager().OnThemeChange();
end;

function FtThemeHasDarkMode(const AName: string): Boolean;
begin
  Result := FtThemeManager().HasDarkMode(AName);
end;

function FtThemeLoadFile(const AFilePath: string): Boolean;
begin
  Result := FtThemeManager().LoadThemeFile(AFilePath);
end;

function FtThemeLoadDir(const ADirPath: string): Integer;
begin
  Result := FtThemeManager().LoadThemeDir(ADirPath);
end;

function FtGetCornerRadius(): Double;
begin
  Result := FtThemeManager().CornerRadius;
end;

procedure FtSetCornerRadius(AValue: Double);
begin
  FtThemeManager().CornerRadius := AValue;
end;

function FtGetEnableShadow(): Boolean;
begin
  Result := FtThemeManager().EnableShadow;
end;

procedure FtSetEnableShadow(AValue: Boolean);
begin
  FtThemeManager().EnableShadow := AValue;
end;

finalization
  if Assigned(uThemeManager) then
  begin
    uThemeManager.Free();
    uThemeManager := nil;
  end;

end.
