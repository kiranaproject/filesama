// TestRunner.pas — console test runner for filesama
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

program TestRunner;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
  FileSama.Model.Test,
  FileSama.Window.Test;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize();
    Application.Run();
  finally
    Application.Free();
  end;
end.
