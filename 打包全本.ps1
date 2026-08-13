# 全本打包脚本
# 功能：将 v1-v4 各卷 _merged 目录下的全部章节+档案插页，按顺序合并为单个 txt 文件
# 用法：在 PowerShell 中执行  .\打包全本.ps1
# 可复用：后续多轮迭代无需改动本脚本，直接重跑即可（自动读取各卷 merged 目录最新内容）
# 输出：UTF-8 带 BOM（Windows 记事本可直接打开），卷间插入卷名分隔页

param(
    [string]$NovelRoot = "D:\Novel\Novel\novel",
    [string]$OutputFile = "D:\Novel\Novel\novel\打包\残域纪事_清河_全本.txt"
)

$volumes = @(
    @{ Dir = "v1_merged"; Name = "第一卷 入局" },
    @{ Dir = "v2_merged"; Name = "第二卷 借" },
    @{ Dir = "v3_merged"; Name = "第三卷 裂" },
    @{ Dir = "v4_merged"; Name = "第四卷 人" }
)

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("《残域纪事：清河》")
[void]$sb.AppendLine("")

$totalFiles = 0

foreach ($vol in $volumes) {
    $dir = Join-Path $NovelRoot $vol.Dir
    if (-not (Test-Path -LiteralPath $dir)) {
        Write-Warning "目录不存在，已跳过：$dir"
        continue
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("════════════════════════════")
    [void]$sb.AppendLine("　　　　$($vol.Name)")
    [void]$sb.AppendLine("════════════════════════════")
    [void]$sb.AppendLine("")

    $files = Get-ChildItem -LiteralPath $dir -Filter *.md | Sort-Object Name
    foreach ($f in $files) {
        $totalFiles++
        $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8
        foreach ($l in $lines) {
            $t = $l.TrimEnd()
            # 去 markdown 标题符与加粗斜体符
            if ($t.StartsWith("## ")) { $t = $t.Substring(3) }
            elseif ($t.StartsWith("# ")) { $t = $t.Substring(2) }
            $t = $t.Replace("**", "").Replace("*", "")
            [void]$sb.AppendLine($t)
        }
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("")
    }
}

$outDir = Split-Path -Parent $OutputFile
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding $true))

Write-Host "打包完成：$OutputFile"
Write-Host "包含文件数：$totalFiles"
Write-Host "总字符数：$($sb.Length)"
