properties {
    $testMessage = 'Executed Test!'
    $compileMessage = 'Executed Compile!'
    $cleanMessage = 'Executed Clean!'
    $configuration = 'Release'
}

Include ".\core\k.ps1"
Include ".\core\utils.ps1"

$scriptRoot = (split-path -parent $MyInvocation.MyCommand.Definition)
$solutionRoot = (get-item $scriptRoot).parent.fullname
$artifactsRoot = "$solutionRoot\artifacts"
$artifactsBuildRoot = "$artifactsRoot\build"
$artifactsTestRoot = "$artifactsRoot\test"
$projectFileName = "project.json"
$artifactsAppsRoot = "$artifactsRoot\Apps"
$srcRoot = "$solutionRoot\src"
$testsRoot = "$solutionRoot\test"
$appProjects = Get-ChildItem "$srcRoot\**\$projectFileName" | foreach { $_.FullName }
$testProjects = Get-ChildItem "$testsRoot\**\$projectFileName" | foreach { $_.FullName }

task default -depends Pack

task Pack -depends Build, Test {

    $packableProjects = $appProjects |  
        where { 
            $projFile = $_;
            $projObj = (get-content $projFile) -join "`n" | ConvertFrom-Json
            $projObj | Get-Member | where { $_.MemberType -eq "NoteProperty" } | Test-Any { $_.Name -eq "commands" }
        }

    $packableProjects | foreach {
        $sourceDirectory = Split-Path $_
        $projName = Split-Path $sourceDirectory -Leaf
        $packDir = Join-Path $artifactsAppsRoot $projName
        k-pack -sourceDirectory $sourceDirectory -configuration $configuration -outputDirectory $packDir
    }
}

task Test -depends Build, Clean { 
    $testMessage
    
    $testProjects | foreach {
        Write-Host $_
        k-run-test -projectFile $_
    }
}

task Check {
    if($(test-globalkpm) -eq $false) { throw "kpm doesn't exists globally" }
}

task Build -depends Clean, Check, Restore { 
    $compileMessage
    
    $appProjects | foreach {
        k-build -projectFile $_ -configuration $configuration -outputDirectory $artifactsBuildRoot
    }
    
    $testProjects | foreach {
        k-build -projectFile $_ -configuration $configuration -outputDirectory $artifactsTestRoot
    }
}

task Restore -depends Check {
    @($srcRoot, $testsRoot) | foreach {
        k-restore $_
    }
}

task Clean {
    $cleanMessage  
    $directories = $(Get-ChildItem "$solutionRoot\artifacts*"),`
        $(Get-ChildItem "$solutionRoot\**\**\bin"),`
        $(Get-ChildItem "$solutionRoot\**\**\node_modules"),` 
        $(Get-ChildItem "$solutionRoot\**\**\bower_components")

    $directories | foreach ($_) { Remove-Item $_.FullName -Force -Recurse }
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}