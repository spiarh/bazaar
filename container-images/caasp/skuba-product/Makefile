PODMAN_OPTIONS	:= 
PODMAN_BUILD	:= podman build $(PODMAN_OPTIONS) -t
GO_VERSION		?= 1.14
BRANCH			?= master
CURATED_BRANCH	:= $(shell echo $(BRANCH) | sed -E 's/\+//g')

rpm-devel:
	./build.sh devel http://download.suse.de/ibs/Devel:/CaaSP:/4.0/SLE_15_SP1/

.PHONY: staging
rpm-staging:
	./build.sh staging http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40/staging/

rpm-product:
	./build.sh product http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40/standard/

rpm-update:
	./build.sh update http://download.suse.de/ibs/SUSE:/SLE-15-SP1:/Update:/Products:/CASP40:/Update/standard/

rpm-version:
	./build.sh ${VERSION} ${REPO}o

git-branch:
	$(PODMAN_BUILD) skuba:git-devel-branch-${CURATED_BRANCH} --build-arg GO_VERSION=${GO_VERSION} --build-arg BRANCH=${BRANCH} --file DockerfileGitBranch .

git-pr:
	$(PODMAN_BUILD) skuba:git-devel-pr${PR_ID}-${PR_NAME} --build-arg GO_VERSION=${GO_VERSION} --build-arg PR_ID=${PR_ID} --build-arg PR_NAME=${PR_NAME} --file DockerfileGitPr .

#go-master:
#	$(PODMAN_BUILD) skuba:go-master-latest --build-arg ${GO_VERSION} --build-arg GIT_BRANCH=${GIT_BRANCH} --file DockerfileGo .

#GIT_BRANCH=release-caasp-4.0-gmc

#  podman build --no-cache -t "$IMAGE_NAME" \
#       --build-arg VERSION="$VERSION" \
#       --build-arg REPO_ENV="$REPO_ENV" \
#       --build-arg REPO="$REPO"
#       --file DockerfileRpm .
