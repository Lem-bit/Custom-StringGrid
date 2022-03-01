unit dlTableViewer;

interface

uses SysUtils, Graphics, Windows, Controls, Forms, Classes, Grids, dlTableTypes,
  dlTableColumns, dlTableItems, StdCtrls;

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
  TTableView = class(TDrawGrid)
  strict private
    FColumns   : TTableColumnList;
    FItems     : TTableItemList;
    FSelectProp: TTableSelectProp;

    //Заблокировать сохранение новой ширины столбца
    FLockWidthChanged: Boolean;
  strict private
    procedure OnAddColumn;

    procedure LockWidthChanged;
    procedure UnlockWidthChanged;
  published
    procedure ColWidthsChanged; override;
    procedure RowHeightsChanged; override;
  strict private
    procedure RenderItems(ACol, ARow: LongInt; ARect: TRect; FShowColumns: Integer);
    function RenderColumns(ACol, ARow: Longint; ARect: TRect): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;

    procedure Repaint; override;
    procedure Paint; override;
    procedure Resize; override;
  public
    property Columns   : TTableColumnList read FColumns;
    property Items     : TTableItemList   read FItems;
    property SelectProp: TTableSelectProp read FSelectProp;
  end;

implementation

{ TTableView }

procedure TTableView.ColWidthsChanged;
begin
  inherited;

  if not Assigned(FColumns) then
    Exit;

  if FLockWidthChanged then
    Exit;

  for var i := 0 to ColCount - 1 do
  begin
    if not Assigned(FColumns.Item[i]) then
      Continue;

    FColumns.Item[i].Width:= ColWidths[i];
  end;

end;

procedure TTableView.RowHeightsChanged;
begin
  inherited;

end;

procedure TTableView.UnlockWidthChanged;
begin
  FLockWidthChanged:= False;
end;

constructor TTableView.Create(AOwner: TComponent);
begin
  inherited;

  DefaultDrawing:= False;
  FixedCols     := 0;
  FixedRows     := 0;
  ColCount      := 0; //Кол-во заголовков
  RowCount      := 0; //Кол-во записей
  Options       := Self.Options + [goRowSelect, goThumbTracking, goColSizing] - [goRangeSelect{, goVertLine, goHorzLine}];

  DoubleBuffered:= True;
  BorderStyle   := bsNone;

  FColumns      := TTableColumnList.Create;
  FItems        := TTableItemList.Create;
  FSelectProp   := TTableSelectProp.Create('');
  FSelectProp.TextOffset.SetXY(2, 0);

  FColumns.OnAddColumn:= OnAddColumn;
end;

destructor TTableView.Destroy;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FItems);
  FreeAndNil(FSelectProp);
  inherited;
end;

procedure TTableView.DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
var SItem: Integer; //Стартовый элемент (если заголовок виден = 1 или нет = 0)
begin

  with Canvas do
  begin
    Brush.Color:= clWhite;
    FillRect(ARect);
  end;

  //Рисуем заголовок
  SItem:= Byte( RenderColumns(ACol, ARow, ARect) );

  //Рисуем элементы
  RenderItems(ACol, ARow, ARect, SItem);
end;

procedure TTableView.LockWidthChanged;
begin
  FLockWidthChanged:= True;
end;

procedure TTableView.OnAddColumn;
begin
  ColCount:= ColCount + 1;
end;

procedure TTableView.Paint;
var SItem: Integer;
begin
  SItem    := 0;

  if Assigned(FColumns) then
  begin
    SItem:= Byte( FColumns.Visible );

    if FColumns.Count > 0 then
      if ColCount <> FColumns.Count then
      begin
        ColCount:= FColumns.Count;
        Resize;
      end;
  end;

  if (Assigned(FItems)) and (FItems.Count > 0) then
    if RowCount <> FItems.Count then
      RowCount:= FItems.Count + SItem;

  if Assigned(FColumns) and Assigned(FItems) and
     (FItems.Count > 0) then
      FixedRows:= Byte( FColumns.Visible );

  inherited;
end;

function TTableView.RenderColumns(ACol, ARow: Longint; ARect: TRect): Boolean;
var Item: TTableColumn;
begin
  Result:= False;
  if not Assigned(FColumns) then
    Exit;

  if not FColumns.Visible then
    Exit;

  Result:= FColumns.Visible;

  if (RowCount > 0) and (RowHeights[0] <> FColumns.Height) then
    RowHeights[0]:= FColumns.Height;

  Item:= FColumns.Item[ACol];
  if (ARow <> 0) or (not Assigned(Item)) then
    Exit;

  if Item.Hide then
    ColWidths[ACol]:= -1
  else
  begin
    Item.Draw(Canvas, ARect);

    if Item.Action.Enable then
      InvalidateRect(Handle, ARect, False);
  end;

end;

procedure TTableView.RenderItems(ACol, ARow: LongInt; ARect: TRect; FShowColumns: Integer);
var Item: TElementObject;
begin
  if not Assigned(FItems) then
    Exit;

  //ACol - X (SubItem), ARow - Y (Item)
  Item:= Items.GetItemObject(ARow - FShowColumns, ACol);
  if not Assigned(Item) then
    Exit;

  //Высота ячейки
  if (Item is TTableItem) and (RowHeights[ARow] <> TTableItem(Item).Height) then
    RowHeights[ARow]:= TTableItem(Item).Height;

  Item.Selected:= (Selection.Top = ARow) or (ifUserSelect in Item.Flags); //Добавить флаги для принудительного выбора
  if not Item.Selected then
    Item.Draw(Canvas, ARect)
  else
    Item.Draw(Canvas, ARect, FSelectProp);

  if Item.Action.Enable then
  begin
    InvalidateRect(Handle, ARect, False);
  end;

end;

procedure TTableView.Repaint;
begin
  inherited;
end;

procedure TTableView.Resize;
begin
  inherited;

  if not Assigned(FColumns) then
    Exit;

  if FColumns.Count < 1 then
    Exit;

  FColumns.Resize(ClientRect);

  LockWidthChanged;
  for var i := 0 to ColCount - 1 do
    if Assigned(FColumns.Item[i]) then
      ColWidths[i]:= FColumns.Item[i].Width;
  UnlockWidthChanged;

end;

end.
