# Custom Grid View (TStringGrid)
  
* Каждому элементу можно назначать цвет, фон, шрифт и т.д.

Пример использования:
```pascal
uses dlTableViewer;
...
var Table: TTableView;
...

procedure OnAnimation(Sender: TItemObject);
begin
  with TItemObject(Sender) do
  begin
    TextOffset.X:= TextOffset.X + 1;
    if TextOffset.X > 100 then
      TextOffset.X:= 1;

    if TextOffset.X > 50 then
      Color:= clBlue
    else
      Color:= clRed;

    Text:= 'Item ' + inttostr(TextOffset.X);
  end;

end;

procedure InitTable;
var Item: TTableItem;
begin
  //Создаем класс таблицы
  Table:= TTableView.Create(nil);
  //Назначаем parent 
  Table.Parent:= fmMain; //это главная форма
  Table.Align := alClient; 

  //Свойства выбранного объекта
  Table.SelectProp.Color:= clSilver;
  Table.SelectProp.FontItem.Align:= alfVertCenter;
  Table.SelectProp.FontItem.Style:= [fsBold];

  //Заголовок
  Table.Columns.Visible:= True;
  Table.Columns.Add('Column 1');
  Table.Columns.Add('Column 2');
  Table.Columns.Add('Column 3');
  Table.Columns.Add('Column 4');
  Table.Columns.Add('Column 5');
  Table.Columns.Add('Column 6');
  Table.Columns.Add('Column 7');

  //Устанавливаем авто размер заголовку 1,2
  Table.Columns.Item[1].AutoSize:= True;
  Table.Columns.Item[2].AutoSize:= True;

  //Создаем 200 элементов
  for var i := 1 to 200 do
  begin
    //Добавление элемента (строки)
    Item:= Table.Items.Add('Item: ' + i.ToString);
    if not Assigned(Item) then
      Continue;
      
    //Добавляем 5 подэлементов строке
    for var j := 1 to 5 do
       Item.Add('SubItem: ' + j.ToString);

    //Включение движущегося текста
    
    Item.SetArgs([ofSelfOffset]); //при выборе объекта будет офсет текущего элемента а не выбора
    Item.OnAnimation:= OnAnimation; //Назначение процедуры "анимации"
    Item.Animation.Interval:= 50;
    Item.Animation.Timer:= 0;
    Item.Animation.Enable:= True;
  end;
```

![image](https://user-images.githubusercontent.com/41462241/153626314-d31ae5fe-9976-4f4f-bb84-836d992798a7.png)
