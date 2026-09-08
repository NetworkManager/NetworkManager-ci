node('cico-workspace') {
    // bind the gitlab token credential; scripts read both env names
    withCredentials([string(credentialsId: 'GL_TOKEN', variable: 'GL_TOKEN'),
                     string(credentialsId: 'GL_TOKEN', variable: 'GITLAB_TOKEN')]) {
        def TRIGGER_DATA = params['TRIGGER_DATA'] ?: ""
        def TD = TRIGGER_DATA ? TRIGGER_DATA.bytes.encodeBase64().toString() : ""
        def MERGE_REQUEST_ID = params['MERGE_REQUEST_ID'] ?: ""
        def REFSPEC = params['REFSPEC'] ?: "main"
        def TEST_BRANCH = params['TEST_BRANCH'] ?: "main"
        def FEATURES = params['FEATURES'] ?: "all"
        def RESERVE = params['RESERVE'] ?: "0s"
        try {
            stage ('set env') {
                currentBuild.description = '<a href="' + env.BUILD_URL + '/execution/node/3/ws/">Live Artifacts</a>'
                if (params['VERSION']) {
                    currentBuild.displayName = "${VERSION}"
                }
                stage ('Kill old jobs'){
                    def jobname = currentBuild.displayName
                    def buildnum = currentBuild.number.toInteger()
                    def job_name = currentBuild.rawBuild.parent.getFullName()
                    def job = Jenkins.instance.getItemByFullName(job_name)
                    for (build in job.builds) {
                        // skip stopped jobs
                        if (!build.isBuilding()) {
                            continue;
                        }
                        // this job
                        if (buildnum == build.getNumber().toInteger()) {
                            println ("Skip this job #" + build.number)
                            continue;
                        }
                        // do not kill different branches / releases
                        if (build.displayName == currentBuild.displayName) {
                            println("Kill job #" + build.number)
                            build.doStop();
                        }
                    }
                }
            }
            stage('clone git repo') {
                def REPO1 = "https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci.git"
                def REPO2 = "https://github.com/NetworkManager/NetworkManager-ci.git"
                def FETCH = MERGE_REQUEST_ID ?
                    "cd NetworkManager-ci && git fetch --update-head-ok origin merge-requests/${MERGE_REQUEST_ID}/head:${TEST_BRANCH}" :
                    "cd NetworkManager-ci && git fetch --update-head-ok origin ${TEST_BRANCH}:${TEST_BRANCH}"
                def CLONE = "rm -rf NetworkManager-ci; timeout 2m git clone -n --depth 1"
                def GET_REPO = "(${CLONE} ${REPO1} && ${FETCH}) || (${CLONE} ${REPO2} && ${FETCH})"
                sh "python3 -m pip install --user python-gitlab pyyaml==5.4.1"
                sh "${GET_REPO} || (sleep 10; ${GET_REPO}) || (sleep 10; ${GET_REPO})"
                sh "cd NetworkManager-ci; git checkout ${TEST_BRANCH}"
            }
            stage('run tests on cico nodes') {
                def run = "python3 run/centos-ci/node_runner.py -t ${TEST_BRANCH} -c ${REFSPEC} -f '${FEATURES}' -b ${env.BUILD_URL} -v ${RELEASE} -d '${TD}'"
                sh """
                  set +x
                  cd NetworkManager-ci
                  ${run}
                """
            }
        }
        finally {
            try {
                stage('publish results') {
                    if (!fileExists('junit.xml')) {
                        // Compilation failed there is config.log
                        if (!fileExists('config.log')) {
                            // skip if aborted before clone; nothing reserved, no repo to run from
                            if (fileExists('NetworkManager-ci')) {
                                println("Pipeline canceled (or crashed)! We do have no junit.xml or config.log")
                                sh """
                                    set +x
                                    cd NetworkManager-ci; python3 run/centos-ci/pipeline_cancel.py ${env.BUILD_URL} '${TD}' ${RELEASE}
                                """
                            }
                        }
                    }
                    archiveArtifacts '*.*'
                    if (params['TMT_ARTIFACTS'] == true) {
                        archiveArtifacts artifacts: 'tmt_m*/**', allowEmptyArchive: 'true'
                    }
                    archiveArtifacts artifacts: 'rpms/*.rpm', allowEmptyArchive: 'true'
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
                    currentBuild.description = ""
                    if (fileExists('NetworkManager-ci')) {
                        sh "python3 NetworkManager-ci/run/centos-ci/return_nodes.py"
                    }
                }
            }
        }
    }
}
