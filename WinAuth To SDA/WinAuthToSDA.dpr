{ WinAuth to SDA converter }
{ Version: 0.1 }
{ Author: Python R.G. }

program WinAuthToSDA;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, Classes;

const
  PROG_VER = '0.1';

const
  LOG_PROG_INFO = 'WinAuth to SDA converter ' + PROG_VER + sLineBreak + 'Author: Python R.G.' + sLineBreak;
  LOG_FILES_FOUND = 'Files found. Press any key to start converting.';
  LOG_FILES_NOT_FOUND = 'Files not found. Put export file to the ''Import'' folder. Press any key to exit.';
  LOG_CONVERTING_COMPLETE = 'Converting complete. Converted: %d. Press any key to exit.';

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

var
  WinAuthFileName: string = '';
  WinAuthFile: TStringList;
  ConvertedCount: Integer = 0;

function ExtractBetweenTags(Const Text, TagFirst, TagLast: string): string;
var
  i, f : integer;
begin
  i := Pos(TagFirst, Text);
  f := Pos(TagLast, Copy(Text, i + length(TagFirst), MAXINT));
  if (i > 0) and (f > 0) then
    Result := Copy(Text, i + length(TagFirst), f - 1);
end;

function WAFilesFound: Boolean;
var
  SearchRec: TSearchRec;
begin
  WinAuthFileName := '';

  if FindFirst(GetCurrentDir + '\Import\' + '*.' + 'txt', faAnyFile,
    SearchRec) = 0 then
  begin
    WinAuthFileName := SearchRec.Name;
    Result := True;
  end
  else
    Result := False;

  FindClose(SearchRec);
end;

function ExportToSDA: Boolean;
const
    EMPTY = '';
var i: Integer;
    SDAFile: TStringList;

var SDA_shared_secret: string;
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
  WinAuthFile := TStringList.Create;
  WinAuthFile.LoadFromFile(GetCurrentDir + '\Import\' + WinAuthFileName);

  SDAFile := TStringList.Create;
  SDAFile.LineBreak := '';

  if WinAuthFile.Count > 0 then
  for i := 0 to WinAuthFile.Count - 1 do begin
    SDA_shared_secret := ExtractBetweenTags(WinAuthFile[i], 'shared_secret%22%3a%22', '%22%2c%22');
    SDA_serial_number := ExtractBetweenTags(WinAuthFile[i], 'serial_number%22%3a%22', '%22%2c%22');
    SDA_revocation_code := ExtractBetweenTags(WinAuthFile[i], 'revocation_code%22%3a%22', '%22%2c%22');
    SDA_uri_otpauth := ExtractBetweenTags(WinAuthFile[i], 'totp/Steam:', '&digits=');
    SDA_server_time := ExtractBetweenTags(WinAuthFile[i], 'server_time%22%3a%22', '%22%2c%22');
    SDA_account_name := ExtractBetweenTags(WinAuthFile[i], 'account_name%22%3a%22', '%22%2c%22');
    SDA_token_gid := ExtractBetweenTags(WinAuthFile[i], 'token_gid%22%3a%22', '%22%2c%22');
    SDA_identity_secret := ExtractBetweenTags(WinAuthFile[i], 'identity_secret%22%3a%22', '%22%2c%22');
    SDA_secret_1 := ExtractBetweenTags(WinAuthFile[i], 'secret_1%22%3a%22', '%22%2c%22');
    SDA_status := ExtractBetweenTags(WinAuthFile[i], 'status%22%3a', '%2c%22');
    SDA_device_id := ExtractBetweenTags(WinAuthFile[i], '&deviceid=android%3a', '&data');;
    SDA_SteamID := ExtractBetweenTags(WinAuthFile[i], 'steamid%22%3a%22', '%22%2c%22');

    // Doesn't exist in WinAuth
    SDA_SessionID := EMPTY;
    SDA_SteamLogin := EMPTY;
    SDA_SteamLoginSecure := EMPTY;
    SDA_WebCookie := EMPTY;
    SDA_OAuthToken := EMPTY;

    SDAFile.Text := WinAuthFile[i].Format(SDA_MAFILE_TEMPLATE,
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

    SDAFile.SaveToFile(GetCurrentDir + '\Export\' + SDA_SteamID + '.maFile');
    Inc(ConvertedCount);
  end;

  WinAuthFile.Free;
  SDAFile.Free;
end;

begin
  try
    if not DirectoryExists(GetCurrentDir + '\Export\') then
      CreateDir(GetCurrentDir + '\Export\');
    if not DirectoryExists(GetCurrentDir + '\Import\') then
      CreateDir(GetCurrentDir + '\Import\');

    if WAFilesFound then
    begin
      Writeln(LOG_PROG_INFO);
      Writeln(LOG_FILES_FOUND);
      Readln;

      ExportToSDA;

      Writeln(Format(LOG_CONVERTING_COMPLETE, [ConvertedCount]));

    end
    else
      Writeln(LOG_FILES_NOT_FOUND);
      Readln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
