<#
.SYNOPSIS
    Sistema de Backup do Windows 11 Optimizer
    Gerencia backup e restauração de configurações

.DESCRIPTION
    Módulo responsável pelo backup automático de configurações
    antes de qualquer modificação crítica.

.AUTHOR
    Kauê Marlon FF

.VERSION
    1.0.0
#>

# Definições globais
$Global:BackupPath = "$PSScriptRoot\..\Backup"
$Global:BackupIndex = @{}

# ====================================================================
# FUNÇÃO: Initialize-Backup
# DESCRIÇÃO: Inicializa o sistema de backup
# ====================================================================
function Initialize-Backup {
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    }
}

# ====================================================================
# FUNÇÃO: Backup-RegistryKey
# DESCRIÇÃO: Faz backup de uma chave do registro
# PARÂMETROS:
#   - RegistryPath: Caminho da chave do registro
#   - Name: Nome do backup
# RETORNO: Caminho do arquivo de backup
# ====================================================================
function Backup-RegistryKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RegistryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $backupFile = Join-Path $BackupPath "$Name-$timestamp.reg"
    
    try {
        # Extrair caminho e chave
        $parts = $RegistryPath -split '\\', 2
        $hive = $parts[0]
        $path = $parts[1]
        
        # Usar reg export
        $regPath = "$hive\$path"
        & reg export $regPath $backupFile /y | Out-Null
        
        Write-Log "Backup do registro: $RegistryPath em $backupFile" -Level Info
        return $backupFile
    }
    catch {
        Write-Log "Erro ao fazer backup do registro: $_" -Level Error
        return $null
    }
}

# ====================================================================
# FUNÇÃO: Backup-File
# DESCRIÇÃO: Faz backup de um arquivo
# PARÂMETROS:
#   - SourcePath: Caminho do arquivo origem
#   - Name: Nome do backup
# RETORNO: Caminho do arquivo de backup
# ====================================================================
function Backup-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    if (-not (Test-Path $SourcePath)) {
        Write-Log "Arquivo não encontrado: $SourcePath" -Level Warning
        return $null
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $backupFile = Join-Path $BackupPath "$Name-$timestamp.bak"
    
    try {
        Copy-Item -Path $SourcePath -Destination $backupFile -Force
        Write-Log "Backup do arquivo: $SourcePath" -Level Info
        return $backupFile
    }
    catch {
        Write-Log "Erro ao fazer backup do arquivo: $_" -Level Error
        return $null
    }
}

# ====================================================================
# FUNÇÃO: Get-BackupList
# DESCRIÇÃO: Lista todos os backups disponíveis
# RETORNO: Array com informações dos backups
# ====================================================================
function Get-BackupList {
    if (-not (Test-Path $BackupPath)) {
        return @()
    }
    
    Get-ChildItem -Path $BackupPath -File | Select-Object Name, FullName, CreationTime, @{Name="Size"; Expression={[math]::Round($_.Length/1MB, 2)}} | Sort-Object CreationTime -Descending
}

# ====================================================================
# FUNÇÃO: Restore-RegistryKey
# DESCRIÇÃO: Restaura uma chave do registro a partir de um backup
# PARÂMETROS:
#   - BackupFile: Caminho do arquivo de backup
# ====================================================================
function Restore-RegistryKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile
    )
    
    if (-not (Test-Path $BackupFile)) {
        Write-Log "Arquivo de backup não encontrado: $BackupFile" -Level Error
        return $false
    }
    
    try {
        & reg import $BackupFile 2>&1 | Out-Null
        Write-Log "Registro restaurado de: $BackupFile" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao restaurar registro: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Restore-File
# DESCRIÇÃO: Restaura um arquivo a partir de um backup
# PARÂMETROS:
#   - BackupFile: Caminho do arquivo de backup
#   - DestinationPath: Caminho de destino
# ====================================================================
function Restore-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )
    
    if (-not (Test-Path $BackupFile)) {
        Write-Log "Arquivo de backup não encontrado: $BackupFile" -Level Error
        return $false
    }
    
    try {
        Copy-Item -Path $BackupFile -Destination $DestinationPath -Force
        Write-Log "Arquivo restaurado: $DestinationPath" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao restaurar arquivo: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Create-RestorePoint
# DESCRIÇÃO: Cria um ponto de restauração do Windows
# PARÂMETROS:
#   - Description: Descrição do ponto de restauração
# RETORNO: $true se criado com sucesso
# ====================================================================
function Create-RestorePoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description
    )
    
    try {
        # Verificar se a restauração do sistema está habilitada
        $restore = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if ($null -eq $restore) {
            Write-Log "Restauração do Sistema não está habilitada" -Level Warning
            return $false
        }
        
        # Criar novo ponto de restauração
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "Ponto de restauração criado: $Description" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao criar ponto de restauração: $_" -Level Error
        return $false
    }
}

# Exportar funções públicas
Export-ModuleMember -Function @(
    'Initialize-Backup',
    'Backup-RegistryKey',
    'Backup-File',
    'Get-BackupList',
    'Restore-RegistryKey',
    'Restore-File',
    'Create-RestorePoint'
)
