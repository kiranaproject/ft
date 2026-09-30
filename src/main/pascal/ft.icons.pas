unit Ft.Icons;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  Floria.Image.Core, Floria.SVG.DOM, Floria.SVG.Parser, Floria.SVG.Rasterizer;

{ ────────────────────────── Default SVG Icon Constants ────────────────────────── }

const
  { Navigation Icons }
  FT_ICON_NAV_BACK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 10 3 L 5 8 L 10 13" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_NAV_FORWARD =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 6 3 L 11 8 L 6 13" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_NAV_UP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 10 L 8 5 L 13 10" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_NEW_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1.5 3.5 C 1.5 2.7 2.2 2 3 2 L 6 2 L 7.5 3.5 L 13 3.5 C 13.8 3.5 14.5 4.2 14.5 5 L 14.5 12.5 C 14.5 13.3 13.8 14 13 14 L 3 14 C 2.2 14 1.5 13.3 1.5 12.5 Z" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linejoin="round"/>' +
    '<path d="M 8 6.5 L 8 11.5 M 5.5 9 L 10.5 9" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_HIDDEN =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 8 C 3 4 5.5 2.5 8 2.5 C 10.5 2.5 13 4 15 8 C 13 12 10.5 13.5 8 13.5 C 5.5 13.5 3 12 1 8 Z" fill="none" stroke="#64748b" stroke-width="1.5"/>' +
    '<circle cx="8" cy="8" r="2.5" fill="#64748b"/>' +
    '</svg>';

  { File & Directory Items }
  FT_ICON_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 3.5 C 1 2.7 1.7 2 2.5 2 L 6 2 L 7.5 3.5 L 13.5 3.5 C 14.3 3.5 15 4.2 15 5 L 15 12.5 C 15 13.3 14.3 14 13.5 14 L 2.5 14 C 1.7 14 1 13.3 1 12.5 Z" fill="#eab308"/>' +
    '</svg>';

  FT_ICON_FILE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#94a3b8"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#cbd5e1"/>' +
    '</svg>';

  FT_ICON_FILE_IMAGE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#38bdf8"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#bae6fd"/>' +
    '<circle cx="5.5" cy="6.5" r="1.2" fill="#ffffff"/>' +
    '<path d="M 4 12 L 6.5 8.5 L 8.5 10.5 L 10.5 7.5 L 12 12 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_FILE_CODE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#6366f1"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#c7d2fe"/>' +
    '<path d="M 6 8 L 4.5 9.5 L 6 11 M 10 8 L 11.5 9.5 L 10 11" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round" fill="none"/>' +
    '</svg>';

  FT_ICON_FILE_ARCHIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#f97316"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#fed7aa"/>' +
    '<rect x="7" y="6" width="2" height="1" fill="#ffffff"/>' +
    '<rect x="7" y="8" width="2" height="1" fill="#ffffff"/>' +
    '<rect x="6.5" y="10" width="3" height="3" rx="0.5" fill="#ffffff"/>' +
    '</svg>';

  { Places Icons }
  FT_ICON_PLACE_HOME =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2 7 L 8 2 L 14 7 L 14 13.5 C 14 13.8 13.8 14 13.5 14 L 9.5 14 L 9.5 9.5 L 6.5 9.5 L 6.5 14 L 2.5 14 C 2.2 14 2 13.8 2 13.5 Z" fill="#3b82f6"/>' +
    '</svg>';

  FT_ICON_PLACE_DESKTOP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="9" rx="1" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5 14 L 11 14 M 8 11 L 8 14" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_PLACE_DOCUMENTS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#0ea5e9"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#bae6fd"/>' +
    '<path d="M 5.5 7 L 10.5 7 M 5.5 9.5 L 10.5 9.5 M 5.5 12 L 9 12" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_PLACE_DOWNLOADS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="7" fill="#10b981"/>' +
    '<path d="M 8 4 L 8 10.5 M 5.5 8.5 L 8 11 L 10.5 8.5" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_PLACE_PICTURES =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="11" rx="1.5" fill="#8b5cf6"/>' +
    '<circle cx="5" cy="5.5" r="1.2" fill="#ffffff"/>' +
    '<path d="M 3 11 L 6.5 7 L 9 9.5 L 11 7.5 L 13 10 L 13 12 C 13 12.5 12.5 13 12 13 L 4 13 C 3.5 13 3 12.5 3 12 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_PLACE_MUSIC =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="7" fill="#ec4899"/>' +
    '<path d="M 6 10 C 6 10.8 5.3 11.5 4.5 11.5 C 3.7 11.5 3 10.8 3 10 C 3 9.2 3.7 8.5 4.5 8.5 C 4.8 8.5 5 8.6 5.2 8.7 L 5.2 4.5 L 11 3.5 L 11 8 C 11 8.8 10.3 9.5 9.5 9.5 C 8.7 9.5 8 8.8 8 8 C 8 7.2 8.7 6.5 9.5 6.5 C 9.8 6.5 10 6.6 10.2 6.7 L 10.2 4.5 L 6 5.2 Z" fill="#ffffff"/>' +
    '</svg>';

  FT_ICON_PLACE_DRIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="4" width="13" height="8" rx="1.5" fill="#64748b"/>' +
    '<circle cx="11.5" cy="8" r="1" fill="#22c55e"/>' +
    '<path d="M 3.5 8 L 8.5 8" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  { Outline Icons (macOS Style) }
  FT_ICON_OUTLINE_HOME =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2 7.5 L 8 2.5 L 14 7.5" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>' +
    '<path d="M 3.5 7 L 3.5 13.5 C 3.5 13.8 3.7 14 4 14 L 12 14 C 12.3 14 12.5 13.8 12.5 13.5 L 12.5 7" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '<path d="M 6.5 14 L 6.5 10.5 C 6.5 10.2 6.7 10 7 10 L 9 10 C 9.3 10 9.5 10.2 9.5 10.5 L 9.5 14" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DESKTOP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="9.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5.5 14 L 10.5 14 M 8 11.5 L 8 14" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DOCUMENTS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3.5 1.5 L 9.5 1.5 L 13 5 L 13 14 C 13 14.3 12.8 14.5 12.5 14.5 L 3.5 14.5 C 3.2 14.5 3 14.3 3 14 L 3 2 C 3 1.7 3.2 1.5 3.5 1.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '<path d="M 9.5 1.5 L 9.5 5 L 13 5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linejoin="round"/>' +
    '<path d="M 5.5 8 L 10.5 8 M 5.5 10.5 L 9 10.5" stroke="#64748b" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DOWNLOADS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 8 4.5 L 8 10.5 M 5.5 8.5 L 8 11 L 10.5 8.5" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_PICTURES =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2.5" width="13" height="11" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="5" cy="6" r="1.2" fill="#64748b"/>' +
    '<path d="M 2.5 12 L 6.5 8 L 9 10.5 L 11 8.5 L 13.5 11" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_MUSIC =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="5" cy="11.5" r="2" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 7 11.5 L 7 4.5 C 7 4.5 9 4 12 3 L 12 8" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '<circle cx="10" cy="10" r="1.8" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 12 10 L 12 3" stroke="#64748b" stroke-width="1.4"/>' +
    '</svg>';

  FT_ICON_OUTLINE_DRIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="4.5" width="13" height="7.5" rx="1.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="11.5" cy="8.25" r="0.9" fill="#64748b"/>' +
    '<path d="M 3.5 8.25 L 9 8.25" stroke="#64748b" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1.5 3.5 C 1.5 2.7 2.2 2 3 2 L 6 2 L 7.5 3.5 L 13 3.5 C 13.8 3.5 14.5 4.2 14.5 5 L 14.5 12.5 C 14.5 13.3 13.8 14 13 14 L 3 14 C 2.2 14 1.5 13.3 1.5 12.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_OUTLINE_FILE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="none" stroke="#64748b" stroke-width="1.4" stroke-linejoin="round"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5" fill="none" stroke="#64748b" stroke-width="1.3" stroke-linejoin="round"/>' +
    '</svg>';

  { General UI / Utility Icons }
  FT_ICON_GEAR =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 8 5.5 C 6.6 5.5 5.5 6.6 5.5 8 C 5.5 9.4 6.6 10.5 8 10.5 C 9.4 10.5 10.5 9.4 10.5 8 C 10.5 6.6 9.4 5.5 8 5.5 Z" fill="none" stroke="#64748b" stroke-width="1.3"/>' +
    '<path d="M 7.3 1.5 L 8.7 1.5 L 9 3 C 9.4 3.2 9.8 3.4 10.2 3.7 L 11.6 3.1 L 12.6 4.1 L 12 5.5 C 12.3 5.9 12.5 6.3 12.7 6.7 L 14.2 7 L 14.2 8.4 L 12.7 8.7 C 12.5 9.1 12.3 9.5 12 9.9 L 12.6 11.3 L 11.6 12.3 L 10.2 11.7 C 9.8 12 9.4 12.2 9 12.4 L 8.7 13.9 L 7.3 13.9 L 7 12.4 C 6.6 12.2 6.2 12 5.8 11.7 L 4.4 12.3 L 3.4 11.3 L 4 9.9 C 3.7 9.5 3.5 9.1 3.3 8.7 L 1.8 8.4 L 1.8 7 L 3.3 6.7 C 3.5 6.3 3.7 5.9 4 5.5 L 3.4 4.1 L 4.4 3.1 L 5.8 3.7 C 6.2 3.4 6.6 3.2 7 3 Z" fill="none" stroke="#64748b" stroke-width="1.2" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_INFO =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="6.5" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<circle cx="8" cy="5" r="0.9" fill="#64748b"/>' +
    '<path d="M 8 7.5 L 8 11.5" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_CHECK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3.5 8.5 L 6.5 11.5 L 12.5 4.5" fill="none" stroke="#22c55e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  FT_ICON_CLOSE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 4 4 L 12 12 M 12 4 L 4 12" fill="none" stroke="#64748b" stroke-width="1.8" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_SEARCH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="7" cy="7" r="4.5" fill="none" stroke="#64748b" stroke-width="1.5"/>' +
    '<path d="M 10.5 10.5 L 14 14" stroke="#64748b" stroke-width="1.8" stroke-linecap="round"/>' +
    '</svg>';

  FT_ICON_REFRESH =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 13.5 8 C 13.5 11 11 13.5 8 13.5 C 5 13.5 2.5 11 2.5 8 C 2.5 5 5 2.5 8 2.5 C 10.5 2.5 12.6 4.2 13.3 6.5" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round"/>' +
    '<path d="M 13.5 2.5 L 13.5 6.5 L 9.5 6.5" fill="none" stroke="#64748b" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

{ ── Extensible Icon Manager & Theming System ── }

type
  TFtIconItem = class
  public
    Name: string;
    SvgLight: string;
    SvgDark: string;
    constructor Create(const AName, ASvgLight, ASvgDark: string);
  end;

  TFtIconManager = class
  private
    FCurrentTheme: string;
    FIcons: TStringList;
    FMonochromeLightColor: string;
    FMonochromeDarkColor: string;
    procedure RegisterDefaults();
  public
    constructor Create();
    destructor Destroy(); override;

    { Retrieve SVG markup — automatically adapts monochrome strokes in dark mode }
    function GetIconSvg(const AName: string; ADarkMode: Boolean = False): string;

    { Render icon SVG directly to a TFloriaImage bitmap at requested dimensions }
    function GetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;

    { Register or override an icon for icon-theming support }
    procedure RegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');
    function HasIcon(const AName: string): Boolean;

    { Customize palette for monochrome outline icons }
    procedure SetMonochromeColors(const ALightColor, ADarkColor: string);
    property MonochromeLightColor: string read FMonochromeLightColor write FMonochromeLightColor;
    property MonochromeDarkColor: string read FMonochromeDarkColor write FMonochromeDarkColor;
    property CurrentTheme: string read FCurrentTheme write FCurrentTheme;
  end;

{ Global singleton and convenience helpers }
function FtIconManager(): TFtIconManager;
function FtGetIconSvg(const AName: string; ADarkMode: Boolean = False): string;
function FtGetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;
procedure FtRegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');

implementation

var
  GIconManager: TFtIconManager = nil;

{ TFtIconItem }

constructor TFtIconItem.Create(const AName, ASvgLight, ASvgDark: string);
begin
  inherited Create();
  Name := AName;
  SvgLight := ASvgLight;
  SvgDark := ASvgDark;
end;

{ TFtIconManager }

constructor TFtIconManager.Create();
begin
  inherited Create();
  FCurrentTheme := 'default';
  FIcons := TStringList.Create();
  FIcons.Sorted := True;
  FIcons.Duplicates := dupIgnore;
  FMonochromeLightColor := '#64748b';
  FMonochromeDarkColor  := '#cbd5e1';
  RegisterDefaults();
end;

destructor TFtIconManager.Destroy();
var
  i: Integer;
begin
  if Assigned(FIcons) then
  begin
    for i := 0 to FIcons.Count - 1 do
      FIcons.Objects[i].Free();
    FreeAndNil(FIcons);
  end;
  inherited Destroy();
end;

procedure TFtIconManager.RegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');
var
  lowerName: string;
  idx: Integer;
  item: TFtIconItem;
begin
  lowerName := LowerCase(Trim(AName));
  if lowerName = '' then Exit;

  idx := FIcons.IndexOf(lowerName);
  if idx >= 0 then
  begin
    item := TFtIconItem(FIcons.Objects[idx]);
    item.SvgLight := ASvgLight;
    if ASvgDark <> '' then
      item.SvgDark := ASvgDark;
  end
  else
  begin
    item := TFtIconItem.Create(lowerName, ASvgLight, ASvgDark);
    FIcons.AddObject(lowerName, item);
  end;
end;

function TFtIconManager.HasIcon(const AName: string): Boolean;
begin
  Result := FIcons.IndexOf(LowerCase(Trim(AName))) >= 0;
end;

procedure TFtIconManager.SetMonochromeColors(const ALightColor, ADarkColor: string);
begin
  if ALightColor <> '' then FMonochromeLightColor := ALightColor;
  if ADarkColor <> '' then FMonochromeDarkColor := ADarkColor;
end;

function TFtIconManager.GetIconSvg(const AName: string; ADarkMode: Boolean = False): string;
var
  lowerName: string;
  idx: Integer;
  item: TFtIconItem;
  svg: string;
begin
  Result := '';
  lowerName := LowerCase(Trim(AName));
  idx := FIcons.IndexOf(lowerName);
  if idx < 0 then Exit;

  item := TFtIconItem(FIcons.Objects[idx]);
  if ADarkMode then
  begin
    if item.SvgDark <> '' then
      Result := item.SvgDark
    else
    begin
      svg := item.SvgLight;
      // Dynamically replace default slate with lighter dark mode palette
      Result := StringReplace(svg, '#64748b', FMonochromeDarkColor, [rfReplaceAll, rfIgnoreCase]);
    end;
  end
  else
    Result := item.SvgLight;
end;

function TFtIconManager.GetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;
var
  svg: string;
  doc: TSVGDocument;
begin
  Result := nil;
  svg := GetIconSvg(AName, ADarkMode);
  if svg = '' then Exit;

  try
    doc := TSVGParser.ParseString(svg);
    if Assigned(doc) then
    begin
      try
        Result := TFloriaSVGRenderer.RenderToImage(doc, AW, AH);
      finally
        doc.Free();
      end;
    end;
  except
    Result := nil;
  end;
end;

procedure TFtIconManager.RegisterDefaults();
begin
  { Navigation }
  RegisterIcon('nav-back', FT_ICON_NAV_BACK);
  RegisterIcon('nav-forward', FT_ICON_NAV_FORWARD);
  RegisterIcon('nav-up', FT_ICON_NAV_UP);
  RegisterIcon('new-folder', FT_ICON_NEW_FOLDER);
  RegisterIcon('hidden', FT_ICON_HIDDEN);
  RegisterIcon('eye', FT_ICON_HIDDEN);

  { Files & Directories }
  RegisterIcon('folder', FT_ICON_FOLDER);
  RegisterIcon('file', FT_ICON_FILE);
  RegisterIcon('file-image', FT_ICON_FILE_IMAGE);
  RegisterIcon('file-code', FT_ICON_FILE_CODE);
  RegisterIcon('file-archive', FT_ICON_FILE_ARCHIVE);

  { Places }
  RegisterIcon('place-home', FT_ICON_PLACE_HOME);
  RegisterIcon('home', FT_ICON_PLACE_HOME);
  RegisterIcon('place-desktop', FT_ICON_PLACE_DESKTOP);
  RegisterIcon('desktop', FT_ICON_PLACE_DESKTOP);
  RegisterIcon('place-documents', FT_ICON_PLACE_DOCUMENTS);
  RegisterIcon('documents', FT_ICON_PLACE_DOCUMENTS);
  RegisterIcon('place-downloads', FT_ICON_PLACE_DOWNLOADS);
  RegisterIcon('downloads', FT_ICON_PLACE_DOWNLOADS);
  RegisterIcon('place-pictures', FT_ICON_PLACE_PICTURES);
  RegisterIcon('pictures', FT_ICON_PLACE_PICTURES);
  RegisterIcon('place-music', FT_ICON_PLACE_MUSIC);
  RegisterIcon('music', FT_ICON_PLACE_MUSIC);
  RegisterIcon('place-drive', FT_ICON_PLACE_DRIVE);
  RegisterIcon('drive', FT_ICON_PLACE_DRIVE);

  { Outline Icons (macOS Style) }
  RegisterIcon('outline-home', FT_ICON_OUTLINE_HOME);
  RegisterIcon('home-outline', FT_ICON_OUTLINE_HOME);
  RegisterIcon('place-home-outline', FT_ICON_OUTLINE_HOME);
  RegisterIcon('outline-desktop', FT_ICON_OUTLINE_DESKTOP);
  RegisterIcon('desktop-outline', FT_ICON_OUTLINE_DESKTOP);
  RegisterIcon('place-desktop-outline', FT_ICON_OUTLINE_DESKTOP);
  RegisterIcon('outline-documents', FT_ICON_OUTLINE_DOCUMENTS);
  RegisterIcon('documents-outline', FT_ICON_OUTLINE_DOCUMENTS);
  RegisterIcon('place-documents-outline', FT_ICON_OUTLINE_DOCUMENTS);
  RegisterIcon('outline-downloads', FT_ICON_OUTLINE_DOWNLOADS);
  RegisterIcon('downloads-outline', FT_ICON_OUTLINE_DOWNLOADS);
  RegisterIcon('place-downloads-outline', FT_ICON_OUTLINE_DOWNLOADS);
  RegisterIcon('outline-pictures', FT_ICON_OUTLINE_PICTURES);
  RegisterIcon('pictures-outline', FT_ICON_OUTLINE_PICTURES);
  RegisterIcon('place-pictures-outline', FT_ICON_OUTLINE_PICTURES);
  RegisterIcon('outline-music', FT_ICON_OUTLINE_MUSIC);
  RegisterIcon('music-outline', FT_ICON_OUTLINE_MUSIC);
  RegisterIcon('place-music-outline', FT_ICON_OUTLINE_MUSIC);
  RegisterIcon('outline-drive', FT_ICON_OUTLINE_DRIVE);
  RegisterIcon('drive-outline', FT_ICON_OUTLINE_DRIVE);
  RegisterIcon('place-drive-outline', FT_ICON_OUTLINE_DRIVE);
  RegisterIcon('outline-folder', FT_ICON_OUTLINE_FOLDER);
  RegisterIcon('folder-outline', FT_ICON_OUTLINE_FOLDER);
  RegisterIcon('outline-file', FT_ICON_OUTLINE_FILE);
  RegisterIcon('file-outline', FT_ICON_OUTLINE_FILE);

  { Utility Icons }
  RegisterIcon('gear', FT_ICON_GEAR);
  RegisterIcon('settings', FT_ICON_GEAR);
  RegisterIcon('info', FT_ICON_INFO);
  RegisterIcon('check', FT_ICON_CHECK);
  RegisterIcon('close', FT_ICON_CLOSE);
  RegisterIcon('search', FT_ICON_SEARCH);
  RegisterIcon('refresh', FT_ICON_REFRESH);
end;

{ Global Accessors }

function FtIconManager(): TFtIconManager;
begin
  if not Assigned(GIconManager) then
    GIconManager := TFtIconManager.Create();
  Result := GIconManager;
end;

function FtGetIconSvg(const AName: string; ADarkMode: Boolean = False): string;
begin
  Result := FtIconManager().GetIconSvg(AName, ADarkMode);
end;

function FtGetIconBitmap(const AName: string; AW: Integer = 16; AH: Integer = 16; ADarkMode: Boolean = False): TFloriaImage;
begin
  Result := FtIconManager().GetIconBitmap(AName, AW, AH, ADarkMode);
end;

procedure FtRegisterIcon(const AName, ASvgLight: string; const ASvgDark: string = '');
begin
  FtIconManager().RegisterIcon(AName, ASvgLight, ASvgDark);
end;

initialization

finalization
  if Assigned(GIconManager) then
    FreeAndNil(GIconManager);

end.
