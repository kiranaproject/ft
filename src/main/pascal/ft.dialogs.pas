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
  Ft.Window, Ft.Theme, Ft.Icons;

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
    procedure UpdateToolbarIcons();
    procedure UpdateLayout();
    procedure OnWindowResize(Sender: TObject; NewWidth, NewHeight: Integer);
    procedure HandleSplitterChange(Sender: TObject; Position: Double);

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
    class procedure CbEntrySubmit(Sender: Pointer; Text: PChar; UserData: Pointer); cdecl; static;
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

  { ── Right Pane Controls: Navigation header on top of file list ── }
  FBtnBack := TFtButton.Create(FWindow);
  FBtnBack.Caption := '';
  FBtnBack.Hint := 'Go Back';
  FBtnBack.IconPosition := ftbipOnly;
  FBtnBack.IconWidth := 16;
  FBtnBack.IconHeight := 16;
  FBtnBack.LoadIconFromSVG(GetNavBackSvg(FtGetDarkMode()));
  FBtnBack.OnClick := @CbBtnBack;
  FBtnBack.UserData := Self;

  FBtnForward := TFtButton.Create(FWindow);
  FBtnForward.Caption := '';
  FBtnForward.Hint := 'Go Forward';
  FBtnForward.IconPosition := ftbipOnly;
  FBtnForward.IconWidth := 16;
  FBtnForward.IconHeight := 16;
  FBtnForward.LoadIconFromSVG(GetNavForwardSvg(FtGetDarkMode()));
  FBtnForward.OnClick := @CbBtnForward;
  FBtnForward.UserData := Self;

  FBtnUp := TFtButton.Create(FWindow);
  FBtnUp.Caption := '';
  FBtnUp.Hint := 'Go Up';
  FBtnUp.IconPosition := ftbipOnly;
  FBtnUp.IconWidth := 16;
  FBtnUp.IconHeight := 16;
  FBtnUp.LoadIconFromSVG(GetNavUpSvg(FtGetDarkMode()));
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
  FBtnHidden.LoadIconFromSVG(GetHiddenSvg(FtGetDarkMode()));
  FBtnHidden.OnToggle := @CbBtnHidden;
  FBtnHidden.UserData := Self;

  FBtnNewFolder := TFtButton.Create(FWindow);
  FBtnNewFolder.Caption := '';
  FBtnNewFolder.Hint := 'New Folder';
  FBtnNewFolder.IconPosition := ftbipOnly;
  FBtnNewFolder.IconWidth := 16;
  FBtnNewFolder.IconHeight := 16;
  FBtnNewFolder.LoadIconFromSVG(GetNewFolderSvg(FtGetDarkMode()));
  FBtnNewFolder.OnClick := @CbBtnNewFolder;
  FBtnNewFolder.UserData := Self;

  FPathBar := TFtPathBar.Create(FWindow, FCurrentDir);
  FPathBar.OnNavigate := @CbPathBarNavigate;
  FPathBar.UserData := Self;

  { ── File Name input (also on the right, on top of file list) ── }
  FLabelName := TFtLabel.Create(FWindow);
  case FDialogType of
    fdtSaveFile:     FLabelName.Text := 'Save as:';
    fdtSelectFolder: FLabelName.Text := 'Folder:';
    else             FLabelName.Text := 'File name:';
  end;

  FEntryName := TFtEntry.Create(FWindow, FDefaultName);
  FEntryName.OnSubmit := @CbEntrySubmit;
  FEntryName.UserData := Self;

  { ── File Table ── }
  FFileTable := TFtTable.Create(FWindow);
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

  { ── Bottom bar ── }
  FBtnCancel := TFtButton.Create(FWindow);
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.OnClick := @CbBtnCancel;
  FBtnCancel.UserData := Self;

  FBtnAction := TFtButton.Create(FWindow);
  FBtnAction.Caption := actionCaption;
  FBtnAction.OnClick := @CbBtnAction;
  FBtnAction.UserData := Self;

  { Filter row }
  FLabelType := TFtLabel.Create(FWindow);
  FLabelType.Text := 'Files of type:';
  FLabelType.Visible := False;

  FCmbFilter := TFtComboBox.Create(FWindow);
  FCmbFilter.Visible := False;
  FCmbFilter.AddItem('All Files (*.*)');

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
  homeDir: string;
  node: TFtTreeNode;
  buf: PChar;
  i: Integer;

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
  if Assigned(FPlacesTree.Root) then
  begin
    for i := 0 to FPlacesTree.Root.ChildCount - 1 do
    begin
      node := FPlacesTree.Root.Children[i];
      if Assigned(node) and Assigned(node.Data) then
      begin
        FreeMem(node.Data);
        node.Data := nil;
      end;
    end;
  end;
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
  AddPlace('File System', '/', FIconDrive);

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

  { 3. Right Pane Controls (placed on top of the file list) }
  contentX := sidebarW + Round(FSplitter.SplitterSize) + 8;
  contentW := W - contentX - MARGIN_X;
  if contentW < 200 then contentW := 200;

  { Row 1: Navigation & Actions toolbar }
  FBtnBack.X      := contentX;
  FBtnBack.Y      := 10;
  FBtnBack.Width  := 30;
  FBtnBack.Height := 30;

  FBtnForward.X   := contentX + 34;
  FBtnForward.Y   := 10;
  FBtnForward.Width := 30;
  FBtnForward.Height := 30;

  FBtnUp.X        := contentX + 68;
  FBtnUp.Y        := 10;
  FBtnUp.Width    := 30;
  FBtnUp.Height   := 30;

  FBtnHidden.X    := W - MARGIN_X - 30;
  FBtnHidden.Y    := 10;
  FBtnHidden.Width := 30;
  FBtnHidden.Height := 30;

  FBtnNewFolder.X := FBtnHidden.X - 34;
  FBtnNewFolder.Y := 10;
  FBtnNewFolder.Width := 30;
  FBtnNewFolder.Height := 30;

  FPathBar.X      := contentX + 104;
  FPathBar.Y      := 10;
  FPathBar.Width  := (FBtnNewFolder.X - 8) - FPathBar.X;
  FPathBar.Height := 30;

  { Row 2: File Name input on top of file list }
  FLabelName.X    := contentX;
  FLabelName.Y    := 50;
  FLabelName.Width := 76;
  FLabelName.Height := 24;

  FEntryName.X    := contentX + 80;
  FEntryName.Y    := 46;
  FEntryName.Width := (W - MARGIN_X) - FEntryName.X;
  FEntryName.Height := 30;

  { Row 3: File Table }
  tableY := 84;
  bottomBarH := 46;
  tableH := (H - bottomBarH) - tableY;
  if tableH < 100 then tableH := 100;

  FFileTable.X      := contentX;
  FFileTable.Y      := tableY;
  FFileTable.Width  := contentW;
  FFileTable.Height := tableH;

  { Row 4: Bottom bar (macOS style: Cancel on left, Primary Action on right) }
  FBtnAction.X := W - MARGIN_X - 84;
  FBtnAction.Y := H - bottomBarH + 7;
  FBtnAction.Width := 84;
  FBtnAction.Height := 30;

  FBtnCancel.X := FBtnAction.X - 10 - 80;
  FBtnCancel.Y := H - bottomBarH + 7;
  FBtnCancel.Width := 80;
  FBtnCancel.Height := 30;

  if Assigned(FCmbFilter) and FCmbFilter.Visible then
  begin
    FLabelType.X := contentX;
    FLabelType.Y := H - bottomBarH + 11;
    FLabelType.Width := 76;
    FLabelType.Height := 24;

    FCmbFilter.X := contentX + 80;
    FCmbFilter.Y := H - bottomBarH + 7;
    FCmbFilter.Width := (FBtnCancel.X - 16) - FCmbFilter.X;
    FCmbFilter.Height := 30;
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

end.
