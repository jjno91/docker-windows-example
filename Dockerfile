# escape=`

FROM microsoft/iis

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# set default values for environment variables
ENV EVENT_LOG_SOURCE *
ENV CONFIG_ENV dev
ENV DEBUG false
ENV PORT 8080

# load build artifacts into image
RUN New-Item -ItemType directory -Path C:\docker
COPY . C:\docker

# move website to standard IIS directory
RUN Move-Item -Path C:\docker\_PublishedWebsites\your_site -Destination C:\inetpub\docker

# create iis application pool
RUN Import-Module WebAdministration; `
    New-Item -Path IIS:\AppPools\docker; `
    Set-ItemProperty IIS:\AppPools\docker -Name autoStart -Value True; `
    Set-ItemProperty IIS:\AppPools\docker -Name managedRuntimeVersion -Value v4.0; `
    Set-ItemProperty IIS:\AppPools\docker -Name managedPipelineMode -Value Integrated; `
    Get-ItemProperty IIS:\AppPools\docker | select *

# grant application pool directory access
RUN Import-Module WebAdministration; `
    ICACLS C:\inetpub\docker /grant 'IIS AppPool\docker:F' /t

# remove all pre-existing IIS sites
RUN Get-Website | Remove-Website

# configure iis logging to a single log file
RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'
RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'truncateSize' -v 4294967295
RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'period' -v 'MaxSize'
RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'directory' -v C:\iislog

ENTRYPOINT ["powershell.exe", "C:\\docker\\start.ps1"]
