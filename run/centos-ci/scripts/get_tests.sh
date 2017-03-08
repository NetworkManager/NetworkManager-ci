# Exit immediately if compilation failed
if [ -e /tmp/nm_compilation_failed ]; then
    exit 1
fi

# Clone NM tests from git and swicth to branch
git clone https://github.com/NetworkManager/NetworkManager-ci.git
cd NetworkManager-ci

git checkout $@
