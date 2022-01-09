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
        stage('clone git repo') {
            REPO1="https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git"
            REPO2="git@gitlab.freedesktop.org:NetworkManager/NetworkManager-ci.git"
            REPO3="https://github.com/NetworkManager/NetworkManager-ci.git"
            sh "python3 -m pip install --user python-gitlab pyyaml==5.4.1"
            sh "timeout 2m git clone -n ${REPO1} || timeout 2m git clone -n ${REPO2} || timeout 2m git clone -n ${REPO3}"
            if (MERGE_REQUEST_ID) {
                sh "cd NetworkManager-ci; git fetch origin merge-requests/${MERGE_REQUEST_ID}/head:${TEST_BRANCH}"
            }
            sh "cd NetworkManager-ci; git checkout ${TEST_BRANCH}"
        }
        stage('run tests on cico nodes') {
            run = "python3 run/centos-ci/node_runner.py -t ${TEST_BRANCH} -c ${REFSPEC} -f ${FEATURES} -b ${env.BUILD_URL} -g ${GL_TOKEN} -v {RELEASE}"
            if (TRIGGER_DATA) {
                TD = TRIGGER_DATA.bytes.encodeBase64().toString()
                run += " -d ${TD}"
            }
            sh """
              set +x
              cd NetworkManager-ci
              ${run}
              for file in results_*/runtest.out; do
                  machine=\${file%/*}
                  machine=\${machine#_*}
                  echo 'Test Output for machine #'\$machine:
                  cat \$file
              done
            """
        }
    }
    finally {
        try {
            stage('publish results') {
                if (!fileExists('RESULT.txt')) {
                    // Compilation failed there is config.log
                    if (!fileExists('config.log')) {
                        println("Pipeline canceled! We do have no RESULT.txt or config.log")
                        sh "cd NetworkManager-ci; python3 run/centos-ci/pipeline_cancel.py ${env.BUILD_URL} ${GL_TOKEN} ${TD}"
                    }
                }
                archiveArtifacts '*.*'
                junit 'junit.xml'
            }
            stage('reserve') {
                if (RESERVE != "0s") {
                    println("You can log in via ssh:")
                    // output just first and second column (delimiter is :)
                    sh "sed 's%:% root@%;s%:.*%%' machines"
                }
                sh 'sleep ${RESERVE}'
            }
        }
        finally {
            stage('return cico nodes') {
                sh "python3 NetworkManager-ci/run/centos-ci/return_nodes.py"
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
