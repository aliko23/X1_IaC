# Deployment Helper Script for Azure Export - Bicep Modules
# This script automates the deployment of exported resources to Azure
#
# Usage:
#   .\Deploy.ps1 -ResourceGroupName "rg-test-prod-gwc-02" -EnvironmentFile "main.bicepparam" -DryRun
#   .\Deploy.ps1 -ResourceGroupName "rg-test-prod-gwc-02" -EnvironmentFile "main.bicepparam" -Deploy

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentFile,
    
    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = "main.bicep",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "germanywestcentral",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Deploy,
    
    [Parameter(Mandatory = $false)]
    [switch]$Validate
)

# ============================================================================
# Functions
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($Message.PadRight(67)) ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message, [int]$StepNumber)
    Write-Host ""
    Write-Host "[Step $StepNumber] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

# ============================================================================
# Main Script
# ============================================================================

Write-Header "Azure Bicep Export - Deployment Helper"

# Check prerequisites
Write-Step "Checking prerequisites" 1

# Check Azure CLI
try {
    $azVersion = az --version | Select-Object -First 1
    Write-Success "Azure CLI found: $azVersion"
} catch {
    Write-Error-Custom "Azure CLI not found. Please install Azure CLI 2.50.0 or later."
    exit 1
}

# Check Bicep
try {
    $bicepVersion = az bicep version
    Write-Success "Bicep CLI Version: $bicepVersion"
} catch {
    Write-Error-Custom "Bicep CLI not found. Please update Azure CLI."
    exit 1
}

# Check template files
Write-Step "Validating template files" 2

if (!(Test-Path $TemplateFile)) {
    Write-Error-Custom "Template file not found: $TemplateFile"
    exit 1
}
Write-Success "Found template file: $TemplateFile"

if (!(Test-Path $EnvironmentFile)) {
    Write-Error-Custom "Parameter file not found: $EnvironmentFile"
    exit 1
}
Write-Success "Found parameter file: $EnvironmentFile"

# Build Bicep files
Write-Step "Building Bicep files" 3
try {
    Write-Info "Building $TemplateFile..."
    az bicep build --file $TemplateFile --outdir "." | Out-Null
    Write-Success "Bicep build successful"
} catch {
    Write-Error-Custom "Bicep build failed: $_"
    exit 1
}

# Check Azure authentication
Write-Step "Checking Azure authentication" 4
try {
    $account = az account show
    if ($null -eq $account) {
        Write-Error-Custom "Not signed in to Azure. Please run 'az login' first."
        exit 1
    }
    $accountInfo = $account | ConvertFrom-Json
    Write-Success "Signed in as: $($accountInfo.user.name)"
    Write-Info "Subscription: $($accountInfo.name) ($($accountInfo.id))"
} catch {
    Write-Error-Custom "Authentication failed: $_"
    exit 1
}

# Check resource group
Write-Step "Checking resource group" 5
try {
    $rg = az group show --name $ResourceGroupName
    if ($null -eq $rg) {
        Write-Info "Resource group '$ResourceGroupName' does not exist. Creating..."
        az group create --name $ResourceGroupName --location $Location
        Write-Success "Resource group created successfully"
    } else {
        $rgInfo = $rg | ConvertFrom-Json
        Write-Success "Resource group exists: $($rgInfo.name)"
        Write-Info "Location: $($rgInfo.location)"
    }
} catch {
    Write-Error-Custom "Failed to check/create resource group: $_"
    exit 1
}

# Validate deployment
if ($Validate -or $DryRun -or $Deploy) {
    Write-Step "Validating template deployment" 6
    Write-Info "Running template validation..."
    
    try {
        $validation = az deployment group validate `
            --resource-group $ResourceGroupName `
            --template-file $TemplateFile `
            --parameters $EnvironmentFile `
            --output json
        
        if ($validation) {
            $validationResult = $validation | ConvertFrom-Json
            Write-Success "Template validation successful"
            Write-Info "Validation Status: $($validationResult.properties.validationResult.status)"
        }
    } catch {
        Write-Error-Custom "Template validation failed: $_"
        exit 1
    }
}

# Dry Run (What-If Analysis)
if ($DryRun) {
    Write-Step "Running What-If analysis" 7
    Write-Info "Analyzing deployment changes..."
    
    try {
        $whatif = az deployment group what-if `
            --resource-group $ResourceGroupName `
            --template-file $TemplateFile `
            --parameters $EnvironmentFile `
            --output json
        
        $whatifResult = $whatif | ConvertFrom-Json
        
        Write-Success "What-If analysis completed"
        Write-Host ""
        Write-Host "Changes that will be made:" -ForegroundColor Cyan
        Write-Host $($whatifResult | ConvertTo-Json -Depth 10)
        
    } catch {
        Write-Error-Custom "What-If analysis failed: $_"
        exit 1
    }
    
    Write-Header "Dry Run Complete - No resources were deployed"
    exit 0
}

# Deploy
if ($Deploy) {
    Write-Step "Deploying resources" 7
    $deploymentName = "bicep-export-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Info "Deployment Name: $deploymentName"
    Write-Info "This process may take several minutes..."
    Write-Host ""
    
    try {
        $deployment = az deployment group create `
            --resource-group $ResourceGroupName `
            --template-file $TemplateFile `
            --parameters $EnvironmentFile `
            --name $deploymentName `
            --output json
        
        $deploymentInfo = $deployment | ConvertFrom-Json
        
        if ($deploymentInfo.properties.provisioningState -eq "Succeeded") {
            Write-Success "Deployment succeeded!"
            Write-Info "Deployment ID: $($deploymentInfo.id)"
            Write-Info "Provisioning State: $($deploymentInfo.properties.provisioningState)"
            
            # Display outputs
            if ($deploymentInfo.properties.outputs.Count -gt 0) {
                Write-Host ""
                Write-Host "Deployment Outputs:" -ForegroundColor Cyan
                foreach ($output in $deploymentInfo.properties.outputs.PSObject.Properties) {
                    Write-Host "  $($output.Name): $($output.Value.value)"
                }
            }
        } else {
            Write-Error-Custom "Deployment failed with status: $($deploymentInfo.properties.provisioningState)"
            exit 1
        }
        
    } catch {
        Write-Error-Custom "Deployment failed: $_"
        exit 1
    }
    
    # Verify deployed resources
    Write-Step "Verifying deployed resources" 8
    Write-Info "Checking deployed resources in resource group..."
    
    try {
        $resources = az resource list `
            --resource-group $ResourceGroupName `
            --output json
        
        $resourceList = $resources | ConvertFrom-Json
        
        Write-Success "Found $($resourceList.Count) resources:"
        foreach ($resource in $resourceList) {
            Write-Info "  - $($resource.type): $($resource.name)"
        }
        
    } catch {
        Write-Error-Custom "Failed to verify resources: $_"
        exit 1
    }
}

# Summary
Write-Header "Deployment Summary"

if (!$Deploy -and !$DryRun -and !$Validate) {
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Validate template:"
    Write-Host "    .\Deploy.ps1 -ResourceGroupName '$ResourceGroupName' -EnvironmentFile '$EnvironmentFile' -Validate"
    Write-Host ""
    Write-Host "  Dry Run (What-If analysis):"
    Write-Host "    .\Deploy.ps1 -ResourceGroupName '$ResourceGroupName' -EnvironmentFile '$EnvironmentFile' -DryRun"
    Write-Host ""
    Write-Host "  Deploy resources:"
    Write-Host "    .\Deploy.ps1 -ResourceGroupName '$ResourceGroupName' -EnvironmentFile '$EnvironmentFile' -Deploy"
    Write-Host ""
}

Write-Success "Script execution completed"
Write-Host ""
