// filesama.window.pas — main application window and FTML integration
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit FileSama.Window;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ftpas, ftpas.types, ftpas.api, ftpas.app, ftpas.canvas, ftpas.widget, ftpas.controls,
  ftpas.layouts, ftpas.menus, ftpas.views, ftpas.dialogs, ftpas.ftml,
  FileSama.Model, FileSama.Ops;

type
  TFileSamaViewMode = (fsvmList, fsvmGrid);

  TFileSamaWindow = class(TFtFTMLForm)
  private
    FModel         : TDirectoryModel;
    FHistory       : TStringList;
    FHistoryIndex  : Integer;
    FFilterQuery   : string;
    FNavigating    : Boolean;
    FViewMode      : TFileSamaViewMode;
    FFilteredIndices: array of Integer;

    // Controls resolved from FTML
    FPathBar       : TFtPathBar;
    FFileTable     : TFtTable;
    FFileGrid      : TFtIconView;
    FPlacesTree    : TFtTreeView;
    FSearchEntry   : TFtEntry;
    FStatusText    : TFtLabel;
    FStatusRight   : TFtLabel;
    FBtnBack       : TFtButton;
    FBtnForward    : TFtButton;
    FBtnUp         : TFtButton;
    FBtnHome       : TFtButton;
    FBtnRefresh    : TFtButton;
    FBtnNewFolder  : TFtButton;
    FBtnHidden     : TFtButton;
    FBtnViewList   : TFtButton;
    FBtnViewGrid   : TFtButton;
    FContextMenu   : TFtPopupMenu;

    { File icon bitmaps (16px for table, 48px for grid) }
    FIconFolder16    : TFtBitmap;
    FIconFile16      : TFtBitmap;
    FIconImage16     : TFtBitmap;
    FIconCode16      : TFtBitmap;
    FIconArchive16   : TFtBitmap;
    FIconFolder48    : TFtBitmap;
    FIconFile48      : TFtBitmap;
    FIconImage48     : TFtBitmap;
    FIconCode48      : TFtBitmap;
    FIconArchive48   : TFtBitmap;
    FIconHome        : TFtBitmap;
    FIconDesktop     : TFtBitmap;
    FIconDocuments   : TFtBitmap;
    FIconDownloads   : TFtBitmap;
    FIconPictures    : TFtBitmap;
    FIconMusic       : TFtBitmap;
    FIconDrive       : TFtBitmap;
    FIconTrash       : TFtBitmap;
    FIconVideos      : TFtBitmap;
    FIconBookmark    : TFtBitmap;
    FSearchRecursive : Boolean;

    function  GetCurrentPath(): string;
    procedure InitIcons();
    procedure FreeIcons();
    procedure SetupPlacesTree();
    function  GetFileIcon(AIsDirectory: Boolean; const AFileName: string; AGrid: Boolean = False): TFtBitmap;
    function  GetSelectedItem(out AItem: TFileItem): Boolean;
    function  PromptRename(const ACurrentName: string; out ANewName: string): Boolean;
    procedure SetViewMode(AMode: TFileSamaViewMode);
    procedure SetupUI();
    procedure HookMenu(const AId: string; AHandler: TFtMenuClickEvent);
    procedure UpdateNavigationState();
    procedure RefreshTable();
    procedure UpdateStatusBar();

    // Event handlers
    procedure HandlePathNavigate(Sender: TFtPathBar; const Path: string);
    procedure HandleTreeSelect(Sender: TFtTreeView; Node: TFtTreeNode);
    procedure HandleTableSelectRow(Sender: TFtTable; RowIndex: Integer);
    procedure HandleTableRowDoubleClick(Sender: TFtTable; RowIndex: Integer);
    procedure HandleColumnClick(Sender: TFtTable; ColumnIndex: Integer);
    procedure HandleGridSelect(Sender: TFtIconView; ItemIndex: Integer);
    procedure HandleGridActivate(Sender: TFtIconView; ItemIndex: Integer);
    procedure HandleWindowKey(Sender: TFtWindow; AKey: LongWord; AIsDown: Boolean);

    // Menu actions
    procedure MenuNewFolder(Sender: TFtMenuItem);
    procedure MenuProperties(Sender: TFtMenuItem);
    procedure MenuQuit(Sender: TFtMenuItem);
    procedure MenuCut(Sender: TFtMenuItem);
    procedure MenuCopy(Sender: TFtMenuItem);
    procedure MenuPaste(Sender: TFtMenuItem);
    procedure MenuRename(Sender: TFtMenuItem);
    procedure MenuDelete(Sender: TFtMenuItem);
    procedure MenuDeletePermanent(Sender: TFtMenuItem);
    procedure MenuSelectAll(Sender: TFtMenuItem);
    procedure MenuSearch(Sender: TFtMenuItem);
    procedure MenuSearchRecursive(Sender: TFtMenuItem);
    procedure MenuToggleHidden(Sender: TFtMenuItem);
    procedure MenuRefresh(Sender: TFtMenuItem);
    procedure MenuGoHome(Sender: TFtMenuItem);
    procedure MenuGoDesktop(Sender: TFtMenuItem);
    procedure MenuGoDocuments(Sender: TFtMenuItem);
    procedure MenuGoDownloads(Sender: TFtMenuItem);
    procedure MenuGoParent(Sender: TFtMenuItem);
    procedure MenuGoRoot(Sender: TFtMenuItem);
    procedure MenuGoLocation(Sender: TFtMenuItem);
    procedure MenuOpenTerminal(Sender: TFtMenuItem);
    procedure MenuAbout(Sender: TFtMenuItem);
    procedure MenuOpenSelection(Sender: TFtMenuItem);
  public
    constructor Create(const AInitialPath: string = ''); reintroduce;
    destructor Destroy(); override;

    procedure NavigateTo(const APath: string; AAddToHistory: Boolean = True);

    // Actions and Event Handlers
    procedure ActionBack(Sender: TFtButton);
    procedure ActionForward(Sender: TFtButton);
    procedure ActionUp(Sender: TFtButton);
    procedure ActionHome(Sender: TFtButton);
    procedure ActionRefresh(Sender: TFtButton);
    procedure ActionNewFolder(Sender: TFtButton);
    procedure ActionToggleHidden(Sender: TFtButton; AToggled: Boolean);
    procedure ActionViewList(Sender: TFtButton);
    procedure ActionViewGrid(Sender: TFtButton);
    procedure HandleSearchChange(Sender: TFtWidget; const AText: string);

    property Model: TDirectoryModel read FModel;
    property CurrentPath: string read GetCurrentPath;
    property ViewMode: TFileSamaViewMode read FViewMode write SetViewMode;
    property PathBar: TFtPathBar read FPathBar;
    property FileTable: TFtTable read FFileTable;
    property FileGrid: TFtIconView read FFileGrid;
    property PlacesTree: TFtTreeView read FPlacesTree;
    property SearchEntry: TFtEntry read FSearchEntry;
    property StatusText: TFtLabel read FStatusText;
    property StatusRight: TFtLabel read FStatusRight;
    property History: TStringList read FHistory;
    property HistoryIndex: Integer read FHistoryIndex;
  end;

implementation

{$R filesama.res}

// -----------------------------------------------------------------------------
// TFileSamaWindow Implementation
// -----------------------------------------------------------------------------

constructor TFileSamaWindow.Create(const AInitialPath: string);
var
  startPath: string;
begin
  inherited Create(1040, 680, 'filesama', 'TFileSamaWindow');

  FModel := TDirectoryModel.Create();
  FHistory := TStringList.Create();
  FHistoryIndex := -1;
  FFilterQuery := '';
  FSearchRecursive := False;
  FNavigating := False;

  InitIcons();
  SetupUI();

  if AInitialPath <> '' then
    startPath := AInitialPath
  else
    startPath := GetHomeDir();

  NavigateTo(startPath, True);
end;

destructor TFileSamaWindow.Destroy();

  procedure FreeAllNodeData(ANode: TFtTreeNode);
  var
    j: Integer;
    ch: TFtTreeNode;
  begin
    if ANode = nil then Exit;
    if Assigned(ANode.Data) then
    begin
      FreeMem(ANode.Data);
      ANode.Data := nil;
    end;
    for j := 0 to ANode.ChildCount - 1 do
    begin
      ch := ANode.Children[j];
      FreeAllNodeData(ch);
      ch.Free();
    end;
  end;
begin
  if (FPlacesTree <> nil) and (FPlacesTree.Root <> nil) then
    FreeAllNodeData(FPlacesTree.Root);
  FreeIcons();
  FHistory.Free();
  FModel.Free();
  inherited Destroy();
end;

procedure TFileSamaWindow.InitIcons();
var
  isDark: Boolean;
begin
  isDark := FtApp().DarkMode;
  FIconFolder16  := FtApp().GetIconBitmap('folder', 16, 16, isDark);
  FIconFile16    := FtApp().GetIconBitmap('file', 16, 16, isDark);
  FIconImage16   := FtApp().GetIconBitmap('file-image', 16, 16, isDark);
  FIconCode16    := FtApp().GetIconBitmap('file-code', 16, 16, isDark);
  FIconArchive16 := FtApp().GetIconBitmap('file-archive', 16, 16, isDark);

  FIconFolder48  := FtApp().GetIconBitmap('folder', 48, 48, isDark);
  FIconFile48    := FtApp().GetIconBitmap('file', 48, 48, isDark);
  FIconImage48   := FtApp().GetIconBitmap('file-image', 48, 48, isDark);
  FIconCode48    := FtApp().GetIconBitmap('file-code', 48, 48, isDark);
  FIconArchive48 := FtApp().GetIconBitmap('file-archive', 48, 48, isDark);

  FIconHome      := FtApp().GetIconBitmap('outline-home', 16, 16, isDark);
  FIconDesktop   := FtApp().GetIconBitmap('outline-desktop', 16, 16, isDark);
  FIconDocuments := FtApp().GetIconBitmap('outline-documents', 16, 16, isDark);
  FIconDownloads := FtApp().GetIconBitmap('outline-downloads', 16, 16, isDark);
  FIconPictures  := FtApp().GetIconBitmap('outline-pictures', 16, 16, isDark);
  FIconMusic     := FtApp().GetIconBitmap('outline-music', 16, 16, isDark);
  FIconDrive     := FtApp().GetIconBitmap('outline-drive', 16, 16, isDark);
  FIconTrash     := FtApp().GetIconBitmap('outline-trash', 16, 16, isDark);
  FIconVideos    := FtApp().GetIconBitmap('outline-videos', 16, 16, isDark);
  FIconBookmark  := FtApp().GetIconBitmap('outline-bookmark', 16, 16, isDark);
end;

procedure TFileSamaWindow.FreeIcons();
begin
  FreeAndNil(FIconFolder16);
  FreeAndNil(FIconFile16);
  FreeAndNil(FIconImage16);
  FreeAndNil(FIconCode16);
  FreeAndNil(FIconArchive16);
  FreeAndNil(FIconFolder48);
  FreeAndNil(FIconFile48);
  FreeAndNil(FIconImage48);
  FreeAndNil(FIconCode48);
  FreeAndNil(FIconArchive48);
  FreeAndNil(FIconHome);
  FreeAndNil(FIconDesktop);
  FreeAndNil(FIconDocuments);
  FreeAndNil(FIconDownloads);
  FreeAndNil(FIconPictures);
  FreeAndNil(FIconMusic);
  FreeAndNil(FIconDrive);
  FreeAndNil(FIconTrash);
  FreeAndNil(FIconVideos);
  FreeAndNil(FIconBookmark);
end;

function TFileSamaWindow.GetFileIcon(AIsDirectory: Boolean; const AFileName: string; AGrid: Boolean = False): TFtBitmap;
var
  ext: string;
begin
  if AIsDirectory then
  begin
    if AGrid then Exit(FIconFolder48) else Exit(FIconFolder16);
  end;

  ext := LowerCase(ExtractFileExt(AFileName));
  if (ext <> '') and (ext[1] = '.') then
    Delete(ext, 1, 1);
  if (ext = 'png') or (ext = 'jpg') or (ext = 'jpeg') or (ext = 'bmp') or
     (ext = 'svg') or (ext = 'gif') or (ext = 'webp') or (ext = 'ico') then
  begin
    if AGrid then Result := FIconImage48 else Result := FIconImage16;
  end
  else if (ext = 'pas') or (ext = 'pp') or (ext = 'c') or (ext = 'h') or
          (ext = 'cpp') or (ext = 'py') or (ext = 'sh') or (ext = 'bash') or
          (ext = 'json') or (ext = 'xml') or (ext = 'html') or (ext = 'css') or
          (ext = 'md') or (ext = 'js') or (ext = 'ts') or (ext = 'sql') then
  begin
    if AGrid then Result := FIconCode48 else Result := FIconCode16;
  end
  else if (ext = 'zip') or (ext = 'tar') or (ext = 'gz') or (ext = 'xz') or
          (ext = '7z') or (ext = 'bz2') or (ext = 'rar') then
  begin
    if AGrid then Result := FIconArchive48 else Result := FIconArchive16;
  end
  else
  begin
    if AGrid then Result := FIconFile48 else Result := FIconFile16;
  end;
end;

procedure TFileSamaWindow.SetupPlacesTree();
var
  homeDir, bkmkFile, line, uri, bLabel, bPath, sub, dev, mnt: string;
  spacePos: Integer;
  tf: TextFile;
  seenMounts: TStringList;

  procedure FreeAllNodeData(ANode: TFtTreeNode);
  var
    j: Integer;
    ch: TFtTreeNode;
  begin
    if ANode = nil then Exit;
    if Assigned(ANode.Data) then
    begin
      FreeMem(ANode.Data);
      ANode.Data := nil;
    end;
    for j := 0 to ANode.ChildCount - 1 do
    begin
      ch := ANode.Children[j];
      FreeAllNodeData(ch);
      ch.Free();
    end;
  end;

  procedure AddPlaceNode(const AText, APath: string; AIcon: TFtBitmap);
  var
    n: TFtTreeNode;
    pathBuf: PChar;
  begin
    if (APath <> homeDir) and (APath <> '/') and not DirectoryExists(APath) then
      Exit;
    n := FPlacesTree.AddNode(AText);
    n.Expanded := True;
    n.SetIcon(AIcon);
    GetMem(pathBuf, Length(APath) + 1);
    Move(Pointer(APath)^, pathBuf^, Length(APath));
    pathBuf[Length(APath)] := #0;
    n.Data := pathBuf;
  end;

  function DecodeMountEscape(const S: string): string;
  begin
    Result := StringReplace(S, '\040', ' ', [rfReplaceAll]);
    Result := StringReplace(Result, '\011', #9, [rfReplaceAll]);
    Result := StringReplace(Result, '\012', #10, [rfReplaceAll]);
    Result := StringReplace(Result, '\134', '\', [rfReplaceAll]);
  end;

begin
  if FPlacesTree = nil then Exit;
  if FPlacesTree.Root <> nil then
  begin
    FreeAllNodeData(FPlacesTree.Root);
    FPlacesTree.Clear();
  end;

  homeDir := GetHomeDir();

  { Places }
  AddPlaceNode('Home',      homeDir, FIconHome);
  AddPlaceNode('Desktop',   GetDesktopDir(), FIconDesktop);
  AddPlaceNode('Documents', GetDocumentsDir(), FIconDocuments);
  AddPlaceNode('Downloads', GetDownloadsDir(), FIconDownloads);
  AddPlaceNode('Pictures',  GetPicturesDir(), FIconPictures);
  AddPlaceNode('Music',     GetMusicDir(), FIconMusic);
  AddPlaceNode('Videos',    GetVideosDir(), FIconVideos);
  AddPlaceNode('Trash',     GetTrashFilesDir(), FIconTrash);

  { Bookmarks from ~/.config/gtk-3.0/bookmarks }
  bkmkFile := homeDir + '/.config/gtk-3.0/bookmarks';
  if FileExists(bkmkFile) then
  begin
    AssignFile(tf, bkmkFile);
    {$I-}
    Reset(tf);
    {$I+}
    if IOResult = 0 then
    begin
      while not Eof(tf) do
      begin
        ReadLn(tf, line);
        line := Trim(line);
        if (line = '') or (line[1] = '#') then Continue;
        if Pos('file://', line) = 1 then
        begin
          spacePos := Pos(' ', line);
          if spacePos > 0 then
          begin
            uri := Copy(line, 1, spacePos - 1);
            bLabel := Trim(Copy(line, spacePos + 1, MaxInt));
          end
          else
          begin
            uri := line;
            bLabel := '';
          end;
          bPath := UriToPath(uri);
          if bLabel = '' then
            bLabel := ExtractFileName(bPath);
          if bLabel = '' then
            bLabel := bPath;
          if (bPath <> homeDir) and
             (bPath <> GetDesktopDir()) and
             (bPath <> GetDocumentsDir()) and
             (bPath <> GetDownloadsDir()) and
             (bPath <> GetPicturesDir()) and
             (bPath <> GetMusicDir()) and
             (bPath <> GetVideosDir()) and
             DirectoryExists(bPath) then
            AddPlaceNode(bLabel, bPath, FIconBookmark);
        end;
      end;
      CloseFile(tf);
    end;
  end;

  { Devices / Mounts }
  AddPlaceNode('Root', '/', FIconDrive);

  seenMounts := TStringList.Create();
  try
    seenMounts.Add('/');
    if FileExists('/proc/mounts') then
    begin
      AssignFile(tf, '/proc/mounts');
      {$I-}
      Reset(tf);
      {$I+}
      if IOResult = 0 then
      begin
        while not Eof(tf) do
        begin
          ReadLn(tf, line);
          line := Trim(line);
          if line = '' then Continue;
          spacePos := Pos(' ', line);
          if spacePos = 0 then Continue;
          dev := Copy(line, 1, spacePos - 1);
          sub := Trim(Copy(line, spacePos + 1, MaxInt));
          spacePos := Pos(' ', sub);
          if spacePos = 0 then Continue;
          mnt := DecodeMountEscape(Copy(sub, 1, spacePos - 1));

          if (Pos('/media/', mnt) = 1) or
             (Pos('/run/media/', mnt) = 1) or
             (Pos('/mnt/', mnt) = 1) then
          begin
            if (seenMounts.IndexOf(mnt) < 0) and DirectoryExists(mnt) then
            begin
              seenMounts.Add(mnt);
              bLabel := ExtractFileName(mnt);
              if bLabel = '' then bLabel := mnt;
              AddPlaceNode(bLabel, mnt, FIconDrive);
            end;
          end;
        end;
        CloseFile(tf);
      end;
    end;
  finally
    seenMounts.Free();
  end;
end;

function TFileSamaWindow.GetCurrentPath(): string;
begin
  if FModel <> nil then
    Result := FModel.CurrentPath
  else
    Result := '';
end;

procedure TFileSamaWindow.SetupUI();
var
  w: TFtWidget;
begin
  w := FindWidget('pathBar');
  if w is TFtPathBar then FPathBar := TFtPathBar(w);

  w := FindWidget('fileTable');
  if w is TFtTable then FFileTable := TFtTable(w);

  w := FindWidget('placesTree');
  if w is TFtTreeView then FPlacesTree := TFtTreeView(w);

  w := FindWidget('searchEntry');
  if w is TFtEntry then FSearchEntry := TFtEntry(w);

  w := FindWidget('statusText');
  if w is TFtLabel then FStatusText := TFtLabel(w);

  w := FindWidget('statusRight');
  if w is TFtLabel then FStatusRight := TFtLabel(w);

  w := FindWidget('btnBack');
  if w is TFtButton then FBtnBack := TFtButton(w);

  w := FindWidget('btnForward');
  if w is TFtButton then FBtnForward := TFtButton(w);

  w := FindWidget('btnUp');
  if w is TFtButton then FBtnUp := TFtButton(w);

  w := FindWidget('btnHome');
  if w is TFtButton then FBtnHome := TFtButton(w);

  w := FindWidget('btnRefresh');
  if w is TFtButton then FBtnRefresh := TFtButton(w);

  w := FindWidget('btnNewFolder');
  if w is TFtButton then FBtnNewFolder := TFtButton(w);

  w := FindWidget('btnHidden');
  if w is TFtButton then
  begin
    FBtnHidden := TFtButton(w);
    FBtnHidden.OnToggle := @ActionToggleHidden;
  end;

  w := FindWidget('btnViewList');
  if w is TFtButton then
  begin
    FBtnViewList := TFtButton(w);
    FBtnViewList.OnClick := @ActionViewList;
    FBtnViewList.Toggled := (FViewMode = fsvmList);
  end;

  w := FindWidget('btnViewGrid');
  if w is TFtButton then
  begin
    FBtnViewGrid := TFtButton(w);
    FBtnViewGrid.OnClick := @ActionViewGrid;
    FBtnViewGrid.Toggled := (FViewMode = fsvmGrid);
  end;

  w := FindWidget('fileContextMenu');
  if w is TFtPopupMenu then FContextMenu := TFtPopupMenu(w);

  w := FindWidget('fileGrid');
  if w is TFtIconView then
  begin
    FFileGrid := TFtIconView(w);
    FFileGrid.OnSelect := @HandleGridSelect;
    FFileGrid.OnActivate := @HandleGridActivate;
    if FContextMenu <> nil then
      FFileGrid.ContextMenuHandle := FContextMenu.Handle;
  end;

  // Wire up button signals
  if FBtnBack <> nil then FBtnBack.OnClick := @ActionBack;
  if FBtnForward <> nil then FBtnForward.OnClick := @ActionForward;
  if FBtnUp <> nil then FBtnUp.OnClick := @ActionUp;
  if FBtnHome <> nil then FBtnHome.OnClick := @ActionHome;
  if FBtnRefresh <> nil then FBtnRefresh.OnClick := @ActionRefresh;
  if FBtnNewFolder <> nil then FBtnNewFolder.OnClick := @ActionNewFolder;

  // Wire up widget signals
  if FPathBar <> nil then FPathBar.OnNavigate := @HandlePathNavigate;
  if FPlacesTree <> nil then FPlacesTree.OnSelect := @HandleTreeSelect;
  if FSearchEntry <> nil then FSearchEntry.OnChange := @HandleSearchChange;

  if FFileTable <> nil then
  begin
    FFileTable.OnSelectRow := @HandleTableSelectRow;
    FFileTable.OnRowDoubleClick := @HandleTableRowDoubleClick;
    FFileTable.OnColumnClick := @HandleColumnClick;
    if FContextMenu <> nil then
      FFileTable.ContextMenuHandle := FContextMenu.Handle;
  end;

  // Wire up Menu actions
  HookMenu('newFolderItem', @MenuNewFolder);
  HookMenu('propertiesItem', @MenuProperties);
  HookMenu('quitItem', @MenuQuit);
  HookMenu('cutItem', @MenuCut);
  HookMenu('copyItem', @MenuCopy);
  HookMenu('pasteItem', @MenuPaste);
  HookMenu('renameItem', @MenuRename);
  HookMenu('deleteItem', @MenuDelete);
  HookMenu('deletePermanentItem', @MenuDeletePermanent);
  HookMenu('selectAllItem', @MenuSelectAll);
  HookMenu('refreshItem', @MenuRefresh);
  HookMenu('showHiddenItem', @MenuToggleHidden);
  HookMenu('goHomeItem', @MenuGoHome);
  HookMenu('goDesktopItem', @MenuGoDesktop);
  HookMenu('goDocumentsItem', @MenuGoDocuments);
  HookMenu('goDownloadsItem', @MenuGoDownloads);
  HookMenu('goParentItem', @MenuGoParent);
  HookMenu('goRootItem', @MenuGoRoot);
  HookMenu('goLocationItem', @MenuGoLocation);
  HookMenu('openTerminalItem', @MenuOpenTerminal);
  HookMenu('aboutItem', @MenuAbout);

  // Search menu actions
  HookMenu('searchItem', @MenuSearch);
  HookMenu('searchRecursiveItem', @MenuSearchRecursive);

  // Context menu actions
  HookMenu('ctxOpenItem', @MenuOpenSelection);
  HookMenu('ctxOpenTerminalItem', @MenuOpenTerminal);
  HookMenu('ctxCutItem', @MenuCut);
  HookMenu('ctxCopyItem', @MenuCopy);
  HookMenu('ctxPasteItem', @MenuPaste);
  HookMenu('ctxRenameItem', @MenuRename);
  HookMenu('ctxDeleteItem', @MenuDelete);
  HookMenu('ctxDeletePermanentItem', @MenuDeletePermanent);
  HookMenu('ctxPropertiesItem', @MenuProperties);

  // Window keyboard shortcuts
  Self.OnKey := @HandleWindowKey;

  SetupPlacesTree();
end;

procedure TFileSamaWindow.HookMenu(const AId: string; AHandler: TFtMenuClickEvent);
var
  mi: TFtMenuItem;
begin
  mi := FindMenuItem(AId);
  if mi <> nil then
    mi.OnClick := AHandler;
end;

procedure TFileSamaWindow.NavigateTo(const APath: string; AAddToHistory: Boolean);
var
  resolved: string;
begin
  if FNavigating then Exit;
  FNavigating := True;
  try
    resolved := ExpandFileName(APath);
    if not DirectoryExists(resolved) then Exit;

    if AAddToHistory then
    begin
      // Trim forward history if we are in the middle of stack
      while FHistory.Count > FHistoryIndex + 1 do
        FHistory.Delete(FHistory.Count - 1);
      FHistory.Add(resolved);
      FHistoryIndex := FHistory.Count - 1;
    end;

    FModel.ScanDirectory(resolved);

    if FPathBar <> nil then
      FPathBar.Path := resolved;

    Title := ExtractFileName(resolved) + ' — Files';
    if Title = ' — Files' then
      Title := '/ — Files';

    RefreshTable();
    UpdateNavigationState();
    UpdateStatusBar();
  finally
    FNavigating := False;
  end;
end;

procedure TFileSamaWindow.RefreshTable();
var
  i, rowIdx, gridIdx: Integer;
  item: TFileItem;
  matches: Boolean;
begin
  if (FFileTable = nil) and (FFileGrid = nil) then Exit;

  if FFileTable <> nil then FFileTable.ClearRows();
  if FFileGrid <> nil then FFileGrid.Clear();
  SetLength(FFilteredIndices, 0);

  for i := 0 to FModel.Count - 1 do
  begin
    item := FModel[i];

    // Filter check (when not already filtered by recursive search)
    if (FFilterQuery <> '') and (not FSearchRecursive) and (FFilterQuery[1] <> '*') then
    begin
      matches := Pos(LowerCase(FFilterQuery), LowerCase(item.Name)) > 0;
      if not matches then Continue;
    end;

    SetLength(FFilteredIndices, Length(FFilteredIndices) + 1);
    FFilteredIndices[High(FFilteredIndices)] := i;

    if FFileTable <> nil then
    begin
      rowIdx := FFileTable.AddRow();
      FFileTable.SetCell(rowIdx, 0, item.Name);
      FFileTable.SetCell(rowIdx, 1, item.SizeFormatted);
      FFileTable.SetCell(rowIdx, 2, item.ModTimeFormatted);
      FFileTable.SetCell(rowIdx, 3, item.TypeDescription);
      FFileTable.SetCellIcon(rowIdx, 0, GetFileIcon(item.IsDirectory, item.Name, False));
    end;

    if FFileGrid <> nil then
    begin
      gridIdx := FFileGrid.AddItem(item.Name, GetFileIcon(item.IsDirectory, item.Name, True));
      FFileGrid.Subtexts[gridIdx] := item.SizeFormatted;
      FFileGrid.Tags[gridIdx] := i;
    end;
  end;
end;

procedure TFileSamaWindow.UpdateNavigationState();
begin
  if FBtnBack <> nil then
    FBtnBack.Enabled := (FHistoryIndex > 0);

  if FBtnForward <> nil then
    FBtnForward.Enabled := (FHistoryIndex < FHistory.Count - 1);

  if FBtnUp <> nil then
    FBtnUp.Enabled := (FModel.CurrentPath <> '/') and (FModel.CurrentPath <> '');
end;

procedure TFileSamaWindow.UpdateStatusBar();
var
  dirs, files: Integer;
  i: Integer;
  infoStr: string;
begin
  dirs := 0;
  files := 0;
  for i := 0 to FModel.Count - 1 do
  begin
    if FModel[i].IsDirectory then
      Inc(dirs)
    else
      Inc(files);
  end;

  infoStr := Format('%d items (%d folders, %d files)', [FModel.Count, dirs, files]);
  if FStatusText <> nil then
    FStatusText.Text := infoStr;

  if FStatusRight <> nil then
    FStatusRight.Text := GetAvailableDiskSpace(FModel.CurrentPath);
end;

// -----------------------------------------------------------------------------
// Signal Handlers
// -----------------------------------------------------------------------------

procedure TFileSamaWindow.HandlePathNavigate(Sender: TFtPathBar; const Path: string);
begin
  NavigateTo(Path, True);
end;

procedure TFileSamaWindow.HandleTreeSelect(Sender: TFtTreeView; Node: TFtTreeNode);
var
  nodeName: string;
begin
  if Node = nil then Exit;
  if Node.Data <> nil then
  begin
    NavigateTo(string(PChar(Node.Data)), True);
    Exit;
  end;

  nodeName := Node.Text;

  if nodeName = 'Home' then
    NavigateTo(GetHomeDir())
  else if nodeName = 'Desktop' then
    NavigateTo(GetDesktopDir())
  else if nodeName = 'Documents' then
    NavigateTo(GetDocumentsDir())
  else if nodeName = 'Downloads' then
    NavigateTo(GetDownloadsDir())
  else if nodeName = 'Pictures' then
    NavigateTo(GetPicturesDir())
  else if nodeName = 'Music' then
    NavigateTo(GetMusicDir())
  else if nodeName = 'Videos' then
    NavigateTo(GetVideosDir())
  else if nodeName = 'Root' then
    NavigateTo('/')
  else if nodeName = 'Trash' then
    NavigateTo(GetTrashFilesDir());
end;

function TFileSamaWindow.GetSelectedItem(out AItem: TFileItem): Boolean;
var
  selIdx, modelIdx: Integer;
begin
  AItem := nil;
  Result := False;
  if FViewMode = fsvmList then
  begin
    if FFileTable <> nil then
      selIdx := FFileTable.SelectedRow
    else
      selIdx := -1;
  end
  else
  begin
    if FFileGrid <> nil then
      selIdx := FFileGrid.SelectedIndex
    else
      selIdx := -1;
  end;

  if (selIdx >= 0) and (selIdx < Length(FFilteredIndices)) then
  begin
    modelIdx := FFilteredIndices[selIdx];
    if (modelIdx >= 0) and (modelIdx < FModel.Count) then
    begin
      AItem := FModel[modelIdx];
      Result := True;
    end;
  end;
end;

procedure TFileSamaWindow.SetViewMode(AMode: TFileSamaViewMode);
var
  selIdx: Integer;
begin
  FViewMode := AMode;
  if FBtnViewList <> nil then
    FBtnViewList.Toggled := (FViewMode = fsvmList);
  if FBtnViewGrid <> nil then
    FBtnViewGrid.Toggled := (FViewMode = fsvmGrid);

  if (FFileTable <> nil) and (FFileGrid <> nil) then
  begin
    if FViewMode = fsvmList then
    begin
      selIdx := FFileGrid.SelectedIndex;
      FFileGrid.Visible := False;
      FFileTable.Visible := True;
      if selIdx >= 0 then
      begin
        FFileTable.SelectedRow := selIdx;
        HandleTableSelectRow(FFileTable, selIdx);
      end;
    end
    else
    begin
      selIdx := FFileTable.SelectedRow;
      FFileTable.Visible := False;
      FFileGrid.Visible := True;
      if selIdx >= 0 then
      begin
        FFileGrid.SelectedIndex := selIdx;
        FFileGrid.ScrollIntoView(selIdx);
        HandleGridSelect(FFileGrid, selIdx);
      end;
    end;
  end;
end;

procedure TFileSamaWindow.HandleTableSelectRow(Sender: TFtTable; RowIndex: Integer);
var
  modelIdx: Integer;
  item: TFileItem;
begin
  if (RowIndex >= 0) and (RowIndex < Length(FFilteredIndices)) then
  begin
    modelIdx := FFilteredIndices[RowIndex];
    if (modelIdx >= 0) and (modelIdx < FModel.Count) then
    begin
      item := FModel[modelIdx];
      if FStatusText <> nil then
        FStatusText.Text := Format('"%s" selected (%s, %s)', [item.Name, item.TypeDescription, item.SizeFormatted]);
    end;
  end;
end;

procedure TFileSamaWindow.HandleTableRowDoubleClick(Sender: TFtTable; RowIndex: Integer);
var
  modelIdx: Integer;
  item: TFileItem;
begin
  if (RowIndex >= 0) and (RowIndex < Length(FFilteredIndices)) then
  begin
    modelIdx := FFilteredIndices[RowIndex];
    if (modelIdx >= 0) and (modelIdx < FModel.Count) then
    begin
      item := FModel[modelIdx];
      if item.IsDirectory then
        NavigateTo(item.FullPath, True)
      else
        LaunchFile(item.FullPath);
    end;
  end;
end;

procedure TFileSamaWindow.HandleGridSelect(Sender: TFtIconView; ItemIndex: Integer);
var
  modelIdx: Integer;
  item: TFileItem;
begin
  if (ItemIndex >= 0) and (ItemIndex < Length(FFilteredIndices)) then
  begin
    modelIdx := FFilteredIndices[ItemIndex];
    if (modelIdx >= 0) and (modelIdx < FModel.Count) then
    begin
      item := FModel[modelIdx];
      if FStatusText <> nil then
        FStatusText.Text := Format('"%s" selected (%s, %s)', [item.Name, item.TypeDescription, item.SizeFormatted]);
    end;
  end;
end;

procedure TFileSamaWindow.HandleGridActivate(Sender: TFtIconView; ItemIndex: Integer);
var
  modelIdx: Integer;
  item: TFileItem;
begin
  if (ItemIndex >= 0) and (ItemIndex < Length(FFilteredIndices)) then
  begin
    modelIdx := FFilteredIndices[ItemIndex];
    if (modelIdx >= 0) and (modelIdx < FModel.Count) then
    begin
      item := FModel[modelIdx];
      if item.IsDirectory then
        NavigateTo(item.FullPath, True)
      else
        LaunchFile(item.FullPath);
    end;
  end;
end;

procedure TFileSamaWindow.HandleSearchChange(Sender: TFtWidget; const AText: string);
var
  query: string;
begin
  FFilterQuery := Trim(AText);
  if FSearchRecursive or ((FFilterQuery <> '') and (FFilterQuery[1] = '*')) then
  begin
    query := FFilterQuery;
    if (query <> '') and (query[1] = '*') then
      query := Trim(Copy(query, 2, MaxInt));
    if query <> '' then
      FModel.SearchRecursive(FModel.CurrentPath, query)
    else
      FModel.ScanDirectory(FModel.CurrentPath);
  end;
  RefreshTable();
end;

// -----------------------------------------------------------------------------
// Button Action Handlers
// -----------------------------------------------------------------------------

procedure TFileSamaWindow.ActionBack(Sender: TFtButton);
begin
  if FHistoryIndex > 0 then
  begin
    Dec(FHistoryIndex);
    NavigateTo(FHistory[FHistoryIndex], False);
  end;
end;

procedure TFileSamaWindow.ActionForward(Sender: TFtButton);
begin
  if FHistoryIndex < FHistory.Count - 1 then
  begin
    Inc(FHistoryIndex);
    NavigateTo(FHistory[FHistoryIndex], False);
  end;
end;

procedure TFileSamaWindow.ActionUp(Sender: TFtButton);
begin
  NavigateTo(GetParentPath(FModel.CurrentPath), True);
end;

procedure TFileSamaWindow.ActionHome(Sender: TFtButton);
begin
  NavigateTo(GetHomeDir(), True);
end;

procedure TFileSamaWindow.ActionRefresh(Sender: TFtButton);
begin
  NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.ActionNewFolder(Sender: TFtButton);
begin
  MenuNewFolder(nil);
end;

procedure TFileSamaWindow.ActionToggleHidden(Sender: TFtButton; AToggled: Boolean);
var
  mi: TFtMenuItem;
begin
  FModel.ShowHidden := AToggled;
  mi := FindMenuItem('showHiddenItem');
  if mi <> nil then
    mi.Checked := AToggled;
  NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.ActionViewList(Sender: TFtButton);
begin
  SetViewMode(fsvmList);
end;

procedure TFileSamaWindow.ActionViewGrid(Sender: TFtButton);
begin
  SetViewMode(fsvmGrid);
end;

procedure TFileSamaWindow.HandleColumnClick(Sender: TFtTable; ColumnIndex: Integer);
begin
  if FModel.SortColumn = ColumnIndex then
    FModel.Sort(ColumnIndex, not FModel.SortAscending)
  else
    FModel.Sort(ColumnIndex, True);
  RefreshTable();
end;

// -----------------------------------------------------------------------------
// Menu Action Handlers
// -----------------------------------------------------------------------------

procedure TFileSamaWindow.MenuNewFolder(Sender: TFtMenuItem);
var
  folderName: string;
  i: Integer;
begin
  folderName := 'New Folder';
  i := 1;
  while DirectoryExists(FModel.CurrentPath + '/' + folderName) do
  begin
    Inc(i);
    folderName := Format('New Folder %d', [i]);
  end;

  if CreateNewFolder(FModel.CurrentPath, folderName) then
    NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.MenuProperties(Sender: TFtMenuItem);
var
  item: TFileItem;
  msg: string;
begin
  if GetSelectedItem(item) then
  begin
    msg := Format('Name: %s' + LineEnding +
                  'Path: %s' + LineEnding +
                  'Type: %s (%s)' + LineEnding +
                  'Size: %s' + LineEnding +
                  'Permissions: %s' + LineEnding +
                  'Modified: %s',
                  [item.Name, item.FullPath, item.TypeDescription, item.MimeType,
                   item.SizeFormatted, item.Permissions, item.ModTimeFormatted]);
    TFtMessageDialog.ShowMessage(msg, 'Item Properties');
  end
  else
  begin
    msg := Format('Location: %s' + LineEnding +
                  'Available Space: %s',
                  [FModel.CurrentPath, GetAvailableDiskSpace(FModel.CurrentPath)]);
    TFtMessageDialog.ShowMessage(msg, 'Directory Properties');
  end;
end;

type
  TRenamePromptSession = class
  private
    FWindow: TFtWindow;
    FEntry: TFtEntry;
    procedure HandleCancel(Sender: TFtButton);
    procedure HandleRename(Sender: TFtButton);
    procedure HandleSubmit(Sender: TFtWidget; const AText: string);
    procedure HandleKey(Sender: TFtWindow; AKey: LongWord; AIsDown: Boolean);
  public
    constructor Create(AWin: TFtWindow; AEnt: TFtEntry);
  end;

constructor TRenamePromptSession.Create(AWin: TFtWindow; AEnt: TFtEntry);
begin
  inherited Create();
  FWindow := AWin;
  FEntry := AEnt;
end;

procedure TRenamePromptSession.HandleCancel(Sender: TFtButton);
begin
  FWindow.ModalResult := FT_MODAL_CANCEL;
  FWindow.Hide();
end;

procedure TRenamePromptSession.HandleRename(Sender: TFtButton);
begin
  FWindow.ModalResult := FT_MODAL_OK;
  FWindow.Hide();
end;

procedure TRenamePromptSession.HandleSubmit(Sender: TFtWidget; const AText: string);
begin
  FWindow.ModalResult := FT_MODAL_OK;
  FWindow.Hide();
end;

procedure TRenamePromptSession.HandleKey(Sender: TFtWindow; AKey: LongWord; AIsDown: Boolean);
begin
  if not AIsDown then Exit;
  if AKey = $FF1B then
  begin
    FWindow.ModalResult := FT_MODAL_CANCEL;
    FWindow.Hide();
  end
  else if (AKey = $FF0D) or (AKey = $FF8D) then
  begin
    FWindow.ModalResult := FT_MODAL_OK;
    FWindow.Hide();
  end;
end;

function TFileSamaWindow.PromptRename(const ACurrentName: string; out ANewName: string): Boolean;
var
  dlg: TFtWindow;
  lbl: TFtLabel;
  entry: TFtEntry;
  btnCancel, btnRename: TFtButton;
  session: TRenamePromptSession;
  res: Integer;
  val: string;
begin
  Result := False;
  ANewName := '';
  dlg := TFtWindow.Create(380, 140, 'Rename');
  dlg.WindowType := ftwtDialog;
  try
    lbl := TFtLabel.Create(dlg, 20, 16, 340, 20, 'Enter a new name:');
    entry := TFtEntry.Create(dlg, 20, 44, 340, 32, ACurrentName);
    btnCancel := TFtButton.Create(dlg, 180, 92, 80, 30, 'Cancel');
    btnRename := TFtButton.Create(dlg, 270, 92, 90, 30, 'Rename');

    session := TRenamePromptSession.Create(dlg, entry);
    try
      btnCancel.OnClick := @session.HandleCancel;
      btnRename.OnClick := @session.HandleRename;
      entry.OnSubmit := @session.HandleSubmit;
      dlg.OnKey := @session.HandleKey;

      dlg.Show();
      entry.SetFocus();
      res := dlg.ShowModal();
      if res = FT_MODAL_OK then
      begin
        val := Trim(entry.Text);
        if (val <> '') and (val <> ACurrentName) then
        begin
          ANewName := val;
          Result := True;
        end;
      end;
    finally
      session.Free();
    end;
  finally
    dlg.Free();
  end;
end;

procedure TFileSamaWindow.HandleWindowKey(Sender: TFtWindow; AKey: LongWord; AIsDown: Boolean);
var
  mods: Cardinal;
  hasCtrl, hasShift, hasAlt: Boolean;
begin
  if not AIsDown then Exit;

  // If search filter entry is active and typing, let it handle standard typing
  if (FSearchEntry <> nil) and FSearchEntry.Focused then
  begin
    if AKey = $FF1B then // Escape: clear search and return to list
    begin
      FSearchEntry.Text := '';
      FFilterQuery := '';
      if FSearchRecursive then
        FModel.ScanDirectory(FModel.CurrentPath);
      RefreshTable();
      if FViewMode = fsvmList then
      begin
        if FFileTable <> nil then FFileTable.SetFocus();
      end
      else
      begin
        if FFileGrid <> nil then FFileGrid.SetFocus();
      end;
    end
    else if (AKey = $FF0D) or (AKey = $FF8D) then // Enter: focus list/grid
    begin
      if FViewMode = fsvmList then
      begin
        if FFileTable <> nil then FFileTable.SetFocus();
      end
      else
      begin
        if FFileGrid <> nil then FFileGrid.SetFocus();
      end;
    end;
    Exit;
  end;

  mods := FtApp().GetKeyboardModifiers();
  hasCtrl := (mods and FT_KEY_MOD_CONTROL) <> 0;
  hasShift := (mods and FT_KEY_MOD_SHIFT) <> 0;
  hasAlt := (mods and FT_KEY_MOD_ALT) <> 0;

  // F2: Rename
  if AKey = $FFBF then
  begin
    MenuRename(nil);
    Exit;
  end;

  // F5: Refresh
  if AKey = $FFC2 then
  begin
    MenuRefresh(nil);
    Exit;
  end;

  // Delete / Shift+Delete
  if (AKey = $FFFF) then
  begin
    if hasShift then
      MenuDeletePermanent(nil)
    else
      MenuDelete(nil);
    Exit;
  end;

  // Alt shortcuts
  if hasAlt then
  begin
    if (AKey = $FF52) then // Alt+Up: Parent Directory
    begin
      ActionUp(nil);
      Exit;
    end;
    if (AKey = $FF50) then // Alt+Home: Home Directory
    begin
      ActionHome(nil);
      Exit;
    end;
    if (AKey = $FF51) then // Alt+Left: Back
    begin
      ActionBack(nil);
      Exit;
    end;
    if (AKey = $FF53) then // Alt+Right: Forward
    begin
      ActionForward(nil);
      Exit;
    end;
    if (AKey = $FF0D) or (AKey = $FF8D) then // Alt+Return: Properties
    begin
      MenuProperties(nil);
      Exit;
    end;
  end;

  // Ctrl shortcuts
  if hasCtrl then
  begin
    if hasShift and ((AKey = $6E) or (AKey = $4E)) then // Ctrl+Shift+N: New Folder
    begin
      MenuNewFolder(nil);
      Exit;
    end;
    if hasShift and ((AKey = $74) or (AKey = $54)) then // Ctrl+Shift+T: Open Terminal
    begin
      MenuOpenTerminal(nil);
      Exit;
    end;
    if (AKey = $63) or (AKey = $43) then // Ctrl+C: Copy
    begin
      MenuCopy(nil);
      Exit;
    end;
    if (AKey = $78) or (AKey = $58) then // Ctrl+X: Cut
    begin
      MenuCut(nil);
      Exit;
    end;
    if (AKey = $76) or (AKey = $56) then // Ctrl+V: Paste
    begin
      MenuPaste(nil);
      Exit;
    end;
    if (AKey = $61) or (AKey = $41) then // Ctrl+A: Select All
    begin
      MenuSelectAll(nil);
      Exit;
    end;
    if (AKey = $68) or (AKey = $48) then // Ctrl+H: Toggle Hidden
    begin
      MenuToggleHidden(nil);
      Exit;
    end;
    if (AKey = $6C) or (AKey = $4C) then // Ctrl+L: Location Bar
    begin
      MenuGoLocation(nil);
      Exit;
    end;
    if hasShift and ((AKey = $66) or (AKey = $46)) then // Ctrl+Shift+F: Recursive Search
    begin
      MenuSearchRecursive(nil);
      Exit;
    end;
    if (AKey = $66) or (AKey = $46) then // Ctrl+F: Search Filter
    begin
      MenuSearch(nil);
      Exit;
    end;
    if (AKey = $71) or (AKey = $51) then // Ctrl+Q: Quit
    begin
      MenuQuit(nil);
      Exit;
    end;
  end;
end;

procedure TFileSamaWindow.MenuQuit(Sender: TFtMenuItem);
begin
  Close();
end;

procedure TFileSamaWindow.MenuSearch(Sender: TFtMenuItem);
begin
  if FSearchEntry <> nil then
  begin
    FSearchEntry.SetFocus();
    FSearchEntry.SelectAll();
  end;
end;

procedure TFileSamaWindow.MenuSearchRecursive(Sender: TFtMenuItem);
begin
  FSearchRecursive := not FSearchRecursive;
  if FSearchEntry <> nil then
  begin
    FSearchEntry.SetFocus();
    FSearchEntry.SelectAll();
  end;
  if FFilterQuery <> '' then
  begin
    if FSearchRecursive then
      FModel.SearchRecursive(FModel.CurrentPath, FFilterQuery)
    else
      FModel.ScanDirectory(FModel.CurrentPath);
    RefreshTable();
  end;
end;

procedure TFileSamaWindow.MenuGoLocation(Sender: TFtMenuItem);
begin
  if FPathBar <> nil then
  begin
    if FPathBar.Mode = ftpbmBreadcrumbs then
      FPathBar.Mode := ftpbmEdit
    else
      FPathBar.Mode := ftpbmBreadcrumbs;
  end;
end;

procedure TFileSamaWindow.MenuCut(Sender: TFtMenuItem);
var
  item: TFileItem;
begin
  if GetSelectedItem(item) then
  begin
    SetFileClipboard([item.FullPath], True);
    if FStatusText <> nil then
      FStatusText.Text := Format('Cut "%s" to clipboard', [item.Name]);
  end;
end;

procedure TFileSamaWindow.MenuCopy(Sender: TFtMenuItem);
var
  item: TFileItem;
begin
  if GetSelectedItem(item) then
  begin
    SetFileClipboard([item.FullPath], False);
    if FStatusText <> nil then
      FStatusText.Text := Format('Copied "%s" to clipboard', [item.Name]);
  end;
end;

procedure TFileSamaWindow.MenuPaste(Sender: TFtMenuItem);
var
  pastedCount: Integer;
begin
  pastedCount := PasteClipboard(FModel.CurrentPath);
  if pastedCount > 0 then
  begin
    NavigateTo(FModel.CurrentPath, False);
    if FStatusText <> nil then
      FStatusText.Text := Format('Pasted %d item(s)', [pastedCount]);
  end;
end;

procedure TFileSamaWindow.MenuRename(Sender: TFtMenuItem);
var
  item: TFileItem;
  newName, newPath: string;
begin
  if GetSelectedItem(item) then
  begin
    if PromptRename(item.Name, newName) then
    begin
      newPath := ExtractFilePath(item.FullPath);
      if (Length(newPath) > 0) and (newPath[Length(newPath)] <> '/') then
        newPath := newPath + '/';
      newPath := newPath + newName;
      if RenameItem(item.FullPath, newPath) then
      begin
        NavigateTo(FModel.CurrentPath, False);
        if FStatusText <> nil then
          FStatusText.Text := Format('Renamed to "%s"', [newName]);
      end;
    end;
  end;
end;

procedure TFileSamaWindow.MenuDelete(Sender: TFtMenuItem);
var
  item: TFileItem;
begin
  if GetSelectedItem(item) then
  begin
    if TrashItem(item.FullPath) then
    begin
      NavigateTo(FModel.CurrentPath, False);
      if FStatusText <> nil then
        FStatusText.Text := Format('Moved "%s" to trash', [item.Name]);
    end;
  end;
end;

procedure TFileSamaWindow.MenuDeletePermanent(Sender: TFtMenuItem);
var
  item: TFileItem;
begin
  if GetSelectedItem(item) then
  begin
    if TFtMessageDialog.Confirm('Delete Permanently',
      Format('Are you sure you want to permanently delete "%s"?', [item.Name]),
      'If you delete an item, it is permanently lost.') then
    begin
      DeletePermanently(item.FullPath);
      NavigateTo(FModel.CurrentPath, False);
      if FStatusText <> nil then
        FStatusText.Text := Format('Permanently deleted "%s"', [item.Name]);
    end;
  end;
end;

procedure TFileSamaWindow.MenuSelectAll(Sender: TFtMenuItem);
begin
  if FViewMode = fsvmList then
  begin
    if FFileTable <> nil then FFileTable.SelectAll();
  end
  else
  begin
    if FFileGrid <> nil then FFileGrid.SelectAll();
  end;
end;

procedure TFileSamaWindow.MenuToggleHidden(Sender: TFtMenuItem);
begin
  FModel.ShowHidden := not FModel.ShowHidden;
  if Sender <> nil then
    Sender.Checked := FModel.ShowHidden;
  if FBtnHidden <> nil then
    FBtnHidden.Toggled := FModel.ShowHidden;
  NavigateTo(FModel.CurrentPath, False);
end;

procedure TFileSamaWindow.MenuRefresh(Sender: TFtMenuItem);
begin
  ActionRefresh(nil);
end;

procedure TFileSamaWindow.MenuGoHome(Sender: TFtMenuItem);
begin
  NavigateTo(GetHomeDir(), True);
end;

procedure TFileSamaWindow.MenuGoDesktop(Sender: TFtMenuItem);
begin
  NavigateTo(GetDesktopDir(), True);
end;

procedure TFileSamaWindow.MenuGoDocuments(Sender: TFtMenuItem);
begin
  NavigateTo(GetDocumentsDir(), True);
end;

procedure TFileSamaWindow.MenuGoDownloads(Sender: TFtMenuItem);
begin
  NavigateTo(GetDownloadsDir(), True);
end;

procedure TFileSamaWindow.MenuGoParent(Sender: TFtMenuItem);
begin
  NavigateTo(GetParentPath(FModel.CurrentPath), True);
end;

procedure TFileSamaWindow.MenuGoRoot(Sender: TFtMenuItem);
begin
  NavigateTo('/', True);
end;

procedure TFileSamaWindow.MenuOpenTerminal(Sender: TFtMenuItem);
begin
  LaunchTerminalAt(FModel.CurrentPath);
end;

procedure TFileSamaWindow.MenuAbout(Sender: TFtMenuItem);
begin
  TFtMessageDialog.ShowMessage('Samarinda Files (filesama)' + LineEnding +
                               'FTML Desktop File Manager' + LineEnding +
                               'Copyright (c) 2026 Dio Affriza',
                               'About Filesama');
end;

procedure TFileSamaWindow.MenuOpenSelection(Sender: TFtMenuItem);
var
  item: TFileItem;
begin
  if GetSelectedItem(item) then
  begin
    if item.IsDirectory then
      NavigateTo(item.FullPath, True)
    else
      LaunchFile(item.FullPath);
  end;
end;

end.
