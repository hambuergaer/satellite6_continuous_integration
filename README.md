# satellite6_continuous_integration
## About this script
Script for deploying puppet modules built by Jenkins CI to Satellite 6

## Script usage
Simply deploy this script on the Satellite server and execute with correct parameters

### Configuration
Edit `properties` to change default script settings

### Flags
  `-v`
    Verbose output

### Required parameters
  `--org`                 
    Satellite 6 Organization


  `--env`                      
    Lifecycle Environment


  `--ccv`                   
    Composite Content View


  `--branch`
    Git branch to check out


  `--puppet-module-repo`
    Puppet Module Repository


  `--puppet-module-product`
    Puppet Module Product


  `--package-output-dir`
    Package output directory


  `--package-tmp-dir`
    Temporary checkout directory


  `--giturl`
    Git URL

### Optional parameters
  `--jenkins-job-name`         
    Jenkins job name

  `--jenkins-build-number`    
    Jenkins build number

  `--log`  
    Logfile

## Script example

```
jenkins-sat-puppet-sync.sh \
--org "My Organization" \
--env myenv \
--branch mybranch \
--ccv myccv \
--puppet-module-repo my-sat6-puppet-repo \
--package-output-dir=/git/my-sat6-puppet-repo \
--package-tmp-dir /tmp \
--giturl ssh://git@server/user/repo.git \
--jenkins-job-name my-jenkins-job \
--jenkins-buildnumber 42 \
--puppet-module-product my-puppet-product
```
