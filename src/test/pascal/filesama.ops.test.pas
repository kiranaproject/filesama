// filesama.ops.test.pas — tests for FreeDesktop clipboard and trash operations
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Ops.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  FileSama.Ops;

type
  TOpsTest = class(TTestCase)
  private
    FTestRoot: string;
    procedure CreateDummyFile(const APath, AContent: string);
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestUriConversion;
    procedure TestClipboardRoundtrip;
    procedure TestCopyPasteAndCollision;
    procedure TestTrashAndMetadata;
    procedure TestDeletePermanently;
  end;

implementation

procedure TOpsTest.CreateDummyFile(const APath, AContent: string);
var
  f: TextFile;
begin
  AssignFile(f, APath);
  Rewrite(f);
  Write(f, AContent);
  CloseFile(f);
end;

procedure TOpsTest.SetUp();
begin
  inherited SetUp();
  FTestRoot := Format('/tmp/filesama_ops_test_%d_%d', [GetProcessID(), GetTickCount64()]);
  ForceDirectories(FTestRoot);
end;

procedure TOpsTest.TearDown();
begin
  if DirectoryExists(FTestRoot) then
    DeletePermanently(FTestRoot);
  inherited TearDown();
end;

procedure TOpsTest.TestUriConversion();
var
  uri, path: string;
begin
  uri := PathToUri('/home/user/My Documents/file #1.txt');
  AssertEquals('Encoded file URI', 'file:///home/user/My%20Documents/file%20%231.txt', uri);

  path := UriToPath(uri);
  AssertEquals('Decoded path', '/home/user/My Documents/file #1.txt', path);

  path := UriToPath('file://localhost/etc/fstab');
  AssertEquals('Localhost URI', '/etc/fstab', path);
end;

procedure TOpsTest.TestClipboardRoundtrip();
var
  file1, file2: string;
  paths: TStringArray;
  isCut: Boolean;
begin
  file1 := FTestRoot + '/clip1.txt';
  file2 := FTestRoot + '/clip2.txt';
  CreateDummyFile(file1, 'data 1');
  CreateDummyFile(file2, 'data 2');

  // Copy mode
  SetFileClipboard([file1, file2], False);
  AssertTrue('Clipboard should have files', HasFileClipboard());
  AssertTrue('GetFileClipboard should succeed', GetFileClipboard(paths, isCut));
  AssertFalse('isCut should be false for copy', isCut);
  AssertEquals('Paths count', 2, Length(paths));
  AssertEquals('Path 1', file1, paths[0]);
  AssertEquals('Path 2', file2, paths[1]);

  // Cut mode
  SetFileClipboard([file1], True);
  AssertTrue('HasFileClipboard after cut', HasFileClipboard());
  AssertTrue('GetFileClipboard cut', GetFileClipboard(paths, isCut));
  AssertTrue('isCut should be true for cut', isCut);
  AssertEquals('Single cut path', 1, Length(paths));
  AssertEquals('Cut path item', file1, paths[0]);
end;

procedure TOpsTest.TestCopyPasteAndCollision();
var
  srcDir, dstDir, srcFile: string;
  pastedCount: Integer;
begin
  srcDir := FTestRoot + '/src';
  dstDir := FTestRoot + '/dst';
  ForceDirectories(srcDir);
  ForceDirectories(dstDir);

  srcFile := srcDir + '/notes.txt';
  CreateDummyFile(srcFile, 'first note');

  // Copy to clipboard
  SetFileClipboard([srcFile], False);

  // Paste 1
  pastedCount := PasteClipboard(dstDir);
  AssertEquals('Pasted count 1', 1, pastedCount);
  AssertTrue('File should exist in destination', FileExists(dstDir + '/notes.txt'));

  // Paste 2 (collision -> notes (copy).txt)
  pastedCount := PasteClipboard(dstDir);
  AssertEquals('Pasted count 2', 1, pastedCount);
  AssertTrue('Copy 1 should exist', FileExists(dstDir + '/notes (copy).txt'));

  // Paste 3 (collision -> notes (copy 2).txt)
  pastedCount := PasteClipboard(dstDir);
  AssertEquals('Pasted count 3', 1, pastedCount);
  AssertTrue('Copy 2 should exist', FileExists(dstDir + '/notes (copy 2).txt'));
end;

procedure TOpsTest.TestTrashAndMetadata();
var
  targetFile, trashFilesDir, trashInfoDir: string;
  expectedFile, expectedInfo: string;
  infoList: TStringList;
begin
  targetFile := FTestRoot + '/junk_item.txt';
  CreateDummyFile(targetFile, 'junk data to be trashed');

  AssertTrue('TrashItem should succeed', TrashItem(targetFile));
  AssertFalse('Original file should no longer exist', FileExists(targetFile));

  trashFilesDir := GetTrashFilesDir();
  trashInfoDir := GetTrashInfoDir();

  expectedFile := trashFilesDir + '/junk_item.txt';
  expectedInfo := trashInfoDir + '/junk_item.txt.trashinfo';

  AssertTrue('File must be in trash files dir', FileExists(expectedFile));
  AssertTrue('Metadata .trashinfo must exist', FileExists(expectedInfo));

  infoList := TStringList.Create();
  try
    infoList.LoadFromFile(expectedInfo);
    AssertTrue('Metadata has [Trash Info] header', Pos('[Trash Info]', infoList.Text) > 0);
    AssertTrue('Metadata specifies Path', Pos('Path=' + targetFile, infoList.Text) > 0);
    AssertTrue('Metadata specifies DeletionDate', Pos('DeletionDate=', infoList.Text) > 0);
  finally
    infoList.Free();
    // Clean up trashed test item
    DeleteFile(expectedFile);
    DeleteFile(expectedInfo);
  end;
end;

procedure TOpsTest.TestDeletePermanently();
var
  dirPath, subDir, file1, file2: string;
begin
  dirPath := FTestRoot + '/folder_to_nuke';
  subDir := dirPath + '/nested';
  ForceDirectories(subDir);

  file1 := dirPath + '/top.txt';
  file2 := subDir + '/deep.txt';
  CreateDummyFile(file1, 'nuke 1');
  CreateDummyFile(file2, 'nuke 2');

  AssertTrue('Directory exists before delete', DirectoryExists(dirPath));
  AssertTrue('DeletePermanently should return true', DeletePermanently(dirPath));
  AssertFalse('Directory should be completely gone', DirectoryExists(dirPath));
end;

initialization
  RegisterTest(TOpsTest);

end.
