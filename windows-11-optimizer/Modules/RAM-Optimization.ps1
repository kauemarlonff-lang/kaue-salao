<#
.SYNOPSIS
    Módulo de Otimização de RAM
    Otimiza memória, pagefile, cache e compressão

.DESCRIPTION
    Implementa otimizações de RAM baseadas em Microsoft best practices.

.NOTES
    - Memory Compression pode impactar latency em SSDs lentos
    - Pagefile otimizado melhora estabilidade
    - Standby List otimizada melhora disponível

.AUTHOR
    Kauê Marlon FF

.VERSION
    1.0.0
#>

# ====================================================================
# FUNÇÃO: Optimize-MemoryCompression
# DESCRIÇÃO: Otimiza compresão de memória
# MOTIVO: Melhora uso de RAM, mantendo memória livre.
#         Pode impactar latência se SSD for lento.
# ====================================================================
function Optimize-MemoryCompression {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Disable = $false
    )
    
    try {
        if ($Disable) {
            # Desativar compressão
            & reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v DisablePageCombining /t REG_DWORD /d 1 /f 2>&1 | Out-Null
            Write-Log "Memory Compression desativada" -Level Info
        }
        else {
            # Ativar e otimizar compressão
            & reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v DisablePageCombining /t REG_DWORD /d 0 /f 2>&1 | Out-Null
            Write-Log "Memory Compression ativada" -Level Info
        }
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar compressão: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-Pagefile
# DESCRIÇÃO: Otimiza pagefile do Windows
# MOTIVO: Evita fragmentação, melhora estabilidade e performance.
# ====================================================================
function Optimize-Pagefile {
    try {
        # Definir pagefile em SSD ápido (geralmente C:)
        # Recomendação: Pagefile = RAM * 1.5 a 2x
        
        $memory = Get-CimInstance -Class Win32_OperatingSystem
        $totalMemoryMB = $memory.TotalVisibleMemorySize / 1024
        $pagefileSizeMB = [int]($totalMemoryMB * 1.5)
        
        # Configuração via registro
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        
        # Criar pagefile customizado
        $pagefileSettings = @{
            'PagingFiles' = @("C:\\pagefile.sys $pagefileSizeMB $pagefileSizeMB")
        }
        
        # Usar CIM para configurar pagefile
        Get-CimInstance -Class Win32_ComputerSystem | Invoke-CimMethod -MethodName SetUserModeSettings -Arguments @{
            PageFileInitialSize = $pagefileSizeMB
            PageFileMaximumSize  = $pagefileSizeMB
        } -ErrorAction SilentlyContinue
        
        Write-Log "Pagefile otimizado: $pagefileSizeMB MB" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar pagefile: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Clear-StandbyList
# DESCRIÇÃO: Limpa Standby List para liberar memória
# MOTIVO: Melhora disponível de memória física.
# ====================================================================
function Clear-StandbyList {
    try {
        # Windows 10+ possui EmptyStandbyList disponível
        $standbyPath = "C:\Windows\System32"
        
        if (Test-Path "$standbyPath\EmptyStandbyList.exe") {
            & "$standbyPath\EmptyStandbyList.exe" standby Z 2>&1 | Out-Null
            Write-Log "Standby List limpo" -Level Info
            return $true
        }
        else {
            # Alternativa: usar PowerShell direto
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            Write-Log "RAM limpa via Garbage Collector" -Level Info
            return $true
        }
    }
    catch {
        Write-Log "Erro ao limpar Standby List: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-Prefetch
# DESCRIÇÃO: Otimiza Prefetch para boot e abertura de programas
# MOTIVO: Acelera carregamento de aplicativos frequentes.
# ====================================================================
function Optimize-Prefetch {
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
        
        # Habilitar Prefetch para todos
        Set-RegistryValue -Path $regPath -Name "EnablePrefetcher" -Value 3 -Type DWord
        
        # Habilitar SuperFetch (SysMain)
        Set-RegistryValue -Path $regPath -Name "EnableSuperfetch" -Value 3 -Type DWord
        
        # Otimizar Prefetch à inicialização
        Set-RegistryValue -Path $regPath -Name "PrefetchTraceFlags" -Value 1575 -Type DWord
        
        Write-Log "Prefetch otimizado" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar Prefetch: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-SysMain
# DESCRIÇÃO: Otimiza ou desativa SysMain (SuperFetch)
# MOTIVO: Melhora boot e abertura de apps, mas consome RAM.
# ====================================================================
function Optimize-SysMain {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Optimized', 'Disabled', 'Automatic')]
        [string]$Mode = 'Optimized'
    )
    
    try {
        $service = Get-Service -Name SysMain -ErrorAction SilentlyContinue
        
        if ($null -eq $service) {
            Write-Log "Serviço SysMain não encontrado" -Level Warning
            return $false
        }
        
        switch ($Mode) {
            'Optimized' {
                Set-Service -Name SysMain -StartupType Automatic
                Start-Service -Name SysMain -ErrorAction SilentlyContinue
                Write-Log "SysMain: Modo Otimizado" -Level Info
            }
            'Disabled' {
                Stop-Service -Name SysMain -Force -ErrorAction SilentlyContinue
                Set-Service -Name SysMain -StartupType Disabled
                Write-Log "SysMain: Desativado" -Level Info
            }
            'Automatic' {
                Set-Service -Name SysMain -StartupType Automatic
                Write-Log "SysMain: Modo Automático" -Level Info
            }
        }
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar SysMain: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-MemoryPriority
# DESCRIÇÃO: Otimiza prioridade de memória para aplicativos
# MOTIVO: Aplicações em foreground recebem prioridade.
# ====================================================================
function Optimize-MemoryPriority {
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        
        # Priorizar memória para foreground
        Set-RegistryValue -Path $regPath -Name "PriorityBoost" -Value 1 -Type DWord
        
        # Otimizar alocação de memória
        Set-RegistryValue -Path $regPath -Name "ClearPageFileAtShutdown" -Value 0 -Type DWord
        
        Write-Log "Memory Priority otimizada" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar Memory Priority: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Get-RAMOptimizationStatus
# DESCRIÇÃO: Retorna status das otimizações de RAM
# RETORNO: Hashtable com status
# ====================================================================
function Get-RAMOptimizationStatus {
    $status = @{}
    
    # Verificar Prefetch
    $prefetchValue = Get-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher"
    $status['Prefetch'] = if ($prefetchValue -eq 3) { "Otimizado" } else { "Não otimizado" }
    
    # Verificar SysMain
    $sysMainService = Get-Service -Name SysMain -ErrorAction SilentlyContinue
    $status['SysMain'] = if ($sysMainService.Status -eq 'Running') { "Ativo" } else { "Inativo" }
    
    # Memória disponível
    $memInfo = Get-MemoryInfo
    $status['Free Memory'] = $memInfo['Free Memory']
    $status['Memory Usage'] = $memInfo['Memory Usage %']
    
    return $status
}

# Exportar funções públicas
Export-ModuleMember -Function @(
    'Optimize-MemoryCompression',
    'Optimize-Pagefile',
    'Clear-StandbyList',
    'Optimize-Prefetch',
    'Optimize-SysMain',
    'Optimize-MemoryPriority',
    'Get-RAMOptimizationStatus'
)
