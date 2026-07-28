# GitHub Pages 自动部署脚本
# 运行前请确保已创建 GitHub Personal Access Token (classic)
# 创建地址: https://github.com/settings/tokens/new
# 权限勾选: repo (完整仓库权限)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   GitHub Pages 自动部署脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 获取用户输入
$githubUsername = Read-Host "请输入你的 GitHub 用户名"
$githubToken = Read-Host "请输入你的 GitHub Personal Access Token (classic)" -AsSecureString
$tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken))

$repoName = "market-view-20260728"
$headers = @{
    "Authorization" = "token $tokenPlain"
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "deploy-script"
}

# 步骤1: 创建仓库
Write-Host ""
Write-Host "[1/4] 正在创建 GitHub 仓库..." -ForegroundColor Yellow
try {
    $body = @{
        name = $repoName
        description = "A股复盘文章 - 手机阅读版"
        private = $false
        auto_init = $false
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "      仓库创建成功: $($response.html_url)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 422) {
        Write-Host "      仓库已存在，跳过创建" -ForegroundColor Green
    } else {
        Write-Host "      创建失败: $_" -ForegroundColor Red
        exit 1
    }
}

# 步骤2: 设置远程仓库并推送
Write-Host ""
Write-Host "[2/4] 正在推送代码到 GitHub..." -ForegroundColor Yellow
try {
    git remote remove origin 2>$null
    git remote add origin "https://$githubUsername`:$tokenPlain@github.com/$githubUsername/$repoName.git"
    git branch -M main
    git push -u origin main --force
    Write-Host "      代码推送成功" -ForegroundColor Green
} catch {
    Write-Host "      推送失败: $_" -ForegroundColor Red
    exit 1
}

# 步骤3: 启用 GitHub Pages
Write-Host ""
Write-Host "[3/4] 正在启用 GitHub Pages..." -ForegroundColor Yellow
try {
    $pagesBody = @{
        source = @{
            branch = "main"
            path = "/"
        }
    } | ConvertTo-Json

    $pagesResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$githubUsername/$repoName/pages" -Method Post -Headers $headers -Body $pagesBody -ContentType "application/json"
    Write-Host "      GitHub Pages 已启用" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host "      Pages 已启用，跳过" -ForegroundColor Green
    } else {
        Write-Host "      启用 Pages 失败: $_" -ForegroundColor Yellow
    }
}

# 步骤4: 获取 Pages URL
Write-Host ""
Write-Host "[4/4] 正在获取访问链接..." -ForegroundColor Yellow
try {
    Start-Sleep -Seconds 2
    $pagesInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$githubUsername/$repoName/pages" -Method Get -Headers $headers
    $pagesUrl = $pagesInfo.html_url
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   部署完成!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   访问地址: $pagesUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   注意: GitHub Pages 首次部署可能需要 1-3 分钟生效" -ForegroundColor Yellow
    Write-Host ""
} catch {
    $fallbackUrl = "https://$githubUsername.github.io/$repoName/"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   部署完成!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   访问地址: $fallbackUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   注意: GitHub Pages 首次部署可能需要 1-3 分钟生效" -ForegroundColor Yellow
    Write-Host ""
}

# 清理 token
$tokenPlain = $null
[System.GC]::Collect()

Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
