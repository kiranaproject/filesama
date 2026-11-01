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
    procedure TestResizeWidgetBounds();
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
  AssertEquals('FileTable column 2 title', 'Modified', FWindow.FileTable.ColumnTitles[2]);
  AssertEquals('FileTable column 3 title', 'Type', FWindow.FileTable.ColumnTitles[3]);
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

procedure TFileWindowTest.TestResizeWidgetBounds();
var
  tb, pb, bHome, bNew, bHid, bRef, se, ca: TFtWidget;
begin
  tb := FWindow.FindWidget('toolBar');
  pb := FWindow.PathBar;
  bHome := FWindow.FindWidget('btnHome');
  bNew := FWindow.FindWidget('btnNewFolder');
  bHid := FWindow.FindWidget('btnHidden');
  bRef := FWindow.FindWidget('btnRefresh');
  se := FWindow.SearchEntry;
  ca := FWindow.FindWidget('contentArea');

  AssertNotNull('toolBar must exist', tb);
  AssertNotNull('pathBar must exist', pb);
  AssertNotNull('btnHome must exist', bHome);
  AssertNotNull('btnNewFolder must exist', bNew);
  AssertNotNull('btnHidden must exist', bHid);
  AssertNotNull('btnRefresh must exist', bRef);
  AssertNotNull('searchEntry must exist', se);
  AssertNotNull('contentArea must exist', ca);

  // Resize window smaller
  FWindow.SetBounds(0, 0, 800, 500);

  AssertEquals('contentArea X at 800x500', 190, ca.X);
  AssertEquals('contentArea Y at 800x500', 28, ca.Y);
  AssertEquals('contentArea Width at 800x500', 610, ca.Width);
  AssertEquals('contentArea Height at 800x500', 446, ca.Height);

  AssertEquals('toolBar X at 800x500', 198, tb.X);
  AssertEquals('toolBar Y at 800x500', 36, tb.Y);
  AssertEquals('toolBar Width at 800x500', 610, tb.Width);

  AssertEquals('btnHome X at 800x500', 300, bHome.X);
  AssertEquals('btnHome Y at 800x500', 38, bHome.Y);

  AssertEquals('pathBar X at 800x500', 336, pb.X);
  AssertEquals('pathBar Y at 800x500', 38, pb.Y);
  AssertEquals('pathBar Width at 800x500', 212, pb.Width);

  AssertEquals('btnNewFolder X at 800x500', 554, bNew.X);
  AssertEquals('btnNewFolder Y at 800x500', 38, bNew.Y);

  AssertEquals('btnHidden X at 800x500', 588, bHid.X);
  AssertEquals('btnHidden Y at 800x500', 38, bHid.Y);

  AssertEquals('btnRefresh X at 800x500', 622, bRef.X);
  AssertEquals('btnRefresh Y at 800x500', 38, bRef.Y);

  AssertEquals('searchEntry X at 800x500', 658, se.X);
  AssertEquals('searchEntry Y at 800x500', 38, se.Y);
  AssertEquals('searchEntry right edge flush with toolBar', tb.X + tb.Width, se.X + se.Width);

  // Resize window larger
  FWindow.SetBounds(0, 0, 1180, 720);

  AssertEquals('contentArea X at 1180x720', 190, ca.X);
  AssertEquals('contentArea Y at 1180x720', 28, ca.Y);
  AssertEquals('contentArea Width at 1180x720', 990, ca.Width);
  AssertEquals('contentArea Height at 1180x720', 666, ca.Height);

  AssertEquals('toolBar X at 1180x720', 198, tb.X);
  AssertEquals('toolBar Y at 1180x720', 36, tb.Y);
  AssertEquals('toolBar Width at 1180x720', 990, tb.Width);

  AssertEquals('btnHome X at 1180x720', 300, bHome.X);
  AssertEquals('btnHome Y at 1180x720', 38, bHome.Y);

  AssertEquals('pathBar X at 1180x720', 336, pb.X);
  AssertEquals('pathBar Y at 1180x720', 38, pb.Y);
  AssertEquals('pathBar Width at 1180x720', 592, pb.Width);

  AssertEquals('btnNewFolder X at 1180x720', 934, bNew.X);
  AssertEquals('btnNewFolder Y at 1180x720', 38, bNew.Y);

  AssertEquals('btnHidden X at 1180x720', 968, bHid.X);
  AssertEquals('btnHidden Y at 1180x720', 38, bHid.Y);

  AssertEquals('btnRefresh X at 1180x720', 1002, bRef.X);
  AssertEquals('btnRefresh Y at 1180x720', 38, bRef.Y);

  AssertEquals('searchEntry X at 1180x720', 1038, se.X);
  AssertEquals('searchEntry Y at 1180x720', 38, se.Y);
  AssertEquals('searchEntry right edge flush with toolBar', tb.X + tb.Width, se.X + se.Width);
end;

initialization
  RegisterTest(TFileWindowTest);

end.
