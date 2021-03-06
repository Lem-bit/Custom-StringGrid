unit dlTableColumns;

interface

uses SysUtils, Classes, Graphics, Windows, Grids, dlTableTypes;

{
  ====================================================
  = TableViewer                                      =
  =                                                  =
  = Author  : Ansperi L.L., 2022                     =
  = Email   : gui_proj@mail.ru                       =
  =                                                  =
  ====================================================
}

const DEF_COLUMN_HEIGHT = 22;
      DEF_COLUMN_WIDTH  = 50;

type
  TTableColumn = class(TItemObject)
    strict private
      FHide    : Boolean; //Скрыть столбец
      FAutoSize: Boolean; //Авто размер столбца
      FWidth   : Integer; //Ширина столбца
    strict private
      procedure SetWidth(AValue: Integer);
    public
      constructor Create(const AText: String);
    public
      property AutoSize: Boolean read FAutoSize write FAutoSize;
      property Hide    : Boolean read FHide     write FHide;
      property Width   : Integer read FWidth    write SetWidth;
  end;

  TTableColumnList = class
    strict private
      FItem   : TList;     //Список колонок
      FVisible: Boolean;   //Показывать заголовок или нет
      FHeight : Integer;   //Высота ячеек
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
      property Height: Integer read FHeight write FHeight;
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
  FItem  := TList.Create;
  FHeight:= DEF_COLUMN_HEIGHT;
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
    Item     : TTableColumn;
begin
  MaxWidth := ARect.Width;
  CAutoSize:= 0;
  WDSize   := 0;

  for i := 0 to FItem.Count - 1 do
  begin
    Item:= TTableColumn(FItem.Items[i]);

    if Item.Hide then
      Continue;

    if Item.AutoSize then
      Inc(CAutoSize, 1)
    else
      Inc(WDSize, Item.Width);
  end;

  if (CAutoSize = 0) or ((MaxWidth - WDSize) < 0) then
    Exit;

  CalcWidth:= ((MaxWidth - WDSize) div CAutoSize) - (FItem.Count + 1);
  if CalcWidth < 2 then
    CalcWidth:= 2;

  for i := 0 to FItem.Count - 1 do
  begin
    Item:= TTableColumn(FItem.Items[i]);
    if not Item.AutoSize then
      Continue;

    Item.Width:= CalcWidth;
  end;
end;

{ TTableColumn }

constructor TTableColumn.Create(const AText: String);
begin
  inherited Create(AText);
  Width   := DEF_COLUMN_WIDTH;
  AutoSize:= False;
  Hide    := False;
  Color   := clSilver;
  TextOffset.SetXY(1, 1);
end;

procedure TTableColumn.SetWidth(AValue: Integer);
begin
  FWidth:= AValue;
end;

end.
