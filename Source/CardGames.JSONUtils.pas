{******************************************************************************}
{                                                                              }
{ CardGames.JSONUtils:                                                         }
{ JSON Utilities for Serialization/Deserialization of Card Games Elements      }
{                                                                              }
{ Copyright (c) 2024                                                           }
{ Author: Carlo Barazzetta                                                     }
{ Contributor: Lorenzo Barazzetta                                              }
{                                                                              }
{ https://github.com/carloBarazzetta/CARD_Games_Delphi                         }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit CardGames.JSONUtils;

interface

uses
  System.Generics.Collections
  , System.Generics.Defaults
  , System.Classes
  , System.JSON
  , CardGames.Events
  , CardGames.Model
  , CardGames.Types
  ;

type
  TObjectList<T: class> = class(TList<T>);  // Utilizzo un TObjectList come container

  TCardGamesClassRegistry = class
    private
      FClassMap: TDictionary<string, TClass>;
    public
      constructor Create;
      destructor Destroy; override;
      function CreateInstance(const ClassName: string): TObject;
      function ClassRegistered(const ClassName: string): Boolean;
    end;

procedure RegisterClassToSerialize(const ClassName: string; AClass: TClass);
function SerializeToJSON(const AObject: TObject): TJSONObject;
function SerializeToString(const AObject: TObject): string;
function DeserializeObject(const AJSONObject: TJSONObject): TObject;
function DeserializeFromJSON(const AJSONStr: string): TObject;
function DeserializeArrayOfObjects(const AJSONString: string): TObjectList<TObject>;
function SplitStringByPipe(const Input: string): TList<string>;
function StringToPlayerType(const EnumString: string): TPlayerType;

var
  CardGamesClassRegistry: TCardGamesClassRegistry;

implementation

uses
  System.Rtti
  , System.DateUtils
  , System.TypInfo
  , System.SysUtils
  ;

function StringToEnum(const EnumString: string; EnumType: PTypeInfo): Integer;
begin
  Result := GetEnumValue(EnumType, EnumString);
end;

function StringToPlayerType(const EnumString: string): TPlayerType;
var
  EnumValue: Integer;
begin
  EnumValue := StringToEnum(EnumString, TypeInfo(TPlayerType));
  Result := TPlayerType(EnumValue);
end;

function SplitStringByPipe(const Input: string): TList<string>;
var
  StartIdx, EndIdx: Integer;
  SubStr: string;
begin
  Result := TList<string>.Create;
  StartIdx := 1;

  for EndIdx := 1 to Length(Input) do
  begin
    if Input[EndIdx] = '|' then
    begin
      SubStr := Copy(Input, StartIdx, EndIdx - StartIdx);
      Result.Add(SubStr);
      StartIdx := EndIdx + 1;
    end;
  end;
  if StartIdx <= Length(Input) then
  begin
    SubStr := Copy(Input, StartIdx, Length(Input) - StartIdx + 1);
    Result.Add(SubStr);
  end;
end;

procedure RegisterClassToSerialize(const ClassName: string; AClass: TClass);
begin
  if not Assigned(CardGamesClassRegistry) then
    CardGamesClassRegistry := TCardGamesClassRegistry.Create;
  CardGamesClassRegistry.FClassMap.Add(ClassName, AClass);
end;

{ TCardGamesClassRegistry }

constructor TCardGamesClassRegistry.Create;
begin
  FClassMap := TDictionary<string, TClass>.Create;
end;

destructor TCardGamesClassRegistry.Destroy;
begin
  FClassMap.Free;
  inherited;
end;

function TCardGamesClassRegistry.ClassRegistered(const ClassName: string): Boolean;
var
  AClass: TClass;
begin
  Result := FClassMap.TryGetValue(ClassName, AClass);
end;

function TCardGamesClassRegistry.CreateInstance(const ClassName: string): TObject;
var
  AClass: TClass;
begin
  if FClassMap.TryGetValue(ClassName, AClass) then
    Result := AClass.Create
  else
    raise Exception.CreateFmt('Class %s not registered', [ClassName]);
end;

function DeserializeArrayOfObjects(const AJSONString: string): TObjectList<TObject>;
var
  JSONArray: TJSONArray;
  JSONValue: TJSONValue;
  JSONObject: TJSONObject;
  DeserializedObject: TObject;
  ObjectList: TObjectList<TObject>;
begin
  ObjectList := TObjectList<TObject>.Create;
  try
    JSONArray := TJSONObject.ParseJSONValue(AJSONString) as TJSONArray;
    try
      if Assigned(JSONArray) then
      begin
        for JSONValue in JSONArray do
        begin
          if JSONValue is TJSONObject then
          begin
            JSONObject := TJSONObject(JSONValue);
            DeserializedObject := DeserializeObject(JSONObject);  // Deserializza ciascun oggetto
            if Assigned(DeserializedObject) then
              ObjectList.Add(DeserializedObject);
          end;
        end;
      end;
    finally
      JSONArray.Free;
    end;
    Result := ObjectList;
  except
    ObjectList.Free;
    raise;  // Rilancia eccezione in caso di errore
  end;
end;

function DeserializeObject(const AJSONObject: TJSONObject): TObject;
var
  Ctx: TRttiContext;
  ObjType: TRttiType;
  RttiProp: TRttiProperty;
  ClassName: string;
  JSONValue: TJSONValue;
  PropName: string;
  PropValue: TValue;
begin
  if not AJSONObject.TryGetValue<string>('ClassName', ClassName) then
    raise Exception.Create('ClassName not found in JSON');

  Result := CardGamesClassRegistry.CreateInstance(ClassName);
  Ctx := TRttiContext.Create;
  ObjType := Ctx.GetType(Result.ClassType);

  for RttiProp in ObjType.GetProperties do
  begin
    PropName := RttiProp.Name;
    if AJSONObject.TryGetValue(PropName, JSONValue) then
    begin
      if (RttiProp.Visibility = mvPublic) and
        ((RttiProp.IsWritable) or (RttiProp.PropertyType.TypeKind = tkClass)) then
      begin
        case RttiProp.PropertyType.TypeKind of
          tkString, tkLString, tkWString, tkUString:
            RttiProp.SetValue(Result, JSONValue.Value);

          tkInteger, tkInt64:
            RttiProp.SetValue(Result, JSONValue.AsType<Integer>);

          tkFloat:
            if RttiProp.PropertyType.QualifiedName = 'System.TDateTime' then
              RttiProp.SetValue(Result, ISO8601ToDate(JSONValue.Value))
            else
              RttiProp.SetValue(Result, JSONValue.AsType<Double>);

          tkEnumeration:
            begin
              // Converti la stringa al valore enumerativo
              PropValue := TValue.FromOrdinal(RttiProp.PropertyType.Handle, GetEnumValue(RttiProp.PropertyType.Handle, JSONValue.Value));
              RttiProp.SetValue(Result, PropValue);
            end;

          tkClass:
            begin
              if (JSONValue is TJSONObject) and (RttiProp.IsWritable) then
                RttiProp.SetValue(Result, DeserializeFromJSON(JSONValue.ToString));
            end;
        end;
      end;
    end;
  end;
end;

function DeserializeFromJSON(const AJSONStr: string): TObject;
var
  JSONObj: TJSONObject;
begin
  JSONObj := TJSONObject.ParseJSONValue(AJSONStr) as TJSONObject;
  if not Assigned(JSONObj) then
    raise Exception.Create('Invalid JSON string');
  try
    Result := DeserializeObject(JSONObj);
  finally
    JSONObj.Free;
  end;
end;

function SerializeToString(const AObject: TObject): string;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := SerializeToJSON(AObject);
  try
    Result := LJSONObject.toString;
  finally
    LJSONObject.Free;
  end;
end;

function SerializeToJSON(const AObject: TObject): TJSONObject;
var
  Ctx: TRttiContext;
  ObjType: TRttiType;
  RttiProp: TRttiProperty;
  LJSONSubObj: TJSONObject;
  PropValue: TValue;
  LElement: TObject;
  EnumName: string;
  OrdValue: Integer;
begin
  Result := TJSONObject.Create;
  Ctx := TRttiContext.Create;
  try
    Result.AddPair('ClassName',AObject.ClassName);
    ObjType := Ctx.GetType(AObject.ClassType);

    for RttiProp in ObjType.GetProperties do
    begin
      if RttiProp.Visibility = mvPublic then
      begin
        if RttiProp.IsReadable and (RttiProp.Name <> 'RefCount') then
        begin
          PropValue := RttiProp.GetValue(AObject);
          case RttiProp.PropertyType.TypeKind of
            tkClass:
              begin
                if (PropValue.IsObject) then
                begin
                  LElement := PropValue.AsObject;
                  if Assigned(LElement) then
                  begin
                    if CardGamesClassRegistry.ClassRegistered(LElement.ClassName) then
                    begin
                      LJSONSubObj := SerializeToJSON(LElement);
                      Result.AddPair(RttiProp.Name, LJSONSubObj);
                    end;
                  end;
                end;
              end;

            tkString, tkLString, tkWString, tkUString:
              Result.AddPair(RttiProp.Name, PropValue.AsString);

            tkInteger, tkInt64:
              Result.AddPair(RttiProp.Name, TJSONNumber.Create(PropValue.AsInteger));

            tkFloat:
              if RttiProp.PropertyType.QualifiedName = 'System.TDateTime' then
                Result.AddPair(RttiProp.Name, DateToISO8601(PropValue.AsExtended))
              else
                Result.AddPair(RttiProp.Name, TJSONNumber.Create(PropValue.AsExtended));

            tkEnumeration:
              begin
                OrdValue := PropValue.AsOrdinal;
                EnumName := GetEnumName(RttiProp.PropertyType.Handle, OrdValue);
                Result.AddPair(RttiProp.Name, EnumName);
              end;
          end;
        end;
      end;
    end;

  finally
    Ctx.Free;
  end;
end;

initialization

finalization
  CardGamesClassRegistry.Free;

end.
