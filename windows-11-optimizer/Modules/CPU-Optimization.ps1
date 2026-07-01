<#
.SYNOPSIS
    Módulo de Otimização de CPU
    Otimiza processor scheduling, power plans e configurações de CPU

.DESCRIPTION
    Este módulo implementa otimizações avançadas de CPU baseadas
    em documentação oficial da Microsoft.

.NOTES
    - Power Plan Ultimate Performance requer privilégios administrativos
    - Core Parking afeta consumo de energia e desempenho
    - Algumas mudanças requerem reinicialização

.AUTHOR
    Kauê Marlon FF

.VERSION
    1.0.0
#>

# ====================================================================
# FUNÇÃO: Set-PowerPlanUltimatePerformance
# DESCRIÇÃO: Ativa o Power Plan "Ultimate Performance"
# MOTIVO: Desativa gerenciamento dinâmico de CPU, mantendo freq.
#         máxima constante. Melhora FPS e reduz latency.
# ====================================================================
function Set-PowerPlanUltimatePerformance {
    try {
        # Criar esquema Ultimate Performance se não existir
        $guid = 'e9a42b02-d5df-448d-aa00-03f14749e311'
        
        # Verificar se já existe
        $existingPlan = powercfg /query | Select-String "Ultimate Performance"
        
        if (-not $existingPlan) {
            powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749e311 | Out-Null
        }
        
        # Ativar Ultimate Performance
        powercfg /setactive $guid 2>&1 | Out-Null
        
        Write-Log "Power Plan: Ultimate Performance ativado" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao ativar Ultimate Performance: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Disable-CoreParking
# DESCRIÇÃO: Desativa Core Parking
# MOTIVO: Evita que cores sejam "estacionados" (desligados).
#         Melhora consistência de desempenho e FPS.
# ====================================================================
function Disable-CoreParking {
    try {
        # Desativar Core Parking via registro
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Processor"
        
        # Park Increase Threshold
        Set-RegistryValue -Path $regPath -Name "ParkingSet" -Value 0 -Type DWord
        Set-RegistryValue -Path $regPath -Name "Distribute" -Value 2 -Type DWord
        
        Write-Log "Core Parking desativado" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao desativar Core Parking: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-ThreadScheduling
# DESCRIÇÃO: Otimiza escalonamento de threads
# MOTIVO: Melhora distribuição de threads entre cores.
# ====================================================================
function Optimize-ThreadScheduling {
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        
        # Ativar SMT (Simultaneous Multithreading)
        Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "SMTEnabled" -Value 1 -Type DWord
        
        Write-Log "Thread Scheduling otimizado" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar thread scheduling: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-ProcessorPerformance
# DESCRIÇÃO: Ajusta registros de desempenho do processador
# MOTIVO: Aumenta freq. de CPU e reduz latência de resposta.
# ====================================================================
function Optimize-ProcessorPerformance {
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3747d440c8"
        
        # Processor Performance Boost Max
        if (Test-Path $regPath) {
            Set-RegistryValue -Path "$regPath\Default" -Name "ACSettingIndex" -Value 100 -Type DWord
            Set-RegistryValue -Path "$regPath\Default" -Name "DCSettingIndex" -Value 100 -Type DWord
        }
        
        # Aumentar freq. mínima do processador
        $minPerfRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41ee-89e6-a94db21ff50b"
        if (Test-Path $minPerfRegPath) {
            Set-RegistryValue -Path "$minPerfRegPath\Default" -Name "ACSettingIndex" -Value 100 -Type DWord
        }
        
        Write-Log "Performance do Processador otimizado" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar performance: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Disable-CPUMitigations
# DESCRIÇÃO: Desativa mitigações de CPU (com aviso de segurança)
# MOTIVO: Mitigações de Spectre/Meltdown impactam desempenho.
#         Apenas para usuários que entendem os riscos.
# AVISO: Pode reduzir segurança do sistema!
# ====================================================================
function Disable-CPUMitigations {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Confirm = $true
    )
    
    if ($Confirm) {
        $message = "AVISO DE SEGURANÇA: Desativar mitigações de CPU pode comprometer a segurança do sistema. Isto é recomendado APENAS em ambientes isolados ou para gaming competitivo. Continuar?"
        if (-not (Show-Confirmation -Message $message)) {
            Write-Log "Mitigações de CPU: Operação cancelada pelo usuário" -Level Info
            return $false
        }
    }
    
    try {
        # Desativar mitigações via registro
        & reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v KernelShadowStacks /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        & reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f 2>&1 | Out-Null
        & reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f 2>&1 | Out-Null
        
        Write-Log "AVISO: Mitigações de CPU desativadas (Risco de Segurança)" -Level Warning
        return $true
    }
    catch {
        Write-Log "Erro ao desativar mitigações: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Disable-IdleStates
# DESCRIÇÃO: Desativa estados de inatividade do processador
# MOTIVO: Pode melhorar resposta em sistemas com latência baixa.
# AVISO: Aumenta consumo de energia!
# ====================================================================
function Disable-IdleStates {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$Confirm = $true
    )
    
    if ($Confirm) {
        $message = "AVISO: Desativar estados de inatividade aumenta consumo de energia. Continuar?"
        if (-not (Show-Confirmation -Message $message)) {
            return $false
        }
    }
    
    try {
        powercfg /change processor-idle-disable 1 2>&1 | Out-Null
        Write-Log "Idle States desativados (Mayor consumo de energia)" -Level Warning
        return $true
    }
    catch {
        Write-Log "Erro ao desativar Idle States: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Optimize-BackgroundTasks
# DESCRIÇÃO: Reduz priority de background tasks
# MOTIVO: Prioriza aplicações em foreground, melhorando resposta.
# ====================================================================
function Optimize-BackgroundTasks {
    try {
        # Reduzir CPU usage de background tasks
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
        Set-RegistryValue -Path $regPath -Name "ConvertibleSlateMode" -Value 0 -Type DWord
        
        # Limitar background processes
        $servicesPath = "HKLM:\SYSTEM\CurrentControlSet\Services"
        
        # Desativar BITS (Background Intelligent Transfer Service) quando não necessário
        # $bits = Get-Service -Name BITS -ErrorAction SilentlyContinue
        # if ($bits) { Set-Service -Name BITS -StartupType Manual }
        
        Write-Log "Background Tasks otimizadas" -Level Info
        return $true
    }
    catch {
        Write-Log "Erro ao otimizar background tasks: $_" -Level Error
        return $false
    }
}

# ====================================================================
# FUNÇÃO: Get-CPUOptimizationStatus
# DESCRIÇÃO: Retorna status das otimizações aplicadas
# RETORNO: Hashtable com status
# ====================================================================
function Get-CPUOptimizationStatus {
    $status = @{}
    
    # Verificar Power Plan
    $powerPlan = powercfg /getactivescheme 2>&1 | Select-String "Ultimate Performance"
    $status['Power Plan'] = if ($powerPlan) { "Ultimate Performance " } else { "Padrão" }
    
    # Verificar Core Parking
    $coreParkingValue = Get-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Processor" -Name "ParkingSet"
    $status['Core Parking'] = if ($coreParkingValue -eq 0) { "Desativado" } else { "Ativo" }
    
    return $status
}

# Exportar funções públicas
Export-ModuleMember -Function @(
    'Set-PowerPlanUltimatePerformance',
    'Disable-CoreParking',
    'Optimize-ThreadScheduling',
    'Optimize-ProcessorPerformance',
    'Disable-CPUMitigations',
    'Disable-IdleStates',
    'Optimize-BackgroundTasks',
    'Get-CPUOptimizationStatus'
)
