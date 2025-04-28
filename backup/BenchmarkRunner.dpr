program BenchmarkRunner;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  UtilsEncodingTypes in 'UtilsEncodingTypes.pas',
  UtilsEncodingBase in 'UtilsEncodingBase.pas',
  UtilsEncodingDetector in 'UtilsEncodingDetector.pas',
  UtilsEncodingConverter in 'UtilsEncodingConverter.pas',
  UtilsEncodingBOM in 'UtilsEncodingBOM.pas',
  UtilsEncodingUTF32Converter in 'UtilsEncodingUTF32Converter.pas',
  UtilsEncodingUTF16Converter in 'UtilsEncodingUTF16Converter.pas',
  UtilsLogs in 'UtilsLogs.pas',
  EncodingBenchmark in 'EncodingBenchmark.pas',
  BenchmarkRunner in 'BenchmarkRunner.pas';

var
  Runner: TBenchmarkRunner;
  Config: TBenchmarkConfig;
  Logger: ILogger;
  OutputPath: string;
  
procedure HandleProgress(const AMessage: string; const AProgress: Double);
begin
  Write(#13); // Carriage return to beginning of line
  Write(Format('Progress: %.1f%% - %s', [AProgress * 100, AMessage]));
end;

procedure SetupDefaultConfigurations(ARunner: TBenchmarkRunner);
var
  Config: TBenchmarkConfig;
begin
  // UTF-8 Configuration
  Config.EncodingType := 'UTF-8';
  Config.SampleSizes := [1024, 10240, 102400, 1048576]; // 1KB, 10KB, 100KB, 1MB
  Config.Iterations := 5;
  Config.ExportResults := True;
  Config.ExportPath := '';
  ARunner.AddConfiguration(Config);

  // UTF-16 Configuration  
  Config.EncodingType := 'UTF-16LE';
  ARunner.AddConfiguration(Config);
  
  // UTF-32 Configuration
  Config.EncodingType := 'UTF-32LE';
  ARunner.AddConfiguration(Config);
  
  // GB18030 Configuration
  Config.EncodingType := 'GB18030';
  ARunner.AddConfiguration(Config);
  
  // GBK Configuration
  Config.EncodingType := 'GBK';
  ARunner.AddConfiguration(Config);
  
  // ASCII Configuration
  Config.EncodingType := 'ASCII';
  ARunner.AddConfiguration(Config);
end;

begin
  try
    // Initialize logger
    TLogManager.Initialize('benchmark_logs.txt');
    Logger := TLogManager.GetLogger('MainApp');
    Logger.Info('Starting Encoding Benchmark Suite');
    
    // Set default output path
    OutputPath := TPath.Combine(TPath.GetDocumentsPath, 'EncodingBenchmarks');
    if not TDirectory.Exists(OutputPath) then
      TDirectory.CreateDirectory(OutputPath);
    
    // Create benchmark runner
    Runner := TBenchmarkRunner.Create(Logger);
    try
      Runner.OutputDirectory := OutputPath;
      Runner.OnProgress := HandleProgress;
      
      // Setup configurations
      SetupDefaultConfigurations(Runner);
      
      // Show startup message
      Writeln('=================================');
      Writeln('  ENCODING BENCHMARK SUITE v1.0  ');
      Writeln('=================================');
      Writeln('');
      Writeln(Format('Benchmark configurations: %d', [5]));
      Writeln(Format('Output directory: %s', [OutputPath]));
      Writeln('Press Enter to start benchmarks...');
      Readln;
      
      // Run benchmarks
      Runner.RunAllBenchmarks;
      
      // Export results
      Runner.ExportAllResults('');
      
      // Generate and display comparison report
      Writeln('');
      Writeln(Runner.GenerateComparisonReport);
      
      // Wait for user to press Enter before exiting
      Writeln('');
      Writeln('Benchmarks completed. Press Enter to exit...');
      Readln;
    finally
      Runner.Free;
    end;
    
    Logger.Info('Benchmark Suite completed successfully');
  except
    on E: Exception do
    begin
      if Assigned(Logger) then
        Logger.Error('Exception: ' + E.Message)
      else
        Writeln('Exception: ' + E.Message);
      Readln;
    end;
  end;
end. 