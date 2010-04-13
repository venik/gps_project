unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, URLMon, ShellApi, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    LabeledEdit1: TLabeledEdit;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Panel2: TPanel;
    Button2: TButton;
    Memo1: TMemo;
    Panel3: TPanel;
    Button3: TButton;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit4: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    LabeledEdit7: TLabeledEdit;
    LabeledEdit8: TLabeledEdit;
    LabeledEdit9: TLabeledEdit;
    LabeledEdit10: TLabeledEdit;
    LabeledEdit11: TLabeledEdit;
    LabeledEdit12: TLabeledEdit;
    LabeledEdit13: TLabeledEdit;
    LabeledEdit14: TLabeledEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
    sResultFile: String;

implementation

{$R *.dfm}

function DownloadFile(SourceFile, DestFile: string): Boolean;
begin
  try
    Result := UrlDownloadToFile(nil, PChar(SourceFile), PChar(DestFile), 0, nil) = 0;
  except
    Result := False;
  end;
end;

Function CreateName():string;
var
today : TDateTime;
NowDateF,NowDateF2,NowTimeF,NowTimeF2:string;
begin
     today := Now;
    NowDateF:=DateToStr(today);
    NowDateF2:=copy(NowDateF,7,4);
    NowDateF2:=NowDateF2+copy(NowDateF,4,2);
    NowDateF2:=NowDateF2+copy(NowDateF,1,2);
    NowTimeF:=TimeToStr(today);
    NowTimeF2:=copy(NowTimeF,1,2);
    NowTimeF2:=NowTimeF2+copy(NowTimeF,4,2);
    NowTimeF2:=NowTimeF2+copy(NowTimeF,7,2);
    form1.Edit1.Text:=NowDateF;
    form1.Edit2.Text:=NowTimeF;
  Result:='almanac\'+NowDateF2+NowTimeF2+'.txt';
end;

procedure TForm1.Button1Click(Sender: TObject);
var
    SourceFile,DestFile:string;
  begin
  SourceFile:=form1.LabeledEdit1.Text;
  DestFile:=CreateName();

  if DownloadFile(SourceFile, DestFile) then
  begin
    ShowMessage('Download succesful!');
    ShellExecute(Application.Handle, PChar('open'), PChar(DestFile),
      PChar(''), nil, SW_NORMAL)
  end
  else
    ShowMessage('Error while downloading ' + SourceFile)
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  SR: TSearchRec;
  iTime: Integer;
   BatchFile: TextFile;
 s:string;
begin
    if FindFirst('almanac\' + '*.txt', faAnyFile, SR) = 0 then
    begin
      repeat
        if SR.Time > iTime then
        begin
          iTime := SR.Time;
          sResultFile := SR.Name;
        end;
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;
    sResultFile:='almanac\'+sResultFile;
    ShowMessage(sResultFile);

    AssignFile(BatchFile,sResultFile);
Reset(BatchFile);
Memo1.Lines.Clear;
While not eof(BatchFile) do
  begin
    Readln(BatchFile, s);
   form1.Memo1.lines.Add(s);
  end;
CloseFile(BatchFile);
end;



procedure TForm1.Button3Click(Sender: TObject);
 type
  Tsattelite=record
   ID:string;
   Health:string;
   Eccentricity:string;
   Time_of_Applicability:string;
   Orbital_Inclination:string;
   Rate_of_Right_Ascen:string;
   SQRT_A:string;
   Right_Ascen_at_Week:string;
   Argument_of_Perigee:string;
   Mean_Anom:string;
   Af0:string;
   Af1:string;
   Week:string;
  end;

 var
  LengthF,i,j:integer;
  Sattelite: array [1..31] of TSattelite;
  List:TStringList;

begin
//Find length file
List := TStringList.Create;
List.LoadFromFile(sResultFile);
LengthF := List.Count;

i:=0;
for j := 1 to 31 do
  begin
//Parsing ID
inc(i);
Sattelite[j].ID:=copy(List[i],29,2);
form1.LabeledEdit4.Text:=Sattelite[j].ID;

//Parsing Health
inc(i);
Sattelite[j].Health:=copy(List[i],29,3);
form1.LabeledEdit5.Text:=Sattelite[j].Health;

//Parsing Eccentricity
inc(i);
Sattelite[j].Eccentricity:=copy(List[i],29,17);
form1.LabeledEdit6.Text:=Sattelite[j].Eccentricity;

//Parsing Time_of_Applicability
inc(i);
Sattelite[j].Time_of_Applicability:=copy(List[i],28,11);
form1.LabeledEdit3.Text:=Sattelite[j].Time_of_Applicability;

//Parsing Orbital_Inclination
inc(i);
Sattelite[j].Orbital_Inclination:=copy(List[i],29,12);
form1.LabeledEdit7.Text:=Sattelite[j].Orbital_Inclination;

//Parsing Rate_of_Right_Ascen
inc(i);
Sattelite[j].Rate_of_Right_Ascen:=copy(List[i],28,18);
form1.LabeledEdit8.Text:=Sattelite[j].Rate_of_Right_Ascen;

//Parsing SQRT_A
inc(i);
Sattelite[j].SQRT_A:=copy(List[i],29,11);
form1.LabeledEdit9.Text:=Sattelite[j].SQRT_A;

//Parsing Right_Ascen_at_Week
inc(i);
Sattelite[j].Right_Ascen_at_Week:=copy(List[i],28,18);
form1.LabeledEdit10.Text:=Sattelite[j].Right_Ascen_at_Week;

//Parsing Argument_of_Perigee
inc(i);
Sattelite[j].Argument_of_Perigee:=copy(List[i],29,11);
form1.LabeledEdit11.Text:=Sattelite[j].Argument_of_Perigee;

//Parsing Mean_Anom
inc(i);
Sattelite[j].Mean_Anom:=copy(List[i],28,18);
form1.LabeledEdit12.Text:=Sattelite[j].Mean_Anom;

//Parsing Af0
inc(i);
Sattelite[j].Af0:=copy(List[i],28,18);
form1.LabeledEdit13.Text:=Sattelite[j].Af0;

//Parsing Af1
inc(i);
Sattelite[j].Af1:=copy(List[i],28,18);
form1.LabeledEdit14.Text:=Sattelite[j].Af1;

//Parsing WEEK
inc(i);
Sattelite[j].Week:=copy(List[i],30,3);
form1.LabeledEdit2.Text:=Sattelite[j].Week;
i:=i+2;
  end;

//Destruct
List.Free;
end;

end.
