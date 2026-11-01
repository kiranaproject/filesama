// filesama.model.test.pas — unit tests for filesystem model and formatting
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Model.Test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  FileSama.Model, FileSama.Ops;

type
  TDirectoryModelTest = class(TTestCase)
  private
    FModel: TDirectoryModel;
    FTestDir: string;
  protected
    procedure SetUp(); override;
    procedure TearDown(); override;
  published
    procedure TestModelCreation();
    procedure TestFileSizeFormatting();
    procedure TestMimeAndTypeDetection();
    procedure TestDirectoryScanning();
    procedure TestHiddenFileFiltering();
    procedure TestSorting();
    procedure TestPathOps();
  end;

implementation

procedure TDirectoryModelTest.SetUp();
begin
  FModel := TDirectoryModel.Create();
  FTestDir := '/tmp/filesama_test_' + IntToStr(GetProcessID());
  CreateDir(FTestDir);
  CreateDir(FTestDir + '/alpha_dir');
  CreateDir(FTestDir + '/beta_dir');
  CreateDir(FTestDir + '/.hidden_dir');

  // Create test files
  with TFileStream.Create(FTestDir + '/file_a.txt', fmCreate) do
  try
    WriteBuffer('hello', 5);
  finally
    Free();
  end;

  with TFileStream.Create(FTestDir + '/file_b.pas', fmCreate) do
  try
    WriteBuffer('unit Test;', 10);
  finally
    Free();
  end;

  with TFileStream.Create(FTestDir + '/.hidden_file.md', fmCreate) do
  try
    WriteBuffer('# doc', 5);
  finally
    Free();
  end;
end;

procedure TDirectoryModelTest.TearDown();
begin
  DeleteFile(FTestDir + '/file_a.txt');
  DeleteFile(FTestDir + '/file_b.pas');
  DeleteFile(FTestDir + '/.hidden_file.md');
  RemoveDir(FTestDir + '/alpha_dir');
  RemoveDir(FTestDir + '/beta_dir');
  RemoveDir(FTestDir + '/.hidden_dir');
  RemoveDir(FTestDir);

  FModel.Free();
end;

procedure TDirectoryModelTest.TestModelCreation();
begin
  AssertNotNull('Model instance must not be nil', FModel);
  AssertEquals('Initial item count is 0', 0, FModel.Count);
  AssertFalse('Default ShowHidden is False', FModel.ShowHidden);
end;

procedure TDirectoryModelTest.TestFileSizeFormatting();
begin
  AssertEquals('0 bytes', '0 B', FModel.FormatFileSize(0));
  AssertEquals('500 bytes', '500 B', FModel.FormatFileSize(500));
  AssertEquals('1.5 KB', '1.5 KB', FModel.FormatFileSize(1536));
  AssertEquals('2.0 MB', '2.0 MB', FModel.FormatFileSize(2 * 1024 * 1024));
  AssertEquals('1.25 GB', '1.25 GB', FModel.FormatFileSize(Round(1.25 * 1024 * 1024 * 1024)));
end;

procedure TDirectoryModelTest.TestMimeAndTypeDetection();
begin
  AssertEquals('Folder mime', 'inode/directory', FModel.DetectMimeType('my_folder', True));
  AssertEquals('Folder description', 'Folder', FModel.GetTypeDescription('my_folder', True));

  AssertEquals('Text mime', 'text/plain', FModel.DetectMimeType('note.txt', False));
  AssertEquals('Text description', 'Plain Text', FModel.GetTypeDescription('note.txt', False));

  AssertEquals('Pascal mime', 'text/x-pascal', FModel.DetectMimeType('main.pas', False));
  AssertEquals('Pascal description', 'Pascal Source', FModel.GetTypeDescription('main.pas', False));

  AssertEquals('PNG mime', 'image/png', FModel.DetectMimeType('icon.png', False));
  AssertEquals('PNG description', 'PNG Image', FModel.GetTypeDescription('icon.png', False));

  AssertEquals('FTML description', 'Floria Markup', FModel.GetTypeDescription('design.ftml', False));
end;

procedure TDirectoryModelTest.TestDirectoryScanning();
begin
  FModel.ScanDirectory(FTestDir);
  AssertEquals('Current path matches', FTestDir, FModel.CurrentPath);
  // Without hidden files: alpha_dir, beta_dir, file_a.txt, file_b.pas (4 items)
  AssertEquals('Non-hidden count is 4', 4, FModel.Count);
end;

procedure TDirectoryModelTest.TestHiddenFileFiltering();
begin
  FModel.ShowHidden := False;
  FModel.ScanDirectory(FTestDir);
  AssertEquals('Count without hidden is 4', 4, FModel.Count);

  FModel.ShowHidden := True;
  FModel.ScanDirectory(FTestDir);
  // With hidden: alpha_dir, beta_dir, .hidden_dir, file_a.txt, file_b.pas, .hidden_file.md (6 items)
  AssertEquals('Count with hidden is 6', 6, FModel.Count);
end;

procedure TDirectoryModelTest.TestSorting();
begin
  FModel.ShowHidden := False;
  FModel.ScanDirectory(FTestDir);
  AssertEquals('Item count', 4, FModel.Count);

  // Directories should always precede files
  AssertTrue('Item 0 is a directory', FModel[0].IsDirectory);
  AssertTrue('Item 1 is a directory', FModel[1].IsDirectory);
  AssertFalse('Item 2 is a file', FModel[2].IsDirectory);
  AssertFalse('Item 3 is a file', FModel[3].IsDirectory);

  // Ascending sort by name
  FModel.Sort(0, True);
  AssertEquals('Item 0 is alpha_dir', 'alpha_dir', FModel[0].Name);
  AssertEquals('Item 1 is beta_dir', 'beta_dir', FModel[1].Name);
  AssertEquals('Item 2 is file_a.txt', 'file_a.txt', FModel[2].Name);
  AssertEquals('Item 3 is file_b.pas', 'file_b.pas', FModel[3].Name);

  // Descending sort by name (directories still precede files)
  FModel.Sort(0, False);
  AssertEquals('Item 0 is beta_dir', 'beta_dir', FModel[0].Name);
  AssertEquals('Item 1 is alpha_dir', 'alpha_dir', FModel[1].Name);
  AssertEquals('Item 2 is file_b.pas', 'file_b.pas', FModel[2].Name);
  AssertEquals('Item 3 is file_a.txt', 'file_a.txt', FModel[3].Name);
end;

procedure TDirectoryModelTest.TestPathOps();
begin
  AssertEquals('Parent of /a/b/c is /a/b', '/a/b', GetParentPath('/a/b/c'));
  AssertEquals('Parent of /a/b is /a', '/a', GetParentPath('/a/b'));
  AssertEquals('Parent of /a is /', '/', GetParentPath('/a'));
  AssertEquals('Parent of / is /', '/', GetParentPath('/'));

  AssertTrue('Home dir not empty', Length(GetHomeDir()) > 0);
  AssertTrue('Desktop dir not empty', Length(GetDesktopDir()) > 0);
end;

initialization
  RegisterTest(TDirectoryModelTest);

end.
