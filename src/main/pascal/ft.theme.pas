unit Ft.Theme;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, IniFiles, Ft.Canvas.Agg, Ft.Font;

type
  { Button interactive states }
  TFtButtonState = (bsNormal, bsHovered, bsPressed);

  { ScrollBar orientation }
  TFtScrollBarOrientation = (ftSbHorizontal, ftSbVertical);

  { RGB Color representation (0.0 .. 1.0) }
  TFtRgbColor = record
    R, G, B: Double;
  end;

  { Complete color palette for a theme mode (Light or Dark) }
  TFtThemePalette = record
    WindowBg: TFtRgbColor;

    BtnNormPlate: TFtRgbColor;
    BtnNormBorder: TFtRgbColor;
    BtnNormText: TFtRgbColor;
    BtnNormBevelTop: TFtRgbColor;
    BtnNormBevelBot: TFtRgbColor;

    BtnHovPlate: TFtRgbColor;
    BtnHovBorder: TFtRgbColor;
    BtnHovText: TFtRgbColor;
    BtnHovBevelTop: TFtRgbColor;
    BtnHovBevelBot: TFtRgbColor;

    BtnPressPlate: TFtRgbColor;
    BtnPressBorder: TFtRgbColor;
    BtnPressText: TFtRgbColor;
    BtnPressBevelTop: TFtRgbColor;
    BtnPressBevelBot: TFtRgbColor;

    BtnTogPlate: TFtRgbColor;
    BtnTogBorder: TFtRgbColor;
    BtnTogText: TFtRgbColor;
    BtnTogIndicator: TFtRgbColor;
    BtnTogBevelTop: TFtRgbColor;
    BtnTogBevelBot: TFtRgbColor;
  end;

  { Forward declarations }
  TFtTheme = class;
  TFtThemeManager = class;

  TFtThemeChangeNotify = procedure() of object;

  { Base theme class }
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
    constructor Create(const AName: string); virtual;
    destructor Destroy(); override;

    function GetName(): string; virtual;
    function GetDarkMode(): Boolean; virtual;
    procedure SetDarkMode(AValue: Boolean); virtual;

    function GetCornerRadius(): Double; virtual;
    procedure SetCornerRadius(AValue: Double); virtual;
    function GetEnableShadow(): Boolean; virtual;
    procedure SetEnableShadow(AValue: Boolean); virtual;

    function HasDarkMode(): Boolean; virtual;
    procedure DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer); virtual; abstract;
    procedure DrawButton(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                         State: TFtButtonState; Toggled: Boolean; 
                         const Caption: string; Font: TFtFont); virtual;
    procedure DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Toggled: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); virtual; abstract;
    procedure DrawSwitch(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                         State: TFtButtonState; Checked: Boolean; 
                         const Caption: string; Font: TFtFont); virtual;
    procedure DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Checked: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); virtual; abstract;
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

    property Name: string read GetName;
    property DarkMode: Boolean read GetDarkMode write SetDarkMode;
    property CornerRadius: Double read GetCornerRadius write SetCornerRadius;
    property EnableShadow: Boolean read GetEnableShadow write SetEnableShadow;
    property ShadowOffsetY: Double read FShadowOffsetY write FShadowOffsetY;
    property ShadowBlur: Double read FShadowBlur write FShadowBlur;
    property ShadowOpacity: Double read FShadowOpacity write FShadowOpacity;
  end;

  { Default Theme: modern Breeze / Fusion flat vector look with rounded corners, vibrant blue accents, and soft drop shadows }
  TFtThemeDefault = class(TFtTheme)
  public
    constructor Create(const AName: string = 'default'); override;
    function HasDarkMode(): Boolean; override;
    procedure DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer); override;
    procedure DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Toggled: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); override;
    procedure DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Checked: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); override;
    function GetAccentColor(): TFtRgbColor; override;
    function GetTextColor(): TFtRgbColor; override;
  end;

  { Backward compatibility alias }
  TFtThemeQt6 = TFtThemeDefault;

  { Dynamic File-Based Theme: loaded at runtime from global or user *.theme files }
  TFtFileTheme = class(TFtTheme)
  private
    FFilePath: string;
    FAuthor: string;
    FDescription: string;
    FStyleType: string;
    FHasDarkSection: Boolean;
    FLightPalette: TFtThemePalette;
    FDarkPalette: TFtThemePalette;
    procedure LoadFromFile(const APath: string);
    function GetActivePalette(): TFtThemePalette;
  public
    constructor CreateFromFile(const APath: string);
    destructor Destroy(); override;

    function HasDarkMode(): Boolean; override;
    procedure DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer); override;
    procedure DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Toggled: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); override;
    procedure DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
                           State: TFtButtonState; Checked: Boolean; 
                           const Caption: string; Font: TFtFont;
                           CustomRadius: Double = -1.0; CustomShadow: Integer = -1); override;
    function GetAccentColor(): TFtRgbColor; override;
    function GetTextColor(): TFtRgbColor; override;
    function GetInputBackground(): TFtRgbColor; override;
    function GetInputBorder(): TFtRgbColor; override;
    function GetScrollBarTrackColor(): TFtRgbColor; override;
    function GetScrollBarThumbColor(): TFtRgbColor; override;
    function GetMenuBackground(): TFtRgbColor; override;
    function GetMenuBorder(): TFtRgbColor; override;

    property FilePath: string read FFilePath;
    property Author: string read FAuthor;
    property Description: string read FDescription;
    property StyleType: string read FStyleType;
  end;

  { Theme Manager: handles registry, current active theme, file discovery, and desktop ricing auto-detection }
  TFtThemeManager = class
  private
    FThemes: TFPList;
    FCurrentTheme: TFtTheme;
    FDarkMode: Boolean;
    FOnThemeChange: TFtThemeChangeNotify;
    function DetectThemeName(): string;
    function DetectDarkMode(): Boolean;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure RegisterTheme(ATheme: TFtTheme);
    function FindTheme(const AName: string): TFtTheme;
    function SetTheme(const AName: string): Boolean;
    function GetCurrentTheme(): TFtTheme;
    function GetThemeName(): string;
    function GetAvailableThemes(): string;

    function GetDarkMode(): Boolean;
    procedure SetDarkMode(AValue: Boolean);
    function HasDarkMode(const AName: string): Boolean;

    function GetCornerRadius(): Double;
    procedure SetCornerRadius(AValue: Double);
    function GetEnableShadow(): Boolean;
    procedure SetEnableShadow(AValue: Boolean);

    function LoadThemeFile(const AFilePath: string): Boolean;
    function LoadThemeDir(const ADirPath: string): Integer;
    procedure ScanThemeDirectories();

    property CurrentTheme: TFtTheme read GetCurrentTheme;
    property DarkMode: Boolean read GetDarkMode write SetDarkMode;
    property CornerRadius: Double read GetCornerRadius write SetCornerRadius;
    property EnableShadow: Boolean read GetEnableShadow write SetEnableShadow;
    property OnThemeChange: TFtThemeChangeNotify read FOnThemeChange write FOnThemeChange;
  end;

function ParseHexColor(const S: string; out R, G, B: Double): Boolean;
function MakeRgbColor(R, G, B: Double): TFtRgbColor;

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

implementation

var
  uThemeManager: TFtThemeManager = nil;

function MakeRgbColor(R, G, B: Double): TFtRgbColor;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
end;

function ParseHexColor(const S: string; out R, G, B: Double): Boolean;
var
  clean: string;
  val: LongWord;
begin
  Result := False;
  clean := Trim(S);
  if clean = '' then Exit;

  if clean[1] = '#' then
    Delete(clean, 1, 1)
  else if (Length(clean) >= 2) and (clean[1] = '0') and (UpCase(clean[2]) = 'X') then
    Delete(clean, 1, 2);

  if Length(clean) = 3 then
    clean := clean[1] + clean[1] + clean[2] + clean[2] + clean[3] + clean[3];

  if Length(clean) = 6 then
  begin
    if TryStrToInt('$' + clean, LongInt(val)) then
    begin
      R := ((val shr 16) and $FF) / 255.0;
      G := ((val shr 8) and $FF) / 255.0;
      B := (val and $FF) / 255.0;
      Result := True;
    end;
  end;
end;

procedure AdjustRgb(var C: TFtRgbColor; Factor: Double);
begin
  C.R := C.R * Factor;
  if C.R > 1.0 then C.R := 1.0;
  if C.R < 0.0 then C.R := 0.0;
  C.G := C.G * Factor;
  if C.G > 1.0 then C.G := 1.0;
  if C.G < 0.0 then C.G := 0.0;
  C.B := C.B * Factor;
  if C.B > 1.0 then C.B := 1.0;
  if C.B < 0.0 then C.B := 0.0;
end;

function ReadColorFromIni(Ini: TIniFile; const Section, Key: string; const DefaultColor: TFtRgbColor): TFtRgbColor;
var
  strVal: string;
  r, g, b: Double;
begin
  strVal := Ini.ReadString(Section, Key, '');
  if (strVal <> '') and ParseHexColor(strVal, r, g, b) then
    Result := MakeRgbColor(r, g, b)
  else
    Result := DefaultColor;
end;

{ TFtTheme }

constructor TFtTheme.Create(const AName: string);
begin
  inherited Create();
  FName := AName;
  FDarkMode := False;
  FCornerRadius := 4.0;
  FEnableShadow := True;
  FShadowOffsetY := 2.0;
  FShadowBlur := 3.5;
  FShadowOpacity := 0.15;
end;

destructor TFtTheme.Destroy();
begin
  inherited Destroy();
end;

function TFtTheme.GetName(): string;
begin
  Result := FName;
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
  Result := False;
end;

procedure TFtTheme.DrawButton(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
  State: TFtButtonState; Toggled: Boolean; const Caption: string; Font: TFtFont);
begin
  DrawButtonEx(Canvas, X, Y, W, H, State, Toggled, Caption, Font, -1.0, -1);
end;

procedure TFtTheme.DrawSwitch(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
  State: TFtButtonState; Checked: Boolean; const Caption: string; Font: TFtFont);
begin
  DrawSwitchEx(Canvas, X, Y, W, H, State, Checked, Caption, Font, -1.0, -1);
end;

function TFtTheme.GetAccentColor(): TFtRgbColor;
begin
  Result := MakeRgbColor(0.24, 0.60, 0.92);
end;

function TFtTheme.GetTextColor(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.935, 0.942, 0.950)
  else
    Result := MakeRgbColor(0.12, 0.14, 0.16);
end;

procedure TFtTheme.DrawFocusRing(Canvas: TFtCanvasAgg; X, Y, W, H: Double; Radius: Double);
var
  accent: TFtRgbColor;
  ringOffset, ringWidth: Double;
begin
  if (W <= 0) or (H <= 0) then Exit;
  accent := GetAccentColor();
  ringOffset := 2.0;
  ringWidth := 1.8;
  if Radius < 0.0 then
    Radius := CornerRadius;
  Canvas.DrawRoundedRectOutline(
    X - ringOffset,
    Y - ringOffset,
    W + (ringOffset * 2.0),
    H + (ringOffset * 2.0),
    Radius + ringOffset,
    ringWidth,
    accent.R, accent.G, accent.B, 0.90
  );
end;

function TFtTheme.GetInputBackground(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.12, 0.14, 0.18)
  else
    Result := MakeRgbColor(1.0, 1.0, 1.0);
end;

function TFtTheme.GetInputBorder(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.24, 0.28, 0.35)
  else
    Result := MakeRgbColor(0.80, 0.83, 0.88);
end;

function TFtTheme.GetInputPlaceholderColor(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.55, 0.60, 0.68)
  else
    Result := MakeRgbColor(0.60, 0.64, 0.70);
end;

procedure TFtTheme.DrawInputPlate(Canvas: TFtCanvasAgg; X, Y, W, H: Double; Focused: Boolean; CustomRadius: Double = -1.0);
var
  effRadius: Double;
  bgCol, borderCol: TFtRgbColor;
begin
  if (W <= 0) or (H <= 0) then Exit;
  if CustomRadius >= 0.0 then
    effRadius := CustomRadius
  else
    effRadius := CornerRadius;

  bgCol := GetInputBackground();
  if Focused then
    borderCol := GetAccentColor()
  else
    borderCol := GetInputBorder();

  { Draw background plate }
  Canvas.DrawRoundedRect(X, Y, W, H, effRadius, bgCol.R, bgCol.G, bgCol.B, 1.0);

  { Draw border outline }
  Canvas.DrawRoundedRectOutline(X, Y, W, H, effRadius, 1.0, borderCol.R, borderCol.G, borderCol.B, 1.0);

  { If focused, draw theme focus ring }
  if Focused then
    DrawFocusRing(Canvas, X, Y, W, H, effRadius);
end;

function TFtTheme.GetScrollBarTrackColor(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.18, 0.20, 0.25)
  else
    Result := MakeRgbColor(0.92, 0.93, 0.95);
end;

function TFtTheme.GetScrollBarThumbColor(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.42, 0.46, 0.54)
  else
    Result := MakeRgbColor(0.68, 0.72, 0.78);
end;

procedure TFtTheme.DrawScrollBar(Canvas: TFtCanvasAgg; X, Y, W, H: Double;
  Orientation: TFtScrollBarOrientation;
  ThumbX, ThumbY, ThumbW, ThumbH: Double;
  Hovered, Dragging: Boolean;
  CustomRadius: Double = -1.0);
var
  trackRad, thumbRad, alpha: Double;
  trackCol, thumbCol: TFtRgbColor;
begin
  if (W <= 0) or (H <= 0) then Exit;

  if CustomRadius >= 0.0 then
  begin
    trackRad := CustomRadius;
    thumbRad := CustomRadius;
  end
  else
  begin
    if Orientation = ftSbVertical then
      trackRad := W / 2.0
    else
      trackRad := H / 2.0;
    thumbRad := trackRad;
  end;

  trackCol := GetScrollBarTrackColor();
  thumbCol := GetScrollBarThumbColor();

  { Subtle track background when hovered or dragging }
  if Hovered or Dragging then
    Canvas.DrawRoundedRect(X, Y, W, H, trackRad, trackCol.R, trackCol.G, trackCol.B, 0.35);

  { Thumb styling }
  if Dragging then
  begin
    thumbCol := GetAccentColor();
    alpha := 0.90;
  end
  else if Hovered then
  begin
    AdjustRgb(thumbCol, 1.15);
    alpha := 0.80;
  end
  else
    alpha := 0.55;

  Canvas.DrawRoundedRect(ThumbX, ThumbY, ThumbW, ThumbH, thumbRad, thumbCol.R, thumbCol.G, thumbCol.B, alpha);
end;

function TFtTheme.GetMenuBackground(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.16, 0.18, 0.22)
  else
    Result := MakeRgbColor(0.98, 0.98, 0.99);
end;

function TFtTheme.GetMenuBorder(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.28, 0.32, 0.38)
  else
    Result := MakeRgbColor(0.82, 0.85, 0.90);
end;

function TFtTheme.GetMenuHoverBackground(): TFtRgbColor;
begin
  Result := GetAccentColor();
end;

function TFtTheme.GetMenuHoverTextColor(): TFtRgbColor;
begin
  Result := MakeRgbColor(1.0, 1.0, 1.0);
end;

function TFtTheme.GetMenuSeparatorColor(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.25, 0.28, 0.34)
  else
    Result := MakeRgbColor(0.88, 0.90, 0.93);
end;

procedure TFtTheme.DrawMenuBar(Canvas: TFtCanvasAgg; X, Y, W, H: Integer);
var
  bgCol, borderCol: TFtRgbColor;
begin
  if (W <= 0) or (H <= 0) then Exit;
  if DarkMode then
  begin
    bgCol := MakeRgbColor(0.14, 0.15, 0.18);
    borderCol := MakeRgbColor(0.22, 0.24, 0.28);
  end
  else
  begin
    bgCol := MakeRgbColor(0.95, 0.96, 0.97);
    borderCol := MakeRgbColor(0.86, 0.88, 0.91);
  end;

  Canvas.DrawRect(X, Y, W, H, bgCol.R, bgCol.G, bgCol.B);
  Canvas.DrawRect(X, Y + H - 1, W, 1, borderCol.R, borderCol.G, borderCol.B);
end;

procedure TFtTheme.DrawMenuBarItem(Canvas: TFtCanvasAgg; X, Y, W, H: Integer;
  const Caption: string; Font: TFtFont; Hovered, Active: Boolean);
var
  pillCol, txtCol: TFtRgbColor;
begin
  if (W <= 0) or (H <= 0) then Exit;

  if Active then
  begin
    pillCol := GetAccentColor();
    txtCol := MakeRgbColor(1.0, 1.0, 1.0);
    Canvas.DrawRect(X, Y, W, H, pillCol.R, pillCol.G, pillCol.B);
  end
  else if Hovered then
  begin
    if DarkMode then
      pillCol := MakeRgbColor(0.25, 0.28, 0.35)
    else
      pillCol := MakeRgbColor(0.88, 0.90, 0.94);
    txtCol := GetTextColor();
    Canvas.DrawRect(X, Y, W, H, pillCol.R, pillCol.G, pillCol.B);
  end
  else
    txtCol := GetTextColor();

  if Assigned(Font) then
    Canvas.DrawTextCentered(X, Y, W, H, Caption, Font, txtCol.R, txtCol.G, txtCol.B);
end;

procedure TFtTheme.DrawPopupMenuPlate(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; CustomRadius: Double = -1.0);
var
  bgCol, borderCol: TFtRgbColor;
begin
  if (W <= 0) or (H <= 0) then Exit;
  bgCol := GetMenuBackground();
  borderCol := GetMenuBorder();

  { Flat rectangular plate filling the native popup window }
  { Rounded corners and drop shadows are handled natively by the X11 compositor }
  Canvas.DrawRoundedRect(X, Y, W, H, 0.0, bgCol.R, bgCol.G, bgCol.B, 1.0);
  Canvas.DrawRoundedRectOutline(X, Y, W, H, 0.0, 1.0, borderCol.R, borderCol.G, borderCol.B, 1.0);
end;

procedure TFtTheme.DrawPopupMenuItem(Canvas: TFtCanvasAgg; X, Y, W, H: Integer;
  const Caption, Shortcut: string; Font: TFtFont;
  Hovered, Enabled, Checked, HasSubMenu: Boolean);
var
  pillCol, txtCol, iconCol, checkCol: TFtRgbColor;
  tx, ty, sw: Double;
begin
  if (W <= 0) or (H <= 0) then Exit;

  if Hovered and Enabled then
  begin
    pillCol := GetMenuHoverBackground();
    Canvas.DrawRect(X, Y, W, H, pillCol.R, pillCol.G, pillCol.B);
    txtCol := GetMenuHoverTextColor();
    iconCol := GetMenuHoverTextColor();
    checkCol := GetMenuHoverTextColor();
  end
  else
  begin
    if Enabled then
    begin
      txtCol := GetTextColor();
      iconCol := GetTextColor();
      checkCol := GetAccentColor();
    end
    else
    begin
      if DarkMode then
        txtCol := MakeRgbColor(0.42, 0.46, 0.52)
      else
        txtCol := MakeRgbColor(0.62, 0.65, 0.70);
      iconCol := txtCol;
      checkCol := txtCol;
    end;
  end;

  if Checked then
    Canvas.DrawCheckMark(X + 13.0, Y + H / 2.0, checkCol.R, checkCol.G, checkCol.B, 1.0);

  if Assigned(Font) then
    ty := Y + (H / 2.0) + (Font.Ascent - Font.Descent) / 2.0
  else
    ty := Y + H / 2.0 + 4.0;

  if Assigned(Font) and (Caption <> '') then
  begin
    tx := X + 26.0;
    Canvas.DrawText(tx, ty, Caption, Font, txtCol.R, txtCol.G, txtCol.B);
  end;

  if Assigned(Font) and (Shortcut <> '') then
  begin
    sw := Font.GetTextWidth(Shortcut);
    if HasSubMenu then
      tx := X + W - 26.0 - sw
    else
      tx := X + W - 14.0 - sw;
    Canvas.DrawText(tx, ty, Shortcut, Font, iconCol.R, iconCol.G, iconCol.B);
  end;

  if HasSubMenu then
    Canvas.DrawSubMenuArrow(X + W - 11.0, Y + H / 2.0, iconCol.R, iconCol.G, iconCol.B, 1.0);
end;

procedure TFtTheme.DrawMenuSeparator(Canvas: TFtCanvasAgg; X, Y, W: Integer);
var
  sepCol: TFtRgbColor;
begin
  if W <= 0 then Exit;
  sepCol := GetMenuSeparatorColor();
  Canvas.DrawRect(X + 2, Y + 3, W - 4, 1, sepCol.R, sepCol.G, sepCol.B);
end;

{ TFtThemeDefault }

constructor TFtThemeDefault.Create(const AName: string);
begin
  inherited Create(AName);
  FCornerRadius := 5.0; // Modern Breeze flat vector curvature
  FEnableShadow := True;
  FShadowOffsetY := 2.0;
  FShadowBlur := 4.0;
  FShadowOpacity := 0.14;
end;

function TFtThemeDefault.HasDarkMode(): Boolean;
begin
  Result := True;
end;

function TFtThemeDefault.GetAccentColor(): TFtRgbColor;
begin
  Result := MakeRgbColor(0.24, 0.60, 0.92);
end;

function TFtThemeDefault.GetTextColor(): TFtRgbColor;
begin
  if DarkMode then
    Result := MakeRgbColor(0.935, 0.942, 0.950)
  else
    Result := MakeRgbColor(0.12, 0.14, 0.16);
end;

procedure TFtThemeDefault.DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer);
begin
  if DarkMode then
    Canvas.Clear(0.137, 0.149, 0.161)
  else
    Canvas.Clear(0.935, 0.942, 0.950);
end;

procedure TFtThemeDefault.DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
  State: TFtButtonState; Toggled: Boolean; const Caption: string; Font: TFtFont;
  CustomRadius: Double; CustomShadow: Integer);
var
  borderR, borderG, borderB: Double;
  plateR, plateG, plateB: Double;
  textR, textG, textB: Double;
  textOffsetX, textOffsetY: Integer;
  rad: Double;
  hasShadow: Boolean;
  sRed, sGreen, sBlue, shOffY, shBlur, shOpac: Double;
begin
  textOffsetX := 0;
  textOffsetY := 0;

  rad := FCornerRadius;
  if CustomRadius >= 0.0 then rad := CustomRadius;

  hasShadow := FEnableShadow;
  if CustomShadow = 0 then hasShadow := False
  else if CustomShadow > 0 then hasShadow := True;

  sRed := 0.0; sGreen := 0.0; sBlue := 0.0;

  if DarkMode then
  begin
    if Toggled then
    begin
      borderR := 0.24; borderG := 0.60; borderB := 0.92;
      plateR  := 0.16; plateG  := 0.22; plateB  := 0.28;
      textR   := 0.35; textG   := 0.70; textB   := 0.95;
      textOffsetY := 1;
    end
    else
    begin
      case State of
        bsPressed:
        begin
          borderR := 0.15; borderG := 0.50; borderB := 0.85;
          plateR  := 0.16; plateG  := 0.18; plateB  := 0.20;
          textR   := 0.24; textG   := 0.60; textB   := 0.92;
          textOffsetY := 1;
        end;
        bsHovered:
        begin
          borderR := 0.24; borderG := 0.60; borderB := 0.92; // Breeze Blue
          plateR  := 0.23; plateG  := 0.25; plateB  := 0.27;
          textR   := 1.00; textG   := 1.00; textB   := 1.00;
          // Blue glow shadow on hover in dark mode!
          sRed := 0.24; sGreen := 0.60; sBlue := 0.92;
        end;
        else // bsNormal
        begin
          borderR := 0.28; borderG := 0.30; borderB := 0.32;
          plateR  := 0.19; plateG  := 0.21; plateB  := 0.23;
          textR   := 0.935; textG  := 0.942; textB  := 0.950;
        end;
      end;
    end;
  end
  else
  begin
    if Toggled then
    begin
      borderR := 0.24; borderG := 0.60; borderB := 0.92;
      plateR  := 0.86; plateG  := 0.91; plateB  := 0.97;
      textR   := 0.10; textG   := 0.30; textB   := 0.58;
      textOffsetY := 1;
    end
    else
    begin
      case State of
        bsPressed:
        begin
          borderR := 0.18; borderG := 0.50; borderB := 0.85;
          plateR  := 0.86; plateG  := 0.90; plateB  := 0.94;
          textR   := 0.08; textG   := 0.25; textB   := 0.52;
          textOffsetY := 1;
        end;
        bsHovered:
        begin
          borderR := 0.24; borderG := 0.60; borderB := 0.92; // Breeze Blue
          plateR  := 1.00; plateG  := 1.00; plateB  := 1.00;
          textR   := 0.08; textG   := 0.12; textB   := 0.18;
          sRed := 0.24; sGreen := 0.60; sBlue := 0.92;
        end;
        else // bsNormal
        begin
          borderR := 0.74; borderG := 0.77; borderB := 0.82;
          plateR  := 0.975; plateG := 0.980; plateB := 0.985;
          textR   := 0.16; textG   := 0.18; textB   := 0.22;
        end;
      end;
    end;
  end;

  // 1. Soft Drop Shadow
  if hasShadow and not Toggled then
  begin
    if State = bsPressed then
    begin
      shOffY := 0.5;
      shBlur := 1.5;
      shOpac := 0.08;
    end
    else if State = bsHovered then
    begin
      shOffY := FShadowOffsetY + 0.5;
      shBlur := FShadowBlur + 2.0;
      if DarkMode then
        shOpac := 0.28
      else
        shOpac := 0.20;
    end
    else
    begin
      shOffY := FShadowOffsetY;
      shBlur := FShadowBlur;
      if DarkMode then
        shOpac := 0.25
      else
        shOpac := FShadowOpacity;
    end;
    Canvas.DrawShadow(X, Y, W, H, rad, 0.0, shOffY, shBlur, sRed, sGreen, sBlue, shOpac);
  end;

  // 2. Rounded Button Plate Fill
  Canvas.DrawRoundedRect(X + 0.5, Y + 0.5, W - 1.0, H - 1.0, rad, plateR, plateG, plateB);

  // 3. Rounded Border (1px)
  Canvas.DrawRoundedRectOutline(X, Y, W, H, rad, 1.0, borderR, borderG, borderB);

  // 4. Button Caption
  if Caption <> '' then
    Canvas.DrawTextCentered(X + textOffsetX, Y + textOffsetY, W, H, Caption, Font, textR, textG, textB);
end;

procedure TFtThemeDefault.DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
  State: TFtButtonState; Checked: Boolean; const Caption: string; Font: TFtFont;
  CustomRadius: Double; CustomShadow: Integer);
var
  trackW, trackH: Integer;
  rad: Double;
  hasShadow: Boolean;
  pad: Double;
  thumbD: Double;
  thumbX, thumbY: Double;
  labelX, labelY: Double;
  trackR, trackG, trackB: Double;
  borderR, borderG, borderB: Double;
  thumbR, thumbG, thumbB: Double;
  thumbBorderR, thumbBorderG, thumbBorderB: Double;
  textR, textG, textB: Double;
  sRed, sGreen, sBlue, shOffY, shBlur, shOpac: Double;
  actualFont: TFtFont;
begin
  if (Caption <> '') and (W >= Round(H * 2.2)) then
  begin
    trackH := H;
    trackW := Round(H * 1.85);
    if trackW < 36 then trackW := 36;
    labelX := X + trackW + 10;
  end
  else
  begin
    trackH := H;
    trackW := W;
    labelX := 0;
  end;

  rad := trackH / 2.0;
  if (CustomRadius >= 0.0) and (CustomRadius < rad) then
    rad := CustomRadius;

  hasShadow := FEnableShadow;
  if CustomShadow = 0 then hasShadow := False
  else if CustomShadow > 0 then hasShadow := True;

  pad := 3.0;
  if trackH < 22 then pad := 2.0;
  thumbD := trackH - pad * 2.0;
  if thumbD < 4.0 then thumbD := 4.0;
  thumbY := Y + pad;

  if Checked then
    thumbX := X + trackW - pad - thumbD
  else
    thumbX := X + pad;

  sRed := 0.0; sGreen := 0.0; sBlue := 0.0;
  shOffY := FShadowOffsetY;
  shBlur := FShadowBlur;
  shOpac := FShadowOpacity;

  if DarkMode then
  begin
    textR := 0.935; textG := 0.942; textB := 0.950;
    if Checked then
    begin
      trackR := 0.24; trackG := 0.60; trackB := 0.92; // Breeze Blue
      borderR := 0.18; borderG := 0.52; borderB := 0.84;
      thumbR := 1.00; thumbG := 1.00; thumbB := 1.00;
      thumbBorderR := 0.90; thumbBorderG := 0.95; thumbBorderB := 1.00;
      // Blue glow shadow
      sRed := 0.24; sGreen := 0.60; sBlue := 0.92;
      shOpac := 0.35;
    end
    else
    begin
      trackR := 0.18; trackG := 0.20; trackB := 0.22;
      if State = bsHovered then
      begin
        borderR := 0.24; borderG := 0.60; borderB := 0.92;
      end
      else
      begin
        borderR := 0.32; borderG := 0.35; borderB := 0.38;
      end;
      thumbR := 0.92; thumbG := 0.94; thumbB := 0.96;
      thumbBorderR := 0.70; thumbBorderG := 0.72; thumbBorderB := 0.75;
    end;
  end
  else
  begin
    textR := 0.12; textG := 0.14; textB := 0.16;
    if Checked then
    begin
      trackR := 0.24; trackG := 0.60; trackB := 0.92; // Breeze Blue
      borderR := 0.18; borderG := 0.52; borderB := 0.84;
      thumbR := 1.00; thumbG := 1.00; thumbB := 1.00;
      thumbBorderR := 0.92; thumbBorderG := 0.96; thumbBorderB := 1.00;
      // Soft blue glow
      sRed := 0.24; sGreen := 0.60; sBlue := 0.92;
      shOpac := 0.28;
    end
    else
    begin
      trackR := 0.86; trackG := 0.88; trackB := 0.90;
      if State = bsHovered then
      begin
        borderR := 0.24; borderG := 0.60; borderB := 0.92;
      end
      else
      begin
        borderR := 0.70; borderG := 0.73; borderB := 0.76;
      end;
      thumbR := 1.00; thumbG := 1.00; thumbB := 1.00;
      thumbBorderR := 0.78; thumbBorderG := 0.80; thumbBorderB := 0.83;
    end;
  end;

  if State = bsHovered then
  begin
    if Checked then
    begin
      trackR := 0.30; trackG := 0.66; trackB := 0.98;
    end;
  end
  else if State = bsPressed then
  begin
    if Checked then
    begin
      trackR := 0.18; trackG := 0.52; trackB := 0.84;
    end;
  end;

  // 1. Soft track shadow / glow
  if hasShadow then
    Canvas.DrawShadow(X, Y, trackW, trackH, rad, 0.0, shOffY, shBlur, sRed, sGreen, sBlue, shOpac);

  // 2. Track Plate
  Canvas.DrawRoundedRect(X + 0.5, Y + 0.5, trackW - 1.0, trackH - 1.0, rad, trackR, trackG, trackB);

  // 3. Track Border Outline
  Canvas.DrawRoundedRectOutline(X, Y, trackW, trackH, rad, 1.0, borderR, borderG, borderB);

  // 4. Thumb Elevation Shadow
  if hasShadow then
    Canvas.DrawShadow(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 0.0, 1.5, 2.5, 0.0, 0.0, 0.0, 0.30);

  // 5. Thumb Plate
  Canvas.DrawRoundedRect(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, thumbR, thumbG, thumbB);

  // 6. Thumb Border
  Canvas.DrawRoundedRectOutline(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 0.8, thumbBorderR, thumbBorderG, thumbBorderB);

  // 7. Caption Text
  if (Caption <> '') and (labelX > X) then
  begin
    if not Assigned(Font) then
      actualFont := FtGetSystemFont()
    else
      actualFont := Font;
    labelY := Y + (H / 2.0) + (actualFont.Ascent - actualFont.Descent) / 2.0;
    Canvas.DrawText(labelX, labelY, Caption, actualFont, textR, textG, textB);
  end;
end;

{ TFtFileTheme }

constructor TFtFileTheme.CreateFromFile(const APath: string);
begin
  FFilePath := APath;
  FName := ChangeFileExt(ExtractFileName(APath), '');
  FDarkMode := False;
  FAuthor := 'Community';
  FDescription := '';
  FStyleType := 'modern';
  FHasDarkSection := False;

  LoadFromFile(APath);
  inherited Create(FName);
end;

destructor TFtFileTheme.Destroy();
begin
  inherited Destroy();
end;

procedure ReadPalette(Ini: TIniFile; const Section: string; var Pal: TFtThemePalette; IsDark: Boolean);
var
  defPlate, defBorder, defText: TFtRgbColor;
  defHovPlate, defHovBorder: TFtRgbColor;
  defPressPlate: TFtRgbColor;
  defTop, defBot: TFtRgbColor;
begin
  if IsDark then
  begin
    Pal.WindowBg := ReadColorFromIni(Ini, Section, 'window.bg', MakeRgbColor(0.15, 0.16, 0.18));
    defPlate   := MakeRgbColor(0.22, 0.24, 0.26);
    defBorder  := MakeRgbColor(0.35, 0.38, 0.42);
    defText    := MakeRgbColor(0.92, 0.93, 0.95);
    defHovPlate:= MakeRgbColor(0.28, 0.30, 0.33);
    defHovBorder:= MakeRgbColor(0.24, 0.60, 0.92);
    defPressPlate := MakeRgbColor(0.18, 0.19, 0.21);
  end
  else
  begin
    Pal.WindowBg := ReadColorFromIni(Ini, Section, 'window.bg', MakeRgbColor(0.94, 0.94, 0.95));
    defPlate   := MakeRgbColor(0.96, 0.96, 0.97);
    defBorder  := MakeRgbColor(0.75, 0.78, 0.82);
    defText    := MakeRgbColor(0.15, 0.17, 0.20);
    defHovPlate:= MakeRgbColor(1.00, 1.00, 1.00);
    defHovBorder:= MakeRgbColor(0.24, 0.60, 0.92);
    defPressPlate := MakeRgbColor(0.88, 0.90, 0.93);
  end;

  Pal.BtnNormPlate  := ReadColorFromIni(Ini, Section, 'button.normal.plate', defPlate);
  Pal.BtnNormBorder := ReadColorFromIni(Ini, Section, 'button.normal.border', defBorder);
  Pal.BtnNormText   := ReadColorFromIni(Ini, Section, 'button.normal.text', defText);

  defTop := Pal.BtnNormPlate;
  AdjustRgb(defTop, 1.15);
  defBot := Pal.BtnNormPlate;
  AdjustRgb(defBot, 0.85);
  Pal.BtnNormBevelTop := ReadColorFromIni(Ini, Section, 'button.normal.bevel.top', defTop);
  Pal.BtnNormBevelBot := ReadColorFromIni(Ini, Section, 'button.normal.bevel.bot', defBot);

  Pal.BtnHovPlate  := ReadColorFromIni(Ini, Section, 'button.hover.plate', defHovPlate);
  Pal.BtnHovBorder := ReadColorFromIni(Ini, Section, 'button.hover.border', defHovBorder);
  Pal.BtnHovText   := ReadColorFromIni(Ini, Section, 'button.hover.text', Pal.BtnNormText);

  defTop := Pal.BtnHovPlate;
  AdjustRgb(defTop, 1.15);
  defBot := Pal.BtnHovPlate;
  AdjustRgb(defBot, 0.85);
  Pal.BtnHovBevelTop := ReadColorFromIni(Ini, Section, 'button.hover.bevel.top', defTop);
  Pal.BtnHovBevelBot := ReadColorFromIni(Ini, Section, 'button.hover.bevel.bot', defBot);

  Pal.BtnPressPlate  := ReadColorFromIni(Ini, Section, 'button.pressed.plate', defPressPlate);
  Pal.BtnPressBorder := ReadColorFromIni(Ini, Section, 'button.pressed.border', Pal.BtnHovBorder);
  Pal.BtnPressText   := ReadColorFromIni(Ini, Section, 'button.pressed.text', Pal.BtnNormText);

  defTop := Pal.BtnPressPlate;
  AdjustRgb(defTop, 0.80);
  defBot := Pal.BtnPressPlate;
  AdjustRgb(defBot, 1.20);
  Pal.BtnPressBevelTop := ReadColorFromIni(Ini, Section, 'button.pressed.bevel.top', defTop);
  Pal.BtnPressBevelBot := ReadColorFromIni(Ini, Section, 'button.pressed.bevel.bot', defBot);

  Pal.BtnTogPlate     := ReadColorFromIni(Ini, Section, 'button.toggled.plate', Pal.BtnPressPlate);
  Pal.BtnTogBorder    := ReadColorFromIni(Ini, Section, 'button.toggled.border', Pal.BtnHovBorder);
  Pal.BtnTogText      := ReadColorFromIni(Ini, Section, 'button.toggled.text', Pal.BtnNormText);
  Pal.BtnTogIndicator := ReadColorFromIni(Ini, Section, 'button.toggled.indicator', Pal.BtnHovBorder);
  Pal.BtnTogBevelTop  := ReadColorFromIni(Ini, Section, 'button.toggled.bevel.top', Pal.BtnPressBevelTop);
  Pal.BtnTogBevelBot  := ReadColorFromIni(Ini, Section, 'button.toggled.bevel.bot', Pal.BtnPressBevelBot);
end;

procedure TFtFileTheme.LoadFromFile(const APath: string);
var
  ini: TIniFile;
  lightSection: string;
begin
  ini := TIniFile.Create(APath);
  try
    FName := Trim(ini.ReadString('Theme', 'Name', FName));
    FAuthor := Trim(ini.ReadString('Theme', 'Author', 'Community'));
    FDescription := Trim(ini.ReadString('Theme', 'Description', ''));
    FStyleType := LowerCase(Trim(ini.ReadString('Theme', 'Style', 'modern')));

    // Rounded Corners & Shadow parameters from [Theme] section
    FCornerRadius := ini.ReadFloat('Theme', 'CornerRadius', 5.0);
    FEnableShadow := ini.ReadBool('Theme', 'Shadow', True);
    FShadowOffsetY := ini.ReadFloat('Theme', 'ShadowOffsetY', 2.0);
    FShadowBlur := ini.ReadFloat('Theme', 'ShadowBlur', 4.0);
    FShadowOpacity := ini.ReadFloat('Theme', 'ShadowOpacity', 0.16);

    if ini.SectionExists('Light') then
      lightSection := 'Light'
    else if ini.SectionExists('Colors') then
      lightSection := 'Colors'
    else if ini.SectionExists('Palette') then
      lightSection := 'Palette'
    else
      lightSection := 'Light';

    ReadPalette(ini, lightSection, FLightPalette, False);

    if ini.SectionExists('Dark') then
    begin
      FHasDarkSection := True;
      ReadPalette(ini, 'Dark', FDarkPalette, True);
    end
    else
    begin
      FHasDarkSection := False;
      FDarkPalette := FLightPalette;
    end;
  finally
    ini.Free();
  end;
end;

function TFtFileTheme.HasDarkMode(): Boolean;
begin
  Result := FHasDarkSection;
end;

function TFtFileTheme.GetActivePalette(): TFtThemePalette;
begin
  if FDarkMode and FHasDarkSection then
    Result := FDarkPalette
  else
    Result := FLightPalette;
end;

function TFtFileTheme.GetAccentColor(): TFtRgbColor;
begin
  Result := GetActivePalette().BtnTogIndicator;
end;

function TFtFileTheme.GetTextColor(): TFtRgbColor;
begin
  Result := GetActivePalette().BtnNormText;
end;

function TFtFileTheme.GetInputBackground(): TFtRgbColor;
var
  pal: TFtThemePalette;
begin
  pal := GetActivePalette();
  if DarkMode then
  begin
    Result := pal.WindowBg;
    AdjustRgb(Result, 0.82);
  end
  else
    Result := MakeRgbColor(1.0, 1.0, 1.0);
end;

function TFtFileTheme.GetInputBorder(): TFtRgbColor;
begin
  Result := GetActivePalette().BtnNormBorder;
 end;

function TFtFileTheme.GetScrollBarTrackColor(): TFtRgbColor;
begin
  Result := GetActivePalette().WindowBg;
end;

function TFtFileTheme.GetScrollBarThumbColor(): TFtRgbColor;
begin
  Result := GetActivePalette().BtnNormBorder;
end;

function TFtFileTheme.GetMenuBackground(): TFtRgbColor;
var
  pal: TFtThemePalette;
begin
  pal := GetActivePalette();
  Result := pal.WindowBg;
  if DarkMode then
    AdjustRgb(Result, 1.08)
  else
    AdjustRgb(Result, 1.02);
end;

function TFtFileTheme.GetMenuBorder(): TFtRgbColor;
var
  pal: TFtThemePalette;
begin
  pal := GetActivePalette();
  Result := pal.BtnNormBorder;
end;

procedure TFtFileTheme.DrawWindowBackground(Canvas: TFtCanvasAgg; W, H: Integer);
var
  pal: TFtThemePalette;
begin
  pal := GetActivePalette();
  Canvas.Clear(pal.WindowBg.R, pal.WindowBg.G, pal.WindowBg.B);
end;

procedure TFtFileTheme.DrawButtonEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
  State: TFtButtonState; Toggled: Boolean; const Caption: string; Font: TFtFont;
  CustomRadius: Double; CustomShadow: Integer);
var
  pal: TFtThemePalette;
  plate, border, text: TFtRgbColor;
  textOffsetX, textOffsetY: Integer;
  is3d: Boolean;
  rad: Double;
  hasShadow: Boolean;
  sRed, sGreen, sBlue, shOffY, shBlur, shOpac: Double;
begin
  pal := GetActivePalette();
  textOffsetX := 0;
  textOffsetY := 0;
  is3d := (FStyleType = 'bevel') or (FStyleType = '3d');

  rad := FCornerRadius;
  if CustomRadius >= 0.0 then rad := CustomRadius;

  hasShadow := FEnableShadow;
  if CustomShadow = 0 then hasShadow := False
  else if CustomShadow > 0 then hasShadow := True;

  sRed := 0.0; sGreen := 0.0; sBlue := 0.0;

  if Toggled then
  begin
    plate   := pal.BtnTogPlate;
    border  := pal.BtnTogBorder;
    text    := pal.BtnTogText;
    if is3d then
    begin
      textOffsetX := 1;
      textOffsetY := 1;
    end;
  end
  else
  begin
    case State of
      bsPressed:
      begin
        plate   := pal.BtnPressPlate;
        border  := pal.BtnPressBorder;
        text    := pal.BtnPressText;
        textOffsetY := 1;
        if is3d then
          textOffsetX := 1;
      end;
      bsHovered:
      begin
        plate   := pal.BtnHovPlate;
        border  := pal.BtnHovBorder;
        text    := pal.BtnHovText;
        // Accent-tinted glow on hover!
        sRed := pal.BtnHovBorder.R;
        sGreen := pal.BtnHovBorder.G;
        sBlue := pal.BtnHovBorder.B;
      end;
      else // bsNormal
      begin
        plate   := pal.BtnNormPlate;
        border  := pal.BtnNormBorder;
        text    := pal.BtnNormText;
      end;
    end;
  end;

  // 1. Drop Shadow
  if hasShadow and not Toggled then
  begin
    if State = bsPressed then
    begin
      shOffY := 0.5;
      shBlur := 1.5;
      shOpac := 0.10;
    end
    else if State = bsHovered then
    begin
      shOffY := FShadowOffsetY + 0.5;
      shBlur := FShadowBlur + 2.0;
      shOpac := FShadowOpacity + 0.10;
    end
    else
    begin
      shOffY := FShadowOffsetY;
      shBlur := FShadowBlur;
      shOpac := FShadowOpacity;
    end;
    Canvas.DrawShadow(X, Y, W, H, rad, 0.0, shOffY, shBlur, sRed, sGreen, sBlue, shOpac);
  end;

  // 2. Rounded Button Plate Fill
  Canvas.DrawRoundedRect(X + 0.5, Y + 0.5, W - 1.0, H - 1.0, rad, plate.R, plate.G, plate.B);

  // 3. Rounded Border (1px)
  Canvas.DrawRoundedRectOutline(X, Y, W, H, rad, 1.0, border.R, border.G, border.B);

  // 4. Caption
  if Caption <> '' then
    Canvas.DrawTextCentered(X + textOffsetX, Y + textOffsetY, W, H, Caption, Font, text.R, text.G, text.B);
end;

procedure TFtFileTheme.DrawSwitchEx(Canvas: TFtCanvasAgg; X, Y, W, H: Integer; 
  State: TFtButtonState; Checked: Boolean; const Caption: string; Font: TFtFont;
  CustomRadius: Double; CustomShadow: Integer);
var
  pal: TFtThemePalette;
  trackW, trackH: Integer;
  rad: Double;
  hasShadow: Boolean;
  pad: Double;
  thumbD: Double;
  thumbX, thumbY: Double;
  labelX, labelY: Double;
  track, border, thumb, thumbBorder, text: TFtRgbColor;
  sRed, sGreen, sBlue, shOffY, shBlur, shOpac: Double;
  actualFont: TFtFont;
begin
  pal := GetActivePalette();

  if (Caption <> '') and (W >= Round(H * 2.2)) then
  begin
    trackH := H;
    trackW := Round(H * 1.85);
    if trackW < 36 then trackW := 36;
    labelX := X + trackW + 10;
  end
  else
  begin
    trackH := H;
    trackW := W;
    labelX := 0;
  end;

  rad := trackH / 2.0;
  if (CustomRadius >= 0.0) and (CustomRadius < rad) then
    rad := CustomRadius;

  hasShadow := FEnableShadow;
  if CustomShadow = 0 then hasShadow := False
  else if CustomShadow > 0 then hasShadow := True;

  pad := 3.0;
  if trackH < 22 then pad := 2.0;
  thumbD := trackH - pad * 2.0;
  if thumbD < 4.0 then thumbD := 4.0;
  thumbY := Y + pad;

  if Checked then
    thumbX := X + trackW - pad - thumbD
  else
    thumbX := X + pad;

  text := pal.BtnNormText;
  sRed := 0.0; sGreen := 0.0; sBlue := 0.0;
  shOffY := FShadowOffsetY;
  shBlur := FShadowBlur;
  shOpac := FShadowOpacity;

  if Checked then
  begin
    track := pal.BtnTogIndicator; // Theme accent color (e.g. Nord #88C0D0, Dracula #BD93F9, Gruvbox #FE8019)
    border := pal.BtnTogBorder;
    thumb := MakeRgbColor(1.0, 1.0, 1.0); // Crisp pure white knob
    thumbBorder := pal.BtnTogBorder;
    // Accent glow shadow if enabled
    sRed := track.R; sGreen := track.G; sBlue := track.B;
    shOpac := 0.30;
  end
  else
  begin
    track := pal.BtnNormBorder;
    border := pal.BtnPressBorder;
    if DarkMode then
    begin
      thumb := pal.BtnNormText; // Light foreground knob in dark mode
      thumbBorder := pal.BtnNormBorder;
    end
    else
    begin
      thumb := MakeRgbColor(1.0, 1.0, 1.0); // Clean white knob in light mode
      thumbBorder := pal.BtnNormBorder;
    end;
  end;

  if State = bsHovered then
  begin
    AdjustRgb(thumb, 1.08);
  end;

  // 1. Drop shadow under switch track
  if hasShadow then
    Canvas.DrawShadow(X, Y, trackW, trackH, rad, 0.0, shOffY, shBlur, sRed, sGreen, sBlue, shOpac);

  // 2. Track Plate
  Canvas.DrawRoundedRect(X + 0.5, Y + 0.5, trackW - 1.0, trackH - 1.0, rad, track.R, track.G, track.B);

  // 3. Track Border Outline
  Canvas.DrawRoundedRectOutline(X, Y, trackW, trackH, rad, 1.0, border.R, border.G, border.B);

  // 4. Thumb Elevation Shadow
  if hasShadow then
    Canvas.DrawShadow(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 0.0, 1.5, 2.5, 0.0, 0.0, 0.0, 0.30);

  // 5. Thumb Plate
  Canvas.DrawRoundedRect(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, thumb.R, thumb.G, thumb.B);

  // 6. Thumb Border
  Canvas.DrawRoundedRectOutline(thumbX, thumbY, thumbD, thumbD, thumbD / 2.0, 0.8, thumbBorder.R, thumbBorder.G, thumbBorder.B);

  // 7. Caption Text
  if (Caption <> '') and (labelX > X) then
  begin
    if not Assigned(Font) then
      actualFont := FtGetSystemFont()
    else
      actualFont := Font;
    labelY := Y + (H / 2.0) + (actualFont.Ascent - actualFont.Descent) / 2.0;
    Canvas.DrawText(labelX, labelY, Caption, actualFont, text.R, text.G, text.B);
  end;
end;

{ TFtThemeManager }

constructor TFtThemeManager.Create();
var
  initThemeName: string;
begin
  inherited Create();
  FThemes := TFPList.Create();
  FOnThemeChange := nil;

  FDarkMode := DetectDarkMode();

  RegisterTheme(TFtThemeDefault.Create('default'));

  ScanThemeDirectories();

  SetDarkMode(FDarkMode);

  initThemeName := DetectThemeName();
  if not SetTheme(initThemeName) then
    SetTheme('default');
end;

destructor TFtThemeManager.Destroy();
var
  i: Integer;
begin
  for i := 0 to FThemes.Count - 1 do
    TFtTheme(FThemes[i]).Free();
  FThemes.Free();
  inherited Destroy();
end;

function TFtThemeManager.DetectDarkMode(): Boolean;
var
  val: string;
  cfgPath: string;
  lines: TStringList;
begin
  Result := False;

  val := LowerCase(Trim(GetEnvironmentVariable('FT_DARK_MODE')));
  if (val = '1') or (val = 'true') or (val = 'yes') or (val = 'dark') then
    Exit(True);
  if (val = '0') or (val = 'false') or (val = 'no') or (val = 'light') then
    Exit(False);

  cfgPath := GetEnvironmentVariable('HOME') + '/.config/floria/dark_mode';
  if FileExists(cfgPath) then
  begin
    lines := TStringList.Create();
    try
      lines.LoadFromFile(cfgPath);
      if lines.Count > 0 then
      begin
        val := LowerCase(Trim(lines[0]));
        if (val = '1') or (val = 'true') or (val = 'yes') or (val = 'dark') then
          Exit(True);
        if (val = '0') or (val = 'false') or (val = 'no') or (val = 'light') then
          Exit(False);
      end;
    finally
      lines.Free();
    end;
  end;

  val := LowerCase(GetEnvironmentVariable('GTK_THEME'));
  if Pos('dark', val) > 0 then
    Exit(True);

  Result := False;
end;

function TFtThemeManager.DetectThemeName(): string;
var
  val: string;
  cfgPath: string;
  lines: TStringList;
begin
  Result := '';

  val := GetEnvironmentVariable('FT_THEME');
  if val <> '' then
    Exit(LowerCase(Trim(val)));

  cfgPath := GetEnvironmentVariable('HOME') + '/.config/floria/theme';
  if FileExists(cfgPath) then
  begin
    lines := TStringList.Create();
    try
      lines.LoadFromFile(cfgPath);
      if lines.Count > 0 then
      begin
        val := LowerCase(Trim(lines[0]));
        if val <> '' then
          Exit(val);
      end;
    finally
      lines.Free();
    end;
  end;

  Result := 'default';
end;

procedure TFtThemeManager.RegisterTheme(ATheme: TFtTheme);
begin
  if Assigned(ATheme) and (FindTheme(ATheme.Name) = nil) then
  begin
    ATheme.DarkMode := FDarkMode;
    FThemes.Add(ATheme);
  end;
end;

function TFtThemeManager.FindTheme(const AName: string): TFtTheme;
var
  i: Integer;
  T: TFtTheme;
begin
  Result := nil;
  for i := 0 to FThemes.Count - 1 do
  begin
    T := TFtTheme(FThemes[i]);
    if SameText(T.Name, AName) then
      Exit(T);
  end;
  if SameText(AName, 'qt6') then
    Exit(FindTheme('default'));
end;

function TFtThemeManager.SetTheme(const AName: string): Boolean;
var
  T: TFtTheme;
begin
  Result := False;
  T := FindTheme(AName);

  if (T = nil) and (FileExists(AName) or (Pos('.theme', LowerCase(AName)) > 0)) then
  begin
    if LoadThemeFile(AName) then
      T := FindTheme(ChangeFileExt(ExtractFileName(AName), ''));
  end;

  if Assigned(T) then
  begin
    FCurrentTheme := T;
    T.DarkMode := FDarkMode;
    Result := True;
    if Assigned(FOnThemeChange) then
      FOnThemeChange();
  end;
end;

function TFtThemeManager.GetCurrentTheme(): TFtTheme;
begin
  Result := FCurrentTheme;
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
    if i > 0 then Result := Result + ',';
    Result := Result + TFtTheme(FThemes[i]).Name;
  end;
end;

function TFtThemeManager.GetDarkMode(): Boolean;
begin
  Result := FDarkMode;
end;

procedure TFtThemeManager.SetDarkMode(AValue: Boolean);
var
  i: Integer;
begin
  FDarkMode := AValue;
  for i := 0 to FThemes.Count - 1 do
    TFtTheme(FThemes[i]).DarkMode := FDarkMode;

  if Assigned(FOnThemeChange) then
    FOnThemeChange();
end;

function TFtThemeManager.HasDarkMode(const AName: string): Boolean;
var
  T: TFtTheme;
begin
  Result := False;
  T := FindTheme(AName);
  if Assigned(T) then
    Result := T.HasDarkMode();
end;

function TFtThemeManager.GetCornerRadius(): Double;
begin
  if Assigned(FCurrentTheme) then
    Result := FCurrentTheme.CornerRadius
  else
    Result := 4.0;
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

function TFtThemeManager.LoadThemeFile(const AFilePath: string): Boolean;
var
  T: TFtFileTheme;
begin
  Result := False;
  if not FileExists(AFilePath) then Exit;
  try
    T := TFtFileTheme.CreateFromFile(AFilePath);
    if Assigned(T) then
    begin
      T.DarkMode := FDarkMode;
      RegisterTheme(T);
      Result := True;
    end;
  except
    Result := False;
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

  if FindFirst(cleanDir + '/*.theme', faAnyFile, sr) = 0 then
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
  homeDir: string;
  customPath: string;
  dirItem: string;
  posDelim: Integer;
begin
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
  LoadThemeDir('themes');
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
