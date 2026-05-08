param(
  [switch]$FailOnWarn
)

$errors = @()
$warns = @()

function Add-Warn($msg){
  $script:warns += $msg
  Write-Warning $msg
}
function Add-Err($msg){
  $script:errors += $msg
  Write-Error $msg
}

# 1) 必要文件检查
$root = Split-Path -Parent $PSCommandPath | Split-Path -Parent
if (-not (Test-Path (Join-Path $root 'DeepCharset.dproj'))) { Add-Err '缺少 DeepCharset.dproj' }
if (-not (Test-Path (Join-Path $root 'DeepCharset.dpr')))  { Add-Err '缺少 DeepCharset.dpr'  }

# 2) 编译器可用性
$msbuild = $env:MSBUILD
if (-not $msbuild) { $msbuild = (Get-Command msbuild -ErrorAction SilentlyContinue)?.Source }
if ($msbuild) { Write-Host "msbuild: $msbuild" } else { Add-Warn '未找到 msbuild（将回退到 dcc64）' }

$dcc = $env:DCC64
if (-not $dcc) { $dcc = (Get-Command dcc64 -ErrorAction SilentlyContinue)?.Source }
if ($dcc) { Write-Host "dcc64: $dcc" } else { Add-Warn '未找到 dcc64（建议安装 Embarcadero 编译器或设置 DCC64）' }

# 3) SynEdit 路径提示（依据 .dproj 中的默认）
$syn1 = 'D:\Personal\Documents\Embarcadero\Studio\23.0\CatalogRepository\SynEdit-12\Source'
$syn2 = 'D:\Personal\Documents\Embarcadero\Studio\23.0\CatalogRepository\SynEdit-12\Source\Highlighters'
if (-not (Test-Path $syn1)) { Add-Warn "SynEdit 源码缺失: $syn1" }
if (-not (Test-Path $syn2)) { Add-Warn "SynEdit Highlighters 缺失: $syn2" }

# 4) 打印建议
Write-Host '建议：可通过 $env:MSBUILD / $env:DCC64 指定编译器路径；必要时修正 .dproj UnitSearchPath 的 SynEdit 目录。'

if ($errors.Count -gt 0) {
  exit 1
}
if ($FailOnWarn -and $warns.Count -gt 0) {
  exit 2
}
exit 0
