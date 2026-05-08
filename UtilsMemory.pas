unit UtilsMemory;

interface

uses
  System.SysUtils, Winapi.Windows, Winapi.PsAPI;

type
  TProcessMemoryStats = record
    WorkingSetKB: Cardinal;
    PeakWorkingSetKB: Cardinal;
    PrivateBytesKB: Cardinal;
    PagefileUsageKB: Cardinal;
  end;

function GetCurrentProcessMemory: TProcessMemoryStats;
function FormatMemoryStats(const S: TProcessMemoryStats): string;

implementation

function GetCurrentProcessMemory: TProcessMemoryStats;
var
  pmc: PROCESS_MEMORY_COUNTERS;
begin
  FillChar(Result, SizeOf(Result), 0);
  FillChar(pmc, SizeOf(pmc), 0);
  pmc.cb := SizeOf(pmc);
  if GetProcessMemoryInfo(GetCurrentProcess, @pmc, SizeOf(pmc)) then
  begin
    Result.WorkingSetKB := pmc.WorkingSetSize div 1024;
    Result.PeakWorkingSetKB := pmc.PeakWorkingSetSize div 1024;
    Result.PrivateBytesKB := 0; // 仅 PROCESS_MEMORY_COUNTERS 可用，省略私有字节
    Result.PagefileUsageKB := pmc.PagefileUsage div 1024;
  end;
end;

function FormatMemoryStats(const S: TProcessMemoryStats): string;
begin
  Result := Format('内存: WS=%dKB, WS_Peak=%dKB, Private=%dKB, PageFile=%dKB',
    [S.WorkingSetKB, S.PeakWorkingSetKB, S.PrivateBytesKB, S.PagefileUsageKB]);
end;

end.
