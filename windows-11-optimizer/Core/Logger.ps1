<#
.SYNOPSIS
    Sistema de Logging do Windows 11 Optimizer
    Gerencia todos os logs da aplicação

.DESCRIPTION
    Módulo responsável por registrar eventos, erros e informações.
    Suporta múltiplos níveis de log (Error, Warning, Info, Debug).

.AUTHOR
    Kauê Marlon FF

.VERSION
    1.0.0
#>

# Definições globais
$Global:LogPath = "$PSScriptRoot\..\Logs"
$Global:LogFile = Join-Path $LogPath "optimizer-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').log"
$Global:LogLevel = "Info" # Error, Warning, Info, Debug

# ====================================================================
# FUNÇÃO: Initialize-Logging
# DESCRIÇÃO: Inicializa o sistema de logging
# ====================================================================
function Initialize-Logging {
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Windows 11 Optimizer iniciado" | Add-Content -Path $LogFile
}

# ====================================================================
# FUNÇÃO: Write-Log
# DESCRIÇÃO: Escreve uma entrada no log
# PARÂMETROS:
#   - Message: Mensagem a registrar
#   - Level: Nível do log (Error, Warning, Info, Debug)
#   - Console: Se deve exibir no console
# ====================================================================
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Error', 'Warning', 'Info', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory = $false)]
        [bool]$Console = $true
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Escrever no arquivo
    Add-Content -Path $LogFile -Value $logEntry
    
    # Exibir no console se necessário
    if ($Console) {
        $colors = @{
            'Error'   = 'Red'
            'Warning' = 'Yellow'
            'Info'    = 'Cyan'
            'Debug'   = 'Gray'
        }
        
        Write-Host $logEntry -ForegroundColor $colors[$Level]
    }
}

# ====================================================================
# FUNÇÃO: Get-LogFile
# DESCRIÇÃO: Retorna o caminho do arquivo de log atual
# RETORNO: Caminho do arquivo
# ====================================================================
function Get-LogFile {
    return $LogFile
}

# ====================================================================
# FUNÇÃO: Get-LogContent
# DESCRIÇÃO: Retorna o conteúdo do log
# RETORNO: Conteúdo do arquivo de log
# ====================================================================
function Get-LogContent {
    if (Test-Path $LogFile) {
        return Get-Content -Path $LogFile
    }
    return $null
}

# ====================================================================
# FUNÇÃO: Export-Log
# DESCRIÇÃO: Exporta o log para arquivo
# PARÂMETROS:
#   - Format: Formato de saída (TXT, CSV, HTML)
#   - Path: Caminho de destino
# ====================================================================
function Export-Log {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('TXT', 'CSV', 'HTML')]
        [string]$Format = 'TXT',
        
        [Parameter(Mandatory = $false)]
        [string]$Path = "$PSScriptRoot\..\Reports\log-export-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').$($Format.ToLower())"
    )
    
    # Garantir que o diretório de relatórios existe
    $reportDir = Split-Path $Path
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    $logContent = Get-LogContent
    
    if ($null -eq $logContent) {
        Write-Log "Nenhum conteúdo de log para exportar" -Level Warning
        return $null
    }
    
    switch ($Format) {
        'TXT' {
            $logContent | Out-File -Path $Path -Encoding UTF8
        }
        'CSV' {
            $logContent | ConvertFrom-Csv -Delimiter ']' | Export-Csv -Path $Path -NoTypeInformation
        }
        'HTML' {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Optimizer - Log Export</title>
    <style>
        body { font-family: Consolas, monospace; background-color: #1e1e1e; color: #00ff00; }
        pre { white-space: pre-wrap; word-wrap: break-word; padding: 20px; }
        .error { color: #ff0000; }
        .warning { color: #ffff00; }
        .info { color: #00ffff; }
        .debug { color: #808080; }
    </style>
</head>
<body>
    <h1>Windows 11 Optimizer - Log Export</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <pre>
"@
            
            foreach ($line in $logContent) {
                if ($line -match '\[Error\]') {
                    $html += "<span class='error'>$line</span>`n"
                }
                elseif ($line -match '\[Warning\]') {
                    $html += "<span class='warning'>$line</span>`n"
                }
                elseif ($line -match '\[Debug\]') {
                    $html += "<span class='debug'>$line</span>`n"
                }
                else {
                    $html += "<span class='info'>$line</span>`n"
                }
            }
            
            $html += @"
    </pre>
</body>
</html>
"@
            
            $html | Out-File -Path $Path -Encoding UTF8
        }
    }
    
    Write-Log "Log exportado: $Path" -Level Info
    return $Path
}

# Exportar funções públicas
Export-ModuleMember -Function @(
    'Initialize-Logging',
    'Write-Log',
    'Get-LogFile',
    'Get-LogContent',
    'Export-Log'
)
