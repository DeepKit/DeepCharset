@echo off
"D:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe" -B DeepCharset.dpr > compile_output.txt 2>&1
type compile_output.txt
