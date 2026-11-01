// filesama.pas — modern desktop file manager for Samarinda DE
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

program filesama;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  ftpas, ftpas.app, ftpas.types,
  FileSama.Window;

var
  MainWindow: TFileSamaWindow;
  targetPath: string;

function GetTargetDirectory(): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to ParamCount() do
  begin
    if (ParamStr(i) <> '') and (ParamStr(i)[1] <> '-') then
    begin
      Result := ParamStr(i);
      Break;
    end;
  end;
end;

begin
  targetPath := GetTargetDirectory();
  MainWindow := TFileSamaWindow.Create(targetPath);
  try
    MainWindow.Show();
    FtApp().Run();
  finally
    MainWindow.Free();
  end;
end.
