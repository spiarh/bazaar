# Jenkins server

```console
docker build -t jenkins-with-plugins .
```

```console
docker run -d -v jenkins_home:/jenkins -p 8080:8080 jenkins-with-plugins:stable
```

## Secrets

Create the following secrets:

```
./secrets/hyperv-user
./secrets/hyperv-password
./secrets/openstack-openrc
./secrets/jenkins-user
./secrets/jenkins-password
./secrets/vmware-user
./secrets/vmware-password
./secrets/jenkins-ssh-private-key
```

## Plugins

| Plugin Name | Description |
|-------------|-------------|
|builld-timeout         | This plugin allows you to automatically abort a build if it's taking too long.Once the timeout is reached, Jenkins behaves as if an invisible hand has clicked the "abort build" button. |
|configuration-as-code  | Configuration as Code plugin has been designed as an  opinionated  way to configure jenkins based on human-readable declarative configuration files. |
|cloudbees-folder       | This plugin allows users to create "folders" to organize jobs. |
|email-ext              | This plugin allows you to configure every aspect of email notifications. You can customize when an email is sent, who should receive it, and what the email says. |
|credentials-binding    | Allows credentials to be bound to environment variables for use from miscellaneous build steps. |
|docker-build-step      | This plugin allows to add various Docker commands into your job as a build step. |
|docker-plugin          | This plugin allows slaves to be dynamically provisioned using Docker. |
|plain-credentials      | Allows use of plain strings and files as credentials. |
|git                    | This plugin integrates Git with Jenkins. |
|github-branch-source   | Multibranch projects and organization folders from GitHub. Maintained by CloudBees, Inc. |
|greenballs             | Changes Hudson to use green balls instead of blue for successful builds. |
|jclouds-jenkins        | This plugin uses JClouds to provide slave launching on most of the currently usable Cloud infrastructures. |
|jdk-tool               | Provides an installer for the JDK tool that downloads the JDK from Oracle's website. |
|junit                  | Allows JUnit-format test results to be published. |
|ldap                   | Adds LDAP authentication to Jenkins. |
|matrix-auth            | Offers matrix-based security authorization strategies (global and per-project). |
|pam-auth               | Adds Unix Pluggable Authentication Module (PAM) support to Jenkins. |
|pipeline-stage-view    | Pipeline Stage View Plugin. |
|pipeline-utility-steps | Small, miscellaneous, cross platform utility steps for Pipeline Plugin jobs |
|ssh-slaves             | Allows to launch agents over SSH, using a Java implementation of the SSH protocol. |
|timestamper            | Adds timestamps to the Console Output. |
|workflow-aggregator    | A suite of plugins that lets you orchestrate automation, simple or complex. |
|ws-cleanup             | This plugin deletes the project workspace when invoked. |



docker-18.06.1-r0 x86_64 {docker} (Apache-2.0) [installed]

