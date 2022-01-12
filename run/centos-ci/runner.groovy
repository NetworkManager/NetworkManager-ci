node('cico-workspace') {
    try {
        stage ('set env') {
            if (params['VERSION']) {
                currentBuild.displayName = "${VERSION}"
            }
            if (!params['TRIGGER_DATA']) {
                TRIGGER_DATA = ""
                TD = ""
            }
            else {
                TD = TRIGGER_DATA.bytes.encodeBase64().toString()
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
            if (MERGE_REQUEST_ID) {
                FETCH = "cd NetworkManager-ci && git fetch origin merge-requests/${MERGE_REQUEST_ID}/head:${TEST_BRANCH}"
            }
            else {
                FETCH = "cd NetworkManager-ci && git fetch origin ${TEST_BRANCH}:${TEST_BRANCH}"
            }
            CLONE = "rm -rf NetworkManager-ci; timeout 2m git clone -n --depth 1"
            GET_REPO = "(${CLONE} ${REPO1} && ${FETCH}) || (${CLONE} ${REPO2} && ${FETCH}) || (${CLONE} ${REPO3} && ${FETCH})"
            sh "python3 -m pip install --user python-gitlab pyyaml==5.4.1"
            sh "${GET_REPO} || (sleep 10; ${GET_REPO}) || (sleep 10; ${GET_REPO})"
            sh "cd NetworkManager-ci; git checkout ${TEST_BRANCH}"
        }
        stage('run tests on cico nodes') {
            run = "python3 run/centos-ci/node_runner.py -t ${TEST_BRANCH} -c ${REFSPEC} -f '${FEATURES}' -b ${env.BUILD_URL} -g ${GL_TOKEN} -v ${RELEASE} -d '${TD}'"
            sh """
              set +x
              cd NetworkManager-ci
              (${run} ; echo \$? > exit_code ) || true
              for file in ../results_*/runtest.log; do
                  [ -f \$file ] || continue
                  machine=\${file%/*}
                  machine=\${machine#_*}
                  echo 'Test Output for machine #'\$machine:
                  cat \$file
              done
              exit \$(cat exit_code)
            """
        }
    }
    finally {
        try {
            stage('publish results') {
                if (!fileExists('junit.xml')) {
                    // Compilation failed there is config.log
                    if (!fileExists('build.log')) {
                        println("Pipeline canceled (or crashed)! We do have no junit.xml or build.log")
                        sh """
                            set +x
                            cd NetworkManager-ci; python3 run/centos-ci/pipeline_cancel.py ${env.BUILD_URL} ${GL_TOKEN} '${TD}'
                        """
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
