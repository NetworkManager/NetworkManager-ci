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
