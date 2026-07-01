<#
.SYNOPSIS
    Sistema de Interface do Windows 11 Optimizer
    Fornece funções para criar uma interface profissional no PowerShell

.DESCRIPTION
    Este módulo contém todas as funções relacionadas à interface visual,
    incluindo cores, menus, barras de progresso e formatação.

.AUTHOR
    Kauê Marlon FF

.VERSION
    1.0.0
#>

# Definição de cores
$Global:Colors = @{
    Success     = 'Green'
    Error       = 'Red'
    Warning     = 'Yellow'
    Info        = 'Cyan'
    Header      = 'Magenta'
    Highlight   = 'White'
    Neutral     = 'Gray'
}

# ====================================================================
# FUNÇÃO: Show-Banner
# DESCRIÇÃO: Exibe o banner principal da aplicação
# ====================================================================
function Show-Banner {
    Clear-Host
    Write-Host "`n" -ForegroundColor $Colors.Header
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor $Colors.Header
    Write-Host "║                                                           ║" -ForegroundColor $Colors.Header
    Write-Host "║         🚀 WINDOWS 11 OPTIMIZER - PROFESSIONAL EDITION 🚀 ║" -ForegroundColor $Colors.Header
    Write-Host "║                                                           ║" -ForegroundColor $Colors.Header
    Write-Host "║              Ferramenta de Otimização Profissional         ║" -ForegroundColor $Colors.Header
    Write-Host "║                   Version 1.0.0 - 2026                    ║" -ForegroundColor $Colors.Header
    Write-Host "║                                                           ║" -ForegroundColor $Colors.Header
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor $Colors.Header
    Write-Host "`n" -ForegroundColor $Colors.Header
}

# ====================================================================
# FUNÇÃO: Show-Menu
# DESCRIÇÃO: Exibe um menu profissional com opções
# PARÂMETROS:
#   - Title: Título do menu
#   - Options: Array com opções do menu
# RETORNO: Número da opção selecionada
# ====================================================================
function Show-Menu {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [array]$Options
    )
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Colors.Header
    Write-Host "  📋 $Title" -ForegroundColor $Colors.Header
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Colors.Header
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $num = $i + 1
        Write-Host "  [$num] $($Options[$i])" -ForegroundColor $Colors.Highlight
    }
    
    Write-Host "  [0] Sair" -ForegroundColor $Colors.Warning
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Colors.Header
    
    do {
        $selection = Read-Host "`nDigite sua escolha"
        if ($selection -match '^[0-9]+$') {
            $selection = [int]$selection
            if ($selection -ge 0 -and $selection -le $Options.Count) {
                return $selection
            }
        }
        Write-Host "❌ Seleção inválida. Tente novamente." -ForegroundColor $Colors.Error
    } while ($true)
}

# ====================================================================
# FUNÇÃO: Show-ProgressBar
# DESCRIÇÃO: Exibe uma barra de progresso personalizada
# PARÂMETROS:
#   - Current: Valor atual
#   - Total: Valor total
#   - Message: Mensagem a exibir
# ====================================================================
function Show-ProgressBar {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Current,
        
        [Parameter(Mandatory = $true)]
        [int]$Total,
        
        [Parameter(Mandatory = $false)]
        [string]$Message = "Processando"
    )
    
    $percent = [math]::Round(($Current / $Total) * 100, 0)
    $barLength = 50
    $filledLength = [math]::Round(($percent / 100) * $barLength)
    $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
    
    Write-Host -NoNewline "\r  $Message: [$bar] $percent%" -ForegroundColor $Colors.Info
    
    if ($Current -eq $Total) {
        Write-Host "`n" 
    }
}

# ====================================================================
# FUNÇÃO: Show-Section
# DESCRIÇÃO: Exibe uma seção com título formatado
# PARÂMETROS:
#   - Title: Título da seção
#   - Icon: Ícone opcional
# ====================================================================
function Show-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$Icon = "▶"
    )
    
    Write-Host "`n" -ForegroundColor $Colors.Header
    Write-Host "  $Icon $Title" -ForegroundColor $Colors.Header
    Write-Host "  " + ("-" * ($Title.Length + 2)) -ForegroundColor $Colors.Header
}

# ====================================================================
# FUNÇÃO: Show-Message
# DESCRIÇÃO: Exibe uma mensagem formatada com tipo
# PARÂMETROS:
#   - Type: Tipo de mensagem (Success, Error, Warning, Info)
#   - Message: Conteúdo da mensagem
# ====================================================================
function Show-Message {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Success', 'Error', 'Warning', 'Info')]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    $icon = @{
        'Success' = '✓'
        'Error'   = '✗'
        'Warning' = '⚠'
        'Info'    = 'ℹ'
    }
    
    $color = $Colors[$Type]
    Write-Host "  $($icon[$Type]) $Message" -ForegroundColor $color
}

# ====================================================================
# FUNÇÃO: Show-Confirmation
# DESCRIÇÃO: Exibe uma caixa de confirmação
# PARÂMETROS:
#   - Message: Mensagem de confirmação
#   - DefaultYes: Se deve ser Yes por padrão
# RETORNO: $true se confirmado, $false caso contrário
# ====================================================================
function Show-Confirmation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [bool]$DefaultYes = $true
    )
    
    Write-Host "`n" -ForegroundColor $Colors.Warning
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $Colors.Warning
    Write-Host "║                  ⚠️  CONFIRMAÇÃO NECESSÁRIA               ║" -ForegroundColor $Colors.Warning
    Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor $Colors.Warning
    Write-Host "║ $($Message.PadRight(56)) ║" -ForegroundColor $Colors.Warning
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $Colors.Warning
    
    $default = if ($DefaultYes) { "S/n" } else { "s/N" }
    $response = Read-Host "`nDeseja continuar? ($default)"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return $response -match '^[Ss]$'
}

# ====================================================================
# FUNÇÃO: Show-Table
# DESCRIÇÃO: Exibe uma tabela formatada
# PARÂMETROS:
#   - Data: Dados da tabela
#   - Title: Título opcional
# ====================================================================
function Show-Table {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $false)]
        [string]$Title
    )
    
    if ($Title) {
        Show-Section -Title $Title
    }
    
    $Data | Format-Table -AutoSize
}

# ====================================================================
# FUNÇÃO: Show-Statistics
# DESCRIÇÃO: Exibe um painel de estatísticas
# PARÂMETROS:
#   - Stats: Hashtable com estatísticas
# ====================================================================
function Show-Statistics {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Stats
    )
    
    Write-Host "`n" -ForegroundColor $Colors.Header
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor $Colors.Header
    Write-Host "║                     📊 ESTATÍSTICAS                       ║" -ForegroundColor $Colors.Header
    Write-Host "╠════════════════════════════════════════════════════════════╣" -ForegroundColor $Colors.Header
    
    foreach ($key in $Stats.Keys) {
        $value = $Stats[$key]
        Write-Host "║ $($key.PadRight(25)) : $($value.ToString().PadRight(28)) ║" -ForegroundColor $Colors.Info
    }
    
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor $Colors.Header
}

# ====================================================================
# FUNÇÃO: Wait-Confirmation
# DESCRIÇÃO: Aguarda confirmação do usuário
# ====================================================================
function Wait-Confirmation {
    Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor $Colors.Neutral
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Exportar funções públicas
Export-ModuleMember -Function @(
    'Show-Banner',
    'Show-Menu',
    'Show-ProgressBar',
    'Show-Section',
    'Show-Message',
    'Show-Confirmation',
    'Show-Table',
    'Show-Statistics',
    'Wait-Confirmation'
)
