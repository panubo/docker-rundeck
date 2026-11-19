# Load bats libraries

# See https://github.com/bats-core/homebrew-bats-core for Homebrew install

# This list of PATHs should cover Linux, Mac and GitHub Actions
BATS_LIB_PATH="${BATS_LIB_PATH:-${HOME}/.bats/libs:/opt/homebrew/lib:/usr/local/bats:/usr/local:/usr/lib/bats:/usr/lib}"
export BATS_LIB_PATH
bats_load_library bats-support
bats_load_library bats-assert
bats_load_library bats-file

# Image under test. The CI workflow builds panubo/rundeck:test before running
# the tests. Override IMAGE to test a locally built image.
IMAGE="${IMAGE:-panubo/rundeck:test}"
export IMAGE
