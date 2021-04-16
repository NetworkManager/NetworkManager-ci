node('cico-workspace') {
    try {
        stage ('set env') {
            currentBuild.displayName = "${VERSION}"
            if (TRIGGER_DATA != null) {
                println("WE DO HAVE TRIGGER_DATA")
                println ("${TRIGGER_DATA}")
                println("WE DO HAVE TRIGGER_DATA")
            }
            else {
                println("NO TRIGGER_DATA")
                TRIGGER_DATA = ""
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
            //TD = TRIGGER_DATA
            println("Preparing commands")
            install = "yum install -y git python3"
            install2 = "python3 -m pip install python-gitlab"
            clone = "git clone https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git -b ${TEST_BRANCH}"
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
                archiveArtifacts '*.*'
                junit 'junit.xml'
            }
            stage('reserve') {
                println("You can log in via: ssh root@${node_hostname}")
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
