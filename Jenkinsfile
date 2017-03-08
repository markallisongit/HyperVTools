#!groovy​
node {
    try {
        notifyBuild('STARTED')
        echo "BUILD_URL=${env.BUILD_URL}"
        echo "ConfigFilePath: ${ConfigFilePath}"
        echo "Delete VM on Successful Build: ${DeleteOnSuccess}"
        
        stage('checkout') {
            // deleteDir()
            checkout scm
        }

        stage('deploy') {
            gitlabCommitStatus("deploy") {
                timeout(time: 30, unit: 'MINUTES') {
                    bat 'powershell Import-Module .\\HyperVTools.psd1; New-HyperVVM -ConfigFilePath \'%ConfigFilePath%\' -Verbose'                
                    load 'DeleteVM.txt' // loads into environment variables
                    echo "VM host: ${VM_HOST}"
                    echo "VM name: ${VM_NAME}"
                }
            }
        }
    }
    catch (e) {
    // If there was an exception thrown, the build failed
    currentBuild.result = "FAILED"
    throw e
  } finally {
    // Success or failure, always send notifications
    notifyBuild(currentBuild.result)
  }
}

// runs on a flyweight executor
stage('delete') {
    if(DeleteOnSuccess=="true") // looks like a bool, but isn't - it's a string
    {
        def job = build job: 'remove-vm', parameters: [[$class: 'StringParameterValue', name: 'VM_NAME', value: "${VM_NAME}"]]
    }
}   

def notifyBuild(String buildStatus = 'STARTED') {
  // build status of null means successful
  buildStatus =  buildStatus ?: 'SUCCESSFUL'

  // Default values
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESSFUL') {
    color = 'GREEN'
    colorCode = '#00FF00'
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  }

  // Send notifications
  slackSend (color: colorCode, message: summary)
}