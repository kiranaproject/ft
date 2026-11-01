unit Ft.Dialogs;

{$mode objfpc}{$H+}

interface

uses
  ctypes, SysUtils, Classes, Math, Types,
  Floria.Image.Core, Floria.Canvas.Agg, Floria.Font,
  Floria.SVG.DOM, Floria.SVG.Parser, Floria.SVG.Rasterizer,
  Ft.Widget, Ft.Widget.Buttons, Ft.Widget.Entries, Ft.Widget.Texts,
  Ft.Widget.Containers, Ft.Widget.Splitters, Ft.Widget.TreeViews,
  Ft.Widget.Tables, Ft.Widget.IconViews, Ft.Widget.Selectors, Ft.Widget.PathBars,
  Ft.Widget.Layouts, Ft.Widget.Images, Ft.Widget.TextAreas,
  Ft.Window, Ft.Theme, Ft.Icons;

type
  TFtMessageDialogType = (
    fmdCustom = 0,
    fmdInformation = 1,
    fmdWarning = 2,
    fmdError = 3,
    fmdQuestion = 4,
    fmdSuccess = 5
  );

  TFtMessageDialogButtons = (
    fmbOk = 0,
    fmbOkCancel = 1,
    fmbYesNo = 2,
    fmbYesNoCancel = 3,
    fmbRetryCancel = 4,
    fmbCustom = 5
  );

  TFtCustomDialogButton = record
    Caption: string;
    ModalResult: Integer;
    IsDefault: Boolean;
    IsDestructive: Boolean;
  end;

  { TFtMessageDialog — customizable alert, confirmation, and prompt dialog }
  TFtMessageDialog = class
  private
    FWindow:               TFtWindow;
    FDialogType:           TFtMessageDialogType;
    FButtonsType:          TFtMessageDialogButtons;
    FTitle:                string;
    FInstruction:          string;
    FMessage:              string;
    FDetails:              string;
    FVerificationText:     string;
    FVerificationChecked:  Boolean;
    FCustomIconSvg:        string;
    FButtons:              array of TFtCustomDialogButton;
    FDefaultResult:        Integer;
    FCancelResult:         Integer;

    { UI Components }
    FRootVBox:             TFtVBox;
    FContentHBox:          TFtHBox;
    FIconWidget:           TFtImage;
    FTextVBox:             TFtVBox;
    FInstructionLabel:     TFtLabel;
    FMessageLabel:         TFtLabel;
    FBtnToggleDetails:     TFtButton;
    FDetailsTextArea:      TFtTextArea;
    FDetailsExpanded:      Boolean;
    FFooterHBox:           TFtHBox;
    FVerificationCheckBox: TFtCheckBox;

    procedure BuildUI();
    procedure SetupDefaultButtons();
    function GetEffectiveTitle(): string;
    function GetDialogIconSvg(): string;

    class procedure CbButtonClick(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbToggleDetails(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbVerificationToggle(Sender: Pointer; Checked: cint32; UserData: Pointer); cdecl; static;
    class procedure CbWindowKey(AWindow: Pointer; AKeySym: Cardinal; AIsDown: Integer; AUserData: Pointer); cdecl; static;
  public
    constructor Create(const ATitle, AInstruction, AMessage: string;
      ADialogType: TFtMessageDialogType = fmdInformation;
      AButtons: TFtMessageDialogButtons = fmbOk);
    destructor Destroy(); override;

    procedure AddButton(const ACaption: string; AModalResult: Integer;
      AIsDefault: Boolean = False; AIsDestructive: Boolean = False);
    procedure ClearButtons();

    function ShowModal(): Integer;

    property Title: string read FTitle write FTitle;
    property Instruction: string read FInstruction write FInstruction;
    property Message: string read FMessage write FMessage;
    property Details: string read FDetails write FDetails;
    property VerificationText: string read FVerificationText write FVerificationText;
    property VerificationChecked: Boolean read FVerificationChecked write FVerificationChecked;
    property CustomIconSvg: string read FCustomIconSvg write FCustomIconSvg;
    property DialogType: TFtMessageDialogType read FDialogType write FDialogType;
    property ButtonsType: TFtMessageDialogButtons read FButtonsType write FButtonsType;
    property DefaultResult: Integer read FDefaultResult write FDefaultResult;
    property CancelResult: Integer read FCancelResult write FCancelResult;
    property Window: TFtWindow read FWindow;
  end;

  TFtDialogType = (
    fdtOpenFile = 0,
    fdtSaveFile = 1,
    fdtSelectFolder = 2
  );

  TFtDialogViewMode = (
    dvmList = 0,
    dvmGrid = 1
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
    FViewMode:        TFtDialogViewMode;

    { Layout containers }
    FRightVBox:    TFtVBox;
    FNavHBox:      TFtHBox;
    FNameHBox:     TFtHBox;
    FBottomHBox:   TFtHBox;

    { Navigation header }
    FBtnBack:      TFtButton;
    FBtnForward:   TFtButton;
    FBtnUp:        TFtButton;
    FPathBar:      TFtPathBar;
    FBtnSearch:    TFtButton;
    FSearchEntry:  TFtEntry;
    FSearchFilter: string;
    FBtnNewFolder: TFtButton;
    FBtnHidden:    TFtButton;
    FBtnViewList:  TFtButton;
    FBtnViewGrid:  TFtButton;

    { Content area }
    FSplitter:    TFtSplitter;
    FPlacesTree:  TFtTreeView;
    FFileTable:   TFtTable;
    FIconView:    TFtIconView;

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
    FIconVideos:    TFloriaImage;
    FIconTrash:     TFloriaImage;
    FIconBookmark:  TFloriaImage;

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
    procedure SetViewMode(AMode: TFtDialogViewMode);
    procedure ToggleSearch();
    procedure UpdateNavButtons();
    procedure UpdateToolbarIcons();
    procedure UpdateLayout();
    procedure OnWindowResize(Sender: TObject; NewWidth, NewHeight: Integer);
    procedure HandleSplitterChange(Sender: TObject; Position: Double);

    { Callbacks - static cdecl wrappers }
    class procedure CbBtnBack(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnForward(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnUp(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnSearch(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbSearchChange(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl; static;
    class procedure CbBtnNewFolder(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnHidden(Sender: Pointer; Toggled: cint32; UserData: Pointer); cdecl; static;
    class procedure CbBtnViewList(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnViewGrid(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbPathBarNavigate(Sender: Pointer; const APath: PChar; UserData: Pointer); cdecl; static;
    class procedure CbPlaceSelect(Sender: Pointer; Node: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbFileSelect(Sender: Pointer; RowIndex: Integer; UserData: Pointer); cdecl; static;
    class procedure CbIconSelect(Sender: Pointer; ItemIndex: Integer; UserData: Pointer); cdecl; static;
    class procedure CbIconActivate(Sender: Pointer; ItemIndex: Integer; UserData: Pointer); cdecl; static;
    class procedure CbBtnAction(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbBtnCancel(Sender: Pointer; UserData: Pointer); cdecl; static;
    class procedure CbEntrySubmit(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl; static;
    class procedure CbWindowKey(Sender: Pointer; KeySym: Cardinal; IsDown: cint32; UserData: Pointer); cdecl; static;
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
    property ViewMode:        TFtDialogViewMode read FViewMode write SetViewMode;
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

{ Message Dialog one-shot functions }
function FtShowMessage(const AMessage: string; const ATitle: string = ''): Integer;
function FtShowInfo(const ATitle, AInstruction, AMessage: string): Integer;
function FtShowWarning(const ATitle, AInstruction, AMessage: string): Integer;
function FtShowError(const ATitle, AInstruction, AMessage: string; const ADetails: string = ''): Integer;
function FtConfirm(const ATitle, AInstruction, AMessage: string): Boolean;
function FtConfirmWithVerification(const ATitle, AInstruction, AMessage, AVerificationText: string;
  var AVerificationChecked: Boolean): Boolean;

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

function GetNavBackSvg(ADark: Boolean): string;
begin
  Result := FtGetIconSvg('nav-back', ADark);
end;

function GetNavForwardSvg(ADark: Boolean): string;
begin
  Result := FtGetIconSvg('nav-forward', ADark);
end;

function GetNavUpSvg(ADark: Boolean): string;
begin
  Result := FtGetIconSvg('nav-up', ADark);
end;

function GetNewFolderSvg(ADark: Boolean): string;
begin
  Result := FtGetIconSvg('new-folder', ADark);
end;

function GetHiddenSvg(ADark: Boolean): string;
begin
  Result := FtGetIconSvg('hidden', ADark);
end;

const
  SVG_NAV_BACK        = FT_ICON_NAV_BACK;
  SVG_NAV_FORWARD     = FT_ICON_NAV_FORWARD;
  SVG_NAV_UP          = FT_ICON_NAV_UP;
  SVG_NEW_FOLDER      = FT_ICON_NEW_FOLDER;
  SVG_HIDDEN          = FT_ICON_HIDDEN;

  SVG_FOLDER          = FT_ICON_FOLDER;
  SVG_FILE            = FT_ICON_FILE;
  SVG_FILE_IMAGE      = FT_ICON_FILE_IMAGE;
  SVG_FILE_CODE       = FT_ICON_FILE_CODE;
  SVG_FILE_ARCHIVE    = FT_ICON_FILE_ARCHIVE;

  SVG_PLACE_HOME      = FT_ICON_OUTLINE_HOME;
  SVG_PLACE_DESKTOP   = FT_ICON_OUTLINE_DESKTOP;
  SVG_PLACE_DOCS      = FT_ICON_OUTLINE_DOCUMENTS;
  SVG_PLACE_DOWNLOADS = FT_ICON_OUTLINE_DOWNLOADS;
  SVG_PLACE_PICTURES  = FT_ICON_OUTLINE_PICTURES;
  SVG_PLACE_MUSIC     = FT_ICON_OUTLINE_MUSIC;
  SVG_PLACE_DRIVE     = FT_ICON_OUTLINE_DRIVE;

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
        Result := TFloriaSVGRenderer.RenderToImage(doc, AW, AH, True);
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
var
  isDark: Boolean;
begin
  isDark := FtGetDarkMode();
  FIconFolder    := FtGetIconBitmap('folder', 16, 16);
  FIconFile      := FtGetIconBitmap('file', 16, 16);
  FIconImage     := FtGetIconBitmap('file-image', 16, 16);
  FIconCode      := FtGetIconBitmap('file-code', 16, 16);
  FIconArchive   := FtGetIconBitmap('file-archive', 16, 16);
  FIconHome      := FtGetIconBitmap('outline-home', 16, 16, isDark);
  FIconDesktop   := FtGetIconBitmap('outline-desktop', 16, 16, isDark);
  FIconDocuments := FtGetIconBitmap('outline-documents', 16, 16, isDark);
  FIconDownloads := FtGetIconBitmap('outline-downloads', 16, 16, isDark);
  FIconPictures  := FtGetIconBitmap('outline-pictures', 16, 16, isDark);
  FIconMusic     := FtGetIconBitmap('outline-music', 16, 16, isDark);
  FIconDrive     := FtGetIconBitmap('outline-drive', 16, 16, isDark);
  FIconVideos    := FtGetIconBitmap('outline-videos', 16, 16, isDark);
  FIconTrash     := FtGetIconBitmap('outline-trash', 16, 16, isDark);
  FIconBookmark  := FtGetIconBitmap('outline-bookmark', 16, 16, isDark);
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
  if Assigned(FIconVideos) then FreeAndNil(FIconVideos);
  if Assigned(FIconTrash) then FreeAndNil(FIconTrash);
  if Assigned(FIconBookmark) then FreeAndNil(FIconBookmark);
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
  FViewMode := dvmList;
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
  FWindow.OnWindowKey := @CbWindowKey;
  FWindow.WindowUserData := Self;

  { ── Splitter between Sidebar and Right Content ── }
  splitterX := 180;
  FSplitter := TFtSplitter.Create(FWindow);
  FSplitter.Orientation := soHorizontal;
  FSplitter.SplitterPos := splitterX;
  FSplitter.SplitterSize := 4.0;
  FSplitter.MinPane1Size := 130;
  FSplitter.MinPane2Size := 380;
  FSplitter.OnPositionChange := @HandleSplitterChange;
  FSplitter.UserData := Self;

  { ── Places Sidebar (Borderless, smooth left, full height like macOS) ── }
  FPlacesTree := TFtTreeView.Create(FWindow);
  FPlacesTree.DrawFrame := False;
  FPlacesTree.PaddingX := 12;
  FPlacesTree.PaddingY := 14;
  FPlacesTree.ItemHeight := 28;
  FPlacesTree.IndentWidth := 16;
  FPlacesTree.OnSelectCb := @CbPlaceSelect;
  FPlacesTree.UserData := Self;

  { ── Right Content VBox ── }
  FRightVBox := TFtVBox.Create(FWindow);
  FRightVBox.Gap := 8.0;

  { ── Row 1: Navigation & Actions toolbar ── }
  FNavHBox := TFtHBox.Create(FRightVBox);
  FNavHBox.Height := 30;
  FNavHBox.FlexGrow := 0.0;
  FNavHBox.Gap := 4.0;
  FNavHBox.AlignItems := ftaiCenter;

  FBtnBack := TFtButton.Create(FNavHBox);
  FBtnBack.SetBounds(0, 0, 30, 30);
  FBtnBack.Caption := '';
  FBtnBack.Hint := 'Go Back';
  FBtnBack.IconPosition := ftbipOnly;
  FBtnBack.IconWidth := 16;
  FBtnBack.IconHeight := 16;
  FBtnBack.LoadIconFromSVG(GetNavBackSvg(FtGetDarkMode()));
  FBtnBack.OnClick := @CbBtnBack;
  FBtnBack.UserData := Self;

  FBtnForward := TFtButton.Create(FNavHBox);
  FBtnForward.SetBounds(0, 0, 30, 30);
  FBtnForward.Caption := '';
  FBtnForward.Hint := 'Go Forward';
  FBtnForward.IconPosition := ftbipOnly;
  FBtnForward.IconWidth := 16;
  FBtnForward.IconHeight := 16;
  FBtnForward.LoadIconFromSVG(GetNavForwardSvg(FtGetDarkMode()));
  FBtnForward.OnClick := @CbBtnForward;
  FBtnForward.UserData := Self;

  FBtnUp := TFtButton.Create(FNavHBox);
  FBtnUp.SetBounds(0, 0, 30, 30);
  FBtnUp.Caption := '';
  FBtnUp.Hint := 'Go Up';
  FBtnUp.IconPosition := ftbipOnly;
  FBtnUp.IconWidth := 16;
  FBtnUp.IconHeight := 16;
  FBtnUp.LoadIconFromSVG(GetNavUpSvg(FtGetDarkMode()));
  FBtnUp.OnClick := @CbBtnUp;
  FBtnUp.UserData := Self;

  FPathBar := TFtPathBar.Create(FNavHBox, FCurrentDir);
  FPathBar.Height := 30;
  FPathBar.FlexGrow := 1.0;
  FPathBar.OnNavigate := @CbPathBarNavigate;
  FPathBar.UserData := Self;

  FBtnNewFolder := TFtButton.Create(FNavHBox);
  FBtnNewFolder.SetBounds(0, 0, 30, 30);
  FBtnNewFolder.Caption := '';
  FBtnNewFolder.Hint := 'New Folder';
  FBtnNewFolder.IconPosition := ftbipOnly;
  FBtnNewFolder.IconWidth := 16;
  FBtnNewFolder.IconHeight := 16;
  FBtnNewFolder.LoadIconFromSVG(GetNewFolderSvg(FtGetDarkMode()));
  FBtnNewFolder.OnClick := @CbBtnNewFolder;
  FBtnNewFolder.UserData := Self;

  FBtnHidden := TFtButton.Create(FNavHBox);
  FBtnHidden.SetBounds(0, 0, 30, 30);
  FBtnHidden.Caption := '';
  FBtnHidden.Hint := 'Show Hidden Files';
  FBtnHidden.CanToggle := True;
  FBtnHidden.Toggled := FShowHiddenFiles;
  FBtnHidden.IconPosition := ftbipOnly;
  FBtnHidden.IconWidth := 16;
  FBtnHidden.IconHeight := 16;
  FBtnHidden.LoadIconFromSVG(GetHiddenSvg(FtGetDarkMode()));
  FBtnHidden.OnToggle := @CbBtnHidden;
  FBtnHidden.UserData := Self;

  { View mode switcher: [ List | Grid ] }
  FBtnViewList := TFtButton.Create(FNavHBox);
  FBtnViewList.SetBounds(0, 0, 30, 30);
  FBtnViewList.Caption := '';
  FBtnViewList.Hint := 'List View';
  FBtnViewList.CanToggle := True;
  FBtnViewList.Toggled := (FViewMode = dvmList);
  FBtnViewList.IconPosition := ftbipOnly;
  FBtnViewList.IconWidth := 16;
  FBtnViewList.IconHeight := 16;
  FBtnViewList.LoadIconFromSVG(FtGetIconSvg('view-list', FtGetDarkMode()));
  FBtnViewList.OnClick := @CbBtnViewList;
  FBtnViewList.UserData := Self;

  FBtnViewGrid := TFtButton.Create(FNavHBox);
  FBtnViewGrid.SetBounds(0, 0, 30, 30);
  FBtnViewGrid.Caption := '';
  FBtnViewGrid.Hint := 'Grid View';
  FBtnViewGrid.CanToggle := True;
  FBtnViewGrid.Toggled := (FViewMode = dvmGrid);
  FBtnViewGrid.IconPosition := ftbipOnly;
  FBtnViewGrid.IconWidth := 16;
  FBtnViewGrid.IconHeight := 16;
  FBtnViewGrid.LoadIconFromSVG(FtGetIconSvg('view-grid', FtGetDarkMode()));
  FBtnViewGrid.OnClick := @CbBtnViewGrid;
  FBtnViewGrid.UserData := Self;

  { Search / Filter button & expandable search entry }
  FBtnSearch := TFtButton.Create(FNavHBox);
  FBtnSearch.SetBounds(0, 0, 30, 30);
  FBtnSearch.Caption := '';
  FBtnSearch.Hint := 'Search / Filter (Ctrl+F)';
  FBtnSearch.CanToggle := True;
  FBtnSearch.IconPosition := ftbipOnly;
  FBtnSearch.IconWidth := 16;
  FBtnSearch.IconHeight := 16;
  FBtnSearch.LoadIconFromSVG(FtGetIconSvg('search', FtGetDarkMode()));
  FBtnSearch.OnClick := @CbBtnSearch;
  FBtnSearch.UserData := Self;

  FSearchEntry := TFtEntry.Create(FNavHBox);
  FSearchEntry.Height := 28;
  FSearchEntry.PreferredWidth := 140;
  FSearchEntry.Visible := False;
  FSearchEntry.Placeholder := 'Filter...';
  FSearchEntry.OnChange := @CbSearchChange;
  FSearchEntry.UserData := Self;

  { ── Row 2: File Name input on top of file list ── }
  FNameHBox := TFtHBox.Create(FRightVBox);
  FNameHBox.Height := 30;
  FNameHBox.FlexGrow := 0.0;
  FNameHBox.Gap := 8.0;
  FNameHBox.AlignItems := ftaiCenter;

  FLabelName := TFtLabel.Create(FNameHBox);
  case FDialogType of
    fdtSaveFile:     FLabelName.Text := 'Save as:';
    fdtSelectFolder: FLabelName.Text := 'Folder:';
    else             FLabelName.Text := 'File name:';
  end;
  FLabelName.SetBounds(0, 0, 76, 24);
  FLabelName.FlexGrow := 0.0;

  FEntryName := TFtEntry.Create(FNameHBox, FDefaultName);
  FEntryName.Height := 30;
  FEntryName.FlexGrow := 1.0;
  FEntryName.OnSubmit := @CbEntrySubmit;
  FEntryName.UserData := Self;

  { ── Row 3: File Table ── }
  FFileTable := TFtTable.Create(FRightVBox);
  FFileTable.FlexGrow := 1.0;
  FFileTable.Visible := (FViewMode = dvmList);
  FFileTable.ZebraStriping := True;
  FFileTable.ShowGridLines := False;
  FFileTable.OnSelectRowCb := @CbFileSelect;
  FFileTable.UserData := Self;
  FFileTable.OnColumnClick := @HandleColumnClick;
  FFileTable.OnRowDoubleClick := @HandleFileDoubleClick;

  { Add columns: Name, Size, Modified, Type }
  FFileTable.AddColumn('Name', 300, taLeft);
  FFileTable.AddColumn('Size', 80, taRight);
  FFileTable.AddColumn('Modified', 130, taLeft);
  FFileTable.AddColumn('Type', 80, taLeft);

  { ── Row 3b: Icon / Grid View ── }
  FIconView := TFtIconView.Create(FRightVBox);
  FIconView.FlexGrow := 1.0;
  FIconView.Visible := (FViewMode = dvmGrid);
  FIconView.ZoomLevel := izlNormal;
  FIconView.OnSelectItemCb := @CbIconSelect;
  FIconView.OnItemActivateCb := @CbIconActivate;
  FIconView.UserData := Self;
  FIconView.OnItemActivateUserData := Self;

  { ── Row 4: Bottom bar ── }
  FBottomHBox := TFtHBox.Create(FRightVBox);
  FBottomHBox.Height := 32;
  FBottomHBox.FlexGrow := 0.0;
  FBottomHBox.Gap := 8.0;
  FBottomHBox.AlignItems := ftaiCenter;

  { Filter row }
  FLabelType := TFtLabel.Create(FBottomHBox);
  FLabelType.Text := 'Files of type:';
  FLabelType.SetBounds(0, 0, 76, 24);
  FLabelType.Visible := False;

  FCmbFilter := TFtComboBox.Create(FBottomHBox);
  FCmbFilter.SetBounds(0, 0, 160, 30);
  FCmbFilter.Visible := False;
  FCmbFilter.AddItem('All Files (*.*)');

  TFtSpacer.Create(FBottomHBox).FlexGrow := 1.0;

  FBtnCancel := TFtButton.Create(FBottomHBox);
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.SetBounds(0, 0, 80, 30);
  FBtnCancel.OnClick := @CbBtnCancel;
  FBtnCancel.UserData := Self;

  FBtnAction := TFtButton.Create(FBottomHBox);
  FBtnAction.Caption := actionCaption;
  FBtnAction.SetBounds(0, 0, 84, 30);
  FBtnAction.OnClick := @CbBtnAction;
  FBtnAction.UserData := Self;

  { Apply initial positions and layout }
  UpdateLayout();

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
  homeDir, bkmkFile, line, uri, bLabel, bPath, sub, dev, mnt, hexStr: string;
  node: TFtTreeNode;
  i, spacePos, codeVal: Integer;
  tf: TextFile;
  seenMounts: TStringList;

  procedure FreeAllNodeData(ANode: TFtTreeNode);
  var
    j: Integer;
  begin
    if ANode = nil then Exit;
    if Assigned(ANode.Data) then
    begin
      FreeMem(ANode.Data);
      ANode.Data := nil;
    end;
    for j := 0 to ANode.ChildCount - 1 do
      FreeAllNodeData(ANode.Children[j]);
  end;

  procedure AddPlace(const ALabel, APath: string; AIcon: TFloriaImage);
  var
    pathBuf: PChar;
  begin
    if (APath <> homeDir) and (APath <> '/') and not DirectoryExists(APath) then
      Exit;
    node := FPlacesTree.AddNode(ALabel);
    node.Icon := AIcon;
    GetMem(pathBuf, Length(APath) + 1);
    Move(Pointer(APath)^, pathBuf^, Length(APath));
    pathBuf[Length(APath)] := #0;
    node.Data := pathBuf;
  end;

  function DecodeUri(const AUri: string): string;
  var
    s: string;
    p: Integer;
  begin
    s := Trim(AUri);
    if Pos('file://localhost/', s) = 1 then
      s := Copy(s, 17, MaxInt)
    else if Pos('file://localhost', s) = 1 then
      s := Copy(s, 17, MaxInt)
    else if Pos('file:///', s) = 1 then
      s := Copy(s, 8, MaxInt)
    else if Pos('file://', s) = 1 then
      s := Copy(s, 8, MaxInt);

    Result := '';
    p := 1;
    while p <= Length(s) do
    begin
      if (s[p] = '%') and (p + 2 <= Length(s)) then
      begin
        hexStr := '$' + Copy(s, p + 1, 2);
        codeVal := StrToIntDef(hexStr, -1);
        if codeVal >= 0 then
        begin
          Result := Result + Chr(codeVal);
          Inc(p, 3);
          Continue;
        end;
      end;
      Result := Result + s[p];
      Inc(p);
    end;
  end;

  function DecodeMountEscape(const S: string): string;
  begin
    Result := StringReplace(S, '\040', ' ', [rfReplaceAll]);
    Result := StringReplace(Result, '\011', #9, [rfReplaceAll]);
    Result := StringReplace(Result, '\012', #10, [rfReplaceAll]);
    Result := StringReplace(Result, '\134', '\', [rfReplaceAll]);
  end;

begin
  if Assigned(FPlacesTree.Root) then
  begin
    for i := 0 to FPlacesTree.Root.ChildCount - 1 do
      FreeAllNodeData(FPlacesTree.Root.Children[i]);
  end;
  FPlacesTree.Clear();
  homeDir := GetEnvironmentVariable('HOME');
  if homeDir = '' then
    homeDir := '/';

  { Places }
  AddPlace('Home',      homeDir, FIconHome);
  AddPlace('Desktop',   homeDir + '/Desktop', FIconDesktop);
  AddPlace('Documents', homeDir + '/Documents', FIconDocuments);
  AddPlace('Downloads', homeDir + '/Downloads', FIconDownloads);
  AddPlace('Pictures',  homeDir + '/Pictures', FIconPictures);
  AddPlace('Music',     homeDir + '/Music', FIconMusic);
  AddPlace('Videos',    homeDir + '/Videos', FIconVideos);
  AddPlace('Trash',     homeDir + '/.local/share/Trash/files', FIconTrash);

  { Bookmarks from ~/.config/gtk-3.0/bookmarks }
  bkmkFile := homeDir + '/.config/gtk-3.0/bookmarks';
  if FileExists(bkmkFile) then
  begin
    AssignFile(tf, bkmkFile);
    {$I-}
    Reset(tf);
    {$I+}
    if IOResult = 0 then
    begin
      while not Eof(tf) do
      begin
        ReadLn(tf, line);
        line := Trim(line);
        if (line = '') or (line[1] = '#') then Continue;
        if Pos('file://', line) = 1 then
        begin
          spacePos := Pos(' ', line);
          if spacePos > 0 then
          begin
            uri := Copy(line, 1, spacePos - 1);
            bLabel := Trim(Copy(line, spacePos + 1, MaxInt));
          end
          else
          begin
            uri := line;
            bLabel := '';
          end;
          bPath := DecodeUri(uri);
          if bLabel = '' then
            bLabel := ExtractFileName(bPath);
          if bLabel = '' then
            bLabel := bPath;
          if (bPath <> homeDir) and
             (bPath <> homeDir + '/Desktop') and
             (bPath <> homeDir + '/Documents') and
             (bPath <> homeDir + '/Downloads') and
             (bPath <> homeDir + '/Pictures') and
             (bPath <> homeDir + '/Music') and
             (bPath <> homeDir + '/Videos') and
             DirectoryExists(bPath) then
            AddPlace(bLabel, bPath, FIconBookmark);
        end;
      end;
      CloseFile(tf);
    end;
  end;

  { Devices / Mounts }
  AddPlace('File System', '/', FIconDrive);

  seenMounts := TStringList.Create();
  try
    seenMounts.Add('/');
    if FileExists('/proc/mounts') then
    begin
      AssignFile(tf, '/proc/mounts');
      {$I-}
      Reset(tf);
      {$I+}
      if IOResult = 0 then
      begin
        while not Eof(tf) do
        begin
          ReadLn(tf, line);
          line := Trim(line);
          if line = '' then Continue;
          spacePos := Pos(' ', line);
          if spacePos = 0 then Continue;
          dev := Copy(line, 1, spacePos - 1);
          sub := Trim(Copy(line, spacePos + 1, MaxInt));
          spacePos := Pos(' ', sub);
          if spacePos = 0 then Continue;
          mnt := DecodeMountEscape(Copy(sub, 1, spacePos - 1));

          if (Pos('/media/', mnt) = 1) or
             (Pos('/run/media/', mnt) = 1) or
             (Pos('/mnt/', mnt) = 1) then
          begin
            if (seenMounts.IndexOf(mnt) < 0) and DirectoryExists(mnt) then
            begin
              seenMounts.Add(mnt);
              bLabel := ExtractFileName(mnt);
              if bLabel = '' then bLabel := mnt;
              AddPlace(bLabel, mnt, FIconDrive);
            end;
          end;
        end;
        CloseFile(tf);
      end;
    end;
  finally
    seenMounts.Free();
  end;

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
  if Assigned(FIconView) then
    FIconView.Clear();
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
      if (FSearchFilter <> '') and (Pos(LowerCase(FSearchFilter), LowerCase(Sr.Name)) = 0) then
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

    if Assigned(FIconView) then
    begin
      rowIdx := FIconView.AddItem(Dirs[i].Name, FIconFolder);
      FIconView.Items[rowIdx].Tag := 1;
    end;
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

    if Assigned(FIconView) then
    begin
      rowIdx := FIconView.AddItem(Files[i].Name, GetFileIcon(ext));
      FIconView.Items[rowIdx].Tag := 0;
      FIconView.Items[rowIdx].SubText := FormatFileSize(Files[i].Size);
    end;
  end;

  FFileTable.Invalidate();
  if Assigned(FIconView) then
    FIconView.Invalidate();
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
  if FDialogType = fdtSelectFolder then
  begin
    FSelectedPath := FCurrentDir;
    FWindow.ModalResult := mrOk;
    FWindow.Hide();
    Exit;
  end;

  if (FViewMode = dvmGrid) and Assigned(FIconView) then
  begin
    selIdx := FIconView.SelectedIndex;
    if (selIdx >= 0) and (selIdx < FIconView.ItemCount) and
       (FIconView.Items[selIdx].Tag = 0) then
    begin
      selName := FIconView.Items[selIdx].Caption;
      fullPath := IncludeTrailingPathDelimiter(FCurrentDir) + selName;
      FEntryName.Text := selName;
      FSelectedPath := fullPath;
      FWindow.ModalResult := mrOk;
      FWindow.Hide();
      Exit;
    end;
  end
  else
  begin
    selIdx := FFileTable.SelectedRow;
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

procedure TFtFileDialog.UpdateToolbarIcons();
var
  isDark: Boolean;
begin
  isDark := FtGetDarkMode();
  if Assigned(FBtnBack) then FBtnBack.LoadIconFromSVG(GetNavBackSvg(isDark));
  if Assigned(FBtnForward) then FBtnForward.LoadIconFromSVG(GetNavForwardSvg(isDark));
  if Assigned(FBtnUp) then FBtnUp.LoadIconFromSVG(GetNavUpSvg(isDark));
  if Assigned(FBtnHidden) then FBtnHidden.LoadIconFromSVG(GetHiddenSvg(isDark));
  if Assigned(FBtnNewFolder) then FBtnNewFolder.LoadIconFromSVG(GetNewFolderSvg(isDark));
  if Assigned(FBtnViewList) then FBtnViewList.LoadIconFromSVG(FtGetIconSvg('view-list', isDark));
  if Assigned(FBtnViewGrid) then FBtnViewGrid.LoadIconFromSVG(FtGetIconSvg('view-grid', isDark));

  { Refresh outline place icons with new dark mode palette }
  FreeIcons();
  InitIcons();
  PopulatePlaces();
  UpdateLayout();
end;

procedure TFtFileDialog.HandleSplitterChange(Sender: TObject; Position: Double);
begin
  UpdateLayout();
end;

procedure TFtFileDialog.UpdateLayout();
var
  W, H: Integer;
  sidebarW: Integer;
  contentX, contentW: Integer;
  tableY, tableH: Integer;
  bottomBarH: Integer;
  isDark: Boolean;
begin
  if not Assigned(FWindow) then Exit;
  W := FWindow.Width;
  H := FWindow.Height;
  isDark := FtGetDarkMode();

  sidebarW := Round(FSplitter.SplitterPos);
  if sidebarW < 130 then sidebarW := 130;
  if sidebarW > W - 380 then sidebarW := W - 380;

  { 1. Left Sidebar: borderless, expands to top, smooth left }
  FPlacesTree.X := 0;
  FPlacesTree.Y := 0;
  FPlacesTree.Width := sidebarW;
  FPlacesTree.Height := H;
  if isDark then
    FPlacesTree.InlineStyle := 'background-color: #18181b; border: none; border-radius: 0px;'
  else
    FPlacesTree.InlineStyle := 'background-color: #f6f8fa; border: none; border-radius: 0px;';

  { 2. Splitter divider between sidebar and right content }
  FSplitter.X := 0;
  FSplitter.Y := 0;
  FSplitter.Width := W;
  FSplitter.Height := H;

  { 3. Right Content Flexbox Layout }
  contentX := sidebarW + Round(FSplitter.SplitterSize) + 8;
  contentW := W - contentX - MARGIN_X;
  if contentW < 200 then contentW := 200;

  if Assigned(FRightVBox) then
  begin
    FRightVBox.SetBounds(contentX, 10, contentW, H - 20);
    FRightVBox.UpdateLayout();
  end;

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

procedure TFtFileDialog.SetViewMode(AMode: TFtDialogViewMode);
var
  selIdx: Integer;
begin
  FViewMode := AMode;
  if Assigned(FBtnViewList) then
    FBtnViewList.Toggled := (FViewMode = dvmList);
  if Assigned(FBtnViewGrid) then
    FBtnViewGrid.Toggled := (FViewMode = dvmGrid);

  if Assigned(FFileTable) and Assigned(FIconView) then
  begin
    if FViewMode = dvmList then
    begin
      selIdx := FIconView.SelectedIndex;
      FIconView.Visible := False;
      FFileTable.Visible := True;
      if (selIdx >= 0) and (selIdx < FFileTable.RowCount) then
        FFileTable.SelectedRow := selIdx;
    end
    else
    begin
      selIdx := FFileTable.SelectedRow;
      FFileTable.Visible := False;
      FIconView.Visible := True;
      if (selIdx >= 0) and (selIdx < FIconView.ItemCount) then
        FIconView.SelectedIndex := selIdx;
    end;
  end;

  if Assigned(FRightVBox) then
    FRightVBox.UpdateLayout();
  if Assigned(FWindow) then
    FWindow.Invalidate();
end;

class procedure TFtFileDialog.CbBtnViewList(Sender: Pointer; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).SetViewMode(dvmList);
end;

class procedure TFtFileDialog.CbBtnViewGrid(Sender: Pointer; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).SetViewMode(dvmGrid);
end;

class procedure TFtFileDialog.CbIconSelect(Sender: Pointer; ItemIndex: Integer;
  UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
  item: TFtIconViewItem;
begin
  dlg := TFtFileDialog(UserData);
  if not Assigned(dlg.FIconView) or (ItemIndex < 0) or (ItemIndex >= dlg.FIconView.ItemCount) then
    Exit;

  item := dlg.FIconView.Items[ItemIndex];
  if item.Tag = 1 then
  begin
    if dlg.FDialogType = fdtSelectFolder then
      dlg.FEntryName.Text :=
        IncludeTrailingPathDelimiter(dlg.FCurrentDir) + item.Caption;
  end
  else
  begin
    if dlg.FDialogType <> fdtSelectFolder then
      dlg.FEntryName.Text := item.Caption;
  end;

  dlg.FEntryName.Invalidate();
end;

class procedure TFtFileDialog.CbIconActivate(Sender: Pointer; ItemIndex: Integer;
  UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
  item: TFtIconViewItem;
  fullPath: string;
begin
  dlg := TFtFileDialog(UserData);
  if not Assigned(dlg.FIconView) or (ItemIndex < 0) or (ItemIndex >= dlg.FIconView.ItemCount) then
    Exit;

  item := dlg.FIconView.Items[ItemIndex];
  fullPath := IncludeTrailingPathDelimiter(dlg.FCurrentDir) + item.Caption;

  if item.Tag = 1 then
  begin
    dlg.FPendingNavigate := fullPath;
  end
  else
  begin
    if dlg.FDialogType <> fdtSelectFolder then
    begin
      dlg.FEntryName.Text := item.Caption;
      dlg.FSelectedPath := fullPath;
      dlg.FWindow.ModalResult := mrOk;
      dlg.FWindow.Hide();
    end;
  end;
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

class procedure TFtFileDialog.CbEntrySubmit(Sender: Pointer;
  Text: PChar; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).CommitSelection();
end;

procedure TFtFileDialog.ToggleSearch();
begin
  if not Assigned(FSearchEntry) then Exit;
  if FSearchEntry.Visible then
  begin
    FSearchEntry.Visible := False;
    FSearchEntry.Text := '';
    FSearchFilter := '';
    if Assigned(FBtnSearch) then
      FBtnSearch.Toggled := False;
    RefreshList();
  end
  else
  begin
    FSearchEntry.Visible := True;
    if Assigned(FBtnSearch) then
      FBtnSearch.Toggled := True;
    FSearchEntry.SetFocus();
    FSearchEntry.SelectAll();
  end;
  if Assigned(FNavHBox) then
  begin
    FNavHBox.UpdateLayout();
    FNavHBox.Invalidate();
  end;
end;

class procedure TFtFileDialog.CbBtnSearch(Sender: Pointer; UserData: Pointer); cdecl;
begin
  TFtFileDialog(UserData).ToggleSearch();
end;

class procedure TFtFileDialog.CbSearchChange(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
begin
  dlg := TFtFileDialog(UserData);
  if Assigned(dlg) then
  begin
    dlg.FSearchFilter := Trim(StrPas(Text));
    dlg.RefreshList();
  end;
end;

class procedure TFtFileDialog.CbWindowKey(Sender: Pointer; KeySym: Cardinal; IsDown: cint32; UserData: Pointer); cdecl;
var
  dlg: TFtFileDialog;
  mods: Cardinal;
  hasCtrl, hasAlt: Boolean;
begin
  if IsDown = 0 then Exit;
  dlg := TFtFileDialog(UserData);
  if dlg = nil then Exit;

  mods := FtGetKeyboardModifiers();
  hasCtrl := (mods and 4) <> 0;
  hasAlt := (mods and 8) <> 0;

  // Escape ($FF1B):
  // 1. If pathbar is in edit mode, revert to breadcrumbs
  // 2. If search is active, clear search and hide search entry
  // 3. Otherwise cancel dialog
  if KeySym = $FF1B then
  begin
    if Assigned(dlg.FPathBar) and (dlg.FPathBar.Mode = pbmEdit) then
    begin
      dlg.FPathBar.CancelEdit();
      Exit;
    end;
    if Assigned(dlg.FSearchEntry) and dlg.FSearchEntry.Visible and (dlg.FSearchEntry.Text <> '') then
    begin
      dlg.ToggleSearch();
      Exit;
    end;
    dlg.FSelectedPath := '';
    dlg.FWindow.ModalResult := mrCancel;
    dlg.FWindow.Hide();
    Exit;
  end;

  // Ctrl+L ($6C / $4C): Toggle path bar location entry mode
  if hasCtrl and ((KeySym = $6C) or (KeySym = $4C)) then
  begin
    if Assigned(dlg.FPathBar) then
    begin
      if dlg.FPathBar.Mode = pbmBreadcrumbs then
        dlg.FPathBar.Mode := pbmEdit
      else
        dlg.FPathBar.Mode := pbmBreadcrumbs;
    end;
    Exit;
  end;

  // Ctrl+F ($66 / $46): Toggle / focus search entry
  if hasCtrl and ((KeySym = $66) or (KeySym = $46)) then
  begin
    dlg.ToggleSearch();
    Exit;
  end;

  // Ctrl+H ($68 / $48): Toggle hidden files
  if hasCtrl and ((KeySym = $68) or (KeySym = $48)) then
  begin
    dlg.FShowHiddenFiles := not dlg.FShowHiddenFiles;
    if Assigned(dlg.FBtnHidden) then
      dlg.FBtnHidden.Toggled := dlg.FShowHiddenFiles;
    dlg.RefreshList();
    Exit;
  end;

  // Alt+Up ($FF52): Go up
  if hasAlt and (KeySym = $FF52) then
  begin
    dlg.GoUp();
    Exit;
  end;

  // Alt+Left ($FF51): Go back
  if hasAlt and (KeySym = $FF51) then
  begin
    dlg.GoBack();
    Exit;
  end;

  // Alt+Right ($FF53): Go forward
  if hasAlt and (KeySym = $FF53) then
  begin
    dlg.GoForward();
    Exit;
  end;

  // F5 ($FFC2): Refresh
  if KeySym = $FFC2 then
  begin
    dlg.RefreshList();
    Exit;
  end;
end;

{ ── Execute ── }

function TFtFileDialog.Execute(): Boolean;
var
  prevModal: TFtWindow;
  lastDarkMode: Boolean;
begin
  BuildUI();
  lastDarkMode := FtGetDarkMode();
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
  FWindow.BringToFront();
  while (FWindow.ModalResult = mrNone) and FWindow.Visible do
  begin
    if Assigned(GProcessEventsProc) then
      GProcessEventsProc();

    if FtGetDarkMode() <> lastDarkMode then
    begin
      lastDarkMode := FtGetDarkMode();
      UpdateToolbarIcons();
    end;

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
  if Assigned(prevModal) then
    prevModal.BringToFront()
  else if Assigned(GActiveWindow) and (GActiveWindow <> FWindow) then
    GActiveWindow.BringToFront();

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

{ ─────────────────────── TFtMessageDialog ────────────────────────────────── }

constructor TFtMessageDialog.Create(const ATitle, AInstruction, AMessage: string;
  ADialogType: TFtMessageDialogType = fmdInformation;
  AButtons: TFtMessageDialogButtons = fmbOk);
begin
  inherited Create();
  FTitle := ATitle;
  FInstruction := AInstruction;
  FMessage := AMessage;
  FDialogType := ADialogType;
  FButtonsType := AButtons;
  FDetails := '';
  FVerificationText := '';
  FVerificationChecked := False;
  FCustomIconSvg := '';
  FWindow := nil;
  FDefaultResult := mrOk;
  FCancelResult := mrCancel;
  FDetailsExpanded := False;
  SetLength(FButtons, 0);
  SetupDefaultButtons();
end;

destructor TFtMessageDialog.Destroy();
begin
  if Assigned(FWindow) then
  begin
    FWindow.Free();
    FWindow := nil;
  end;
  SetLength(FButtons, 0);
  inherited Destroy();
end;

procedure TFtMessageDialog.ClearButtons();
begin
  SetLength(FButtons, 0);
  FButtonsType := fmbCustom;
end;

procedure TFtMessageDialog.AddButton(const ACaption: string; AModalResult: Integer;
  AIsDefault: Boolean = False; AIsDestructive: Boolean = False);
var
  idx: Integer;
begin
  idx := Length(FButtons);
  SetLength(FButtons, idx + 1);
  FButtons[idx].Caption := ACaption;
  FButtons[idx].ModalResult := AModalResult;
  FButtons[idx].IsDefault := AIsDefault;
  FButtons[idx].IsDestructive := AIsDestructive;
  if AIsDefault then
    FDefaultResult := AModalResult;
end;

procedure TFtMessageDialog.SetupDefaultButtons();
begin
  if Length(FButtons) > 0 then Exit;

  case FButtonsType of
    fmbOk:
      begin
        AddButton('OK', mrOk, True, False);
        FDefaultResult := mrOk;
        FCancelResult := mrOk;
      end;
    fmbOkCancel:
      begin
        AddButton('Cancel', mrCancel, False, False);
        AddButton('OK', mrOk, True, False);
        FDefaultResult := mrOk;
        FCancelResult := mrCancel;
      end;
    fmbYesNo:
      begin
        AddButton('No', mrNo, False, False);
        AddButton('Yes', mrYes, True, False);
        FDefaultResult := mrYes;
        FCancelResult := mrNo;
      end;
    fmbYesNoCancel:
      begin
        AddButton('Cancel', mrCancel, False, False);
        AddButton('No', mrNo, False, False);
        AddButton('Yes', mrYes, True, False);
        FDefaultResult := mrYes;
        FCancelResult := mrCancel;
      end;
    fmbRetryCancel:
      begin
        AddButton('Cancel', mrCancel, False, False);
        AddButton('Retry', mrRetry, True, False);
        FDefaultResult := mrRetry;
        FCancelResult := mrCancel;
      end;
  end;
end;

function TFtMessageDialog.GetEffectiveTitle(): string;
begin
  if FTitle <> '' then
    Exit(FTitle);
  case FDialogType of
    fmdInformation: Result := 'Information';
    fmdWarning:     Result := 'Warning';
    fmdError:       Result := 'Error';
    fmdQuestion:    Result := 'Question';
    fmdSuccess:     Result := 'Success';
    else            Result := 'Notice';
  end;
end;

function TFtMessageDialog.GetDialogIconSvg(): string;
begin
  if FCustomIconSvg <> '' then
    Exit(FCustomIconSvg);
  case FDialogType of
    fmdInformation: Result := FtGetIconSvg('dialog-info');
    fmdWarning:     Result := FtGetIconSvg('dialog-warning');
    fmdError:       Result := FtGetIconSvg('dialog-error');
    fmdQuestion:    Result := FtGetIconSvg('dialog-question');
    fmdSuccess:     Result := FtGetIconSvg('dialog-success');
    else            Result := '';
  end;
end;

class procedure TFtMessageDialog.CbButtonClick(Sender: Pointer; UserData: Pointer); cdecl;
var
  dlg: TFtMessageDialog;
  btn: TFtButton;
begin
  dlg := TFtMessageDialog(UserData);
  btn := TFtButton(Sender);
  if Assigned(dlg) and Assigned(btn) and Assigned(dlg.FWindow) then
  begin
    dlg.FWindow.ModalResult := btn.Tag;
    dlg.FWindow.Hide();
  end;
end;

class procedure TFtMessageDialog.CbToggleDetails(Sender: Pointer; UserData: Pointer); cdecl;
var
  dlg: TFtMessageDialog;
  newH: Integer;
begin
  dlg := TFtMessageDialog(UserData);
  if not Assigned(dlg) or not Assigned(dlg.FWindow) then Exit;
  dlg.FDetailsExpanded := not dlg.FDetailsExpanded;
  if Assigned(dlg.FDetailsTextArea) then
    dlg.FDetailsTextArea.Visible := dlg.FDetailsExpanded;
  if dlg.FDetailsExpanded then
  begin
    if Assigned(dlg.FBtnToggleDetails) then
      dlg.FBtnToggleDetails.Caption := 'Details ▲';
    newH := dlg.FWindow.Height + 140;
  end
  else
  begin
    if Assigned(dlg.FBtnToggleDetails) then
      dlg.FBtnToggleDetails.Caption := 'Details ▼';
    newH := dlg.FWindow.Height - 140;
  end;
  dlg.FWindow.Resize(dlg.FWindow.Width, newH);
  dlg.FWindow.UpdateLayout();
  dlg.FWindow.Invalidate();
end;

class procedure TFtMessageDialog.CbVerificationToggle(Sender: Pointer; Checked: cint32; UserData: Pointer); cdecl;
var
  dlg: TFtMessageDialog;
begin
  dlg := TFtMessageDialog(UserData);
  if Assigned(dlg) then
    dlg.FVerificationChecked := (Checked <> 0);
end;

class procedure TFtMessageDialog.CbWindowKey(AWindow: Pointer; AKeySym: Cardinal; AIsDown: Integer; AUserData: Pointer); cdecl;
var
  dlg: TFtMessageDialog;
begin
  if AIsDown = 0 then Exit;
  dlg := TFtMessageDialog(AUserData);
  if not Assigned(dlg) or not Assigned(dlg.FWindow) then Exit;

  // Return / Enter (XK_Return: $FF0D=65293, XK_KP_Enter: $FF8D=65421)
  if (AKeySym = 65293) or (AKeySym = 65421) then
  begin
    dlg.FWindow.ModalResult := dlg.FDefaultResult;
    dlg.FWindow.Hide();
  end
  // Escape (XK_Escape: $FF1B=65307)
  else if (AKeySym = 65307) then
  begin
    dlg.FWindow.ModalResult := dlg.FCancelResult;
    dlg.FWindow.Hide();
  end;
end;

procedure TFtMessageDialog.BuildUI();
var
  dlgW, dlgH: Integer;
  contentW, textColW: Integer;
  sysFont, fntInst, fntMsg: TFtFont;
  instLines, msgLines: TFtTextLineArray;
  instH, msgH, textH, contentH: Integer;
  verificationH, detailsH, buttonsH: Integer;
  svgIcon: string;
  btn: TFtButton;
  i: Integer;
  posX, posY: Integer;
  btnW: Integer;
  measurer: TFtText;
  detailsHBox: TFtHBox;
begin
  if Assigned(FWindow) then Exit;

  SetupDefaultButtons();

  dlgW := 480;
  contentW := dlgW - 40;
  textColW := contentW - 48 - 16; { 48px icon + 16px gap }

  sysFont := FtGetSystemFont();
  if not Assigned(sysFont) then
    sysFont := FtFontManager().GetFont('sans-serif,10');

  instH := 0;
  msgH := 0;
  measurer := TFtText.Create(nil);
  try
    measurer.WordWrap := True;
    if FInstruction <> '' then
    begin
      fntInst := FtFontManager().GetFont(sysFont.FamilyName + ',' + IntToStr(Round(sysFont.Size * 1.15)) + ',bold');
      if not Assigned(fntInst) then fntInst := sysFont;
      measurer.Text := FInstruction;
      instLines := measurer.BuildLines(fntInst, textColW);
      instH := Length(instLines) * Round(fntInst.Size * 1.35) + 6;
      if instH < Round(fntInst.Size * 1.35) then instH := Round(fntInst.Size * 1.35) + 6;
    end;

    if FMessage <> '' then
    begin
      fntMsg := sysFont;
      measurer.Text := FMessage;
      msgLines := measurer.BuildLines(fntMsg, textColW);
      msgH := Length(msgLines) * Round(fntMsg.Size * 1.35) + 6;
      if msgH < Round(fntMsg.Size * 1.35) then msgH := Round(fntMsg.Size * 1.35) + 6;
    end;
  finally
    measurer.Free();
  end;

  textH := instH + msgH;
  if (FInstruction <> '') and (FMessage <> '') then
    textH := textH + 6;
  contentH := Max(48, textH);

  verificationH := 0;
  if FVerificationText <> '' then
    verificationH := 26 + 12;

  detailsH := 0;
  if FDetails <> '' then
    detailsH := 28 + 10;

  buttonsH := 32 + 16;
  dlgH := 40 + contentH + detailsH + verificationH + buttonsH;
  if dlgH < 170 then dlgH := 170;

  FWindow := FtCreateWindow(dlgW, dlgH, GetEffectiveTitle(), ftwtDialog);
  FWindow.OnWindowKey := @CbWindowKey;
  FWindow.WindowUserData := Self;

  FRootVBox := TFtVBox.Create(FWindow);
  FRootVBox.SetBounds(0, 0, dlgW, dlgH);
  FRootVBox.SetPadding(20.0, 20.0);
  FRootVBox.Gap := 14.0;
  FWindow.RootLayout := FRootVBox;

  FContentHBox := TFtHBox.Create(FRootVBox);
  FContentHBox.AlignItems := ftaiStart;
  FContentHBox.Gap := 16.0;

  svgIcon := GetDialogIconSvg();
  if svgIcon <> '' then
  begin
    FIconWidget := TFtImage.Create(FContentHBox, 0, 0, 48, 48);
    FIconWidget.LoadSVGFromString(svgIcon);
    FIconWidget.PreferredWidth := 48;
    FIconWidget.PreferredHeight := 48;
    FIconWidget.FlexShrink := 0.0;
  end;

  FTextVBox := TFtVBox.Create(FContentHBox);
  FTextVBox.FlexGrow := 1.0;
  FTextVBox.Gap := 6.0;

  if FInstruction <> '' then
  begin
    FInstructionLabel := TFtLabel.Create(FTextVBox);
    FInstructionLabel.WordWrap := True;
    FInstructionLabel.Text := FInstruction;
    FInstructionLabel.FontDesc := sysFont.FamilyName + ',' + IntToStr(Round(sysFont.Size * 1.15)) + ',bold';
    FInstructionLabel.PreferredHeight := instH;
  end;

  if FMessage <> '' then
  begin
    FMessageLabel := TFtLabel.Create(FTextVBox);
    FMessageLabel.WordWrap := True;
    FMessageLabel.Text := FMessage;
    if FInstruction <> '' then
      FMessageLabel.InlineStyle := 'color: #64748b;'
    else
      FMessageLabel.InlineStyle := '';
    FMessageLabel.PreferredHeight := msgH;
  end;

  if FDetails <> '' then
  begin
    detailsHBox := TFtHBox.Create(FRootVBox);
    detailsHBox.PreferredHeight := 28;
    detailsHBox.AlignItems := ftaiCenter;

    FBtnToggleDetails := TFtButton.Create(detailsHBox);
    FBtnToggleDetails.Caption := 'Details ▼';
    FBtnToggleDetails.SetBounds(0, 0, 96, 26);
    FBtnToggleDetails.PreferredWidth := 96;
    FBtnToggleDetails.PreferredHeight := 26;
    FBtnToggleDetails.InlineStyle := 'font-size: 11px;';
    FBtnToggleDetails.OnClick := @CbToggleDetails;
    FBtnToggleDetails.UserData := Self;

    FDetailsTextArea := TFtTextArea.Create(FRootVBox);
    FDetailsTextArea.Text := FDetails;
    FDetailsTextArea.ReadOnly := True;
    FDetailsTextArea.Visible := False;
    FDetailsTextArea.SetBounds(0, 0, contentW, 110);
    FDetailsTextArea.PreferredHeight := 110;
    FDetailsTextArea.InlineStyle := 'font-family: monospace; font-size: 11px;';
  end;

  FFooterHBox := TFtHBox.Create(FRootVBox);
  FFooterHBox.AlignItems := ftaiCenter;
  FFooterHBox.Gap := 10.0;

  if FVerificationText <> '' then
  begin
    FVerificationCheckBox := TFtCheckBox.Create(FFooterHBox);
    FVerificationCheckBox.Caption := FVerificationText;
    FVerificationCheckBox.Checked := FVerificationChecked;
    FVerificationCheckBox.OnToggle := @CbVerificationToggle;
    FVerificationCheckBox.UserData := Self;
  end;

  TFtSpacer.Create(FFooterHBox).FlexGrow := 1.0;

  for i := 0 to High(FButtons) do
  begin
    btn := TFtButton.Create(FFooterHBox);
    btn.Caption := FButtons[i].Caption;
    btn.Tag := FButtons[i].ModalResult;
    btn.OnClick := @CbButtonClick;
    btn.UserData := Self;
    btn.PreferredHeight := 32;
    btnW := Max(80, Round(btn.GetPreferredWidth() + 20));
    btn.SetBounds(0, 0, btnW, 32);
    btn.PreferredWidth := btnW;
    if FButtons[i].IsDefault then
      btn.InlineStyle := 'background-color: #2563eb; color: #ffffff; border-color: #1d4ed8; font-weight: bold;'
    else if FButtons[i].IsDestructive then
      btn.InlineStyle := 'background-color: #ef4444; color: #ffffff; border-color: #dc2626; font-weight: bold;';
  end;

  if Assigned(GActiveWindow) and (GActiveWindow <> FWindow) and (GActiveWindow.Width > 0) then
  begin
    posX := GActiveWindow.X + (GActiveWindow.Width - dlgW) div 2;
    posY := GActiveWindow.Y + (GActiveWindow.Height - dlgH) div 2;
  end
  else
  begin
    posX := (FWindow.ScreenWidth - dlgW) div 2;
    posY := (FWindow.ScreenHeight - dlgH) div 2;
  end;
  if posX < 10 then posX := 10;
  if posY < 30 then posY := 30;
  FWindow.SetPosition(posX, posY);
  FWindow.UpdateLayout();
end;

function TFtMessageDialog.ShowModal(): Integer;
begin
  BuildUI();
  FWindow.ShowModal();
  if Assigned(FVerificationCheckBox) then
    FVerificationChecked := FVerificationCheckBox.Checked;
  Result := FWindow.ModalResult;
  if (Result = mrCancel) and (FCancelResult <> mrNone) then
    Result := FCancelResult;
end;

function FtShowMessage(const AMessage: string; const ATitle: string = ''): Integer;
var
  dlg: TFtMessageDialog;
begin
  dlg := TFtMessageDialog.Create(ATitle, '', AMessage, fmdInformation, fmbOk);
  try
    Result := dlg.ShowModal();
  finally
    dlg.Free();
  end;
end;

function FtShowInfo(const ATitle, AInstruction, AMessage: string): Integer;
var
  dlg: TFtMessageDialog;
begin
  dlg := TFtMessageDialog.Create(ATitle, AInstruction, AMessage, fmdInformation, fmbOk);
  try
    Result := dlg.ShowModal();
  finally
    dlg.Free();
  end;
end;

function FtShowWarning(const ATitle, AInstruction, AMessage: string): Integer;
var
  dlg: TFtMessageDialog;
begin
  dlg := TFtMessageDialog.Create(ATitle, AInstruction, AMessage, fmdWarning, fmbOk);
  try
    Result := dlg.ShowModal();
  finally
    dlg.Free();
  end;
end;

function FtShowError(const ATitle, AInstruction, AMessage: string; const ADetails: string = ''): Integer;
var
  dlg: TFtMessageDialog;
begin
  dlg := TFtMessageDialog.Create(ATitle, AInstruction, AMessage, fmdError, fmbOk);
  try
    dlg.Details := ADetails;
    Result := dlg.ShowModal();
  finally
    dlg.Free();
  end;
end;

function FtConfirm(const ATitle, AInstruction, AMessage: string): Boolean;
var
  dlg: TFtMessageDialog;
begin
  dlg := TFtMessageDialog.Create(ATitle, AInstruction, AMessage, fmdQuestion, fmbYesNo);
  try
    Result := (dlg.ShowModal() = mrYes);
  finally
    dlg.Free();
  end;
end;

function FtConfirmWithVerification(const ATitle, AInstruction, AMessage, AVerificationText: string;
  var AVerificationChecked: Boolean): Boolean;
var
  dlg: TFtMessageDialog;
  res: Integer;
begin
  dlg := TFtMessageDialog.Create(ATitle, AInstruction, AMessage, fmdQuestion, fmbYesNo);
  try
    dlg.VerificationText := AVerificationText;
    dlg.VerificationChecked := AVerificationChecked;
    res := dlg.ShowModal();
    AVerificationChecked := dlg.VerificationChecked;
    Result := (res = mrYes);
  finally
    dlg.Free();
  end;
end;

end.
