// for source of truth, see: https://github.com/jjno91/jenkinsfiles/blob/master/docker-windows.Jenkinsfile

pipeline {

  // I don't have Windows on Kubernetes figured out yet, so you will need a preconfigured Windows agent
  agent { label 'windows' }

  options {
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  environment {
    REGISTRY = "YOUR_REGISTRY"
  }

  stages {
    stage('Code Build') {
      steps {
        // you should have an msbuild command to build your application code here
        // powershell 'msbuild'
      }
    }
    stage('Docker Build') {
      steps {
        powershell 'docker build -t ${env:REGISTRY}:latest .'
      }
    }
    stage('Tag') {
      steps {
        powershell 'docker tag ${env:REGISTRY}:latest ${env:REGISTRY}:$(git rev-parse --short HEAD)'
        powershell 'echo "New Image: $(git rev-parse --short HEAD)'
      }
    }
    stage('Push') {
      steps {
        powershell 'docker push ${env:REGISTRY}:latest'
        powershell 'docker push ${env:REGISTRY}:$(git rev-parse --short HEAD)'
      }
    }

    // this stage goes away once this is running on Kubernetes
    stage('Image Cleanup') {
      steps {
        powershell 'docker rmi ${env:REGISTRY}:latest'
        powershell 'docker rmi ${env:REGISTRY}:$(git rev-parse --short HEAD)'
      }
    }
  }
}
