node('cico-workspace') {
    try {
        stage ('set env') {
            if (params['VERSION']) {
                currentBuild.displayName = "${VERSION}"
            }
            if (!params['TRIGGER_DATA']) {
                TRIGGER_DATA = ""
            }
            if (!params['MERGE_REQUEST_ID']) {
                MERGE_REQUEST_ID = ""
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
            env.node1_hostname = "${node[0]}.ci.centos.org"
            env.node1_ssid = "${node[1]}"
        }
        stage('get cico node') {
            node = sh(script: "cico --debug node get -f value -c hostname -c comment --release ${RELEASE}", returnStdout: true).trim().tokenize(' ')
            env.node2_hostname = "${node[0]}.ci.centos.org"
            env.node2_ssid = "${node[1]}"
        }

        stage('run tests') {
            println("Prepare env")
            // Use byte64 to push the data to avoid encoding issues
            TD = TRIGGER_DATA.bytes.encodeBase64().toString()
            println("Preparing commands")
            install = "yum install -y git python3 wget"
            install2 = "python3 -m pip install python-gitlab pyyaml"
            clone = "git clone https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git; cd NetworkManager-ci; "
            if (MERGE_REQUEST_ID) {
                clone += " git fetch origin merge-requests/${MERGE_REQUEST_ID}/head:${TEST_BRANCH} ;"
            }
            clone += " git checkout ${TEST_BRANCH}"
            run = "cd NetworkManager-ci; python3 run/centos-ci/node_runner.py -t ${TEST_BRANCH} -c ${REFSPEC} -f ${FEATURES} -b ${env.BUILD_URL} -g ${GL_TOKEN}"
            if (TRIGGER_DATA) {
                run += " -d ${TD}"
            }
            println("Running install on machine 1")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} '${install}'"
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} '${install2}'"
            println("Running install on machine 2")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node2_hostname} '${install}'"
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node2_hostname} '${install2}'"
            println("Running clone on machine 1")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} '${clone}'"
            println("Running clone on machine 2")
            sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node2_hostname} '${clone}'"
            println("Running tests")
            sh """
                set +x
                echo "Running tests on 2 machines, progress is visible in Workspaces: ${env.BUILD_URL}/ws"
                { ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} '${run} -m 1' ; } &> m1.stdout &
                { ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node2_hostname} '${run} -m 2' ; } &> m2.stdout &
                wait
                cat m1.stdout
                cat m2.stdout
            """
        }
    }
    finally {
        try {
            stage('publish results') {
                sh "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname}:/tmp/results/* ."
                sh 'sleep 10'
                sh "mv RESULT.txt RESULT.m1.txt || true"
                sh "mv journal.log.bz2 journal.log.m1.bz2 || true"
                sh "mv junit.xml junit.m1.xml || true"
                sh "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node2_hostname}:/tmp/results/* ."
                sh 'sleep 10'
                sh "mv RESULT.txt RESULT.m2.txt || true"
                sh "mv journal.log.bz2 journal.log.m2.bz2 || true"
                sh "mv junit.xml junit.m2.xml || true"
                // Check if we have RESULT so whole pipeline was not canceled
                if (!fileExists('RESULT.m1.txt') || !fileExists('RESULT.m2.txt')) {
                    // Compilation failed there is config.log
                    if (!fileExists('config.log')) {
                        println("Pipeline canceled! We do have no RESULT.txt or config.log")
                        cancel = "cd NetworkManager-ci; python3 run/centos-ci/pipeline_cancel.py ${env.BUILD_URL} ${GL_TOKEN} ${TD}"
                        sh """
                            set +x
                            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} '${cancel}'
                            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node2_hostname} '${cancel}'
                        """
                    }
                }
                println("Merge junit.xml")
                merge_junit = "cd NetworkManager-ci; python3 run/centos-ci/merge_junit.py /tmp/results/junit.m1.xml /tmp/results/junit.m2.xml"
                sh """
                  set +x
                  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no junit.m2.xml root@${node1_hostname}:/tmp/results/junit.m2.xml
                  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} 'mv /tmp/results/junit.xml /tmp/results/junit.m1.xml'
                  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname} '${merge_junit} > /tmp/results/junit.xml'
                  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${node1_hostname}:/tmp/results/junit.xml junit.xml
                  sleep 10
                """
                archiveArtifacts '*.*'
                junit 'junit.xml'
            }
            stage('reserve') {
                if (RESERVE != "0s") {
                    println("You can log in via:")
                    println("ssh root@${node1_hostname}")
                    println("ssh root@${node2_hostname}")
                }
                sh 'sleep ${RESERVE}'
            }
        }
        finally {
            stage('return cico node') {
                sh 'cico node done ${node1_ssid} > commandResult'
                sh 'cico node done ${node2_ssid} > commandResult'
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
        if (build.displayName == currentBuild.displayName) {
            println(build.number)
            build.doStop();
        }
    }
}
