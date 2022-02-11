unit dlTableColumns;

interface

uses SysUtils, Classes, Graphics, Windows, dlTableTypes;

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
  TTableColumn = class(TItemObject)
    strict private
      FHide    : Boolean; //Скрыть столбец
      FAutoSize: Boolean; //Авто размер столбца
      FWidth   : Integer; //Ширина столбца
    public
      constructor Create(const AText: String);
    public
      property AutoSize: Boolean read FAutoSize write FAutoSize;
      property Hide    : Boolean read FHide     write FHide;
      property Width   : Integer read FWidth    write FWidth;
  end;

  TTableColumnList = class
    strict private
      FItem   : TList;     //Список колонок
      FVisible: Boolean;   //Показывать заголовок или нет
    strict private
      function At(const AIndex: Integer): Boolean;
      function GetItemCount: Integer;
      function GetItem(AIndex: Integer): TTableColumn;
    public
      OnAddColumn: TTableViewProcAddColumn;
    public
      constructor Create;
      destructor Destroy; override;

      function Add(const Text: String): TTableColumn;
      procedure Resize(ARect: TRect);
    public
      property Count: Integer read GetItemCount;
      property Visible: Boolean read FVisible write FVisible;
      property Item[index: integer]: TTableColumn read GetItem;
  end;

implementation

{ TTableColumnList }

function TTableColumnList.Add(const Text: String): TTableColumn;
begin
  if Assigned(OnAddColumn) then
    OnAddColumn;

  Result:= TTableColumn.Create(Text);
  FItem.Add(Result);
end;

constructor TTableColumnList.Create;
begin
  FItem:= TList.Create;
end;

destructor TTableColumnList.Destroy;
var i: integer;
begin
  if Assigned(FItem) then
  begin
    for i := 0 to FItem.Count - 1 do
     if Assigned(TTableColumn(FItem.Items[i])) then
       TTableColumn(FItem.Items[i]).Free;

    FreeAndNil(FItem);
  end;

  inherited;
end;

function TTableColumnList.At(const AIndex: Integer): Boolean;
begin
  Result:= not ( (FItem = nil) or (AIndex < 0) or (AIndex > FItem.Count - 1) );
end;

function TTableColumnList.GetItem(AIndex: Integer): TTableColumn;
begin
  Result:= nil;
  if not At(AIndex) then
    Exit;

  Result:= TTableColumn(FItem.Items[AIndex]);
end;

function TTableColumnList.GetItemCount: Integer;
begin
  Result:= -1;
  if Assigned(FItem) then
    Result:= FItem.Count;
end;

procedure TTableColumnList.Resize(ARect: TRect);
var i: integer;
    MaxWidth : Integer;
    CAutoSize: Integer; //Кол-во ячеек с авто шириной
    WDSize   : Integer; //Ширина ячеек не AutoSize
    CalcWidth: Integer; //Ширина
begin
  MaxWidth := ARect.Width;
  CAutoSize:= 0;
  WDSize   := 0;

  for i := 0 to FItem.Count - 1 do
    with TTableColumn(FItem.Items[i]) do
    begin
      if Hide then Continue;

      if AutoSize then
        Inc(CAutoSize, 1)
      else
        Inc(WDSize, Width);
    end;

  if (CAutoSize = 0) or ((MaxWidth - WDSize) < 0) then
    exit;

  CalcWidth:= ((MaxWidth - WDSize) div CAutoSize) - (FItem.Count + 1);
  if CalcWidth < 2 then
    CalcWidth:= 2;

  for i := 0 to FItem.Count - 1 do
    with TTableColumn(FItem.Items[i]) do
     if AutoSize then
       Width:= CalcWidth;

end;

{ TTableColumn }

constructor TTableColumn.Create(const AText: String);
begin
  inherited Create(AText);
  Width   := 50;
  AutoSize:= False;
  Hide    := False;
end;

{procedure TTableColumn.OnAnimation;
begin
  inherited;

  TextOffset.X:= TextOffset.X + 1;
   if TextOffset.X > 100 then
     TextOffset.X:= 0;
end;  }

end.
