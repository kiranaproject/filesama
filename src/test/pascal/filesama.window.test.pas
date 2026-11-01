// filesama.window.test.pas — integration tests for application window and FTML
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Window.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  ftpas, ftpas.api, ftpas.types, ftpas.app, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.menus, ftpas.views,
  FileSama.Model, FileSama.Window;

type
  TFileWindowTest = class(TTestCase)
  private
    FWindow  : TFileSamaWindow;
    FTestDir : string;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestWindowCreationAndFTMLResolution();
    procedure TestInitialNavigation();
    procedure TestNavigationHistoryStack();
    procedure TestSearchFilter();
  end;

implementation

procedure TFileWindowTest.SetUp();
begin
  if not FtIsLibLoaded() then
  begin
    if not FtLoadLib() then
      Fail('Could not load libft.so');
  end;

  try
    FtApp().Initialize();
  except
    on E: Exception do
      Fail('FtApp.Initialize failed: ' + E.Message);
  end;

  FTestDir := '/tmp/filesama_win_test_' + IntToStr(GetProcessID());
  CreateDir(FTestDir);
  CreateDir(FTestDir + '/subfolder_alpha');
  CreateDir(FTestDir + '/subfolder_beta');

  with TFileStream.Create(FTestDir + '/document.txt', fmCreate) do
  try
    WriteBuffer('test', 4);
  finally
    Free();
  end;

  FWindow := TFileSamaWindow.Create(FTestDir);
end;

procedure TFileWindowTest.TearDown();
begin
  if FWindow <> nil then
    FreeAndNil(FWindow);

  DeleteFile(FTestDir + '/document.txt');
  RemoveDir(FTestDir + '/subfolder_alpha');
  RemoveDir(FTestDir + '/subfolder_beta');
  RemoveDir(FTestDir);
end;

procedure TFileWindowTest.TestWindowCreationAndFTMLResolution();
begin
  AssertNotNull('Window must be created', FWindow);
  AssertNotNull('PathBar must be resolved from FTML', FWindow.PathBar);
  AssertNotNull('FileTable must be resolved from FTML', FWindow.FileTable);
  AssertNotNull('PlacesTree must be resolved from FTML', FWindow.PlacesTree);
  AssertNotNull('SearchEntry must be resolved from FTML', FWindow.SearchEntry);
  AssertNotNull('StatusText must be resolved from FTML', FWindow.StatusText);
  AssertNotNull('StatusRight must be resolved from FTML', FWindow.StatusRight);

  AssertEquals('FileTable ColumnCount is 4', 4, FWindow.FileTable.ColumnCount);
  AssertEquals('FileTable column 0 title', 'Name', FWindow.FileTable.ColumnTitles[0]);
  AssertEquals('FileTable column 1 title', 'Size', FWindow.FileTable.ColumnTitles[1]);
  AssertEquals('FileTable column 2 title', 'Type', FWindow.FileTable.ColumnTitles[2]);
  AssertEquals('FileTable column 3 title', 'Modified', FWindow.FileTable.ColumnTitles[3]);
end;

procedure TFileWindowTest.TestInitialNavigation();
begin
  AssertEquals('CurrentPath matches FTestDir', FTestDir, FWindow.CurrentPath);
  AssertEquals('PathBar path matches FTestDir', FTestDir, FWindow.PathBar.Path);
  AssertEquals('Model item count is 3', 3, FWindow.Model.Count);
  AssertEquals('FileTable row count is 3', 3, FWindow.FileTable.RowCount);

  // Status text should reflect items count
  AssertTrue('Status text contains "3 items"', Pos('3 items', FWindow.StatusText.Text) > 0);
end;

procedure TFileWindowTest.TestNavigationHistoryStack();
var
  subDir: string;
begin
  subDir := FTestDir + '/subfolder_alpha';
  AssertEquals('Initial history count is 1', 1, FWindow.History.Count);
  AssertEquals('Initial history index is 0', 0, FWindow.HistoryIndex);

  // Navigate to subfolder
  FWindow.NavigateTo(subDir, True);
  AssertEquals('History count is now 2', 2, FWindow.History.Count);
  AssertEquals('History index is now 1', 1, FWindow.HistoryIndex);
  AssertEquals('CurrentPath updated to subfolder', subDir, FWindow.CurrentPath);

  // Trigger Back
  FWindow.ActionBack(nil);
  AssertEquals('History index decremented to 0', 0, FWindow.HistoryIndex);
  AssertEquals('CurrentPath returned to FTestDir', FTestDir, FWindow.CurrentPath);

  // Trigger Forward
  FWindow.ActionForward(nil);
  AssertEquals('History index incremented to 1', 1, FWindow.HistoryIndex);
  AssertEquals('CurrentPath moved forward to subfolder', subDir, FWindow.CurrentPath);
end;

procedure TFileWindowTest.TestSearchFilter();
begin
  AssertEquals('Initial row count is 3', 3, FWindow.FileTable.RowCount);

  // Filter for "alpha"
  FWindow.HandleSearchChange(nil, 'alpha');
  AssertEquals('Filtered row count is 1', 1, FWindow.FileTable.RowCount);
  AssertEquals('Filtered row name is subfolder_alpha', 'subfolder_alpha', FWindow.FileTable.GetCell(0, 0));

  // Clear filter
  FWindow.HandleSearchChange(nil, '');
  AssertEquals('Restored row count is 3', 3, FWindow.FileTable.RowCount);
end;

initialization
  RegisterTest(TFileWindowTest);

end.
