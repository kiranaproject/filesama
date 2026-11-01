// filesama.ops.pas — filesystem operations, path helpers, and process launching
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Ops;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BaseUnix, ctypes;

function  GetHomeDir(): string;
function  GetDesktopDir(): string;
function  GetDocumentsDir(): string;
function  GetDownloadsDir(): string;
function  GetPicturesDir(): string;
function  GetMusicDir(): string;
function  GetVideosDir(): string;
function  GetTrashDir(): string;
function  GetParentPath(const APath: string): string;
function  FormatPathDisplay(const APath: string): string;
function  GetAvailableDiskSpace(const APath: string): string;

procedure LaunchFile(const APath: string);
procedure LaunchTerminalAt(const APath: string);
function  CreateNewFolder(const AParentPath, AFolderName: string): Boolean;
function  DeleteItem(const APath: string): Boolean;
function  RenameItem(const AOldPath, ANewPath: string): Boolean;

implementation

function libc_system(cmd: PChar): cint; cdecl; external 'c' name 'system';

type
  TStatVFS = record
    f_bsize   : culong;
    f_frsize  : culong;
    f_blocks  : culong;
    f_bfree   : culong;
    f_bavail  : culong;
    f_files   : culong;
    f_ffree   : culong;
    f_favail  : culong;
    f_fsid    : culong;
    f_flag    : culong;
    f_namemax : culong;
    __f_spare : array[0..5] of cint;
  end;

function statvfs(path: PChar; var buf: TStatVFS): cint; cdecl; external 'c' name 'statvfs';

function GetHomeDir(): string;
begin
  Result := GetEnvironmentVariable('HOME');
  if Result = '' then
    Result := '/home/' + GetEnvironmentVariable('USER');
  if Result = '' then
    Result := '/';
end;

function GetDesktopDir(): string;
begin
  Result := GetHomeDir() + '/Desktop';
  if not DirectoryExists(Result) then
    Result := GetHomeDir();
end;

function GetDocumentsDir(): string;
begin
  Result := GetHomeDir() + '/Documents';
  if not DirectoryExists(Result) then
    Result := GetHomeDir();
end;

function GetDownloadsDir(): string;
begin
  Result := GetHomeDir() + '/Downloads';
  if not DirectoryExists(Result) then
    Result := GetHomeDir();
end;

function GetPicturesDir(): string;
begin
  Result := GetHomeDir() + '/Pictures';
  if not DirectoryExists(Result) then
    Result := GetHomeDir();
end;

function GetMusicDir(): string;
begin
  Result := GetHomeDir() + '/Music';
  if not DirectoryExists(Result) then
    Result := GetHomeDir();
end;

function GetVideosDir(): string;
begin
  Result := GetHomeDir() + '/Videos';
  if not DirectoryExists(Result) then
    Result := GetHomeDir();
end;

function GetTrashDir(): string;
begin
  Result := GetHomeDir() + '/.local/share/Trash/files';
end;

function GetParentPath(const APath: string): string;
var
  p: string;
begin
  p := Trim(APath);
  while (Length(p) > 1) and (p[Length(p)] = '/') do
    Delete(p, Length(p), 1);
  Result := ExtractFilePath(p);
  while (Length(Result) > 1) and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
  if Result = '' then
    Result := '/';
end;

function FormatPathDisplay(const APath: string): string;
var
  home: string;
begin
  home := GetHomeDir();
  if (APath = home) then
    Result := '~'
  else if (Pos(home + '/', APath) = 1) then
    Result := '~/' + Copy(APath, Length(home) + 2, MaxInt)
  else
    Result := APath;
end;

function GetAvailableDiskSpace(const APath: string): string;
var
  buf: TStatVFS;
  freeBytes: Int64;
const
  GB = 1024 * 1024 * 1024;
  MB = 1024 * 1024;
begin
  FillChar(buf, SizeOf(buf), 0);
  if statvfs(PChar(APath), buf) = 0 then
  begin
    freeBytes := Int64(buf.f_bavail) * Int64(buf.f_frsize);
    if freeBytes >= GB then
      Result := Format('%.1f GB free', [freeBytes / GB])
    else
      Result := Format('%.1f MB free', [freeBytes / MB]);
  end
  else
    Result := '';
end;

procedure LaunchFile(const APath: string);
var
  cmd: string;
begin
  if not FileExists(APath) and not DirectoryExists(APath) then Exit;
  // Use xdg-open in background
  cmd := 'xdg-open "' + APath + '" >/dev/null 2>&1 &';
  libc_system(PChar(cmd));
end;

procedure LaunchTerminalAt(const APath: string);
var
  cmd: string;
begin
  // Try consolesama if installed, else fallback to standard X11 terminal
  if FileExists('/home/afumi/Documents/projects/kirana/consolesama/target/consolesama') then
    cmd := 'cd "' + APath + '" && /home/afumi/Documents/projects/kirana/consolesama/target/consolesama >/dev/null 2>&1 &'
  else
    cmd := 'cd "' + APath + '" && x-terminal-emulator >/dev/null 2>&1 || xterm >/dev/null 2>&1 &';
  libc_system(PChar(cmd));
end;

function CreateNewFolder(const AParentPath, AFolderName: string): Boolean;
var
  target: string;
begin
  target := AParentPath;
  if (Length(target) > 0) and (target[Length(target)] <> '/') then
    target := target + '/';
  target := target + AFolderName;
  Result := CreateDir(target);
end;

function DeleteItem(const APath: string): Boolean;
begin
  if DirectoryExists(APath) then
    Result := RemoveDir(APath)
  else if FileExists(APath) then
    Result := DeleteFile(APath)
  else
    Result := False;
end;

function RenameItem(const AOldPath, ANewPath: string): Boolean;
begin
  Result := RenameFile(AOldPath, ANewPath);
end;

end.
