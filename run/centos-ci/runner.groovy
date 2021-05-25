node('cico-workspace') {
    try {
        stage ('set env') {
            if (params['VERSION']) {
                currentBuild.displayName = "${VERSION}"
            }
            if (!params['TRIGGER_DATA']) {
                TRIGGER_DATA = ""
            }
            if (!params['REFSPEC']) {
                REFSPEC = "main"
            }
            if (!params['TEST_BRANCH']) {
                TEST_BRANCH = "master"
            }
            if (!params['FEATURES']) {
                FEATURES = "all"
            }
            if (!params['RESERVE']) {
                RESERVE = "0s"
            }
            // Cancel older builds
            script {
                println("Killing old jobs if running")
                killJobs (currentBuild)
            }
        }
        stage('get cico node') {
            node = sh(script: "cico --debug node get -f value -c hostname -c comment --release ${RELEASE}", returnStdout: true).trim().tokenize(' ')
            env.node_hostname = "${node[0]}.ci.centos.org"
            env.node_ssid = "${node[1]}"
        }

        stage('run tests') {
            println("Prepare env")
            // Use byte64 to push the data to avoid encoding issues
            TD = TRIGGER_DATA.bytes.encodeBase64().toString()
            println("Preparing commands")
            install = "yum install -y git python3 wget"
            install2 = "python3 -m pip install python-gitlab pyyaml"
            clone = "git clone https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git; cd NetworkManager-ci; git checkout  ${TEST_BRANCH}"
            run = "cd NetworkManager-ci; python3 run/centos-ci/node_runner.py ${TEST_BRANCH} ${REFSPEC} ${FEATURES} ${env.BUILD_URL} ${GL_TOKEN} ${TD}"
            println("Running install")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${install}'"
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${install2}'"
            println("Running clone")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${clone}'"
            println("Running tests")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${run}'"
        }
    }
    finally {
        try {
            stage('publish results') {
                sh "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname}:/tmp/results/* ."
                // Check if we have RESULT so whole pipeline was not canceled
                sh 'sleep 10'
                if (!new File('RESULT.txt').exists()) {
                    println("I assume we have been ABORTED as there is no RESULT.TXT")
                    sh "ls"
                    // Compilation failed there is config.log
                    if (!new File('config.log').exists()) {
                        println("Pipeline canceled!")
                        cancel = "cd NetworkManager-ci; python3 run/centos-ci/pipeline_cancel.py ${env.BUILD_URL} ${GL_TOKEN} ${TD}"
                        sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${cancel}'"
                    }
                }
                archiveArtifacts '*.*'
                junit 'junit.xml'
            }
            stage('reserve') {
                if (RESERVE != "0s") {
                    println("You can log in via:")
                    println("ssh root@${node_hostname}")
                }
                sh 'sleep ${RESERVE}'
            }
        }
        finally {
            stage('return cico node') {
                sh 'cico node done ${node_ssid} > commandResult'
            }
        }
    }
}

@NonCPS
def killJobs (currentBuild) {
    println("in KillJobs")
    println()
    def jobname = currentBuild.displayName
    def buildnum = currentBuild.number.toInteger()
    def job_name = currentBuild.rawBuild.parent.getFullName()
    def job = Jenkins.instance.getItemByFullName(job_name)
    for (build in job.builds) {
        if (!build.isBuilding()) { continue; }
        if (buildnum == build.getNumber().toInteger()) { continue; println "equals" }
        println(build.number)
        build.doStop();
    }
}
