#!/usr/bin/bash
# Build container image for running Ansible on ppc64le
# Default build tool is docker; to use podman, run "export EYE_CONTAINER_RUNTIME=podman" before running this script (untested!)

# config
dryrun=0
debug=0
verbose=1
image="ansible-runtime"
ver="1.0.3"
runtime="${EYE_CONTAINER_RUNTIME:-docker}"

# Do we have jq installed?
jq=$(which jq 2>/dev/null)

# To get arch for use in tag, run one of:
#   Podman 1.8: podman version --format '{{.Client.OsArch}}'|cut -d/ -f2
#   Podman 1.6 (RHEL 7.6; also works for podman 3.0): podman version --format '{{.OsArch}}'|cut -d/ -f2
#   Docker: docker version --format '{{.Client.Arch}}'
if [ "${runtime}" = "podman" ]
then
	arch="$(podman version --format '{{.OsArch}}'|cut -d/ -f2)"
else
	arch="$(docker version --format '{{.Client.Arch}}')"
fi
colarch=$(uname -p)

# init
cd $(dirname $0)
srcdir=$PWD
cd ../../
basedir=$PWD
umask 022
savesubdir=saved-images
savedir=$basedir/$savesubdir

# Backblaze
CONFDIR=$basedir/.b2conf
test -e $CONFDIR || mkdir -p $CONFDIR
b2cmd="${runtime} run --rm -u $(id -u) -v $CONFDIR:/home/b2 -v $PWD:/data -w /data cliffordw/backblaze-b2"
# check whether we're logged in
$b2cmd get-account-info
if [ $? -ne 0 ]
then
    if [ -z "$B2ID" -o -z "$B2KEY" ]
    then
        echo "Error: can't log in to BackBlaze - please set \$B2ID & \$B2KEY and rerun"
        exit
    else
        $b2cmd authorize-account "$B2ID" "$B2KEY"
    fi
fi

cd $srcdir
${runtime} build -t ${image}:${ver}-${arch} -f Containerfile .
cd $savedir/containers/${arch}
${runtime} save ${image}:${ver}-${arch} | gzip -9 > ${image}_${ver}-${arch}.tgz
sha256sum ${image}_${ver}-${arch}.tgz > ${image}_${ver}-${arch}.tgz.sha256sum
if [ -z "$jq" ]
then
	touch -r ${image}_${ver}-${arch}.tgz ${image}_${ver}-${arch}.tgz.sha256sum
else
	time=$(${runtime} inspect ${image}:${ver}-${arch} | $jq -r '.[] | .Created')
	touch -d $time ${image}_${ver}-${arch}.tgz ${image}_${ver}-${arch}.tgz.sha256sum
fi  

cd $basedir
$b2cmd sync --noProgress ${savesubdir}/containers/${arch} b2://eye-containers/containers/${arch}/
