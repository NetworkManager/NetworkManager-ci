node('cico-workspace') {
    try {
        stage('get cico node') {
            node = sh(script: "cico --debug node get -f value -c hostname -c comment --release ${RELEASE}", returnStdout: true).trim().tokenize(' ')
            env.node_hostname = "${node[0]}.ci.centos.org"
            env.node_ssid = "${node[1]}"
        }

        stage('run tests') {
            println("Running tests")
            install = "yum install -y git python3"
            clone = "git clone https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git -b ${TEST_BRANCH}"
            run = "cd NetworkManager-ci; python3 run/centos-ci/node_runner.py ${TEST_BRANCH} ${CODE_BRANCH} ${FEATURES}"
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${install}'"
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${clone}'"
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname} '${run}'"
        }
    }
    finally {
        try {
            stage('publish results') {
                sh "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node_hostname}:/tmp/results/* ."
                archiveArtifacts '*.html'
                junit 'junit.xml'
            }
        }
        finally {
            stage('return cico node') {
                sh 'cico node done ${node_ssid} > commandResult'
            }
        }
    }
}
