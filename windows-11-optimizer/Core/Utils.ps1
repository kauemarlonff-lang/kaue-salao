<#
.SYNOPSIS
    Funções Utilitárias do Windows 11 Optimizer
    Ferramentas gerais de suporte

.DESCRIPTION
    Módulo com funções úteis para todo o sistema.

.AUTHOR
    Kauê Marlon FF

.VERSION
    1.0.0
#>

# ====================================================================
# FUNÇÃO: Test-Administrator
# DESCRIÇÃO: Verifica se o script está sendo executado como administrador
# RETORNO: $true se administrador, $false caso contrário
# ====================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ====================================================================
# FUNÇÃO: Test-Windows11
# DESCRIÇÃO: Verifica se o SO é Windows 11
# RETORNO: $true se Windows 11, $false caso contrário
# ====================================================================
function Test-Windows11 {
    $os = Get-CimInstance -Class Win32_OperatingSystem
    $version = [Version]$os.Version
    $buildNumber = $os.BuildNumber
    
    # Windows 11 começa no build 22000
    return ($version.Major -eq 10 -and $buildNumber -ge 22000)
}

# ====================================================================
# FUNÇÃO: Get-OSInfo
# DESCRIÇÃO: Retorna informações do SO
# RETORNO: Hashtable com informações
# ====================================================================
function Get-OSInfo {
    $os = Get-CimInstance -Class Win32_OperatingSystem
    $csinfo = Get-CimInstance -Class Win32_ComputerSystemProduct
    
    return @{
        'OS Name'          = $os.Caption
        'Version'          = $os.Version
        'Build'            = $os.BuildNumber
        'Architecture'     = $os.OSArchitecture
        'Install Date'     = [DateTime]$os.InstallDate
        'Last Boot Time'   = [DateTime]$os.LastBootUpTime
        'System Uptime'    = (New-TimeSpan -Start ([DateTime]$os.LastBootUpTime) -End (Get-Date)).ToString('d\.hh\:mm\:ss')
    }
}

# ====================================================================
# FUNÇÃO: Get-ProcessorInfo
# DESCRIÇÃO: Retorna informações do processador
# RETORNO: Hashtable com informações
# ====================================================================
function Get-ProcessorInfo {
    $cpu = Get-CimInstance -Class Win32_Processor
    
    return @{
        'Name'                = $cpu.Name
        'Cores'               = $cpu.NumberOfCores
        'Logical Processors'  = $cpu.NumberOfLogicalProcessors
        'Max Clock Speed'     = "$($cpu.MaxClockSpeed) MHz"
        'Architecture'        = $cpu.Architecture
        'Virtualization'      = $cpu.VirtualizationFirmwareEnabled
    }
}

# ====================================================================
# FUNÇÃO: Get-MemoryInfo
# DESCRIÇÃO: Retorna informações de memória
# RETORNO: Hashtable com informações
# ====================================================================
function Get-MemoryInfo {
    $memory = Get-CimInstance -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $ram = Get-CimInstance -Class Win32_OperatingSystem
    $freeMem = $ram.FreePhysicalMemory / 1MB
    $totalMem = $ram.TotalVisibleMemorySize / 1MB
    $usedMem = $totalMem - $freeMem
    
    return @{
        'Total Memory'      = "{0:F2} GB" -f ($memory.Sum / 1GB)
        'Used Memory'       = "{0:F2} GB" -f $usedMem
        'Free Memory'       = "{0:F2} GB" -f $freeMem
        'Memory Usage %'    = "{0:F2}%" -f (($usedMem / $totalMem) * 100)
    }
}

# ====================================================================
# FUNÇÃO: Get-DiskInfo
# DESCRIÇÃO: Retorna informações de disco
# RETORNO: Array com informações de cada disco
# ====================================================================
function Get-DiskInfo {
    $disks = Get-CimInstance -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    $result = @()
    foreach ($disk in $disks) {
        $result += @{
            'Drive'         = $disk.DeviceID
            'Size (GB)'     = [math]::Round($disk.Size / 1GB, 2)
            'Used (GB)'     = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
            'Free (GB)'     = [math]::Round($disk.FreeSpace / 1GB, 2)
            'Usage %'       = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
        }
    }
    
    return $result
}

# ====================================================================
# FUNÇÃO: Test-RegistryValue
# DESCRIÇÃO: Verifica se um valor do registro existe
# PARÂMETROS:
#   - Path: Caminho do registro
#   - Name: Nome do valor
# RETORNO: $true se existe, $false caso contrário
# ====================================================================
function Test-RegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        return $null -ne $value
    }
    catch {
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Set-RegistryValue
# DESCRIÇÃO: Define um valor no registro
# PARÂMETROS:
#   - Path: Caminho do registro
#   - Name: Nome do valor
#   - Value: Valor a definir
#   - Type: Tipo do valor (String, DWord, QWord, Binary, ExpandString, MultiString)
# RETORNO: $true se sucesso, $false caso contrário
# ====================================================================
function Set-RegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        $Value,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('String', 'DWord', 'QWord', 'Binary', 'ExpandString', 'MultiString')]
        [string]$Type = 'DWord'
    )
    
    try {
        # Criar o caminho se não existir
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Converter tipo para PropertyType correto
        $propertyType = $Type
        if ($Type -eq 'DWord') { $propertyType = 'DWord' }
        if ($Type -eq 'QWord') { $propertyType = 'QWord' }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $propertyType -Force | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Get-RegistryValue
# DESCRIÇÃO: Obtém um valor do registro
# PARÂMETROS:
#   - Path: Caminho do registro
#   - Name: Nome do valor
# RETORNO: Valor do registro ou $null
# ====================================================================
function Get-RegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        return $value.$Name
    }
    catch {
        return $null
    }
}

# ====================================================================
# FUNÇÃO: Restart-SystemOnDemand
# DESCRIÇÃO: Agenda reinicialização do sistema
# PARÂMETROS:
#   - Delay: Tempo em segundos antes de reiniciar
#   - Force: Forçar reinicialização
# ====================================================================
function Restart-SystemOnDemand {
    param(
        [Parameter(Mandatory = $false)]
        [int]$Delay = 60,
        
        [Parameter(Mandatory = $false)]
        [bool]$Force = $false
    )
    
    $forceFlag = if ($Force) { '/f' } else { '' }
    & shutdown.exe /r /t $Delay /c "Windows 11 Optimizer - Reinicial." $forceFlag 2>&1 | Out-Null
}

# Exportar funções públicas
Export-ModuleMember -Function @(
    'Test-Administrator',
    'Test-Windows11',
    'Get-OSInfo',
    'Get-ProcessorInfo',
    'Get-MemoryInfo',
    'Get-DiskInfo',
    'Test-RegistryValue',
    'Set-RegistryValue',
    'Get-RegistryValue',
    'Restart-SystemOnDemand'
)
