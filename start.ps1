# load web config based on environment variable
#
# this allows you to load arbitrary config files
# such as Web.config at runtime based on APP_ENV
# value passed to container
Get-ChildItem -Path "C:\artifacts\${env:APP_ENV}\*" | Copy-Item -Destination "C:\inetpub\your_site\"

# remove all pre-existing IIS sites
Get-Website | Remove-Website

# configure IIS logging to a single location
Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'
Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'truncateSize' -v 4294967295
Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'period' -v 'MaxSize'
Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'directory' -v 'c:\iislog'

# launch your website
New-WebSite -Name your_site -Port 8080 -PhysicalPath "C:\inetpub\your_site"
Echo 'Web Site Created'
Start-Website -Name your_site
Get-Website

# force a log entry
Invoke-WebRequest http://localhost:8080 -UseBasicParsing | Out-Null

# force a log flush to guaruntee the log file is created
netsh http flush logbuffer | Out-Null

# confirm that ServiceMonitor.exe exists in this image
if ( !(Test-Path 'C:\ServiceMonitor.exe') ) {
  Echo 'C:\ServiceMonitor.exe does not exist on this image, therefore service health cannot be assessed and the application will never exit'

  # wait for log file to get generated
  While ($true) {

    # mute output until the log file is generated
    if ( Test-Path 'C:\iislog\W3SVC\u_extend1.log' ) {
      Get-Content -Wait -Path 'C:\iislog\W3SVC\u_extend1.log'
    }
  }
}

# start a job to tail IIS logs
${log-job} = Start-Job -scriptblock {

  # wait for log file to get generated
  While ($true) {

    # mute output until the log file is generated
    if ( Test-Path 'C:\iislog\W3SVC\u_extend1.log' ) {
      Get-Content -Wait -Path 'C:\iislog\W3SVC\u_extend1.log'
    }
  }
}

# start a job to monitor IIS health
${health-job} = Start-Job -scriptblock {
  C:\ServiceMonitor.exe w3svc
}

While ($true) {

  # output logs
  Receive-Job -job ${log-job}

  # if health job is not running then kill the container
  if ((${health-job} | Where State -eq "Running").Count -eq 0) {
    Echo 'ServiceMonitor.exe has died, exiting'
    exit
  }

  # pause between evaluations
  Start-Sleep -Seconds 15
}
