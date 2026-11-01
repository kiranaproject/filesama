// filesama.ops.pas — filesystem operations, path helpers, and process launching
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Ops;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, BaseUnix, ctypes, ftpas.app;

type
  TStringArray = array of string;

function  GetHomeDir(): string;
function  GetDesktopDir(): string;
function  GetDocumentsDir(): string;
function  GetDownloadsDir(): string;
function  GetPicturesDir(): string;
function  GetMusicDir(): string;
function  GetVideosDir(): string;
function  GetTrashDir(): string;
function  GetTrashFilesDir(): string;
function  GetTrashInfoDir(): string;
function  GetParentPath(const APath: string): string;
function  FormatPathDisplay(const APath: string): string;
function  GetAvailableDiskSpace(const APath: string): string;

function  PathToUri(const APath: string): string;
function  UriToPath(const AUri: string): string;

{ FreeDesktop File Clipboard (x-special/gnome-copied-files) }
procedure SetFileClipboard(const APaths: array of string; ACut: Boolean);
function  HasFileClipboard(): Boolean;
function  GetFileClipboard(out APaths: TStringArray; out AIsCut: Boolean): Boolean;
function  PasteClipboard(const ADestDir: string): Integer;

{ FreeDesktop Trash Specification (~/.local/share/Trash) }
function  TrashItem(const APath: string): Boolean;
function  DeletePermanently(const APath: string): Boolean;
function  GetTrashItemCount(): Integer;
function  EmptyTrash(): Boolean;

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
  Result := GetHomeDir() + '/.local/share/Trash';
end;

function GetTrashFilesDir(): string;
begin
  Result := GetTrashDir() + '/files';
end;

function GetTrashInfoDir(): string;
begin
  Result := GetTrashDir() + '/info';
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

function PathToUri(const APath: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := 'file://';
  for i := 1 to Length(APath) do
  begin
    c := APath[i];
    if c in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~', '/'] then
      Result := Result + c
    else
      Result := Result + '%' + IntToHex(Ord(c), 2);
  end;
end;

function UriToPath(const AUri: string): string;
var
  s: string;
  i, codeVal: Integer;
  hexStr: string;
begin
  s := Trim(AUri);
  if Pos('file://localhost/', s) = 1 then
    s := Copy(s, 17, MaxInt)
  else if Pos('file://localhost', s) = 1 then
    s := Copy(s, 17, MaxInt)
  else if Pos('file:///', s) = 1 then
    s := Copy(s, 8, MaxInt)
  else if Pos('file://', s) = 1 then
    s := Copy(s, 8, MaxInt);

  Result := '';
  i := 1;
  while i <= Length(s) do
  begin
    if (s[i] = '%') and (i + 2 <= Length(s)) then
    begin
      hexStr := '$' + Copy(s, i + 1, 2);
      codeVal := StrToIntDef(hexStr, -1);
      if codeVal >= 0 then
      begin
        Result := Result + Chr(codeVal);
        Inc(i, 3);
        Continue;
      end;
    end;
    Result := Result + s[i];
    Inc(i);
  end;
end;

procedure SetFileClipboard(const APaths: array of string; ACut: Boolean);
var
  payload: string;
  i: Integer;
begin
  if Length(APaths) = 0 then Exit;
  if ACut then
    payload := 'cut' + LineEnding
  else
    payload := 'copy' + LineEnding;

  for i := 0 to High(APaths) do
  begin
    if APaths[i] <> '' then
      payload := payload + PathToUri(APaths[i]) + LineEnding;
  end;

  FtApp().ClipboardText := payload;
end;

function HasFileClipboard(): Boolean;
var
  clip: string;
begin
  clip := Trim(FtApp().ClipboardText);
  Result := (Pos('copy' + #10, clip) = 1) or (Pos('copy' + #13#10, clip) = 1) or
            (Pos('cut' + #10, clip) = 1) or (Pos('cut' + #13#10, clip) = 1);
end;

function GetFileClipboard(out APaths: TStringArray; out AIsCut: Boolean): Boolean;
var
  lines: TStringList;
  clip, firstLine, uriLine, pathStr: string;
  i: Integer;
begin
  SetLength(APaths, 0);
  AIsCut := False;
  Result := False;

  clip := Trim(FtApp().ClipboardText);
  if clip = '' then Exit;

  lines := TStringList.Create();
  try
    lines.Text := clip;
    if lines.Count < 2 then Exit;

    firstLine := LowerCase(Trim(lines[0]));
    if firstLine = 'cut' then
      AIsCut := True
    else if firstLine = 'copy' then
      AIsCut := False
    else
      Exit;

    for i := 1 to lines.Count - 1 do
    begin
      uriLine := Trim(lines[i]);
      if uriLine = '' then Continue;
      pathStr := UriToPath(uriLine);
      if (pathStr <> '') and (FileExists(pathStr) or DirectoryExists(pathStr)) then
      begin
        SetLength(APaths, Length(APaths) + 1);
        APaths[High(APaths)] := pathStr;
      end;
    end;

    Result := Length(APaths) > 0;
  finally
    lines.Free();
  end;
end;

function MakeUniqueDestination(const ADestDir, AFileName: string): string;
var
  baseName, ext, candidate: string;
  dotPos, counter: Integer;
begin
  dotPos := RPos('.', AFileName);
  if (dotPos > 1) and not DirectoryExists(ADestDir + '/' + AFileName) then
  begin
    baseName := Copy(AFileName, 1, dotPos - 1);
    ext := Copy(AFileName, dotPos, MaxInt);
  end
  else
  begin
    baseName := AFileName;
    ext := '';
  end;

  candidate := ADestDir + '/' + AFileName;
  if not FileExists(candidate) and not DirectoryExists(candidate) then
    Exit(candidate);

  counter := 1;
  repeat
    if counter = 1 then
      candidate := Format('%s/%s (copy)%s', [ADestDir, baseName, ext])
    else
      candidate := Format('%s/%s (copy %d)%s', [ADestDir, baseName, counter, ext]);
    Inc(counter);
  until not FileExists(candidate) and not DirectoryExists(candidate);

  Result := candidate;
end;

function CopyFileInternal(const ASrc, ADst: string): Boolean;
var
  srcStream, dstStream: TFileStream;
begin
  Result := False;
  try
    srcStream := TFileStream.Create(ASrc, fmOpenRead or fmShareDenyNone);
    try
      dstStream := TFileStream.Create(ADst, fmCreate);
      try
        dstStream.CopyFrom(srcStream, srcStream.Size);
        Result := True;
      finally
        dstStream.Free();
      end;
    finally
      srcStream.Free();
    end;
  except
    Result := False;
  end;
end;

function CopyDirectoryInternal(const ASrc, ADst: string): Boolean;
var
  rec: TSearchRec;
  srcItem, dstItem: string;
begin
  Result := CreateDir(ADst);
  if not Result and not DirectoryExists(ADst) then Exit(False);

  if FindFirst(ASrc + '/*', faAnyFile, rec) = 0 then
  begin
    try
      repeat
        if (rec.Name = '.') or (rec.Name = '..') then Continue;
        srcItem := ASrc + '/' + rec.Name;
        dstItem := ADst + '/' + rec.Name;
        if (rec.Attr and faDirectory) <> 0 then
          CopyDirectoryInternal(srcItem, dstItem)
        else
          CopyFileInternal(srcItem, dstItem);
      until FindNext(rec) <> 0;
    finally
      FindClose(rec);
    end;
  end;
  Result := True;
end;

function DeletePermanently(const APath: string): Boolean;
var
  rec: TSearchRec;
  itemPath: string;
begin
  Result := False;
  if DirectoryExists(APath) then
  begin
    if FindFirst(APath + '/*', faAnyFile, rec) = 0 then
    begin
      try
        repeat
          if (rec.Name = '.') or (rec.Name = '..') then Continue;
          itemPath := APath + '/' + rec.Name;
          DeletePermanently(itemPath);
        until FindNext(rec) <> 0;
      finally
        FindClose(rec);
      end;
    end;
    Result := RemoveDir(APath);
  end
  else if FileExists(APath) then
    Result := DeleteFile(APath);
end;

function TrashItem(const APath: string): Boolean;
var
  filesDir, infoDir: string;
  fileName, destFile, infoFile, baseName, ext: string;
  counter, dotPos: Integer;
  infoContent: string;
  infoList: TStringList;
begin
  Result := False;
  if not FileExists(APath) and not DirectoryExists(APath) then Exit;

  filesDir := GetTrashFilesDir();
  infoDir := GetTrashInfoDir();

  ForceDirectories(filesDir);
  ForceDirectories(infoDir);

  fileName := ExtractFileName(APath);
  dotPos := RPos('.', fileName);
  if (dotPos > 1) and not DirectoryExists(APath) then
  begin
    baseName := Copy(fileName, 1, dotPos - 1);
    ext := Copy(fileName, dotPos, MaxInt);
  end
  else
  begin
    baseName := fileName;
    ext := '';
  end;

  destFile := filesDir + '/' + fileName;
  infoFile := infoDir + '/' + fileName + '.trashinfo';
  counter := 1;
  while FileExists(destFile) or DirectoryExists(destFile) or FileExists(infoFile) do
  begin
    destFile := Format('%s/%s.%d%s', [filesDir, baseName, counter, ext]);
    infoFile := Format('%s/%s.%d%s.trashinfo', [infoDir, baseName, counter, ext]);
    Inc(counter);
  end;

  // Move the item into files/
  if not RenameFile(APath, destFile) then
  begin
    // If cross-filesystem move fails, try copy + delete
    if DirectoryExists(APath) then
    begin
      if not CopyDirectoryInternal(APath, destFile) then Exit(False);
      DeletePermanently(APath);
    end
    else
    begin
      if not CopyFileInternal(APath, destFile) then Exit(False);
      DeleteFile(APath);
    end;
  end;

  // Write .trashinfo metadata
  infoContent := '[Trash Info]' + LineEnding +
                 'Path=' + APath + LineEnding +
                 'DeletionDate=' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now) + LineEnding;

  infoList := TStringList.Create();
  try
    infoList.Text := infoContent;
    infoList.SaveToFile(infoFile);
    Result := True;
  finally
    infoList.Free();
  end;
end;

function GetTrashItemCount(): Integer;
var
  rec: TSearchRec;
  fDir: string;
begin
  Result := 0;
  fDir := GetTrashFilesDir();
  if not DirectoryExists(fDir) then Exit;

  if FindFirst(fDir + '/*', faAnyFile, rec) = 0 then
  begin
    try
      repeat
        if (rec.Name <> '.') and (rec.Name <> '..') then
          Inc(Result);
      until FindNext(rec) <> 0;
    finally
      FindClose(rec);
    end;
  end;
end;

function EmptyTrash(): Boolean;
var
  fDir, iDir: string;
  rec: TSearchRec;
begin
  Result := True;
  fDir := GetTrashFilesDir();
  iDir := GetTrashInfoDir();

  if DirectoryExists(fDir) then
  begin
    if FindFirst(fDir + '/*', faAnyFile, rec) = 0 then
    begin
      try
        repeat
          if (rec.Name <> '.') and (rec.Name <> '..') then
            DeletePermanently(fDir + '/' + rec.Name);
        until FindNext(rec) <> 0;
      finally
        FindClose(rec);
      end;
    end;
  end;

  if DirectoryExists(iDir) then
  begin
    if FindFirst(iDir + '/*', faAnyFile, rec) = 0 then
    begin
      try
        repeat
          if (rec.Name <> '.') and (rec.Name <> '..') then
            DeletePermanently(iDir + '/' + rec.Name);
        until FindNext(rec) <> 0;
      finally
        FindClose(rec);
      end;
    end;
  end;
end;

function PasteClipboard(const ADestDir: string): Integer;
var
  paths: TStringArray;
  isCut: Boolean;
  i: Integer;
  src, fileName, targetDest: string;
begin
  Result := 0;
  if not DirectoryExists(ADestDir) then Exit;
  if not GetFileClipboard(paths, isCut) then Exit;

  for i := 0 to High(paths) do
  begin
    src := paths[i];
    if not FileExists(src) and not DirectoryExists(src) then Continue;

    fileName := ExtractFileName(src);
    targetDest := MakeUniqueDestination(ADestDir, fileName);

    if isCut then
    begin
      if RenameFile(src, targetDest) then
        Inc(Result)
      else if DirectoryExists(src) then
      begin
        if CopyDirectoryInternal(src, targetDest) then
        begin
          DeletePermanently(src);
          Inc(Result);
        end;
      end
      else if CopyFileInternal(src, targetDest) then
      begin
        DeleteFile(src);
        Inc(Result);
      end;
    end
    else
    begin
      if DirectoryExists(src) then
      begin
        if CopyDirectoryInternal(src, targetDest) then
          Inc(Result);
      end
      else if CopyFileInternal(src, targetDest) then
        Inc(Result);
    end;
  end;

  if isCut and (Result > 0) then
    FtApp().ClipboardText := '';
end;

end.
