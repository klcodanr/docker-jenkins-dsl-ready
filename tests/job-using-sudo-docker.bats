#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-sudo-docker

load lib/test_helpers

@test "------ preparing $(basename $BATS_TEST_FILENAME .bats) ------" {
    docker_clean $SUT_CONTAINER
}

@test "SUT container with 'sudo docker' capabilities created" {
    docker run -d --name $SUT_CONTAINER \
        -v $BATS_TEST_DIRNAME/resources/dsl-job-using-sudo-docker/:/usr/share/jenkins/ref/jobs/SeedJob/workspace/:ro \
        -P \
        -v /var/run/docker.sock:/var/run/docker.sock \
        $DOCKER_OPTS_ENABLING_DOCKER \
        $SUT_IMAGE
}

################################################################################

@test "Jenkins is initialized" {
    retry 30 5 jenkins_url /
}

@test "job SeedJob exists" {
    retry 5 2 jenkins_url /job/SeedJob/
}

@test "job SeedJob build #1 created" {
    retry 5 2 jenkins_url /job/SeedJob/1/
}

@test "job SeedJob last build suceeded" {
    jenkins_job_success SeedJob || {
        echo -e "\n\n---------------------------------------------------------"
        curl --silent --fail $(get_jenkins_url)/job/SeedJob/lastBuild/consoleText
        echo -e "---------------------------------------------------------\n\n"
        false
    }
}

################################################################################

@test "job test-sudo-docker created" {
    retry 5 2 jenkins_url /job/test-sudo-docker/
}

@test "build job test-sudo-docker" {
    jenkins_build_job test-sudo-docker
}

@test "job test-sudo-docker suceeded" {
    jenkins_job_success test-sudo-docker || {
        echo -e "\n\n---------------------------------------------------------"
        curl --silent --fail $(get_jenkins_url)/job/test-sudo-docker/lastBuild/consoleText
        echo -e "---------------------------------------------------------\n\n"
        false
    }
}
