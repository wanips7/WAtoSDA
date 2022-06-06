{ WinAuth to SDA converter }
{ Version: 0.3 }
{ Author: wanips }

program WinAuthToSDA;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, Classes, System.IOUtils;

const
  PROG_VER = '0.2';

const
  MSG_PROG_INFO = 'WinAuth to SDA converter ' + PROG_VER + sLineBreak + '=============================';
  MSG_WINAUTH_FILES_FOUND = '%d WinAuth file(s) found. Press any key to start converting.';
  MSG_FILES_NOT_FOUND = 'WinAuth files not found. Put WinAuth file to the ''Import'' folder. ';
  MSG_CONVERTING_COMPLETE = 'Done. Converted count: %d';
  MSG_CONVERTING_ERROR = 'Converting error with %s file!';

const                       
  WINAUTH_FILE_EXT = '.txt';
  SDA_FILE_EXT = '.maFile';
  
const
  SDA_MAFILE_TEMPLATE =
    '{"shared_secret":"%s",' +
    '"serial_number":"%s",' +
    '"revocation_code":"%s",' +
    '"uri":"otpauth://totp/Steam:%s&issuer=Steam",' +
    '"server_time":%s,' +
    '"account_name":"%s",' +
    '"token_gid":"%s",' +
    '"identity_secret":"%s",' +
    '"secret_1":"%s",' +
    '"status":%s,' +
    '"device_id":"android:%s",' +
    '"fully_enrolled":true,' +
    '"Session":{"SessionID":"%s",' +
    '"SteamLogin":"%s",' +
    '"SteamLoginSecure":"%s",' +
    '"WebCookie":"%s",' +
    '"OAuthToken":"%s",' +
    '"SteamID":%s}}';

type
  TFilesList = TArray<string>;
  TDirList = TArray<string>;
    
var
  WinAuthStrings: TStringList;
  ConvertedCount: Integer = 0;
  FilesList: TFilesList;
  AppPath: string;
  OutputPath: string;
  ImportPath: string;
  s: string;

procedure Print(const Value: string);
begin
  Writeln(Value);
  Readln;
end;
  
procedure CreateDirIfNotExist(const DirList: TDirList);
var
  s: string;
begin
  for s in DirList do
    if not DirectoryExists(s) then
      CreateDir(s);
end;
  
function GetBetween(Const Source, TagFirst, TagLast: string): string;
var
  i, f : integer;
begin
  i := Pos(TagFirst, Source);
  f := Pos(TagLast, Copy(Source, i + length(TagFirst), MAXINT));
  if (i > 0) and (f > 0) then
    Result := Copy(Source, i + length(TagFirst), f - 1);
end;

function GetWinAuthFilesList(const Path: string): TFilesList;
var
  s: string;
begin
  Result := [];

  for s in TDirectory.GetFiles(Path, '*' + WINAUTH_FILE_EXT) do
    Result := Result + [s];
end;

function ConvertWinAuthFileToSDA(const Source, SavePath: string): Boolean;
const
  EMPTY = '';
    
var 
  i: Integer;
  SDAFile: TStringList;

var 
  SDA_shared_secret: string;
  SDA_serial_number: string;
  SDA_revocation_code: string;
  SDA_uri_otpauth: string;
  SDA_server_time: string;
  SDA_account_name: string;
  SDA_token_gid: string;
  SDA_identity_secret: string;
  SDA_secret_1: string;
  SDA_status: string;
  SDA_device_id: string;
  SDA_SessionID: string;
  SDA_SteamLogin: string;
  SDA_SteamLoginSecure: string;
  SDA_WebCookie: string;
  SDA_OAuthToken: string;
  SDA_SteamID: string;

begin
  Result := False;

  WinAuthStrings := TStringList.Create;
  WinAuthStrings.LoadFromFile(Source);

  SDAFile := TStringList.Create;
  SDAFile.LineBreak := '';

  if WinAuthStrings.Count > 0 then
  begin
    for i := 0 to WinAuthStrings.Count - 1 do 
    begin
      if not WinAuthStrings[i].StartsWith('otpauth://totp/Steam') then
        Exit;

      SDA_shared_secret := GetBetween(WinAuthStrings[i], 'shared_secret%22%3a%22', '%22%2c%22');
      SDA_serial_number := GetBetween(WinAuthStrings[i], 'serial_number%22%3a%22', '%22%2c%22');
      SDA_revocation_code := GetBetween(WinAuthStrings[i], 'revocation_code%22%3a%22', '%22%2c%22');
      SDA_uri_otpauth := GetBetween(WinAuthStrings[i], 'totp/Steam:', '&digits=');
      SDA_server_time := GetBetween(WinAuthStrings[i], 'server_time%22%3a%22', '%22%2c%22');
      SDA_account_name := GetBetween(WinAuthStrings[i], 'account_name%22%3a%22', '%22%2c%22');
      SDA_token_gid := GetBetween(WinAuthStrings[i], 'token_gid%22%3a%22', '%22%2c%22');
      SDA_identity_secret := GetBetween(WinAuthStrings[i], 'identity_secret%22%3a%22', '%22%2c%22');
      SDA_secret_1 := GetBetween(WinAuthStrings[i], 'secret_1%22%3a%22', '%22%2c%22');
      SDA_status := GetBetween(WinAuthStrings[i], 'status%22%3a', '%2c%22');
      SDA_device_id := GetBetween(WinAuthStrings[i], '&deviceid=android%3a', '&data');;
      SDA_SteamID := GetBetween(WinAuthStrings[i], 'steamid%22%3a%22', '%22%2c%22');

      { Doesn't exist in WinAuth }
      SDA_SessionID := EMPTY;
      SDA_SteamLogin := EMPTY;
      SDA_SteamLoginSecure := EMPTY;
      SDA_WebCookie := EMPTY;
      SDA_OAuthToken := EMPTY;

      SDAFile.Text := WinAuthStrings[i].Format(SDA_MAFILE_TEMPLATE,
      [SDA_shared_secret,
       SDA_serial_number,
       SDA_revocation_code,
       SDA_uri_otpauth,
       SDA_server_time,
       SDA_account_name,
       SDA_token_gid,
       SDA_identity_secret,
       SDA_secret_1,
       SDA_status,
       SDA_device_id,
       SDA_SessionID,
       SDA_SteamLogin,
       SDA_SteamLoginSecure,
       SDA_WebCookie,
       SDA_OAuthToken,
       SDA_SteamID]);

      SDAFile.Text := StringReplace(SDAFile.Text, '%3d', '=', [rfReplaceAll, rfIgnoreCase]);
      SDAFile.Text := StringReplace(SDAFile.Text, '%2f', '/', [rfReplaceAll, rfIgnoreCase]);
      SDAFile.Text := StringReplace(SDAFile.Text, '%2b', '+', [rfReplaceAll, rfIgnoreCase]);

      if SDA_SteamID = EMPTY then
        Exit;
      
      SDAFile.SaveToFile(OutputPath + SDA_SteamID + WINAUTH_FILE_EXT);
      
      Inc(ConvertedCount);
    end;

    Result := True;
  end;

  WinAuthStrings.Free;
  SDAFile.Free;
end;

begin
  try
    Writeln(MSG_PROG_INFO);

    AppPath := ExtractFilePath(ParamStr(0));
    ImportPath := AppPath + '\Import\';
    OutputPath := AppPath + '\Output\';

    CreateDirIfNotExist([OutputPath, ImportPath]);
      
    FilesList := GetWinAuthFilesList(ImportPath); 
    if Length(FilesList) > 0 then
    begin
      Print(Format(MSG_WINAUTH_FILES_FOUND, [Length(FilesList)]));
      
      for s in FilesList do
        if not ConvertWinAuthFileToSDA(s, OutputPath) then
        begin
          Print(Format(MSG_CONVERTING_ERROR, [s]));
        end;

      Print(Format(MSG_CONVERTING_COMPLETE, [ConvertedCount]));  
    end
    else
      Print(MSG_FILES_NOT_FOUND);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
