# PowerShell script to complete Pathway → Department refactoring
# Run this in PowerShell from the quiz_app directory

Write-Host "Starting Pathway → Department refactoring..." -ForegroundColor Green

# Files to update
$files = @(
    "lib\screens\enhanced_user_dashboard.dart",
    "lib\screens\enhanced_admin_dashboard.dart",
    "lib\screens\add_question_screen.dart"
)

# Replacements to make
$replacements = @{
    "_pathwayService" = "_departmentService"
    "List<Pathway>" = "List<Department>"
    "Pathway?" = "Department?"
    "Pathway " = "Department "
    "getAllPathways" = "getAllDepartments"
    "getPathwayById" = "getDepartmentById"
    "getPathwayLevels" = "getDepartmentLevels"
    "getOrientationPathway" = "getOrientationDepartment"
    "createPathwayLevel" = "createDepartmentLevel"
    "updatePathwayLevel" = "updateDepartmentLevel"
    "deletePathwayLevel" = "deleteDepartmentLevel"
    "createPathway" = "createDepartment"
    "updatePathway" = "updateDepartment"
    "deletePathway" = "deleteDepartment"
    "pathwayId" = "departmentId"
    "pathwayName" = "departmentName"
    "currentPathway" = "currentDepartment"
    "orientationPathway" = "orientationDepartment"
}

foreach ($file in $files) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Write-Host "Updating $file..." -ForegroundColor Yellow
        $content = Get-Content $filePath -Raw
        
        foreach ($key in $replacements.Keys) {
            $content = $content -replace [regex]::Escape($key), $replacements[$key]
        }
        
        Set-Content $filePath $content -NoNewline
        Write-Host "  ✓ Updated $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nRefactoring complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run the database migration in Supabase"
Write-Host "2. Test the app compilation"
Write-Host "3. Update UI text (Pathway → Department)"
