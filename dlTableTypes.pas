unit dlTableTypes;

interface

uses SysUtils, System.Types, Graphics, Windows;

{
  ====================================================
  = TableViewer                                      =
  =                                                  =
  = Author  : Ansperi L.L., 2022                     =
  = Email   : gui_proj@mail.ru                       =
  =                                                  =
  ====================================================
}

type
  TTableViewProcAddColumn = procedure() of Object;

  TFontAlign = (alfNone, alfTop, alfBottom, alfCenter, alfRight, alfVertCenter);
  TFontObject = class
    strict private
      FSize : Integer;
      FAlign: Cardinal;
      FColor: TColor;
      FStyle: TFontStyles;
      FName : String;
    strict private
      procedure SetAlign(AAlign: TFontAlign);
      function GetAlign: TFontAlign;
    public
      constructor Create;
      function GetWinAlign: Cardinal;
    public
      property Align: TFontAlign  read GetAlign write SetAlign;
      property Color: TColor      read FColor   write FColor;
      property Style: TFontStyles read FStyle   write FStyle;
      property Size : Integer     read FSize    write FSize;
      property Name : String      read FName    write FName;
  end;

  TPenObject = class
    strict private
      FColor: TColor;
    public
      property Color: TColor read FColor write FColor;
  end;

  TImageObject = class
    public
  end;

  TTextOffset = class
    strict private
      FX: Integer;
      FY: Integer;
    public
      constructor Create;
    public
      property X: Integer read FX write FX;
      property Y: Integer read FY write FY;
  end;

  TAnimation = class
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
  TTableProcOnAnimation = procedure (Sender: TItemObject) of Object;
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
      FTextOffset: TTextOffset;  //Сдвиг изображения
      FAnimation : TAnimation;   //Анимация чего либо

      FArguments : TItemObjectFlagSet; //Флаги объекта
    strict private
      procedure DoTimer;

      procedure DrawItem(ACanvas: TCanvas; ARect: TRect);
      procedure DrawCustom(ACanvas: TCanvas; ARect: TRect; ACustomProp: TItemObject);
    public
      constructor Create(const AText: String);
      destructor Destroy; override;

      procedure Draw(ACanvas: TCanvas; ARect: TRect; ACustomProp: TItemObject = nil); virtual;

      procedure SetArgs(AArgSet: TItemObjectFlagSet);
      procedure RemoveArgs(AArgSet: TItemObjectFlagSet);
    public
      OnAnimation: TTableProcOnAnimation;
    public
      property FontItem  : TFontObject        read FFont       write FFont;
      property Color     : TColor             read FColor      write FColor;
      property Pen       : TPenObject         read FPen        write FPen;
      property Image     : TImageObject       read FImage      write FImage;
      property Animation : TAnimation         read FAnimation  write FAnimation;
      property TextOffset: TTextOffset        read FTextOffset write FTextOffset;
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
  FTextOffset:= TTextOffset.Create;
  FAnimation := TAnimation.Create;

  FColor     := clWhite;
  FPen.Color := clBlack;
  FText      := AText;
end;

destructor TItemObject.Destroy;
begin
  if Assigned(FFont)       then FreeAndNil(FFont);
  if Assigned(FPen)        then FreeAndNil(FPen);
  if Assigned(FImage)      then FreeAndNil(FImage);
  if Assigned(FAnimation)  then FreeAndNil(FAnimation);
  if Assigned(FTextOffset) then FreeAndNil(FTextOffset);

  inherited;
end;

procedure TItemObject.DrawItem(ACanvas: TCanvas; ARect: TRect);
var PTextRect: TRect;
    PPenRect : TRect;
begin
  with ACanvas do
  begin
    //Настройки цвета фона
    Brush.Color:= Color;
    FillRect(ARect);

    //Рамка
    PPenRect      := ARect;
    PPenRect.Left := PPenRect.Left - 1;
    PPenRect.Right:= PPenRect.Right + 1;
    Pen.Color     := Self.Pen.Color;
    Rectangle(PPenRect);

    //Настройки шрифта
    Font.Color:= FontItem.Color;
    Font.Style:= FontItem.Style;
    Font.Size := FontItem.Size;
    Font.Name := FontItem.Name;

    //Вывод текста
    SetBkMode(Handle, Transparent);
    PTextRect:= ARect;
    PTextRect.Left:= PTextRect.Left + TextOffset.X;
    PTextRect.Top := PTextRect.Top  + TextOffset.Y;
    DrawText(Handle, PChar(Text), Length(Text), PTextRect, FontItem.GetWinAlign or DT_WORD_ELLIPSIS or DT_NOCLIP);
  end;
end;

procedure TItemObject.Draw(ACanvas: TCanvas; ARect: TRect;
  ACustomProp: TItemObject);
begin
  if not Assigned(ACanvas) then
    Exit;

  if Assigned(ACustomProp) then
    DrawCustom(ACanvas, ARect, ACustomProp)
  else
    DrawItem(ACanvas, ARect);

  DoTimer;
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
    PPenRect      := ARect;
    PPenRect.Left := PPenRect.Left - 1;
    PPenRect.Right:= PPenRect.Right + 1;
    Pen.Color     := ACustomProp.Pen.Color;
    Rectangle(PPenRect);

    //Настройки шрифта
    Font.Color:= ACustomProp.FontItem.Color;
    Font.Style:= ACustomProp.FontItem.Style;
    Font.Size := ACustomProp.FontItem.Size;
    Font.Name := ACustomProp.FontItem.Name;

    //Вывод текста
    SetBkMode(Handle, Transparent);
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


    DrawText(Handle, Text, Length(Text), PTextRect, ACustomProp.FontItem.GetWinAlign or DT_WORD_ELLIPSIS or DT_NOCLIP or DT_SINGLELINE  );
  end;
end;

procedure TItemObject.RemoveArgs(AArgSet: TItemObjectFlagSet);
begin
  FArguments:= FArguments - AArgSet;
end;

procedure TItemObject.SetArgs(AArgSet: TItemObjectFlagSet);
begin
  FArguments:= FArguments + AArgSet;
end;

procedure TItemObject.DoTimer;
begin
  if not Assigned(FAnimation) then
    Exit;

  if not Animation.Enable then
    Exit;

  if GetCurrentTime - Animation.Timer < Animation.Interval then
    Exit;

  Animation.Timer := GetCurrentTime;

  if Assigned(OnAnimation) then
    OnAnimation(Self);
end;

{ TTextOffset }

constructor TTextOffset.Create;
begin
  FX:= 1;
  FY:= 1;
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

function TFontObject.GetAlign: TFontAlign;
begin
  Result:= alfNone;

  case FAlign of
    DT_TOP    : Result:= alfTop;
    DT_BOTTOM : Result:= alfBottom;
    DT_CENTER : Result:= alfCenter;
    DT_RIGHT  : Result:= alfRight;
    DT_VCENTER: Result:= alfVertCenter;
  end;
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
    alfVertCenter: FAlign:= DT_VCENTER;
  end;
end;

{ TAnimation }

constructor TAnimation.Create;
begin
  FInterval:= 100;
  FTimer   := 0;
  FEnable  := False;
end;

procedure TAnimation.ResetTimer;
begin
  Timer:= 0;
end;

procedure TAnimation.SetCurrentTime;
begin
  Timer:= GetCurrentTime;
end;

end.
