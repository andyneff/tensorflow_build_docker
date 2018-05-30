ARG CUDA_VERSION_2=9.0
FROM nvidia/cuda:${CUDA_VERSION_2}-cudnn7-devel-ubuntu16.04

SHELL ["/bin/bash", "-euxvc"]

RUN apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        software-properties-common ; \
    add-apt-repository -y ppa:openjdk-r/ppa ; \
    apt-get update ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openjdk-8-jdk openjdk-8-jre-headless apt-transport-https wget unzip \
        python3-numpy python3-dev python3-pip python3-wheel python3-setuptools git; \
    # Cleanup
    rm -r /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

ARG BAZEL_VERSION=0.13.1

# Running bazel inside a `docker build` command causes trouble, cf:
#   https://github.com/bazelbuild/bazel/issues/134
# The easiest solution is to set up a bazelrc file forcing --batch.
# Similarly, we need to workaround sandboxing issues:
#   https://github.com/bazelbuild/bazel/issues/418
RUN echo "startup --batch" >>/etc/bazel.bazelr; \
    echo "build --spawn_strategy=standalone --genrule_strategy=standalone" >> /etc/bazel.bazelrc; \
    mkdir /root/bazel ; \
    cd /root/bazel ; \
    wget -q https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh ; \
    chmod a+x bazel-*.sh ; \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh ; \
    rm -f bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

# Fix horrible deficiencies in the tensorflow build system
RUN ln -s /usr/bin/python3 /usr/bin/python; \
    ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/lib/libcuda.so.1

ENV TF_NEED_CUDA=1 TF_NEED_GCP=0 \
    TF_NEED_S3=0 TF_NEED_KAFKA=0 TF_NEED_GDR=0 \
    TF_NEED_VERBS=0 TF_NEED_OPENCL_SYCL=0 TF_NEED_TENSORRT=0 \
    TF_NCCL_VERSION=1.3 TF_CUDA_CLANG=0 \
    GCC_HOST_COMPILER_PATH=/usr/bin/gcc \
    TF_NEED_MPI=0 TF_SET_ANDROID_WORKSPACE=0 \
    TF_NEED_JEMALLOC=1 TF_NEED_HDFS=1 \
    TF_NEED_OPENCL=0 TF_ENABLE_XLA=0 \
    TF_CUDA_VERSION=${CUDA_VERSION_2} TF_CUDNN_VERSION=7 \
    TF_CUDA_COMPUTE_CAPABILITIES=5.2 \
    CUDA_PATH="/usr/local/cuda" \
    CUDA_TOOLKIT_PATH="/usr/local/cuda" \
    CUDNN_INSTALL_PATH="/usr/local/cuda" \
    PYTHON_BIN_PATH=/usr/bin/python3 \
    PYTHON_LIB_PATH=/usr/lib/python3/dist-packages \
    CI_BUILD_PYTHON=/usr/bin/python3 \
    CC_OPT_FLAGS="-march=native" \
    TENSORFLOW_HOME=/root/tensorflow \
    LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64/stubs \
    TENSORFLOW_VERSION=v1.8.0

ARG CUDNN_VERSION_2=7.0.5.15

RUN apt-get update; \
    apt-get install -y --no-install-recommends --allow-downgrades \
            libcudnn7-dev=${CUDNN_VERSION_2}-1+cuda${CUDA_VERSION_2} \
            libcudnn7=${CUDNN_VERSION_2}-1+cuda${CUDA_VERSION_2}; \
    rm -rf /var/lib/apt/lists/*

CMD if [ ! -d /tmp/wheel ]; then echo "Please docker mount in wheel output dir to /tmp/wheel"; exit 1; fi; \
    git clone -b ${TENSORFLOW_VERSION} https://github.com/tensorflow/tensorflow.git /src; \
    cd /src; \
    ./configure; \
    bazel build --verbose_failures --config=opt --config=cuda //tensorflow/tools/pip_package:build_pip_package; \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/wheel