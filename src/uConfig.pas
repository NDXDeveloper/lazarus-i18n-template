{ ═══════════════════════════════════════════════════════════════════════════════
  uConfig.pas - Minimal persistent application configuration.

  Stores settings as an INI file in the per-user configuration directory:
    Windows : %APPDATA%\lazarus-i18n-template\config.ini
    Unix    : $HOME/.config/lazarus-i18n-template/config.ini

  A small, persistent configuration object, reduced to what the template needs:
  a single persisted setting, the chosen UI language. It is kept deliberately
  small and easy to extend — add fields and read/write them in Load/Save the
  same way as Language.

  License: MIT (see LICENSE at the repository root).
  ═══════════════════════════════════════════════════════════════════════════════ }

unit uConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

type
  { TConfig }
  TConfig = class
  private
    FConfigPath: string;
    FLanguage: string;
    FModified: Boolean;
    function GetConfigDir: string;
    function GetConfigFilePath: string;
    procedure SetLanguage(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;

    { Read the INI file into memory (keeps defaults if it does not exist yet). }
    procedure Load;
    { Write the current settings back to the INI file. }
    procedure Save;

    { Full path of the INI file actually used. }
    property ConfigFilePath: string read FConfigPath;
    property Modified: Boolean read FModified write FModified;

    { Saved UI language code, e.g. 'en' or 'fr'. An empty string means
      "no preference yet": detect the OS language at startup. }
    property Language: string read FLanguage write SetLanguage;
  end;

{ Global configuration instance (created on first use, saved-if-modified and
  freed at shutdown). }
function Config: TConfig;

implementation

const
  APP_ID          = 'lazarus-i18n-template';
  CONFIG_FILENAME = 'config.ini';
  SECTION_GENERAL = 'General';

var
  FConfig: TConfig = nil;

function Config: TConfig;
begin
  if FConfig = nil then
    FConfig := TConfig.Create;
  Result := FConfig;
end;

{ TConfig }

constructor TConfig.Create;
begin
  inherited Create;
  FLanguage := '';            { empty = auto-detect OS language }
  FModified := False;
  FConfigPath := GetConfigFilePath;
  Load;
end;

destructor TConfig.Destroy;
begin
  { Safety net for any setting changed without an explicit Save. }
  if FModified then
    Save;
  inherited Destroy;
end;

function TConfig.GetConfigDir: string;
begin
  {$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('APPDATA') + PathDelim + APP_ID + PathDelim;
  {$ELSE}
  Result := GetEnvironmentVariable('HOME') + PathDelim + '.config' +
            PathDelim + APP_ID + PathDelim;
  {$ENDIF}
end;

function TConfig.GetConfigFilePath: string;
begin
  Result := GetConfigDir + CONFIG_FILENAME;
end;

procedure TConfig.SetLanguage(const AValue: string);
begin
  if FLanguage = AValue then
    Exit;
  FLanguage := AValue;
  FModified := True;
end;

procedure TConfig.Load;
var
  Ini: TIniFile;
begin
  if not FileExists(FConfigPath) then
    Exit;                       { nothing saved yet: keep defaults }
  try
    Ini := TIniFile.Create(FConfigPath);
    try
      FLanguage := Ini.ReadString(SECTION_GENERAL, 'Language', '');
    finally
      Ini.Free;
    end;
    FModified := False;
  except
    { Ignore an unreadable/corrupt config and keep defaults. }
  end;
end;

procedure TConfig.Save;
var
  Ini: TIniFile;
  Dir: string;
begin
  Dir := GetConfigDir;
  if not DirectoryExists(Dir) then
    ForceDirectories(Dir);
  try
    Ini := TIniFile.Create(FConfigPath);
    try
      Ini.WriteString(SECTION_GENERAL, 'Language', FLanguage);
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
    FModified := False;
  except
    { Ignore write errors (e.g. a read-only home directory). }
  end;
end;

initialization

finalization
  FreeAndNil(FConfig);

end.
