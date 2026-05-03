$sourceDir = "d:\Test_Android\flutter_application_1\temp_agency"
$destBaseDir = "C:\Users\kimmi\.gemini\antigravity\skills"

$agentDirs = @("academic", "design", "engineering", "game-development", "marketing", "paid-media", "sales", "product", "project-management", "testing", "support", "spatial-computing", "specialized")

if (-not (Test-Path $destBaseDir)) {
    mkdir $destBaseDir
}

$count = 0
foreach ($dir in $agentDirs) {
    $fullDir = Join-Path $sourceDir $dir
    if (-not (Test-Path $fullDir)) { continue }

    $files = Get-ChildItem -Path $fullDir -Filter "*.md" -File
    foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Check for frontmatter
        if ($content -match "^---([\s\S]*?)---([\s\S]*)") {
            $frontmatter = $matches[1]
            $body = $matches[2]
            
            $nameMatch = $frontmatter -match "name: (.*)"
            $name = if ($nameMatch) { $matches[1].Trim() } else { continue }
            
            $descMatch = $frontmatter -match "description: (.*)"
            $description = if ($descMatch) { $matches[1].Trim() } else { "" }
            
            # Slugify: agency-<name-lowered-kebab>
            $slug = "agency-" + ($name.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', '')
            
            $targetDir = Join-Path $destBaseDir $slug
            if (-not (Test-Path $targetDir)) {
                mkdir $targetDir
            }
            
            $skillFile = Join-Path $targetDir "SKILL.md"
            $today = (Get-Date).ToString("yyyy-MM-dd")
            
            $skillContent = @"
---
name: $slug
description: $description
risk: low
source: community
date_added: '$today'
---
$body
"@
            Set-Content -Path $skillFile -Value $skillContent -Encoding UTF8
            $count++
            Write-Host "Installed: $slug"
        }
    }
}

Write-Host "`nTotal: $count skills installed/updated."
