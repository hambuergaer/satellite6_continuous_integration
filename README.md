# satellite6_continuous_integration

Jenkins job scriptlet:
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /var/lib/jenkins/users/jenkins-git/.ssh/id_rsa jenkins-git@sat6.example.com /home/jenkins-git/jenkins-sat-puppet-sync.sh dev ${JOB_NAME##*/} $BUILD_NUMBER
