# 全本打包脚本（电子书排版版）
# 功能：将 v1-v4 各卷 _merged 目录下的全部章节+档案插页，按顺序合并为单个 txt
# 排版规则（贴合电子版小说阅读习惯）：
#   1. 正文段落：首行缩进两个全角空格，段落之间仅换行、不留空行
#   2. 章标题（第X章 X）、节名（原单字章名）、卷分隔线：顶格不缩进
#   3. 档案插页中的表格：转成纯文本行（竖线替换为全角空格）
#   4. markdown 加粗/斜体符号全部去除
#   5. 卷与卷之间插入卷名分隔页
# 用法：在 PowerShell 中执行  .\打包全本.ps1
# 可复用：后续多轮迭代无需改动本脚本，直接重跑即可

param(
    [string]$NovelRoot = "D:\Novel\Novel\novel",
    [string]$OutputFile = "D:\Novel\Novel\novel\打包\残域纪事_清河_全本.txt",
    [string[]]$VolumeDirs = @()
)

$allVolumes = @(
    @{ Dir = "v1_merged"; Name = "第一卷 入局" },
    @{ Dir = "v2_merged"; Name = "第二卷 借" },
    @{ Dir = "v3_merged"; Name = "第三卷 裂" },
    @{ Dir = "v4_merged"; Name = "第四卷 人" }
)

# 未指定时导出全部卷；指定时按给定目录顺序导出
if ($VolumeDirs.Count -eq 0) {
    $volumes = $allVolumes
} else {
    $volumes = @()
    foreach ($d in $VolumeDirs) {
        $v = $allVolumes | Where-Object { $_.Dir -eq $d }
        if ($v) { $volumes += $v } else { Write-Warning "未知卷目录，跳过：$d" }
    }
}

$INDENT = "　　"   # 两个全角空格
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("《残域纪事：清河》")
[void]$sb.AppendLine("")

$totalFiles = 0
$totalParagraphs = 0

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
        $isFirstContent = $true
        $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8
        foreach ($l in $lines) {
            $t = $l.TrimEnd()
            if ($t -eq "") { continue }

            # 去 markdown 加粗/斜体符号
            $t = $t.Replace("**", "").Replace("*", "")

            # 章标题："# 第X章 X" -> 顶格
            if ($t.StartsWith("# ")) {
                if (-not $isFirstContent) { [void]$sb.AppendLine("") }
                [void]$sb.AppendLine($t.Substring(2))
                $isFirstContent = $false
                continue
            }
            # 节名："## X" -> 顶格
            if ($t.StartsWith("## ")) {
                if (-not $isFirstContent) { [void]$sb.AppendLine("") }
                [void]$sb.AppendLine($t.Substring(3))
                $isFirstContent = $false
                continue
            }
            # 表格行："| 序号 | ..." -> 纯文本
            if ($t.StartsWith("|")) {
                $cells = $t.Trim("|") -split "\|" | ForEach-Object { $_.Trim() }
                # 跳过 markdown 表格分隔行（如 |---|---|）
                if (($cells | Where-Object { $_ -notmatch "^---+" }).Count -eq 0) { continue }
                $row = $cells -join "　"
                [void]$sb.AppendLine($row)
                $isFirstContent = $false
                continue
            }
            # 场景分隔线："——"
            if ($t -match "^—+$") {
                [void]$sb.AppendLine("")
                [void]$sb.AppendLine("　　　　$t")
                [void]$sb.AppendLine("")
                continue
            }
            # 正文段落：首行缩进
            [void]$sb.AppendLine($INDENT + $t)
            $totalParagraphs++
            $isFirstContent = $false
        }
    }
}

$outDir = Split-Path -Parent $OutputFile
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding $true))

Write-Host "打包完成：$OutputFile"
Write-Host "包含文件数：$totalFiles"
Write-Host "正文段落数：$totalParagraphs"
Write-Host "总字符数：$($sb.Length)"
