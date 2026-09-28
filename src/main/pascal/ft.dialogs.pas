unit Ft.Dialogs;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Types,
  Floria.Image.Core, Floria.Canvas.Agg,
  Floria.SVG.DOM, Floria.SVG.Parser, Floria.SVG.Rasterizer,
  Ft.Widget, Ft.Widget.Buttons, Ft.Widget.Entries, Ft.Widget.Texts,
  Ft.Widget.Containers, Ft.Widget.Splitters, Ft.Widget.TreeViews,
  Ft.Widget.Tables, Ft.Widget.Selectors, Ft.Widget.PathBars,
  Ft.Window, Ft.Theme;

type
  TFtDialogType = (
    fdtOpenFile = 0,
    fdtSaveFile = 1,
    fdtSelectFolder = 2
  );

  { TFtFileDialog — main file picker window }
  TFtFileDialog = class
  private
    FWindow:          TFtWindow;
    FDialogType:      TFtDialogType;
    FCurrentDir:      string;
    FSelectedPath:    string;
    FFilter:          string;
    FDefaultName:     string;
    FShowHiddenFiles: Boolean;

    { Navigation header }
    FBtnBack:      TFtButton;
    FBtnForward:   TFtButton;
    FBtnUp:        TFtButton;
    FPathBar:      TFtPathBar;
    FBtnNewFolder: TFtButton;
    FBtnHidden:    TFtButton;

    { Content area }
    FSplitter:    TFtSplitter;
    FPlacesTree:  TFtTreeView;
    FFileTable:   TFtTable;

    { Bottom bar }
    FLabelName:   TFtLabel;
    FEntryName:   TFtEntry;
    FLabelType:   TFtLabel;
    FCmbFilter:   TFtComboBox;
    FBtnAction:   TFtButton;
    FBtnCancel:   TFtButton;

    { History }
    FHistory:   TStringList;
    FHistoryPos: Integer;

    { Deferred navigation — set inside table callbacks, processed in Execute loop }
    FPendingNavigate: string;

    { Cached icon bitmaps }
    FIconFolder:    TFloriaImage;
    FIconFile:      TFloriaImage;
    FIconImage:     TFloriaImage;
    FIconCode:      TFloriaImage;
    FIconArchive:   TFloriaImage;
    FIconHome:      TFloriaImage;
    FIconDesktop:   TFloriaImage;
    FIconDocuments: TFloriaImage;
    FIconDownloads: TFloriaImage;
    FIconPictures:  TFloriaImage;
    FIconMusic:     TFloriaImage;
    FIconDrive:     TFloriaImage;

    procedure InitIcons();
    procedure FreeIcons();
    function GetFileIcon(const AExt: string): TFloriaImage;

    procedure BuildUI();
    procedure PopulatePlaces();
    procedure RefreshList();
    procedure NavigateTo(const APath: string);
    procedure GoBack();
    procedure GoForward();
    procedure GoUp();
    procedure CommitSelection();
    procedure UpdateNavButtons();
    procedure UpdateLayout();
    procedure OnWindowResize(Sender: TObject; NewWidth, NewHeight: Integer);

    { Callbacks - static cdecl wrappers }
    class procedure CbBtnBack(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnForward(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnUp(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnNewFolder(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnHidden(Sender: Pointer; Toggled: cint32; UserData: Pointer); cdecl; static;
    class procedure CbPathBarNavigate(Sender: Pointer; const APath: PChar; UserData: Pointer); cdecl; static;
    class procedure CbPlaceSelect(Sender: Pointer; Node: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbFileSelect(Sender: Pointer; RowIndex: Integer; UserData: Pointer); cdecl; static;
    class procedure CbBtnAction(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnCancel(Sender: Pointer; UserData: Pointer); cdecl; static;
    procedure HandleColumnClick(Sender: TObject; ColumnIndex: Integer);
    procedure HandleFileDoubleClick(Sender: TObject; RowIndex: Integer);
  public
    constructor Create(ADialogType: TFtDialogType);
    destructor Destroy(); override;

    function Execute(): Boolean;

    property DialogType:      TFtDialogType read FDialogType write FDialogType;
    property Directory:       string read FCurrentDir write FCurrentDir;
    property DefaultName:     string read FDefaultName write FDefaultName;
    property Filter:          string read FFilter write FFilter;
    property ShowHiddenFiles: Boolean read FShowHiddenFiles write FShowHiddenFiles;
    property SelectedPath:    string read FSelectedPath;
  end;

  { Convenience subclasses }
  TFtOpenFileDialog = class(TFtFileDialog)
  public
    constructor Create();
  end;

  TFtSaveFileDialog = class(TFtFileDialog)
  public
    constructor Create();
  end;

  TFtSelectFolderDialog = class(TFtFileDialog)
  public
    constructor Create();
  end;

{ Convenience one-shot functions }
function FtDialogOpenFile(const ATitle: string; const ADir: string = '';
  const AFilter: string = ''): string;
function FtDialogSaveFile(const ATitle: string; const ADir: string = '';
  const ADefaultName: string = ''; const AFilter: string = ''): string;
function FtDialogSelectFolder(const ATitle: string; const ADir: string = ''): string;

implementation

{ ───────────────────────────── Helpers ───────────────────────────────────── }

const
  DIALOG_W = 860;
  DIALOG_H = 560;
  HEADER_H = 52;
  BOTTOM_H = 52;
  MARGIN_X = 14;
  PADDING  = 8;

type
  TFileEntry = record
    Name:    string;
    IsDir:   Boolean;
    Size:    Int64;
    ModTime: TDateTime;
  end;

function FormatFileSize(ABytes: Int64): string;
begin
  if ABytes < 1024 then
    Result := IntToStr(ABytes) + ' B'
  else if ABytes < 1024 * 1024 then
    Result := FormatFloat('0.#', ABytes / 1024.0) + ' KB'
  else if ABytes < 1024 * 1024 * 1024 then
    Result := FormatFloat('0.#', ABytes / (1024.0 * 1024.0)) + ' MB'
  else
    Result := FormatFloat('0.##', ABytes / (1024.0 * 1024.0 * 1024.0)) + ' GB';
end;

function FormatFileTime(ADate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn', ADate);
end;

{ ───────────────────────────── SVG Icons ────────────────────────────────── }

const
  SVG_NAV_BACK =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 10 3 L 5 8 L 10 13" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  SVG_NAV_FORWARD =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 6 3 L 11 8 L 6 13" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  SVG_NAV_UP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 10 L 8 5 L 13 10" fill="none" stroke="#64748b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  SVG_NEW_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 3.5 C 1 2.7 1.7 2 2.5 2 L 6 2 L 7.5 3.5 L 13.5 3.5 C 14.3 3.5 15 4.2 15 5 L 15 12.5 C 15 13.3 14.3 14 13.5 14 L 2.5 14 C 1.7 14 1 13.3 1 12.5 Z" fill="#eab308"/>' +
    '<path d="M 8 7 L 8 11 M 6 9 L 10 9" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round"/>' +
    '</svg>';

  SVG_HIDDEN =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 8 C 3 4 5.5 2.5 8 2.5 C 10.5 2.5 13 4 15 8 C 13 12 10.5 13.5 8 13.5 C 5.5 13.5 3 12 1 8 Z" fill="none" stroke="#64748b" stroke-width="1.5"/>' +
    '<circle cx="8" cy="8" r="2.5" fill="#64748b"/>' +
    '</svg>';

  SVG_FOLDER =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 1 3.5 C 1 2.7 1.7 2 2.5 2 L 6 2 L 7.5 3.5 L 13.5 3.5 C 14.3 3.5 15 4.2 15 5 L 15 12.5 C 15 13.3 14.3 14 13.5 14 L 2.5 14 C 1.7 14 1 13.3 1 12.5 Z" fill="#eab308"/>' +
    '</svg>';

  SVG_FILE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#94a3b8"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#cbd5e1"/>' +
    '</svg>';

  SVG_FILE_IMAGE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#38bdf8"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#bae6fd"/>' +
    '<circle cx="5.5" cy="6.5" r="1.2" fill="#ffffff"/>' +
    '<path d="M 4 12 L 6.5 8.5 L 8.5 10.5 L 10.5 7.5 L 12 12 Z" fill="#ffffff"/>' +
    '</svg>';

  SVG_FILE_CODE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#6366f1"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#c7d2fe"/>' +
    '<path d="M 6 8 L 4.5 9.5 L 6 11 M 10 8 L 11.5 9.5 L 10 11" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round" fill="none"/>' +
    '</svg>';

  SVG_FILE_ARCHIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#f97316"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#fed7aa"/>' +
    '<rect x="7" y="6" width="2" height="1" fill="#ffffff"/>' +
    '<rect x="7" y="8" width="2" height="1" fill="#ffffff"/>' +
    '<rect x="6.5" y="10" width="3" height="3" rx="0.5" fill="#ffffff"/>' +
    '</svg>';

  SVG_PLACE_HOME =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 2 7 L 8 2 L 14 7 L 14 13.5 C 14 13.8 13.8 14 13.5 14 L 9.5 14 L 9.5 9.5 L 6.5 9.5 L 6.5 14 L 2.5 14 C 2.2 14 2 13.8 2 13.5 Z" fill="#3b82f6"/>' +
    '</svg>';

  SVG_PLACE_DESKTOP =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="9" rx="1" fill="none" stroke="#64748b" stroke-width="1.4"/>' +
    '<path d="M 5 14 L 11 14 M 8 11 L 8 14" stroke="#64748b" stroke-width="1.4" stroke-linecap="round"/>' +
    '</svg>';

  SVG_PLACE_DOCS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<path d="M 3 1.5 C 3 1.2 3.2 1 3.5 1 L 9.5 1 L 13 4.5 L 13 14.5 C 13 14.8 12.8 15 12.5 15 L 3.5 15 C 3.2 15 3 14.8 3 14.5 Z" fill="#0ea5e9"/>' +
    '<path d="M 9.5 1 L 9.5 4.5 L 13 4.5 Z" fill="#bae6fd"/>' +
    '<path d="M 5.5 7 L 10.5 7 M 5.5 9.5 L 10.5 9.5 M 5.5 12 L 9 12" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

  SVG_PLACE_DOWNLOADS =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="7" fill="#10b981"/>' +
    '<path d="M 8 4 L 8 10.5 M 5.5 8.5 L 8 11 L 10.5 8.5" fill="none" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>' +
    '</svg>';

  SVG_PLACE_PICTURES =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="2" width="13" height="11" rx="1.5" fill="#8b5cf6"/>' +
    '<circle cx="5" cy="5.5" r="1.2" fill="#ffffff"/>' +
    '<path d="M 3 11 L 6.5 7 L 9 9.5 L 11 7.5 L 13 10 L 13 12 C 13 12.5 12.5 13 12 13 L 4 13 C 3.5 13 3 12.5 3 12 Z" fill="#ffffff"/>' +
    '</svg>';

  SVG_PLACE_MUSIC =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<circle cx="8" cy="8" r="7" fill="#ec4899"/>' +
    '<path d="M 6 10 C 6 10.8 5.3 11.5 4.5 11.5 C 3.7 11.5 3 10.8 3 10 C 3 9.2 3.7 8.5 4.5 8.5 C 4.8 8.5 5 8.6 5.2 8.7 L 5.2 4.5 L 11 3.5 L 11 8 C 11 8.8 10.3 9.5 9.5 9.5 C 8.7 9.5 8 8.8 8 8 C 8 7.2 8.7 6.5 9.5 6.5 C 9.8 6.5 10 6.6 10.2 6.7 L 10.2 4.5 L 6 5.2 Z" fill="#ffffff"/>' +
    '</svg>';

  SVG_PLACE_DRIVE =
    '<svg viewBox="0 0 16 16" width="16" height="16">' +
    '<rect x="1.5" y="4" width="13" height="8" rx="1.5" fill="#64748b"/>' +
    '<circle cx="11.5" cy="8" r="1" fill="#22c55e"/>' +
    '<path d="M 3.5 8 L 8.5 8" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>' +
    '</svg>';

function SvgToImage(const ASvg: string; AW, AH: Integer): TFloriaImage;
var
  doc: TSVGDocument;
begin
  Result := nil;
  if ASvg = '' then Exit;
  try
    doc := TSVGParser.ParseString(ASvg);
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

{ Sort comparison helpers for the file table }
var
  GTableSortCol: Integer = 0;
  GTableSortDesc: Boolean = False;

{ ─────────────────────── TFtFileDialog ─────────────────────────────────── }

procedure TFtFileDialog.InitIcons();
begin
  FIconFolder    := SvgToImage(SVG_FOLDER, 16, 16);
  FIconFile      := SvgToImage(SVG_FILE, 16, 16);
  FIconImage     := SvgToImage(SVG_FILE_IMAGE, 16, 16);
  FIconCode      := SvgToImage(SVG_FILE_CODE, 16, 16);
  FIconArchive   := SvgToImage(SVG_FILE_ARCHIVE, 16, 16);
  FIconHome      := SvgToImage(SVG_PLACE_HOME, 16, 16);
  FIconDesktop   := SvgToImage(SVG_PLACE_DESKTOP, 16, 16);
  FIconDocuments := SvgToImage(SVG_PLACE_DOCS, 16, 16);
  FIconDownloads := SvgToImage(SVG_PLACE_DOWNLOADS, 16, 16);
  FIconPictures  := SvgToImage(SVG_PLACE_PICTURES, 16, 16);
  FIconMusic     := SvgToImage(SVG_PLACE_MUSIC, 16, 16);
  FIconDrive     := SvgToImage(SVG_PLACE_DRIVE, 16, 16);
end;

procedure TFtFileDialog.FreeIcons();
begin
  if Assigned(FIconFolder) then FreeAndNil(FIconFolder);
  if Assigned(FIconFile) then FreeAndNil(FIconFile);
  if Assigned(FIconImage) then FreeAndNil(FIconImage);
  if Assigned(FIconCode) then FreeAndNil(FIconCode);
  if Assigned(FIconArchive) then FreeAndNil(FIconArchive);
  if Assigned(FIconHome) then FreeAndNil(FIconHome);
  if Assigned(FIconDesktop) then FreeAndNil(FIconDesktop);
  if Assigned(FIconDocuments) then FreeAndNil(FIconDocuments);
  if Assigned(FIconDownloads) then FreeAndNil(FIconDownloads);
  if Assigned(FIconPictures) then FreeAndNil(FIconPictures);
  if Assigned(FIconMusic) then FreeAndNil(FIconMusic);
  if Assigned(FIconDrive) then FreeAndNil(FIconDrive);
end;

function TFtFileDialog.GetFileIcon(const AExt: string): TFloriaImage;
begin
  if (AExt = 'png') or (AExt = 'jpg') or (AExt = 'jpeg') or (AExt = 'bmp') or
     (AExt = 'svg') or (AExt = 'gif') or (AExt = 'webp') or (AExt = 'ico') then
    Result := FIconImage
  else if (AExt = 'pas') or (AExt = 'pp') or (AExt = 'c') or (AExt = 'h') or
          (AExt = 'cpp') or (AExt = 'py') or (AExt = 'sh') or (AExt = 'bash') or
          (AExt = 'json') or (AExt = 'xml') or (AExt = 'html') or (AExt = 'css') or
          (AExt = 'md') or (AExt = 'js') or (AExt = 'ts') or (AExt = 'sql') then
    Result := FIconCode
  else if (AExt = 'zip') or (AExt = 'tar') or (AExt = 'gz') or (AExt = 'xz') or
          (AExt = '7z') or (AExt = 'bz2') or (AExt = 'rar') then
    Result := FIconArchive
  else
    Result := FIconFile;
end;

constructor TFtFileDialog.Create(ADialogType: TFtDialogType);
begin
  inherited Create();
  FDialogType := ADialogType;
  FCurrentDir := GetEnvironmentVariable('HOME');
  if FCurrentDir = '' then
    FCurrentDir := '/';
  FSelectedPath := '';
  FFilter := '';
  FDefaultName := '';
  FShowHiddenFiles := False;
  FHistory := TStringList.Create();
  FHistoryPos := -1;
  FPendingNavigate := '';
  InitIcons();
end;

destructor TFtFileDialog.Destroy();
begin
  FreeIcons();
  FHistory.Free();
  if Assigned(FWindow) then
    FreeAndNil(FWindow);
  inherited Destroy();
end;

procedure TFtFileDialog.BuildUI();
var
  title: string;
  actionCaption: string;
  splitterX: Integer;
begin
  case FDialogType of
    fdtOpenFile:     begin title := 'Open File';     actionCaption := 'Open';   end;
    fdtSaveFile:     begin title := 'Save File';     actionCaption := 'Save';   end;
    fdtSelectFolder: begin title := 'Select Folder'; actionCaption := 'Select'; end;
  end;

  FWindow := FtCreateWindow(DIALOG_W, DIALOG_H, title, ftwtDialog);
  FWindow.SetWindowType(ftwtDialog);
  FWindow.OnResize := @OnWindowResize;

  { ── Navigation header ── }
  FBtnBack := TFtButton.Create(FWindow);
  FBtnBack.Caption := '';
  FBtnBack.Hint := 'Go Back';
  FBtnBack.IconPosition := ftbipOnly;
  FBtnBack.IconWidth := 16;
  FBtnBack.IconHeight := 16;
  FBtnBack.LoadIconFromSVG(SVG_NAV_BACK);
  FBtnBack.X := MARGIN_X;
  FBtnBack.Y := PADDING;
  FBtnBack.Width := 30;
  FBtnBack.Height := 32;
  FBtnBack.OnClick := @CbBtnBack;
  FBtnBack.UserData := Self;

  FBtnForward := TFtButton.Create(FWindow);
  FBtnForward.Caption := '';
  FBtnForward.Hint := 'Go Forward';
  FBtnForward.IconPosition := ftbipOnly;
  FBtnForward.IconWidth := 16;
  FBtnForward.IconHeight := 16;
  FBtnForward.LoadIconFromSVG(SVG_NAV_FORWARD);
  FBtnForward.X := MARGIN_X + 34;
  FBtnForward.Y := PADDING;
  FBtnForward.Width := 30;
  FBtnForward.Height := 32;
  FBtnForward.OnClick := @CbBtnForward;
  FBtnForward.UserData := Self;

  FBtnUp := TFtButton.Create(FWindow);
  FBtnUp.Caption := '';
  FBtnUp.Hint := 'Go Up';
  FBtnUp.IconPosition := ftbipOnly;
  FBtnUp.IconWidth := 16;
  FBtnUp.IconHeight := 16;
  FBtnUp.LoadIconFromSVG(SVG_NAV_UP);
  FBtnUp.X := MARGIN_X + 68;
  FBtnUp.Y := PADDING;
  FBtnUp.Width := 30;
  FBtnUp.Height := 32;
  FBtnUp.OnClick := @CbBtnUp;
  FBtnUp.UserData := Self;

  FBtnHidden := TFtButton.Create(FWindow);
  FBtnHidden.Caption := '';
  FBtnHidden.Hint := 'Show Hidden Files';
  FBtnHidden.CanToggle := True;
  FBtnHidden.Toggled := FShowHiddenFiles;
  FBtnHidden.IconPosition := ftbipOnly;
  FBtnHidden.IconWidth := 16;
  FBtnHidden.IconHeight := 16;
  FBtnHidden.LoadIconFromSVG(SVG_HIDDEN);
  FBtnHidden.X := DIALOG_W - MARGIN_X - 30;
  FBtnHidden.Y := PADDING;
  FBtnHidden.Width := 30;
  FBtnHidden.Height := 32;
  FBtnHidden.OnToggle := @CbBtnHidden;
  FBtnHidden.UserData := Self;

  FBtnNewFolder := TFtButton.Create(FWindow);
  FBtnNewFolder.Caption := '';
  FBtnNewFolder.Hint := 'New Folder';
  FBtnNewFolder.IconPosition := ftbipOnly;
  FBtnNewFolder.IconWidth := 16;
  FBtnNewFolder.IconHeight := 16;
  FBtnNewFolder.LoadIconFromSVG(SVG_NEW_FOLDER);
  FBtnNewFolder.X := DIALOG_W - MARGIN_X - 66;
  FBtnNewFolder.Y := PADDING;
  FBtnNewFolder.Width := 30;
  FBtnNewFolder.Height := 32;
  FBtnNewFolder.OnClick := @CbBtnNewFolder;
  FBtnNewFolder.UserData := Self;

  FPathBar := TFtPathBar.Create(FWindow, FCurrentDir);
  FPathBar.X := MARGIN_X + 104;
  FPathBar.Y := PADDING;
  FPathBar.Width := (FBtnNewFolder.X - 8) - FPathBar.X;
  FPathBar.Height := 32;
  FPathBar.OnNavigate := @CbPathBarNavigate;
  FPathBar.UserData := Self;

  { ── Content area ── }
  splitterX := 180;

  FSplitter := TFtSplitter.Create(FWindow);
  FSplitter.Orientation := soHorizontal;
  FSplitter.X := MARGIN_X;
  FSplitter.Y := HEADER_H;
  FSplitter.Width := DIALOG_W - (MARGIN_X * 2);
  FSplitter.Height := DIALOG_H - HEADER_H - BOTTOM_H;
  FSplitter.SplitterPos := splitterX;
  FSplitter.MinPane1Size := 120;
  FSplitter.MinPane2Size := 300;

  FPlacesTree := TFtTreeView.Create(FSplitter);
  FPlacesTree.X := MARGIN_X;
  FPlacesTree.Y := HEADER_H;
  FPlacesTree.Width := splitterX;
  FPlacesTree.Height := DIALOG_H - HEADER_H - BOTTOM_H;
  FPlacesTree.OnSelectCb := @CbPlaceSelect;
  FPlacesTree.UserData := Self;

  FFileTable := TFtTable.Create(FSplitter);
  FFileTable.X := MARGIN_X + splitterX;
  FFileTable.Y := HEADER_H;
  FFileTable.Width := FSplitter.Width - splitterX;
  FFileTable.Height := DIALOG_H - HEADER_H - BOTTOM_H;
  FFileTable.ZebraStriping := True;
  FFileTable.ShowGridLines := False;
  FFileTable.OnSelectRowCb := @CbFileSelect;
  FFileTable.UserData := Self;
  FFileTable.OnColumnClick := @HandleColumnClick;
  FFileTable.OnRowDoubleClick := @HandleFileDoubleClick;

  { Add columns: Name, Size, Modified, Type }
  FFileTable.AddColumn('Name', 320, taLeft);
  FFileTable.AddColumn('Size', 80, taRight);
  FFileTable.AddColumn('Modified', 130, taLeft);
  FFileTable.AddColumn('Type', 80, taLeft);

  FSplitter.SetPanes(FPlacesTree, FFileTable);

  { ── Bottom bar ── }
  FBtnCancel := TFtButton.Create(FWindow);
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.X := DIALOG_W - MARGIN_X - 80;
  FBtnCancel.Y := DIALOG_H - BOTTOM_H + 10;
  FBtnCancel.Width := 80;
  FBtnCancel.Height := 32;
  FBtnCancel.OnClick := @CbBtnCancel;
  FBtnCancel.UserData := Self;

  FBtnAction := TFtButton.Create(FWindow);
  FBtnAction.Caption := actionCaption;
  FBtnAction.X := FBtnCancel.X - 10 - 84;
  FBtnAction.Y := DIALOG_H - BOTTOM_H + 10;
  FBtnAction.Width := 84;
  FBtnAction.Height := 32;
  FBtnAction.OnClick := @CbBtnAction;
  FBtnAction.UserData := Self;

  FLabelName := TFtLabel.Create(FWindow);
  FLabelName.Text := 'File name:';
  FLabelName.X := MARGIN_X;
  FLabelName.Y := DIALOG_H - BOTTOM_H + 14;
  FLabelName.Width := 74;
  FLabelName.Height := 24;

  FEntryName := TFtEntry.Create(FWindow, FDefaultName);
  FEntryName.X := MARGIN_X + 78;
  FEntryName.Y := DIALOG_H - BOTTOM_H + 8;
  FEntryName.Width := (FBtnAction.X - 16) - FEntryName.X;
  FEntryName.Height := 32;

  { Filter row }
  FLabelType := TFtLabel.Create(FWindow);
  FLabelType.Text := 'Files of type:';
  FLabelType.X := MARGIN_X;
  FLabelType.Y := DIALOG_H - BOTTOM_H + 38 + 10;
  FLabelType.Width := 74;
  FLabelType.Height := 24;
  FLabelType.Visible := False;

  FCmbFilter := TFtComboBox.Create(FWindow);
  FCmbFilter.X := FEntryName.X;
  FCmbFilter.Y := DIALOG_H - BOTTOM_H + 36 + 8;
  FCmbFilter.Width := FEntryName.Width;
  FCmbFilter.Height := 28;
  FCmbFilter.Visible := False;
  FCmbFilter.AddItem('All Files (*.*)');

  { Initialize navigation history with the initial directory }
  FHistory.Clear();
  FHistory.Add(FCurrentDir);
  FHistoryPos := 0;

  { Populate places sidebar and initial directory }
  PopulatePlaces();
  RefreshList();
  UpdateNavButtons();

  FWindow.InvalidateStyle();
  FWindow.Invalidate();
end;

procedure TFtFileDialog.PopulatePlaces();
var
  homeDir: string;
  node: TFtTreeNode;
  buf: PChar;

  procedure AddPlace(const ALabel, APath: string; AIcon: TFloriaImage);
  var
    pathBuf: PChar;
  begin
    if (APath <> homeDir) and not DirectoryExists(APath) then
      Exit;
    node := FPlacesTree.AddNode(ALabel);
    node.Icon := AIcon;
    GetMem(pathBuf, Length(APath) + 1);
    Move(Pointer(APath)^, pathBuf^, Length(APath));
    pathBuf[Length(APath)] := #0;
    node.Data := pathBuf;
  end;

begin
  FPlacesTree.Clear();
  homeDir := GetEnvironmentVariable('HOME');
  if homeDir = '' then
    homeDir := '/';

  AddPlace('Home',      homeDir, FIconHome);
  AddPlace('Desktop',   homeDir + '/Desktop', FIconDesktop);
  AddPlace('Documents', homeDir + '/Documents', FIconDocuments);
  AddPlace('Downloads', homeDir + '/Downloads', FIconDownloads);
  AddPlace('Pictures',  homeDir + '/Pictures', FIconPictures);
  AddPlace('Music',     homeDir + '/Music', FIconMusic);

  { Root }
  node := FPlacesTree.AddNode('/');
  node.Icon := FIconDrive;
  GetMem(buf, 2);
  buf[0] := '/';
  buf[1] := #0;
  node.Data := buf;

  FPlacesTree.RebuildVisibleNodes();
end;

procedure TFtFileDialog.RefreshList();
var
  Sr: TSearchRec;
  Dirs, Files: array of TFileEntry;
  DirCount, FileCount, r, i: Integer;
  ext: string;
  entry: TFileEntry;
  rowIdx: Integer;
begin
  FFileTable.ClearRows();
  DirCount := 0;
  FileCount := 0;
  SetLength(Dirs, 0);
  SetLength(Files, 0);

  if not DirectoryExists(FCurrentDir) then
    Exit;

  if FindFirst(IncludeTrailingPathDelimiter(FCurrentDir) + '*', faAnyFile, Sr) = 0 then
  begin
    repeat
      if (Sr.Name = '.') or (Sr.Name = '..') then
        Continue;
      if (not FShowHiddenFiles) and (Length(Sr.Name) > 0) and (Sr.Name[1] = '.') then
        Continue;

      entry.Name := Sr.Name;
      entry.IsDir := (Sr.Attr and faDirectory) <> 0;
      entry.Size := Sr.Size;
      entry.ModTime := FileDateToDateTime(Sr.Time);

      if entry.IsDir then
      begin
        Inc(DirCount);
        SetLength(Dirs, DirCount);
        Dirs[DirCount - 1] := entry;
      end
      else
      begin
        Inc(FileCount);
        SetLength(Files, FileCount);
        Files[FileCount - 1] := entry;
      end;
    until FindNext(Sr) <> 0;
    FindClose(Sr);
  end;

  { Sort directories alphabetically }
  for i := 0 to DirCount - 2 do
    for r := 0 to DirCount - 2 - i do
      if CompareText(Dirs[r].Name, Dirs[r + 1].Name) > 0 then
      begin
        entry := Dirs[r];
        Dirs[r] := Dirs[r + 1];
        Dirs[r + 1] := entry;
      end;

  { Sort files alphabetically }
  for i := 0 to FileCount - 2 do
    for r := 0 to FileCount - 2 - i do
      if CompareText(Files[r].Name, Files[r + 1].Name) > 0 then
      begin
        entry := Files[r];
        Files[r] := Files[r + 1];
        Files[r + 1] := entry;
      end;

  { Insert directories first }
  for i := 0 to DirCount - 1 do
  begin
    rowIdx := FFileTable.AddRow([Dirs[i].Name, '', FormatFileTime(Dirs[i].ModTime), 'Folder']);
    { Tag = 1 means directory }
    TFtTableRow(FFileTable.Rows[rowIdx]).Tag := 1;
    FFileTable.SetCellIcon(rowIdx, 0, FIconFolder);
  end;

  { Insert files }
  for i := 0 to FileCount - 1 do
  begin
    ext := LowerCase(ExtractFileExt(Files[i].Name));
    if ext <> '' then
      Delete(ext, 1, 1); { strip the dot }
    rowIdx := FFileTable.AddRow([Files[i].Name,
      FormatFileSize(Files[i].Size),
      FormatFileTime(Files[i].ModTime),
      ext]);
    TFtTableRow(FFileTable.Rows[rowIdx]).Tag := 0;
    FFileTable.SetCellIcon(rowIdx, 0, GetFileIcon(ext));
  end;

  FFileTable.Invalidate();
end;

procedure TFtFileDialog.NavigateTo(const APath: string);
var
  absPath: string;
begin
  absPath := ExcludeTrailingPathDelimiter(APath);
  if absPath = '' then
    absPath := '/';

  if not DirectoryExists(absPath) then
    Exit;

  { Do not push duplicate if already at this path }
  if (FHistory.Count > 0) and (FHistoryPos >= 0) and (FHistoryPos < FHistory.Count) and
     (FHistory[FHistoryPos] = absPath) then
    Exit;

  { Prune forward history }
  while FHistory.Count > FHistoryPos + 1 do
    FHistory.Delete(FHistory.Count - 1);

  FHistory.Add(absPath);
  Inc(FHistoryPos);

  FCurrentDir := absPath;
  FPathBar.NavigateTo(absPath);
  RefreshList();
  UpdateNavButtons();

  if FDialogType = fdtSelectFolder then
    FEntryName.Text := absPath
  else
    FEntryName.Text := '';
end;

procedure TFtFileDialog.GoBack();
begin
  if FHistoryPos > 0 then
  begin
    Dec(FHistoryPos);
    FCurrentDir := FHistory[FHistoryPos];
    FPathBar.NavigateTo(FCurrentDir);
    RefreshList();
    UpdateNavButtons();
  end;
end;

procedure TFtFileDialog.GoForward();
begin
  if FHistoryPos < FHistory.Count - 1 then
  begin
    Inc(FHistoryPos);
    FCurrentDir := FHistory[FHistoryPos];
    FPathBar.NavigateTo(FCurrentDir);
    RefreshList();
    UpdateNavButtons();
  end;
end;

procedure TFtFileDialog.GoUp();
var
  parent: string;
begin
  parent := ExtractFileDir(ExcludeTrailingPathDelimiter(FCurrentDir));
  if parent <> FCurrentDir then
    NavigateTo(parent);
end;

procedure TFtFileDialog.CommitSelection();
var
  selIdx: Integer;
  selName: string;
  fullPath: string;
begin
  selIdx := FFileTable.SelectedRow;

  if FDialogType = fdtSelectFolder then
  begin
    FSelectedPath := FCurrentDir;
    FWindow.ModalResult := mrOk;
    FWindow.Hide();
    Exit;
  end;

  { Priority: table selection → name entry }
  if (selIdx >= 0) and (selIdx < FFileTable.RowCount) and
     (TFtTableRow(FFileTable.Rows[selIdx]).Tag = 0) then
  begin
    selName := FFileTable.GetCell(selIdx, 0);
    fullPath := IncludeTrailingPathDelimiter(FCurrentDir) + selName;
    FEntryName.Text := selName;
    FSelectedPath := fullPath;
    FWindow.ModalResult := mrOk;
    FWindow.Hide();
    Exit;
  end;

  if Trim(FEntryName.Text) <> '' then
  begin
    fullPath := IncludeTrailingPathDelimiter(FCurrentDir) + Trim(FEntryName.Text);
    FSelectedPath := fullPath;
    FWindow.ModalResult := mrOk;
    FWindow.Hide();
    Exit;
  end;
end;

procedure TFtFileDialog.UpdateNavButtons();
begin
  FBtnBack.Enabled := FHistoryPos > 0;
  FBtnForward.Enabled := FHistoryPos < FHistory.Count - 1;
  FBtnUp.Enabled := ExcludeTrailingPathDelimiter(FCurrentDir) <> '/';
  FBtnBack.Invalidate();
  FBtnForward.Invalidate();
  FBtnUp.Invalidate();
end;

procedure TFtFileDialog.UpdateLayout();
var
  W, H: Integer;
begin
  if not Assigned(FWindow) then Exit;
  W := FWindow.Width;
  H := FWindow.Height;

  { Header }
  FBtnBack.X      := MARGIN_X;
  FBtnForward.X   := MARGIN_X + 34;
  FBtnUp.X        := MARGIN_X + 68;
  FPathBar.X      := MARGIN_X + 104;
  FBtnHidden.X    := W - MARGIN_X - 30;
  FBtnNewFolder.X := W - MARGIN_X - 66;
  FPathBar.Width  := (FBtnNewFolder.X - 8) - FPathBar.X;

  { Content splitter }
  FSplitter.X      := MARGIN_X;
  FSplitter.Width  := W - (MARGIN_X * 2);
  FSplitter.Height := H - HEADER_H - BOTTOM_H;
  FSplitter.UpdateLayout();

  { Bottom bar }
  FBtnCancel.X := W - MARGIN_X - 80;
  FBtnCancel.Y := H - BOTTOM_H + 10;
  FBtnAction.X := FBtnCancel.X - 10 - 84;
  FBtnAction.Y := H - BOTTOM_H + 10;

  FLabelName.X := MARGIN_X;
  FLabelName.Y := H - BOTTOM_H + 14;
  FEntryName.X := MARGIN_X + 78;
  FEntryName.Y := H - BOTTOM_H + 8;
  FEntryName.Width := (FBtnAction.X - 16) - FEntryName.X;

  FLabelType.X := MARGIN_X;
  FLabelType.Y := H - BOTTOM_H + 38 + 10;
  FCmbFilter.X := FEntryName.X;
  FCmbFilter.Width := FEntryName.Width;
  FCmbFilter.Y := H - BOTTOM_H + 36 + 8;

  FWindow.Invalidate();
end;

procedure TFtFileDialog.OnWindowResize(Sender: TObject;
  NewWidth, NewHeight: Integer);
begin
  UpdateLayout();
end;

{ ── Class callbacks ── }

class procedure TFtFileDialog.CbBtnBack(Sender: Pointer; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).GoBack();
end;

class procedure TFtFileDialog.CbBtnForward(Sender: Pointer; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).GoForward();
end;

class procedure TFtFileDialog.CbBtnUp(Sender: Pointer; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).GoUp();
end;

class procedure TFtFileDialog.CbBtnNewFolder(Sender: Pointer; UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
  newDir: string;
begin
  dlg := TFtFileDialog(UserData);
  newDir := IncludeTrailingPathDelimiter(dlg.FCurrentDir) + 'New Folder';
  try
    MkDir(newDir);
    dlg.RefreshList();
  except
    { Silently ignore if creation failed }
  end;
end;

class procedure TFtFileDialog.CbBtnHidden(Sender: Pointer; Toggled: cint32;
  UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
begin
  dlg := TFtFileDialog(UserData);
  dlg.FShowHiddenFiles := (Toggled <> 0);
  dlg.RefreshList();
end;

class procedure TFtFileDialog.CbPathBarNavigate(Sender: Pointer;
  const APath: PChar; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).FPendingNavigate := string(APath);
end;

class procedure TFtFileDialog.CbPlaceSelect(Sender: Pointer; Node: Pointer;
  UserData: Pointer); cdecl;
var
  tn: TFtTreeNode;
  path: string;
begin
  tn := TFtTreeNode(Node);
  if Assigned(tn) and Assigned(tn.Data) then
  begin
    path := string(PChar(tn.Data));
    TFtFileDialog(UserData).FPendingNavigate := path;
  end;
end;

class procedure TFtFileDialog.CbFileSelect(Sender: Pointer; RowIndex: Integer;
  UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
  selName: string;
begin
  dlg := TFtFileDialog(UserData);
  if (RowIndex < 0) or (RowIndex >= dlg.FFileTable.RowCount) then
    Exit;

  selName := dlg.FFileTable.GetCell(RowIndex, 0);

  if TFtTableRow(dlg.FFileTable.Rows[RowIndex]).Tag = 1 then
  begin
    { Directory — update name entry to show path, do not navigate yet }
    if dlg.FDialogType = fdtSelectFolder then
      dlg.FEntryName.Text :=
        IncludeTrailingPathDelimiter(dlg.FCurrentDir) + selName;
  end
  else
  begin
    { File — reflect in name entry }
    if dlg.FDialogType <> fdtSelectFolder then
      dlg.FEntryName.Text := selName;
  end;

  dlg.FEntryName.Invalidate();
end;

procedure TFtFileDialog.HandleFileDoubleClick(Sender: TObject;
  RowIndex: Integer);
var
  selName, fullPath: string;
begin
  if (RowIndex < 0) or (RowIndex >= FFileTable.RowCount) then
    Exit;

  selName := FFileTable.GetCell(RowIndex, 0);
  fullPath := IncludeTrailingPathDelimiter(FCurrentDir) + selName;

  if TFtTableRow(FFileTable.Rows[RowIndex]).Tag = 1 then
  begin
    { Folder double-clicked: navigate into directory }
    FPendingNavigate := fullPath;
  end
  else
  begin
    { File double-clicked: open/select file and commit }
    if FDialogType <> fdtSelectFolder then
    begin
      FEntryName.Text := selName;
      FSelectedPath := fullPath;
      FWindow.ModalResult := mrOk;
      FWindow.Hide();
    end;
  end;
end;

procedure TFtFileDialog.HandleColumnClick(Sender: TObject;
  ColumnIndex: Integer);
begin
  if GTableSortCol = ColumnIndex then
    GTableSortDesc := not GTableSortDesc
  else
  begin
    GTableSortCol := ColumnIndex;
    GTableSortDesc := False;
  end;
  { Update sort indicator }
  if FFileTable.Columns[ColumnIndex].SortOrder = soAscending then
    FFileTable.Columns[ColumnIndex].SortOrder := soDescending
  else
    FFileTable.Columns[ColumnIndex].SortOrder := soAscending;
  FFileTable.Invalidate();
end;

class procedure TFtFileDialog.CbBtnAction(Sender: Pointer;
  UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).CommitSelection();
end;

class procedure TFtFileDialog.CbBtnCancel(Sender: Pointer;
  UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
begin
  dlg := TFtFileDialog(UserData);
  dlg.FSelectedPath := '';
  dlg.FWindow.ModalResult := mrCancel;
  dlg.FWindow.Hide();
end;

{ ── Execute ── }

function TFtFileDialog.Execute(): Boolean;
var
  prevModal: TFtWindow;
begin
  BuildUI();
  FPendingNavigate := '';
  FWindow.SetPosition(
    (FWindow.ScreenWidth  - DIALOG_W) div 2,
    (FWindow.ScreenHeight - DIALOG_H) div 2);

  { Custom modal loop — we can't use ShowModal() because we need to
    process deferred navigations between event dispatches. }
  prevModal := GModalWindow;
  FWindow.ModalResult := mrNone;
  FWindow.IsModal := True;
  GModalWindow := FWindow;
  FWindow.Show();
  while (FWindow.ModalResult = mrNone) and FWindow.Visible do
  begin
    if Assigned(GProcessEventsProc) then
      GProcessEventsProc();

    { Process deferred directory navigation }
    if FPendingNavigate <> '' then
    begin
      NavigateTo(FPendingNavigate);
      FPendingNavigate := '';
    end;

    Sleep(5);
  end;
  FWindow.IsModal := False;
  GModalWindow := prevModal;

  Result := (FWindow.ModalResult = mrOk) and (FSelectedPath <> '');
end;

{ ── Subclasses ── }

constructor TFtOpenFileDialog.Create();
begin
  inherited Create(fdtOpenFile);
end;

constructor TFtSaveFileDialog.Create();
begin
  inherited Create(fdtSaveFile);
end;

constructor TFtSelectFolderDialog.Create();
begin
  inherited Create(fdtSelectFolder);
end;

{ ── Convenience functions ── }

function FtDialogOpenFile(const ATitle: string; const ADir: string;
  const AFilter: string): string;
var
  dlg: TFtOpenFileDialog;
begin
  Result := '';
  dlg := TFtOpenFileDialog.Create();
  try
    if ADir <> '' then
      dlg.Directory := ADir;
    dlg.Filter := AFilter;
    if dlg.Execute() then
      Result := dlg.SelectedPath;
  finally
    dlg.Free();
  end;
end;

function FtDialogSaveFile(const ATitle: string; const ADir: string;
  const ADefaultName: string; const AFilter: string): string;
var
  dlg: TFtSaveFileDialog;
begin
  Result := '';
  dlg := TFtSaveFileDialog.Create();
  try
    if ADir <> '' then
      dlg.Directory := ADir;
    dlg.DefaultName := ADefaultName;
    dlg.Filter := AFilter;
    if dlg.Execute() then
      Result := dlg.SelectedPath;
  finally
    dlg.Free();
  end;
end;

function FtDialogSelectFolder(const ATitle: string;
  const ADir: string): string;
var
  dlg: TFtSelectFolderDialog;
begin
  Result := '';
  dlg := TFtSelectFolderDialog.Create();
  try
    if ADir <> '' then
      dlg.Directory := ADir;
    if dlg.Execute() then
      Result := dlg.SelectedPath;
  finally
    dlg.Free();
  end;
end;

end.
