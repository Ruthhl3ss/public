# Azure DevOps self-hosted agent - Linux (Ubuntu 24.04, x64)
# Build on an Apple Silicon Mac for an x64 NAS:
#   docker buildx build --platform linux/amd64 -t azdo-agent-linux:latest --load .
#
# Based on Microsoft's "Run a self-hosted agent in Docker" sample:
#   https://learn.microsoft.com/azure/devops/pipelines/agents/docker

FROM ubuntu:24.04

# .NET SDK channel from the Ubuntu archive (dotnet-sdk-<version>).
ARG DOTNET_SDK_VERSION=10.0
ARG PS_MODULES="Az.Accounts Az.Avd PSCloudPc Microsoft.Graph.Authentication"

ENV DEBIAN_FRONTEND=noninteractive \
    TARGETARCH="linux-x64" \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    POWERSHELL_TELEMETRY_OPTOUT=1

# 1. Latest OS updates + agent prerequisites
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg lsb-release apt-transport-https \
      git jq unzip zip libicu74 sudo \
 && rm -rf /var/lib/apt/lists/*

# 2. Microsoft (PowerShell) and Azure CLI apt repos, HashiCorp (Terraform) apt repo
#    PowerShell: https://learn.microsoft.com/powershell/scripting/install/install-ubuntu
#    Azure CLI:  https://learn.microsoft.com/cli/azure/install-azure-cli-linux?pivots=apt (option 2)
#    Terraform:  https://developer.hashicorp.com/terraform/install#linux
RUN set -eux; \
    . /etc/os-release; \
    curl -fsSL "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -o /tmp/packages-microsoft-prod.deb; \
    dpkg -i /tmp/packages-microsoft-prod.deb; rm /tmp/packages-microsoft-prod.deb; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg; \
    printf 'Types: deb\nURIs: https://packages.microsoft.com/repos/azure-cli/\nSuites: %s\nComponents: main\nArchitectures: amd64\nSigned-by: /etc/apt/keyrings/microsoft.gpg\n' "${VERSION_CODENAME}" > /etc/apt/sources.list.d/azure-cli.sources; \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/hashicorp.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends powershell azure-cli terraform "dotnet-sdk-${DOTNET_SDK_VERSION}"; \
    rm -rf /var/lib/apt/lists/*

# 3. Bicep (latest standalone binary)
#    https://learn.microsoft.com/azure/azure-resource-manager/bicep/install#linux
RUN curl -fsSL -o /usr/local/bin/bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 \
 && chmod +x /usr/local/bin/bicep

# 4. PowerShell modules for all users (PSResourceGet ships with PowerShell 7.4+)
RUN pwsh -NoLogo -NoProfile -Command " \
      \$ErrorActionPreference = 'Stop'; \
      foreach (\$m in '${PS_MODULES}'.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) { Install-PSResource -Name \$m -Scope AllUsers -TrustRepository -Quiet }; \
      Get-Module -ListAvailable | Where-Object Name -like 'Az.*' | Format-Table Name, Version"

WORKDIR /azp/
COPY ./start.sh ./
RUN sed -i 's/\r$//' ./start.sh && chmod +x ./start.sh

# Non-root agent user; Azure CLI uses the Bicep binary on PATH instead of downloading its own.
RUN useradd -m -d /home/agent agent \
 && chown -R agent:agent /azp /home/agent
USER agent
RUN az config set bicep.use_binary_from_path=true --only-show-errors \
 && az config set core.collect_telemetry=false --only-show-errors

ENTRYPOINT [ "./start.sh" ]
