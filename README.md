
Builds tensorflow wheel using CUDA and CUDNN for you

Based roughly on the tensorflow docker, but works.

## Usage

    docker build -t tf .
    docker run -it --rm -v `pwd`:/tmp/wheel tf

## Docker Args

- `CUDA_VERSION_2` - Version of CUDA, defaults to `9.0`
- `CUDNN_VERSION_2` - Version of CUDNN to use, defaults to `7.0.5.15`
- `BAZEL_VERSION` - Version of Bazel to use, defaults to `0.13.1`


## Docker ENV vars

- Many used in configure.py, not covered here
    - `TF_CUDA_COMPUTE_CAPABILITIES` - Defaults to `5.2`, you'll probably want
it to include whatever card capabilities you are using.
- `TENSORFLOW_VERSION` - tag/SHA/branch to checkout. Using branch name is not
recommended because the underlying SHA can change, but do whatever you want.
Defaults to `v1.8.0`
