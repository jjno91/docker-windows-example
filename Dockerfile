FROM microsoft/iis

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# load build artifacts into image
RUN New-Item -ItemType directory -Path C:\artifacts
COPY . C:\artifacts

# move website to standard IIS directory
RUN New-Item -ItemType directory -Path C:\inetpub\your_site
RUN Move-Item -Path C:\artifacts\_PublishedWebsites\your_site -Destination C:\inetpub\your_site

EXPOSE 8080

ENTRYPOINT ["powershell.exe", "C:\\artifacts\\start.ps1"]
