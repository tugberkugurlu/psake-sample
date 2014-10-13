function k-build {

    param(
    
        [String]
        [parameter(Mandatory=$true)]
        $projectFile,
        
        [String]
        [parameter(Mandatory=$true)]
        $configuration, 
        
        [String]
        [parameter(Mandatory=$true)]
        $outputDirectory
    )
    
    exec {
        kpm build $projectFile --configuration $configuration --out $outputDirectory
    }
}

function k-restore {

    param(
    
        [String]
        [parameter(Mandatory=$true)]
        $sourceDirectory
    )
    
    exec {
        kpm restore $sourceDirectory
    }
}

function test-globalkpm {

    $result = $true
    try {
        $(& kpm --version) | Out-Null
    }
    catch {
        $result = $false
    }
    
    return $result
}