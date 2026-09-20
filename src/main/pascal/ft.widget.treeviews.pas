unit Ft.Widget.TreeViews;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math,
  Ft.Bitmap, Ft.Canvas.Agg, Ft.Font, Ft.Widget, Ft.Widget.Containers, Ft.Widget.ScrollBars, Ft.Theme, Ft.Css;

type
  TFtTreeNode = class;
  TFtTreeView = class;

  TFtNodeSelectEvent = procedure(Sender: TObject; Node: TFtTreeNode) of object;
  TFtNodeSelectCallback = procedure(Sender: Pointer; Node: Pointer; UserData: Pointer); cdecl;

  TFtTreeNode = class
  private
    FText: string;
    FData: Pointer;
    FTag: Integer;
    FExpanded: Boolean;
    FIcon: TFtBitmap;
    FParent: TFtTreeNode;
    FChildren: TFPList; // TFtTreeNode
    FTreeView: TFtTreeView;
    function GetChild(AIndex: Integer): TFtTreeNode;
    function GetChildCount(): Integer;
    function GetLevel(): Integer;
  public
    constructor Create(ATreeView: TFtTreeView; AParent: TFtTreeNode = nil); virtual;
    destructor Destroy(); override;

    function AddChild(const AText: string): TFtTreeNode;
    procedure DeleteChild(AIndex: Integer);
    procedure Clear();
    function HasChildren(): Boolean;
    function IndexInParent(): Integer;

    property Text: string read FText write FText;
    property Data: Pointer read FData write FData;
    property Tag: Integer read FTag write FTag;
    property Expanded: Boolean read FExpanded write FExpanded;
    property Icon: TFtBitmap read FIcon write FIcon;
    property Parent: TFtTreeNode read FParent;
    property Level: Integer read GetLevel;
    property ChildCount: Integer read GetChildCount;
    property Children[AIndex: Integer]: TFtTreeNode read GetChild;
    property TreeView: TFtTreeView read FTreeView;
  end;

  TFtTreeView = class(TFtContainer)
  private
    FRoot: TFtTreeNode;
    FVisibleNodes: TFPList; // Flattened visible TFtTreeNode list
    FSelectedNode: TFtTreeNode;
    FHoveredNode: TFtTreeNode;
    FItemHeight: Double;
    FIndentWidth: Double;
    FDestroying: Boolean;
    FOnSelect: TFtNodeSelectEvent;
    FOnSelectCb: TFtNodeSelectCallback;

    procedure SetSelectedNode(AValue: TFtTreeNode);
    procedure SetItemHeight(AValue: Double);
    procedure SetIndentWidth(AValue: Double);
    procedure CollectVisibleNodes(ANode: TFtTreeNode);
    function NodeAtPosition(AY: Integer; out InArrow: Boolean): TFtTreeNode;
  protected
    procedure DrawContent(Canvas: TFtCanvasAgg); override;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;
    function GetElementType(): string; override;

    procedure RebuildVisibleNodes();
    function AddNode(const AText: string; AParentNode: TFtTreeNode = nil): TFtTreeNode;
    procedure Clear();

    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;

    property Root: TFtTreeNode read FRoot;
    property SelectedNode: TFtTreeNode read FSelectedNode write SetSelectedNode;
    property ItemHeight: Double read FItemHeight write SetItemHeight;
    property IndentWidth: Double read FIndentWidth write SetIndentWidth;
    property Destroying: Boolean read FDestroying;
    property OnSelect: TFtNodeSelectEvent read FOnSelect write FOnSelect;
    property OnSelectCb: TFtNodeSelectCallback read FOnSelectCb write FOnSelectCb;
  end;

implementation

{ TFtTreeNode }

constructor TFtTreeNode.Create(ATreeView: TFtTreeView; AParent: TFtTreeNode = nil);
begin
  inherited Create();
  FTreeView := ATreeView;
  FParent := AParent;
  FText := '';
  FData := nil;
  FTag := 0;
  FExpanded := False;
  FIcon := nil;
  FChildren := TFPList.Create();
end;

destructor TFtTreeNode.Destroy();
var
  i: Integer;
begin
  for i := 0 to FChildren.Count - 1 do
    TFtTreeNode(FChildren[i]).Free();
  FChildren.Clear();
  FreeAndNil(FChildren);
  inherited Destroy();
end;

function TFtTreeNode.GetChild(AIndex: Integer): TFtTreeNode;
begin
  if (AIndex >= 0) and (AIndex < FChildren.Count) then
    Result := TFtTreeNode(FChildren[AIndex])
  else
    Result := nil;
end;

function TFtTreeNode.GetChildCount(): Integer;
begin
  Result := FChildren.Count;
end;

function TFtTreeNode.GetLevel(): Integer;
var
  p: TFtTreeNode;
begin
  Result := 0;
  p := FParent;
  while Assigned(p) and (p <> FTreeView.Root) do
  begin
    Inc(Result);
    p := p.Parent;
  end;
end;

function TFtTreeNode.AddChild(const AText: string): TFtTreeNode;
begin
  Result := TFtTreeNode.Create(FTreeView, Self);
  Result.Text := AText;
  FChildren.Add(Result);
  if Assigned(FTreeView) and not FTreeView.Destroying then
    FTreeView.RebuildVisibleNodes();
end;

procedure TFtTreeNode.DeleteChild(AIndex: Integer);
var
  node: TFtTreeNode;
begin
  if (AIndex >= 0) and (AIndex < FChildren.Count) then
  begin
    node := TFtTreeNode(FChildren[AIndex]);
    FChildren.Delete(AIndex);
    node.Free();
    if Assigned(FTreeView) and not FTreeView.Destroying then
      FTreeView.RebuildVisibleNodes();
  end;
end;

procedure TFtTreeNode.Clear();
var
  i: Integer;
begin
  for i := 0 to FChildren.Count - 1 do
    TFtTreeNode(FChildren[i]).Free();
  FChildren.Clear();
  if Assigned(FTreeView) and not FTreeView.Destroying then
    FTreeView.RebuildVisibleNodes();
end;

function TFtTreeNode.HasChildren(): Boolean;
begin
  Result := FChildren.Count > 0;
end;

function TFtTreeNode.IndexInParent(): Integer;
begin
  if Assigned(FParent) then
    Result := FParent.FChildren.IndexOf(Self)
  else
    Result := -1;
end;

{ TFtTreeView }

constructor TFtTreeView.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FDestroying := False;
  FRoot := TFtTreeNode.Create(Self, nil);
  FRoot.Expanded := True;
  FVisibleNodes := TFPList.Create();
  FSelectedNode := nil;
  FHoveredNode := nil;
  FItemHeight := 24.0;
  FIndentWidth := 18.0;
  FFocusable := True;
  FDrawFrame := True;
  FScrollBarMode := ftSbModeAutoBoth;
end;

destructor TFtTreeView.Destroy();
begin
  FDestroying := True;
  FSelectedNode := nil;
  FHoveredNode := nil;
  FreeAndNil(FRoot);
  FreeAndNil(FVisibleNodes);
  inherited Destroy();
end;

function TFtTreeView.GetElementType(): string;
begin
  Result := 'treeview';
end;

procedure TFtTreeView.SetItemHeight(AValue: Double);
begin
  if AValue < 16.0 then AValue := 16.0;
  if FItemHeight <> AValue then
  begin
    FItemHeight := AValue;
    RebuildVisibleNodes();
  end;
end;

procedure TFtTreeView.SetIndentWidth(AValue: Double);
begin
  if AValue < 8.0 then AValue := 8.0;
  if FIndentWidth <> AValue then
  begin
    FIndentWidth := AValue;
    Invalidate();
  end;
end;

procedure TFtTreeView.CollectVisibleNodes(ANode: TFtTreeNode);
var
  i: Integer;
  child: TFtTreeNode;
begin
  for i := 0 to ANode.ChildCount - 1 do
  begin
    child := ANode.Children[i];
    FVisibleNodes.Add(child);
    if child.Expanded and child.HasChildren() then
      CollectVisibleNodes(child);
  end;
end;

procedure TFtTreeView.RebuildVisibleNodes();
begin
  if FDestroying or (FVisibleNodes = nil) or (FRoot = nil) then Exit;
  FVisibleNodes.Clear();
  CollectVisibleNodes(FRoot);
  ContentHeight := FVisibleNodes.Count * FItemHeight;
  Invalidate();
end;

function TFtTreeView.AddNode(const AText: string; AParentNode: TFtTreeNode = nil): TFtTreeNode;
begin
  if not Assigned(AParentNode) then
    AParentNode := FRoot;
  Result := AParentNode.AddChild(AText);
end;

procedure TFtTreeView.Clear();
begin
  FRoot.Clear();
  FSelectedNode := nil;
  FHoveredNode := nil;
  RebuildVisibleNodes();
end;

procedure TFtTreeView.SetSelectedNode(AValue: TFtTreeNode);
begin
  if FSelectedNode <> AValue then
  begin
    FSelectedNode := AValue;
    Invalidate();

    if Assigned(FOnSelect) then
      FOnSelect(Self, FSelectedNode);
    if Assigned(FOnSelectCb) then
      FOnSelectCb(Pointer(Self), Pointer(FSelectedNode), FUserData);
  end;
end;

function TFtTreeView.NodeAtPosition(AY: Integer; out InArrow: Boolean): TFtTreeNode;
var
  relY: Double;
  idx: Integer;
begin
  InArrow := False;
  Result := nil;
  relY := (AY - Y) + FScrollY;
  if relY < 0.0 then Exit;

  idx := Trunc(relY / FItemHeight);
  if (idx >= 0) and (idx < FVisibleNodes.Count) then
    Result := TFtTreeNode(FVisibleNodes[idx]);
end;

procedure TFtTreeView.DrawContent(Canvas: TFtCanvasAgg);
var
  theme: TFtTheme;
  accent: TFtRgbColor;
  i: Integer;
  node: TFtTreeNode;
  nodeY, nodeX: Double;
  viewTop, viewBottom: Double;
  isSelected, isHovered: Boolean;
  arrowCX, arrowCY: Double;
  textR, textG, textB: Double;
  textStartX, iconW, iconH, iconY: Double;
begin
  theme := FtGetTheme();
  accent := theme.GetAccentColor();

  viewTop := FScrollY;
  viewBottom := FScrollY + Height;

  for i := 0 to FVisibleNodes.Count - 1 do
  begin
    node := TFtTreeNode(FVisibleNodes[i]);
    nodeY := Y + (i * FItemHeight) - FScrollY;

    // Viewport culling
    if (nodeY + FItemHeight < Y) or (nodeY > Y + Height) then
      Continue;

    nodeX := X + 8.0 + (node.Level * FIndentWidth);
    isSelected := (node = FSelectedNode);
    isHovered := (node = FHoveredNode);

    // Row selection background
    if isSelected then
    begin
      Canvas.DrawRoundedRect(X + 2.0, nodeY + 1.0, Width - 4.0, FItemHeight - 2.0, 4.0, accent.R, accent.G, accent.B, 0.85);
      textR := 1.0; textG := 1.0; textB := 1.0;
    end
    else if isHovered then
    begin
      if theme.DarkMode then
        Canvas.DrawRoundedRect(X + 2.0, nodeY + 1.0, Width - 4.0, FItemHeight - 2.0, 4.0, 0.25, 0.26, 0.32, 0.6)
      else
        Canvas.DrawRoundedRect(X + 2.0, nodeY + 1.0, Width - 4.0, FItemHeight - 2.0, 4.0, 0.88, 0.90, 0.94, 0.6);
      if theme.DarkMode then
      begin textR := 0.9; textG := 0.9; textB := 0.9; end
      else
      begin textR := 0.1; textG := 0.1; textB := 0.1; end;
    end
    else
    begin
      if theme.DarkMode then
      begin textR := 0.85; textG := 0.85; textB := 0.85; end
      else
      begin textR := 0.15; textG := 0.15; textB := 0.15; end;
    end;

    // Expander triangle arrow
    if node.HasChildren() then
    begin
      arrowCX := nodeX + 4.0;
      arrowCY := nodeY + FItemHeight * 0.5;
      if node.Expanded then
      begin
        // Downward pointing arrow
        Canvas.DrawLine(arrowCX - 4.0, arrowCY - 2.0, arrowCX, arrowCY + 3.0, 1.5, textR, textG, textB, 0.9);
        Canvas.DrawLine(arrowCX, arrowCY + 3.0, arrowCX + 4.0, arrowCY - 2.0, 1.5, textR, textG, textB, 0.9);
      end
      else
      begin
        // Rightward pointing arrow
        Canvas.DrawLine(arrowCX - 2.0, arrowCY - 4.0, arrowCX + 3.0, arrowCY, 1.5, textR, textG, textB, 0.9);
        Canvas.DrawLine(arrowCX + 3.0, arrowCY, arrowCX - 2.0, arrowCY + 4.0, 1.5, textR, textG, textB, 0.9);
      end;
    end;

    // Node icon & text
    textStartX := nodeX + 16.0;
    if Assigned(node.Icon) and (node.Icon.Width > 0) and (node.Icon.Height > 0) then
    begin
      iconH := Min(FItemHeight - 6.0, 16.0);
      iconW := (node.Icon.Width / node.Icon.Height) * iconH;
      iconY := nodeY + (FItemHeight - iconH) * 0.5;
      Canvas.DrawImageScaled(textStartX, iconY, iconW, iconH, node.Icon, 1.0);
      textStartX := textStartX + iconW + 4.0;
    end;

    Canvas.DrawTextLeft(textStartX, nodeY + 2.0, Width - (textStartX + 4.0 - X), FItemHeight - 4.0, node.Text, Font, textR, textG, textB);
  end;
end;

procedure TFtTreeView.MouseDown(AX, AY: Integer; AButton: Integer);
var
  node: TFtTreeNode;
  inArrow: Boolean;
  nodeX: Double;
begin
  inherited MouseDown(AX, AY, AButton);

  if AButton = 1 then
  begin
    node := NodeAtPosition(AY, inArrow);
    if Assigned(node) then
    begin
      nodeX := X + 8.0 + (node.Level * FIndentWidth);
      // Check if click was on arrow (within 16px of node start)
      if node.HasChildren() and (AX >= nodeX - 2.0) and (AX <= nodeX + 14.0) then
      begin
        node.Expanded := not node.Expanded;
        RebuildVisibleNodes();
      end
      else
      begin
        SelectedNode := node;
      end;
    end;
  end;
end;

procedure TFtTreeView.MouseMove(AX, AY: Integer);
var
  node: TFtTreeNode;
  inArrow: Boolean;
begin
  inherited MouseMove(AX, AY);

  node := NodeAtPosition(AY, inArrow);
  if FHoveredNode <> node then
  begin
    FHoveredNode := node;
    Invalidate();
  end;
end;

procedure TFtTreeView.MouseLeave();
begin
  inherited MouseLeave();
  if Assigned(FHoveredNode) then
  begin
    FHoveredNode := nil;
    Invalidate();
  end;
end;

procedure TFtTreeView.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
var
  idx: Integer;
begin
  inherited KeyDown(AKeySym, AState, AChar);

  if not Assigned(FSelectedNode) and (FVisibleNodes.Count > 0) then
  begin
    SelectedNode := TFtTreeNode(FVisibleNodes[0]);
    Exit;
  end;

  idx := FVisibleNodes.IndexOf(FSelectedNode);
  if idx < 0 then Exit;

  // Up Arrow ($FF52): Previous visible node
  if (AKeySym = $FF52) and (idx > 0) then
  begin
    SelectedNode := TFtTreeNode(FVisibleNodes[idx - 1]);
  end
  // Down Arrow ($FF54): Next visible node
  else if (AKeySym = $FF54) and (idx < FVisibleNodes.Count - 1) then
  begin
    SelectedNode := TFtTreeNode(FVisibleNodes[idx + 1]);
  end
  // Right Arrow ($FF53): Expand node or go to first child
  else if AKeySym = $FF53 then
  begin
    if FSelectedNode.HasChildren() then
    begin
      if not FSelectedNode.Expanded then
      begin
        FSelectedNode.Expanded := True;
        RebuildVisibleNodes();
      end
      else if FSelectedNode.ChildCount > 0 then
      begin
        SelectedNode := FSelectedNode.Children[0];
      end;
    end;
  end
  // Left Arrow ($FF51): Collapse node or go to parent
  else if AKeySym = $FF51 then
  begin
    if FSelectedNode.HasChildren() and FSelectedNode.Expanded then
    begin
      FSelectedNode.Expanded := False;
      RebuildVisibleNodes();
    end
    else if Assigned(FSelectedNode.Parent) and (FSelectedNode.Parent <> FRoot) then
    begin
      SelectedNode := FSelectedNode.Parent;
    end;
  end;
end;

end.
