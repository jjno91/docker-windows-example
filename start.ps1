# load web config based on environment variable
#
# this allows you to load arbitrary config files
# such as Web.config at runtime based on
# CONFIG_ENV value passed to container
Get-ChildItem -Path "C:\docker\config\${env:CONFIG_ENV}\*" | Copy-Item -Destination "C:\inetpub\docker\"

# launch website
New-WebSite -Name docker -Port ${env:PORT} -PhysicalPath "C:\inetpub\docker" -ApplicationPool "docker"

# start a job to tail iis logs
${log-job} = Start-Job -scriptblock {

  # wait for log file to get generated
  While ($true) {

    # mute output until the log file is generated
    if ( Test-Path 'C:\iislog\W3SVC\u_extend1.log' ) {
      Get-Content -Wait -Path 'C:\iislog\W3SVC\u_extend1.log'
    }

    # pause between evaluations
    Start-Sleep -Seconds 5
  }
}

# start a job to monitor iis health
${health-job} = Start-Job -scriptblock {
  $i = 0
  while ( $i -lt ${env:RESTART_COUNT} ) {
    $i++
    Start-Sleep -Seconds 15
    C:\ServiceMonitor.exe w3svc
  }
}

# dump application event logs up to this time
${current-time} = Get-Date
Get-EventLog -LogName "Application" `
             -Source "${env:EVENT_LOG_SOURCE}" `
             -Before ${current-time} `
             | select -ExpandProperty message

# primary loop to monitor application health and output logs
While ($true) {

  # dump application event logs since last evaluation
  ${last-time} = ${current-time}
  ${current-time} = Get-Date
  Get-EventLog -LogName "Application" `
               -Source "${env:EVENT_LOG_SOURCE}" `
               -After ${last-time} `
               -Before ${current-time} `
               | select -ExpandProperty message

  # output iis logs
  Receive-Job -job ${log-job}

  # if health job is not running then kill the container
  if ((${health-job} | Where State -eq "Running").Count -eq 0) {
    Receive-Job -job ${health-job}
    Echo 'ServiceMonitor.exe has died, exiting'
    
    # only exit if debugging isn't enabled
    if ( ! [boolean]::Parse("${env:DEBUG}") ) {
      exit
    }
  }

  # pause between evaluations
  Start-Sleep -Seconds 15
}
