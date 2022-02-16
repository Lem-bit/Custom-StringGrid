unit dlTableItems;

interface

uses SysUtils, Classes, Grids, dlTableTypes;

{
  ====================================================
  = TableViewer                                      =
  =                                                  =
  = Author  : Ansperi L.L., 2022                     =
  = Email   : gui_proj@mail.ru                       =
  =                                                  =
  ====================================================
}

const DEF_TEXT_OFFSET = 2;
      DEF_ITEM_HEIGHT = 20;

type
  TTableItemFlag    = (
      ifUserSelect //Принудительно выбрать объект
    );
  TTableItemFlagSet = Set of TTableItemFlag;

  TElementObject = class(TItemObject)
    protected
      FSelected: Boolean;           //Выбран объект или нет
      FFlags   : TTableItemFlagSet; //Флаги
    protected
    public
      constructor Create(AText: String);
      destructor Destroy; override;
    public
      property Selected: Boolean           read FSelected write FSelected;
      property Flags   : TTableItemFlagSet read FFlags    write FFlags;
  end;

  TTableItem = class;
  TTableSubItem = class(TElementObject)
    strict private
      FOwner: TTableItem;
    public
      constructor Create(AOwner: TTableItem; AText: String);
      destructor Destroy; override;
    public
      procedure SetFlags(AFlagSet: TTableItemFlagSet); virtual;
      procedure RemoveFlags(AFlagSet: TTableItemFlagSet); virtual;
  end;

  TTableItem = class(TElementObject)
    strict private
      const SELF_INDEX = 0;
    strict private
      FSubItem: TList;
      FHeight : Integer;
    strict private
      function At(const AIndex: Integer): Boolean;
      function Contains(AValue: Integer; AValueList: TArray<integer>): Boolean;
    public
      constructor Create(AText: String);
      destructor Destroy; override;

      procedure SetFlags(AFlagSet: TTableItemFlagSet; AWithSubItems: Boolean = True; AItemIndex: TArray<Integer> = nil);
      procedure RemoveFlags(AFlagSet: TTableItemFlagSet; AWithSubItems: Boolean = True; AItemIndex: TArray<Integer> = nil);
    public
      function GetSubItem(AIndex: Integer): TTableSubItem;
      function Add(const AText: String): TTableSubItem;
    public
      property SubItem[AIndex: Integer]: TTableSubItem read GetSubItem;
      property Height: Integer read FHeight write FHeight;
  end;

  TTableItemList = class
    strict private
      FItem : TList;   //Список элементов
    strict private
      function At(const AIndex: Integer): Boolean;
      function GetItemCount: Integer;
      function GetItem(AIndex: Integer): TTableItem;

      procedure SetCapacity(AValue: Integer);
      function GetCapacity: Integer;
    public
      constructor Create;
      destructor Destroy; override;

      function GetItemObject(AItem, ASubItem: Integer): TElementObject;

      procedure Clear;
    public
      function Add(const Text: String): TTableItem;
      property Count: Integer read GetItemCount;
      property Item[index: integer]: TTableItem read GetItem;

      property Capacity: Integer read GetCapacity write SetCapacity;
  end;

implementation

{ TTableItemList }

function TTableItemList.Add(const Text: String): TTableItem;
begin
  Result:= TTableItem.Create(Text);
  Result.TextOffset.SetXY(DEF_TEXT_OFFSET, 0);
  FItem.Add(Result);
end;

function TTableItemList.At(const AIndex: Integer): Boolean;
begin
  Result:= ( Assigned(FItem) and (AIndex > -1) and (AIndex < FItem.Count) );
end;

procedure TTableItemList.Clear;
begin
  for var i := 0 to FItem.Count - 1 do
    TTableItem(FItem[i]).Free;

  FItem.Clear;
end;

constructor TTableItemList.Create;
begin
  FItem := TList.Create;
end;

destructor TTableItemList.Destroy;
var i: integer;
begin
  if Assigned(FItem) then
  begin
    for i := 0 to FItem.Count - 1 do
      TTableItem(FItem.Items[i]).Free;

    FreeAndNil(FItem);
  end;

  inherited;
end;

function TTableItemList.GetCapacity: Integer;
begin
  Result:= FItem.Capacity;
end;

function TTableItemList.GetItem(AIndex: Integer): TTableItem;
begin
  Result:= nil;
  if not At(AIndex) then
    Exit;

  Result:= FItem.Items[AIndex];
end;

function TTableItemList.GetItemObject(AItem, ASubItem: Integer): TElementObject;
begin
  Result:= GetItem(AItem);
  if not Assigned(Result) then
    Exit;

  if ASubItem > 0 then
    Result:= TTableItem( Result ).GetSubItem(ASubItem - 1);
end;

procedure TTableItemList.SetCapacity(AValue: Integer);
begin
  FItem.Capacity:= AValue;
end;

function TTableItemList.GetItemCount: Integer;
begin
  Result:= -1;
  if Assigned(FItem) then
    Result:= FItem.Count;
end;

{ TTableItem }

function TTableItem.Add(const AText: String): TTableSubItem;
begin
  Result:= TTableSubItem.Create(Self, AText);
  Result.TextOffset.SetXY(DEF_TEXT_OFFSET, 0);
  FSubItem.Add(Result);
end;

function TTableItem.At(const AIndex: Integer): Boolean;
begin
  Result:= Assigned(FSubItem) and (AIndex > -1) and (AIndex < FSubItem.Count);
end;

function TTableItem.Contains(AValue: Integer; AValueList: TArray<integer>): Boolean;
begin
  Result:= False;
  if AValueList = nil then
    Exit;

  for var i := Low(AValueList) to High(AValueList) do
    if AValue = AValueList[i] then
      Exit(True);
end;

constructor TTableItem.Create(AText: String);
begin
  inherited Create(AText);
  FSubItem:= TList.Create;
  FHeight := DEF_ITEM_HEIGHT;
end;

destructor TTableItem.Destroy;
begin
  if Assigned(FSubItem) then
    for var i := 0 to FSubItem.Count - 1 do
      TTableItem(FSubItem[i]).Free;

  FreeAndNil(FSubItem);
  inherited;
end;

function TTableItem.GetSubItem(AIndex: Integer): TTableSubItem;
begin
  Result:= nil;
  if not At(AIndex) then
    Exit;

  Result:= TTableSubItem(FSubItem[AIndex]);
end;

procedure TTableItem.RemoveFlags(AFlagSet: TTableItemFlagSet;
  AWithSubItems: Boolean; AItemIndex: TArray<Integer>);
begin
  if (AItemIndex = nil) or (Contains(SELF_INDEX, AItemIndex)) then
    FFlags:= FFlags - AFlagSet;

  if not AWithSubItems then
    Exit;

  for var i := 0 to FSubItem.Count - 1 do
    if (AItemIndex = nil) or (Contains(i, AItemIndex)) then
      SubItem[i].RemoveFlags(AFlagSet);
end;

procedure TTableItem.SetFlags(AFlagSet: TTableItemFlagSet;
  AWithSubItems: Boolean; AItemIndex: TArray<Integer>);
begin
  if (AItemIndex = nil) or (Contains(SELF_INDEX, AItemIndex)) then
    FFlags:= FFlags + AFlagSet;

  if not AWithSubItems then
    Exit;

  for var i := 0 to FSubItem.Count - 1 do
    if (AItemIndex = nil) or (Contains(i + 1, AItemIndex)) then
      SubItem[i].SetFlags(AFlagSet);
end;

{ TTableSubItem }

constructor TTableSubItem.Create(AOwner: TTableItem; AText: String);
begin
  inherited Create(AText);
  FOwner:= AOwner;
end;

destructor TTableSubItem.Destroy;
begin
  inherited;
end;


procedure TTableSubItem.RemoveFlags(AFlagSet: TTableItemFlagSet);
begin
  FFlags:= FFlags - AFlagSet;
end;

procedure TTableSubItem.SetFlags(AFlagSet: TTableItemFlagSet);
begin
  FFlags:= FFlags + AFlagSet;
end;

{ TElementObject }

constructor TElementObject.Create(AText: String);
begin
  inherited Create(AText);
end;

destructor TElementObject.Destroy;
begin

  inherited;
end;

end.
