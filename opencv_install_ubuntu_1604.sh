#!/usr/bin/env bash
set -o errexit

function run () {
sudo apt install -y libjpeg8-dev libtiff5-dev libjasper-dev libpng12-dev libhdf5-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev \
    libx264-dev libgtk-3-dev libatlas-base-dev gfortran \
    build-essential cmake pkg-config libeigen3-dev libtbb-dev libtbb2 \
    make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils


# step 2. install pyenv
echo 'export PATH="~/.pyenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
source ~/.bashrc
curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

# step 2. set up pyenv
if ! type "pyenv" > /dev/null; then
  echo "error: pyenv not installed properly"
  echo "info: install pyenv"
  exit 1
fi

pyenv update
PYTHON_CONFIGURE_OPTS="--enable-shared" CFLAGS="-O2" pyenv install 3.6.0
pyenv global 3.6.0

if [[ `python --version` != "Python 3.6.0" ]]; then
  echo "error: python installation failure"
  echo "info: check if pyenv is installed correctly"
  exit 1
fi

if [[ `which python` != "${HOME}/.pyenv/shims/python" ]]; then
  echo "error: failed to detect pyenv python"
  echo "info: check if pyenv is installed correctly"
  exit 1
fi

# step 3. install numpy
pip install -U pip setuptools wheel cython numpy

# step 4. setup /opt
sudo mkdir -p /opt/src
sudo chown $(whoami) /opt
sudo chown $(whoami) /opt/src
cd /opt/src

# step 6. build opencv
cd /opt/src
curl -L https://github.com/opencv/opencv/archive/3.2.0.zip -o opencv32.zip
curl -L https://github.com/opencv/opencv_contrib/archive/3.2.0.zip -o opencv32contrib.zip
unzip opencv32.zip
unzip opencv32contrib.zip
mv -v opencv-3.2.0 /opt/src/opencv32_py36
mv -v opencv_contrib-3.2.0 /opt/src/opencv32_py36_contrib
cd /opt/src/opencv32_py36
mkdir /opt/src/opencv32_py36/release
cd /opt/src/opencv32_py36/release
cmake \
    -D CMAKE_INSTALL_PREFIX=/opt/opencv32_py36 \
    -D OPENCV_EXTRA_MODULES_PATH=/opt/src/opencv32_py36_contrib/modules \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D BUILD_TIFF=ON \
    -D BUILD_opencv_java=OFF \
    -D WITH_CUDA=OFF \
    -D ENABLE_AVX=ON \
    -D WITH_OPENGL=ON \
    -D WITH_OPENCL=ON \
    -D WITH_IPP=OFF \
    -D WITH_TBB=ON \
    -D WITH_EIGEN=ON \
    -D WITH_V4L=ON \
    -D WITH_VTK=OFF \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D PYTHON3_LIBRARY=$(python -c "import re, os.path; print(os.path.normpath(os.path.join(os.path.dirname(re.__file__), '..', 'libpython3.6m.so')))") \
    -D PYTHON3_EXECUTABLE=$(which python) \
    -D PYTHON3_INCLUDE_DIRS=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -D PYTHON3_PACKAGES_PATH=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") ..
    make -j8
    cd /opt/src/opencv32_py36/release
    make install
    pyenv virtualenv 3.6.0 main
    pyenv global main
    pip install -U pip setuptools wheel numpy  # important to install in every new virtual environment where we symlink opencv
    ln -s "$HOME/.pyenv/versions/3.6.0/lib/python3.6/site-packages/cv2.cpython-36m-x86_64-linux-gnu.so" \
        "$HOME/.pyenv/versions/main/lib/python3.6/site-packages/cv2.cpython-36m-x86_64-linux-gnu.so"
}
run
