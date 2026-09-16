unit Ft.Widget.Images;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  Ft.Widget,
  Ft.Canvas.Agg,
  Ft.Bitmap,
  Ft.Theme,
  Ft.Css;

type
  TFtImageScaleMode = (
    ftismFit = 0,     { Aspect fit centered }
    ftismStretch = 1, { Stretch to full widget bounds }
    ftismCenter = 2,  { 1:1 original size centered }
    ftismNone = 3     { 1:1 original size at (0, 0) }
  );

  TFtImage = class(TFtWidget)
  private
    FBitmap: TFtBitmap;
    FOwnsBitmap: Boolean;
    FScaleMode: TFtImageScaleMode;
  public
    constructor Create(AParent: TFtWidget; AX, AY, AW, AH: Integer; const AFilePath: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure LoadFromFile(const AFilePath: string);
    procedure LoadFromMemory(AData: Pointer; ASize: Integer);
    procedure SetBitmap(ABitmap: TFtBitmap; AOwnsBitmap: Boolean = False);

    procedure Draw(ACanvas: TFtCanvasAgg); override;
    function GetElementType(): string; override;

    property Bitmap: TFtBitmap read FBitmap;
    property OwnsBitmap: Boolean read FOwnsBitmap write FOwnsBitmap;
    property ScaleMode: TFtImageScaleMode read FScaleMode write FScaleMode;
  end;

implementation

constructor TFtImage.Create(AParent: TFtWidget; AX, AY, AW, AH: Integer; const AFilePath: string = '');
begin
  inherited Create(AParent);
  X := AX;
  Y := AY;
  Width := AW;
  Height := AH;
  FBitmap := nil;
  FOwnsBitmap := False;
  FScaleMode := ftismFit;

  if AFilePath <> '' then
    LoadFromFile(AFilePath);
end;

destructor TFtImage.Destroy();
begin
  if FOwnsBitmap and Assigned(FBitmap) then
  begin
    FBitmap.Free();
    FBitmap := nil;
  end;
  inherited Destroy();
end;

procedure TFtImage.LoadFromFile(const AFilePath: string);
begin
  if FOwnsBitmap and Assigned(FBitmap) then
    FBitmap.Free();

  FBitmap := TFtBitmap.CreateFromFile(AFilePath);
  FOwnsBitmap := True;
  Invalidate();
end;

procedure TFtImage.LoadFromMemory(AData: Pointer; ASize: Integer);
begin
  if FOwnsBitmap and Assigned(FBitmap) then
    FBitmap.Free();

  FBitmap := TFtBitmap.CreateFromMemory(AData, ASize);
  FOwnsBitmap := True;
  Invalidate();
end;

procedure TFtImage.SetBitmap(ABitmap: TFtBitmap; AOwnsBitmap: Boolean = False);
begin
  if FOwnsBitmap and Assigned(FBitmap) and (FBitmap <> ABitmap) then
    FBitmap.Free();

  FBitmap := ABitmap;
  FOwnsBitmap := AOwnsBitmap;
  Invalidate();
end;

function TFtImage.GetElementType(): string;
begin
  Result := 'image';
end;

procedure TFtImage.Draw(ACanvas: TFtCanvasAgg);
var
  st: TFtWidgetStyle;
  drawX, drawY, drawW, drawH: Double;
  scale, scaleX, scaleY: Double;
  r: Double;
begin
  if not Visible then Exit;

  st := GetResolvedStyle();
  r := st.BorderRadius;

  // Background if styled
  if st.HasBgColor then
  begin
    if r > 0.0 then
      ACanvas.DrawRoundedRect(X, Y, Width, Height, r, st.BgColor.R, st.BgColor.G, st.BgColor.B, 1.0)
    else
      ACanvas.DrawRect(X, Y, Width, Height, st.BgColor.R, st.BgColor.G, st.BgColor.B);
  end;

  if Assigned(FBitmap) and (FBitmap.Width > 0) and (FBitmap.Height > 0) then
  begin
    case FScaleMode of
      ftismStretch:
      begin
        drawX := X;
        drawY := Y;
        drawW := Width;
        drawH := Height;
      end;
      ftismCenter:
      begin
        drawW := FBitmap.Width;
        drawH := FBitmap.Height;
        drawX := X + (Width - drawW) / 2.0;
        drawY := Y + (Height - drawH) / 2.0;
      end;
      ftismNone:
      begin
        drawX := X;
        drawY := Y;
        drawW := FBitmap.Width;
        drawH := FBitmap.Height;
      end;
      else // ftismFit
      begin
        scaleX := Width / FBitmap.Width;
        scaleY := Height / FBitmap.Height;
        if scaleX < scaleY then
          scale := scaleX
        else
          scale := scaleY;
        drawW := FBitmap.Width * scale;
        drawH := FBitmap.Height * scale;
        drawX := X + (Width - drawW) / 2.0;
        drawY := Y + (Height - drawH) / 2.0;
      end;
    end;

    if (Round(drawW) = FBitmap.Width) and (Round(drawH) = FBitmap.Height) then
      ACanvas.DrawImage(drawX, drawY, FBitmap, 1.0)
    else
      ACanvas.DrawImageScaled(drawX, drawY, drawW, drawH, FBitmap, 1.0);
  end;

  // Border outline if styled
  if (st.BorderWidth > 0.0) and st.HasBorderColor then
  begin
    if r > 0.0 then
      ACanvas.DrawRoundedRectOutline(X, Y, Width, Height, r, st.BorderWidth, st.BorderColor.R, st.BorderColor.G, st.BorderColor.B, 1.0)
    else
      ACanvas.DrawRect(Round(X), Round(Y), Width, Round(st.BorderWidth), st.BorderColor.R, st.BorderColor.G, st.BorderColor.B);
  end;

  inherited Draw(ACanvas);
end;

end.
