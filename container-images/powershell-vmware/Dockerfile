# https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7
ARG VERSION=7.0.0

FROM r.spiarh.fr/powershell:${VERSION}
LABEL maintainer="_me@spiarh.fr"

RUN pwsh -Command 'Install-Module VMware.PowerCLI -Force' && \
	pwsh -Command 'Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false'
