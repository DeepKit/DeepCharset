# Delphi 12中实现回调的方法总结

## 1. 事件处理回调(Event Handlers)

```delphi
// 声明事件类型
TNotifyEvent = procedure(Sender: TObject) of object;
TMouseEvent = procedure(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer) of object;

// 在类中声明事件属性
property OnClick: TNotifyEvent read FOnClick write FOnClick;
property OnMouseMove: TMouseEvent read FOnMouseMove write FOnMouseMove;

// 触发事件
if Assigned(OnClick) then OnClick(Self);
```

## 2. 匿名方法(Anonymous Methods)

```delphi
// 声明匿名方法类型
TProcessProc = reference to procedure(const Value: string);

// 使用匿名方法作为参数
procedure ProcessItems(const Items: TArray<string>; Callback: TProcessProc);

// 调用示例
ProcessItems(MyArray, 
  procedure(const Item: string)
  begin
    ShowMessage(Item);
  end);
```

## 3. 委托引用(Reference to)

```delphi
// 声明回调类型
type
  TProgressCallback = reference to procedure(const Percentage: Integer);
  TErrorCallback = reference to procedure(const ErrorMsg: string);

// 在方法中使用
procedure ProcessFile(const FileName: string; 
                     ProgressCallback: TProgressCallback;
                     ErrorCallback: TErrorCallback);
                     
// 调用方式
ProcessFile('data.txt', 
  procedure(Percentage: Integer)
  begin
    ProgressBar.Position := Percentage;
  end,
  procedure(ErrorMsg: string)
  begin
    ShowMessage('错误: ' + ErrorMsg);
  end);
```

## 4. 接口回调(Interface Callbacks)

```delphi
// 定义回调接口
IProgressObserver = interface
  ['{UNIQUE-GUID-HERE}']
  procedure UpdateProgress(const Percentage: Integer);
  procedure OnComplete;
  procedure OnError(const ErrorMsg: string);
end;

// 实现接口
TMyProgressObserver = class(TInterfacedObject, IProgressObserver)
public
  procedure UpdateProgress(const Percentage: Integer);
  procedure OnComplete;
  procedure OnError(const ErrorMsg: string);
end;

// 使用接口回调
procedure ProcessWithInterface(Observer: IProgressObserver);
```

## 5. 方法指针(Method Pointers)

```delphi
// 声明方法指针类型
type
  TIntFunc = function(X, Y: Integer): Integer;

// 使用方法指针
function ProcessValues(A, B: Integer; Operation: TIntFunc): Integer;
begin
  Result := Operation(A, B);
end;

// 实现供调用的函数
function Add(X, Y: Integer): Integer;
begin
  Result := X + Y;
end;

// 调用
Value := ProcessValues(10, 20, Add);
```

## 6. 实例场景应用

### 异步操作中的回调

```delphi
procedure TMyClass.PerformAsyncOperation(
  OnComplete: TProc<TResult>; 
  OnError: TProc<Exception>);
begin
  TTask.Run(
    procedure
    begin
      try
        var Result := DoSomeWork;
        TThread.Queue(nil,
          procedure
          begin
            OnComplete(Result);
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              OnError(E);
            end);
      end;
    end);
end;
```

### 网络请求回调

```delphi
procedure SendRequest(
  const URL: string;
  OnSuccess: TProc<string>;
  OnFailure: TProc<Integer, string>);
begin
  // 执行HTTP请求并在完成时调用相应回调
end;

// 调用
SendRequest('https://api.example.com/data',
  procedure(Response: string)
  begin
    // 处理成功响应
  end,
  procedure(StatusCode: Integer; ErrorMsg: string)
  begin
    // 处理错误
  end);
``` 