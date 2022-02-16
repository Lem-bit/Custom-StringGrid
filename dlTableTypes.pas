unit dlTableTypes;

interface

uses SysUtils, System.Types, Windows, Graphics;

{
  ====================================================
  = TableViewer                                      =
  =                                                  =
  = Author  : Ansperi L.L., 2022                     =
  = Email   : gui_proj@mail.ru                       =
  =                                                  =
  ====================================================
}

const DRAW_OFFSET_CELL  = 1;
      DRAW_OFFSET_IMAGE = 2; //Разделитель картинки и текста

type
  TTableViewProcAddColumn = procedure() of Object;

  TFontAlign = (alfNone, alfTop, alfBottom, alfCenter, alfRight, alfVertCenter, alfFullCenter);
  TFontObject = class
    strict private
      FSize     : Integer;
      FAlign    : Cardinal;
      FUserAlign: TFontAlign;
      FColor    : TColor;
      FStyle    : TFontStyles;
      FName     : String;
    strict private
      procedure SetAlign(AAlign: TFontAlign);
    public
      constructor Create;
      function GetWinAlign: Cardinal;
    public
      property Align: TFontAlign  read FUserAlign write SetAlign;
      property Color: TColor      read FColor     write FColor;
      property Style: TFontStyles read FStyle     write FStyle;
      property Size : Integer     read FSize      write FSize;
      property Name : String      read FName      write FName;
  end;

  TPenObject = class
    strict private
      FColor: TColor;
    public
      property Color: TColor read FColor write FColor;
  end;

  TOffset = record
    strict private
      FX: Integer;
      FY: Integer;
    strict private
      procedure SetY(AY: Integer);
      procedure SetX(AX: Integer);
    public
      procedure SetXY(AX, AY: Integer);
    public
      property X: Integer read FX write SetX;
      property Y: Integer read FY write SetY;
  end;

  TImageAlign  = (ialLeft, ialCenter, ialRight);
  TImageObject = class
    strict private
      FBitmap: TBitmap;
      FAlign : TImageAlign;
      FOffset: TOffset;
    public
      constructor Create;
      destructor Destroy; override;

      procedure LoadFromFile(AFileName: String);
      procedure SetSize(AWidth, AHeight: Integer);
    public
      property Bitmap: TBitmap     read FBitmap write FBitmap;
      property Align : TImageAlign read FAlign  write FAlign;
      property Offset: TOffset     read FOffset write FOffset;
  end;

  TTableAction = class
    strict private
      FEnable  : Boolean;
      FTimer   : Cardinal;
      FInterval: Cardinal;
    public
      constructor Create;
      procedure ResetTimer;
      procedure SetCurrentTime;
    public
      property Enable  : Boolean  read FEnable   write FEnable;
      property Timer   : Cardinal read FTimer    write FTimer;
      property Interval: Cardinal read FInterval write FInterval;
  end;

  TItemObject = class;
  TTableProcOnAction = procedure (Sender: TItemObject) of Object;
  TTableProcOnDraw   = procedure (AItem: TItemObject; ACanvas: TCanvas; ARect: TRect) of Object;
  TItemObjectFlag = (
     ofSelfOffset  //Если объект выбран то использовать Offset из своих параметров
  );
  TItemObjectFlagSet = Set of TItemObjectFlag;
  TItemObject = class
    strict private
      FText      : String;       //Текст
      FFont      : TFontObject;  //Шрифт
      FColor     : TColor;       //Цвет фоновый
      FPen       : TPenObject;   //Параметры прорисовки
      FImage     : TImageObject; //Изображение
      FTextOffset: TOffset;      //Сдвиг изображения
      FAction    : TTableAction; //Действие по времени

      FArguments : TItemObjectFlagSet; //Флаги объекта
    strict private
      procedure DoTimer;
      function SetRectOffset(ARect: TRect; AOffset: Integer): TRect;

      function DrawImage(ACanvas: TCanvas; ARect: TRect): Integer;
      procedure DrawItem(ACanvas: TCanvas; ARect: TRect);
      procedure DrawCustom(ACanvas: TCanvas; ARect: TRect; ACustomProp: TItemObject);
    public
      constructor Create(const AText: String);
      destructor Destroy; override;

      procedure Draw(ACanvas: TCanvas; ARect: TRect; ACustomProp: TItemObject = nil); virtual;

      procedure SetArgs(AArgSet: TItemObjectFlagSet);
      procedure RemoveArgs(AArgSet: TItemObjectFlagSet);
    public
      OnAction        : TTableProcOnAction; //
      OnBeforeDraw    : TTableProcOnDraw;   //Вызывается до прорисовки
      OnAfterDraw     : TTableProcOnDraw;   //Вызывается после прорисовки
      OnCustomDraw    : TTableProcOnDraw;   //Своя прорисовка, перекрывает текущую
      OnBeforeDrawText: TTableProcOnDraw;   //Вызывается перед прорисовкой текста
    public
      property FontItem  : TFontObject        read FFont       write FFont;
      property Color     : TColor             read FColor      write FColor;
      property Pen       : TPenObject         read FPen        write FPen;
      property Image     : TImageObject       read FImage      write FImage;
      property Action    : TTableAction       read FAction     write FAction;
      property TextOffset: TOffset            read FTextOffset write FTextOffset;
      property Text      : String             read FText       write FText;
      property Args      : TItemObjectFlagSet read FArguments  write FArguments;
  end;

  TTableSelectProp = class(TItemObject);

implementation

{ TItemObject }

constructor TItemObject.Create(const AText: String);
begin
  FFont      := TFontObject.Create;
  FPen       := TPenObject.Create;
  FImage     := TImageObject.Create;
  FAction    := TTableAction.Create;

  FColor     := clWhite;
  FPen.Color := clBlack;
  FText      := AText;
end;

destructor TItemObject.Destroy;
begin
  if Assigned(FFont) then
    FreeAndNil(FFont);

  if Assigned(FPen) then
    FreeAndNil(FPen);

  if Assigned(FImage) then
    FreeAndNil(FImage);

  if Assigned(FAction) then
    FreeAndNil(FAction);

  inherited;
end;

function TItemObject.DrawImage(ACanvas: TCanvas; ARect: TRect): Integer;
var X, Y: Integer;
begin
  Result:= 0;
  X:= 0;
  Y:= 0;

  if not Assigned(Image.Bitmap) then
    Exit;

  case Image.Align of
    ialLeft  : begin
      X:= ARect.Left + Image.Offset.X;
      Y:= ARect.Top  + Image.Offset.Y;
      Result:= Image.Bitmap.Width;
    end;

    ialCenter: begin
      X:= ARect.CenterPoint.X + Image.Offset.X;
      Y:= ARect.Top  + Image.Offset.Y;
      Result:= 0;
    end;

    ialRight : begin
      X:= ARect.Right - Image.Bitmap.Width + Image.Offset.X;
      Y:= ARect.Top  + Image.Offset.Y;
      Result:= 0;
    end;
  end;

  ACanvas.Draw(X, Y, Image.Bitmap);
end;

procedure TItemObject.DrawItem(ACanvas: TCanvas; ARect: TRect);
var PTextRect: TRect;
    PPenRect : TRect;
begin
  with ACanvas do
  begin
    Brush.Color:= Color;
    FillRect(ARect);

    //Рамка
    PPenRect := SetRectOffset(ARect, DRAW_OFFSET_CELL);
    Pen.Color:= Self.Pen.Color;
    Rectangle(PPenRect);

    //Настройки шрифта
    Font.Color:= FontItem.Color;
    Font.Style:= FontItem.Style;
    Font.Size := FontItem.Size;
    Font.Name := FontItem.Name;

    if Assigned(OnBeforeDrawText) then
      OnBeforeDrawText(Self, ACanvas, ARect);

    //Вывод текста
    SetBkMode(Handle, TRANSPARENT);
    PTextRect     := ARect;
    PTextRect.Left:= PTextRect.Left + TextOffset.X;
    PTextRect.Top := PTextRect.Top  + TextOffset.Y;

    //Изображение
    var WImage:= DrawImage(ACanvas, ARect);
    if WImage > 0 then
      PTextRect.Left:= PTextRect.Left + WImage + DRAW_OFFSET_IMAGE;

    DrawText(Handle, PChar(Text), Length(Text), PTextRect, FontItem.GetWinAlign{ or DT_WORD_ELLIPSIS or DT_NOCLIP});
  end;
end;

procedure TItemObject.DrawCustom(ACanvas: TCanvas; ARect: TRect; ACustomProp: TItemObject);
var PTextRect: TRect;
    PPenRect : TRect;
begin
  with ACanvas do
  begin
    //Настройки цвета фона
    Brush.Color:= ACustomProp.Color;
    FillRect(ARect);

    //Рамка
    PPenRect := SetRectOffset(ARect, DRAW_OFFSET_CELL);
    Pen.Color:= ACustomProp.Pen.Color;
    Rectangle(PPenRect);

    //Настройки шрифта
    Font.Color:= ACustomProp.FontItem.Color;
    Font.Style:= ACustomProp.FontItem.Style;
    Font.Size := ACustomProp.FontItem.Size;
    Font.Name := ACustomProp.FontItem.Name;

    if Assigned(OnBeforeDrawText) then
      OnBeforeDrawText(Self, ACanvas, ARect);

    //Вывод текста
    SetBkMode(Handle, TRANSPARENT);
    PTextRect:= ARect;

    if ofSelfOffset in FArguments then
    begin
      PTextRect.Left:= PTextRect.Left + TextOffset.X;
      PTextRect.Top := PTextRect.Top  + TextOffset.Y;
    end
    else
    begin
      PTextRect.Left:= PTextRect.Left + ACustomProp.TextOffset.X;
      PTextRect.Top := PTextRect.Top  + ACustomProp.TextOffset.Y;
    end;

    //Изображение
    var WImage:= DrawImage(ACanvas, ARect);
    if WImage > 0 then
      PTextRect.Left:= PTextRect.Left + WImage + DRAW_OFFSET_IMAGE;

    DrawText(Handle, Text, Length(Text), PTextRect, ACustomProp.FontItem.GetWinAlign or DT_WORD_ELLIPSIS or DT_NOCLIP or DT_SINGLELINE  );
  end;
end;

procedure TItemObject.Draw(ACanvas: TCanvas; ARect: TRect;
  ACustomProp: TItemObject);
begin
  if not Assigned(ACanvas) then
    Exit;

  if Assigned(OnBeforeDraw) then
    OnBeforeDraw(Self, ACanvas, ARect);

  if Assigned(OnCustomDraw) then
    OnCustomDraw(Self, ACanvas, ARect)
  else
    if Assigned(ACustomProp) then
      DrawCustom(ACanvas, ARect, ACustomProp)
    else
      DrawItem(ACanvas, ARect);

  if Assigned(OnAfterDraw) then
    OnAfterDraw(Self, ACanvas, ARect);

  DoTimer;
end;

procedure TItemObject.RemoveArgs(AArgSet: TItemObjectFlagSet);
begin
  FArguments:= FArguments - AArgSet;
end;

procedure TItemObject.SetArgs(AArgSet: TItemObjectFlagSet);
begin
  FArguments:= FArguments + AArgSet;
end;

function TItemObject.SetRectOffset(ARect: TRect; AOffset: Integer): TRect;
begin
  Result.Left  := ARect.Left   - AOffset;
  Result.Right := ARect.Right  + AOffset;
  Result.Top   := ARect.Top    - AOffset;
  Result.Bottom:= ARect.Bottom + AOffset;
end;

procedure TItemObject.DoTimer;
begin
  if not Assigned(FAction) then
    Exit;

  if not Action.Enable then
    Exit;

  if GetCurrentTime - Action.Timer < Action.Interval then
    Exit;

  Action.Timer := GetCurrentTime;

  if Assigned(OnAction) then
    OnAction(Self);
end;

{ TFontObject }

constructor TFontObject.Create;
begin
  Color:= clBlack;
  Style:= [];
  Align:= alfNone;
  Size := 8;
  Name := 'Tahoma';
end;

function TFontObject.GetWinAlign: Cardinal;
begin
  Result:= FAlign;
end;

procedure TFontObject.SetAlign(AAlign: TFontAlign);
begin
  case AAlign of
    alfNone      : FAlign:= 0;
    alfTop       : FAlign:= DT_TOP;
    alfBottom    : FAlign:= DT_BOTTOM;
    alfCenter    : FAlign:= DT_CENTER;
    alfRight     : FAlign:= DT_RIGHT;
    alfVertCenter: FAlign:= DT_VCENTER or DT_SINGLELINE;
    alfFullCenter: FAlign:= DT_CENTER or DT_VCENTER or DT_SINGLELINE;
  end;

  FUserAlign:= AAlign;
end;

{ TAnimation }

constructor TTableAction.Create;
begin
  FInterval:= 100;
  FTimer   := 0;
  FEnable  := False;
end;

procedure TTableAction.ResetTimer;
begin
  Timer:= 0;
end;

procedure TTableAction.SetCurrentTime;
begin
  Timer:= GetCurrentTime;
end;

{ TImageObject }

constructor TImageObject.Create;
begin
  FBitmap:= nil;
  FAlign := ialLeft;
end;

destructor TImageObject.Destroy;
begin
  if Assigned(FBitmap) then
    FreeAndNil(FBitmap);

  inherited;
end;

procedure TImageObject.LoadFromFile(AFileName: String);
begin
  if not FileExists(AFileName) then
    Exit;

  if not Assigned(FBitmap) then
    FBitmap:= TBitmap.Create;

  FBitmap.LoadFromFile(AFileName);
end;

procedure TImageObject.SetSize(AWidth, AHeight: Integer);
begin
  if not Assigned(FBitmap) then
    Exit;

  if AWidth > 0 then
    FBitmap.Width:= AWidth;

  if AHeight > 0 then
    FBitmap.Height:= AHeight;
end;

{ TOffset }

procedure TOffset.SetX(AX: Integer);
begin
  FX:= AX;
end;

procedure TOffset.SetXY(AX, AY: Integer);
begin
  SetX(AX);
  SetY(AY);
end;

procedure TOffset.SetY(AY: Integer);
begin
  FY:= AY;
end;

end.
