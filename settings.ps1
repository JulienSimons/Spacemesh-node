
##################################################
## Spacemesh node PowerShell monitoring script. ##
## Contributions by Jonh and Sakki. 		    ##
## Compiled by Julien S. 					    ## 
## Last edited: 01/05/24                        ##
##################################################

function main {
$currentDate = Get-Date -Format "yyyyMMdd_HHmmss"  	# Get current date (specified below as local time).

	#-------------------Start Editing-------------------

    $title = "Spacemesh Node"	                 	# Name to show in window.
    $walletAddress = "sm1qqqqqqxuu09fa4plqfzgq2deq0wwlvekdn5za8slt7nd4"  # Your SMH wallet address.
    $provider = "0"									# Your GPU number; default 0. Found in Control Panel.
    $numunits = "4" 								# 1 unit = 64GB; minimum of 4 units.
    $postFileLocation = "D:\\node_1"					# PoST data location.
    $filelock = "afairtest"							# Afair name; can be renamed to anything.
    $maxFileSize = "2147483648"						# .bin file size; default 4294967296 KB.
    #-------------------Stop Editing-------------------
    #-----------------Advance Settings-----------------
    $config = ".\config.mainnet.json"				# config.mainnet.json file location.
    $smdataLocation = ".\sm_data"					# Node dataBase location.
    $tcpPort = "7513" 								# If port 7513 throws an error, change it (e.g. 7514) and try again.
    $logOutputPath = "output_$currentDate.txt"		# Log name uses _$currentDate for diferent logs.
    $goSpacemeshLocation = ".\go-spacemesh.exe"		# go-sm file location.
    $localDateTime = "Yes" 							# Yes/No. This will change the log date into a localized Time/Date format.

	#-------------------Stop Editing-------------------

    $dateColor = "Green"
    $otherColor = "DarkGray"
    $errorLevelColor = @{
        INFO = "Cyan"
        WARN = "Yellow"
        DEBUG = "DarkYellow"
        ERROR = "Red" 
	FATAL = "Magenta"
    }
	
	# This filters on the second loglevel column (INFO, WARN, DEBUG, etc). Use "ALL" to see everything.    
    $searchKeyword = "ALL" 
	
    if (!(Test-Path "$($logOutputPath)")) {
        New-Item -path "$($logOutputPath)" -type File
    }
	if (!(Test-Path $postFileLocation -PathType Container)) {
		New-Item -ItemType Directory -Force -Path $postFileLocation
	}
	else {
		Write-Host -ForegroundColor green "
		----------------------------------------
		        Power Script is Starting
		----------------------------------------"
	}

	$host.UI.RawUI.WindowTitle = $title
    
	# Check if go-spacemesh is already running. If it is, ignore. Do not relaunch.
    $processFilePath = (Get-Item $goSpacemeshLocation).FullName
    $processName = (Get-Item $goSpacemeshLocation).BaseName
    $runningProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
    $processIsRunning = $false
    foreach ($proc in $runningProcesses) {
        if ($proc.Path -eq $processFilePath) {
            $processIsRunning = $true
            break
        }
    }
    if (-not $processIsRunning) {
        $process = Start-Process -NoNewWindow -FilePath $goSpacemeshLocation -ArgumentList "--listen /ip4/0.0.0.0/tcp/$tcpPort", "--config", $config, "-d", $smdataLocation, "--smeshing-coinbase", $walletAddress, "--smeshing-start", "--filelock", $filelock, "--smeshing-opts-datadir", $postFileLocation, "--smeshing-opts-provider", $provider, "--smeshing-opts-numunits", $numunits, "--smeshing-opts-maxfilesize", $maxFileSize -RedirectStandardOutput $logOutputPath
    }
    colorizeLogs -logs $logOutputPath -searchKeyword $searchKeyword
}
function colorizeLogs {
    Param(
        [string]$logs,
        [string]$searchKeyword
    )

	# Check if each line is in the correct format; otherwise, ignore.
    Get-Content -Path $logs -Wait | ForEach-Object {
        $parts = $_ -split '\t'
        
        $dateConversionSuccessful = $true
        try { 
            $logDate = Get-Date $parts[0]
        } catch {
            $dateConversionSuccessful = $false
        }

        if ($dateConversionSuccessful) {         
            if ($searchKeyword -match "ALL") {$searchKeyword = $null}
            if ($parts.Count -gt 2 -and $parts[1] -match $searchKeyword) {
                $eLColor = $errorLevelColor[$parts[1]]
                if ($localDateTime -match "Yes") {$logDate = $logDate.ToString("yyyy/MM/dd - HH:mm:ss.fff, dddd")} else {$logDate = $parts[0]}
                Write-Host -NoNewline -ForegroundColor $dateColor $logDate
                Write-Host -NoNewline -ForegroundColor $otherColor "`t"
                Write-Host -NoNewline -ForegroundColor $eLColor $parts[1]
                Write-Host -NoNewline -ForegroundColor $otherColor "`t"

                for ($i = 2; $i -lt $parts.Count; $i++) {
                    Write-Host -NoNewline -ForegroundColor $otherColor $parts[$i]
                    if ($i -ne $parts.Count - 1) {
                        Write-Host -NoNewline -ForegroundColor $otherColor "`t"
                    }
                }        
                Write-Host ""
            }
        }    
    }
}
main
