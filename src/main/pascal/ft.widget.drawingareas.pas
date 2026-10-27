unit Ft.Widget.DrawingAreas;

// Ft.Widget.DrawingAreas
// =======================
// Generic custom drawing area widget for Floria Toolkit.
// Designed for custom rendering engines (creative apps, vector editors,
// digital painting, game viewports, audio visualizers, and CAD viewports).
// Provides direct subpixel canvas painting and unified mouse/wheel/key events.

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  Ft.Canvas,
  Ft.Widget;

type
  TFtDrawingArea = class;

  { Callback types for DrawingArea }
  TFtDrawingPaintCallback = procedure(Sender: TFtWidget; Canvas: TFtCanvas; UserData: Pointer); cdecl;
  TFtDrawingMouseEvent = procedure(Sender: TFtWidget; X, Y: Integer; Button: Integer; UserData: Pointer); cdecl;
  TFtDrawingMouseMoveEvent = procedure(Sender: TFtWidget; X, Y: Integer; UserData: Pointer); cdecl;
  TFtDrawingWheelEvent = procedure(Sender: TFtWidget; X, Y: Integer; DeltaX, DeltaY: Integer; UserData: Pointer); cdecl;
  TFtDrawingKeyEvent = procedure(Sender: TFtWidget; KeySym: Cardinal; State: Cardinal; UserData: Pointer); cdecl;
  TFtDrawingResizeEvent = procedure(Sender: TFtWidget; NewWidth, NewHeight: Integer; UserData: Pointer); cdecl;

  { TFtDrawingArea }
  TFtDrawingArea = class(TFtWidget)
  private
    FCursor: Integer;
    FClipToBounds: Boolean;
    FUserData: Pointer;

    FOnPaint: TFtDrawingPaintCallback;
    FOnMouseDown: TFtDrawingMouseEvent;
    FOnMouseUp: TFtDrawingMouseEvent;
    FOnMouseMove: TFtDrawingMouseMoveEvent;
    FOnMouseWheel: TFtDrawingWheelEvent;
    FOnMouseEnter: TFtDrawingMouseMoveEvent;
    FOnMouseLeave: TFtDrawingMouseMoveEvent;
    FOnKeyDown: TFtDrawingKeyEvent;
    FOnKeyUp: TFtDrawingKeyEvent;
    FOnResize: TFtDrawingResizeEvent;
  protected
    function GetElementType(): string; override;
  public
    constructor Create(AParent: TFtWidget); override;
    destructor Destroy(); override;

    procedure Draw(Canvas: TFtCanvas); override;
    function GetCursor(): Integer; override;

    procedure MouseDown(AX, AY: Integer; AButton: Integer); override;
    procedure MouseUp(AX, AY: Integer; AButton: Integer); override;
    procedure MouseMove(AX, AY: Integer); override;
    procedure MouseEnter(); override;
    procedure MouseLeave(); override;
    procedure KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string); override;
    procedure KeyUp(AKeySym: Cardinal; AState: Cardinal); override;

    procedure Resize(AWidth, AHeight: Integer); virtual;
    procedure SetBounds(AX, AY, AW, AH: Integer); override;

    property Cursor: Integer read FCursor write FCursor;
    property ClipToBounds: Boolean read FClipToBounds write FClipToBounds;
    property UserData: Pointer read FUserData write FUserData;

    property OnPaint: TFtDrawingPaintCallback read FOnPaint write FOnPaint;
    property OnMouseDown: TFtDrawingMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp: TFtDrawingMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseMove: TFtDrawingMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseWheel: TFtDrawingWheelEvent read FOnMouseWheel write FOnMouseWheel;
    property OnMouseEnter: TFtDrawingMouseMoveEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TFtDrawingMouseMoveEvent read FOnMouseLeave write FOnMouseLeave;
    property OnKeyDown: TFtDrawingKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyUp: TFtDrawingKeyEvent read FOnKeyUp write FOnKeyUp;
    property OnResize: TFtDrawingResizeEvent read FOnResize write FOnResize;
  end;

implementation

constructor TFtDrawingArea.Create(AParent: TFtWidget);
begin
  inherited Create(AParent);
  FCursor := FT_CURSOR_DEFAULT;
  FClipToBounds := True;
  FFocusable := False;
  FUserData := nil;

  FOnPaint := nil;
  FOnMouseDown := nil;
  FOnMouseUp := nil;
  FOnMouseMove := nil;
  FOnMouseWheel := nil;
  FOnMouseEnter := nil;
  FOnMouseLeave := nil;
  FOnKeyDown := nil;
  FOnKeyUp := nil;
  FOnResize := nil;
end;

destructor TFtDrawingArea.Destroy();
begin
  inherited Destroy();
end;

function TFtDrawingArea.GetElementType(): string;
begin
  Result := 'drawingarea';
end;

function TFtDrawingArea.GetCursor(): Integer;
begin
  Result := FCursor;
end;

procedure TFtDrawingArea.Resize(AWidth, AHeight: Integer);
begin
  if (Width <> AWidth) or (Height <> AHeight) then
  begin
    Width := AWidth;
    Height := AHeight;
    Invalidate();
    if Assigned(FOnResize) then
      FOnResize(Self, Width, Height, FUserData);
  end;
end;

procedure TFtDrawingArea.SetBounds(AX, AY, AW, AH: Integer);
var
  sizeChanged: Boolean;
begin
  sizeChanged := (Width <> AW) or (Height <> AH);
  inherited SetBounds(AX, AY, AW, AH);
  if sizeChanged and Assigned(FOnResize) then
    FOnResize(Self, Width, Height, FUserData);
end;

procedure TFtDrawingArea.Draw(Canvas: TFtCanvas);
begin
  if not Visible or not Assigned(Canvas) then Exit;

  if FClipToBounds then
    Canvas.PushClipRect(X, Y, Width, Height);
  try
    if Assigned(FOnPaint) then
      FOnPaint(Self, Canvas, FUserData);
  finally
    if FClipToBounds then
      Canvas.PopClipRect();
  end;
end;

procedure TFtDrawingArea.MouseDown(AX, AY: Integer; AButton: Integer);
var
  relX, relY: Integer;
  deltaX, deltaY: Integer;
begin
  relX := AX - X;
  relY := AY - Y;

  // Handle standard X11 scroll wheel buttons (4=Up, 5=Down, 6=Left, 7=Right)
  // Consume the wheel event here so it does not scroll ancestor containers
  if AButton in [4, 5, 6, 7] then
  begin
    if Assigned(FOnMouseWheel) then
    begin
      deltaX := 0;
      deltaY := 0;
      case AButton of
        4: deltaY := 1;
        5: deltaY := -1;
        6: deltaX := -1;
        7: deltaX := 1;
      end;
      FOnMouseWheel(Self, relX, relY, deltaX, deltaY, FUserData);
    end;
    Exit;
  end;

  inherited MouseDown(AX, AY, AButton);

  if FFocusable then
    SetFocus();

  if Assigned(FOnMouseDown) then
    FOnMouseDown(Self, relX, relY, AButton, FUserData);
end;

procedure TFtDrawingArea.MouseUp(AX, AY: Integer; AButton: Integer);
var
  relX, relY: Integer;
begin
  inherited MouseUp(AX, AY, AButton);

  if AButton in [4, 5, 6, 7] then Exit;

  relX := AX - X;
  relY := AY - Y;

  if Assigned(FOnMouseUp) then
    FOnMouseUp(Self, relX, relY, AButton, FUserData);
end;

procedure TFtDrawingArea.MouseMove(AX, AY: Integer);
var
  relX, relY: Integer;
begin
  inherited MouseMove(AX, AY);

  relX := AX - X;
  relY := AY - Y;

  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self, relX, relY, FUserData);
end;

procedure TFtDrawingArea.MouseEnter();
begin
  inherited MouseEnter();
  if Assigned(FOnMouseEnter) then
    FOnMouseEnter(Self, 0, 0, FUserData);
end;

procedure TFtDrawingArea.MouseLeave();
begin
  inherited MouseLeave();
  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Self, 0, 0, FUserData);
end;

procedure TFtDrawingArea.KeyDown(AKeySym: Cardinal; AState: Cardinal; const AChar: string);
begin
  inherited KeyDown(AKeySym, AState, AChar);
  if Assigned(FOnKeyDown) then
    FOnKeyDown(Self, AKeySym, AState, FUserData);
end;

procedure TFtDrawingArea.KeyUp(AKeySym: Cardinal; AState: Cardinal);
begin
  inherited KeyUp(AKeySym, AState);
  if Assigned(FOnKeyUp) then
    FOnKeyUp(Self, AKeySym, AState, FUserData);
end;

end.
