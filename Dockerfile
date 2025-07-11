FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-runtime
ARG DEBIAN_FRONTEND=noninteractive
ARG TEST_ENV

WORKDIR /app

RUN conda update conda -y

RUN --mount=type=cache,target="/var/cache/apt",sharing=locked \
    --mount=type=cache,target="/var/lib/apt/lists",sharing=locked \
    apt-get -y update \
    && apt-get install -y git \
    && apt-get install -y wget \
    && apt-get install -y curl \
    && apt-get install -y g++ freeglut3-dev build-essential libx11-dev \
    libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev libfreeimage-dev \
    && apt-get -y install ffmpeg libsm6 libxext6 libffi-dev python3-dev python3-pip gcc
    
    ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_CACHE_DIR=/.cache \
    PORT=9090 \
    WORKERS=2 \
    THREADS=4 \
    CUDA_HOME=/usr/local/cuda
    
    ENV CUDA_HOME=/opt/conda \
    TORCH_CUDA_ARCH_LIST="6.0;6.1;7.0;7.5;8.0;8.6+PTX;8.9;9.0"
    
# Instead of COPY, clone them in Dockerfile
RUN git clone https://github.com/HumanSignal/label-studio-sdk.git /label-studio-sdk
RUN git clone https://github.com/HumanSignal/label-studio-ml-backend.git /label-studio-ml-backend

# Install SDK first with compatible Pillow
RUN pip install --no-deps /label-studio-sdk && \
pip install "pillow==10.4.0"

# Then install ML backend without its deps
RUN pip install --no-deps /label-studio-ml-backend

# Manually install required deps
RUN pip install \
flask~=3.1 \
requests~=2.31 \
    colorama~=0.4 \
    semver~=3.0.2 \
    werkzeug>=3.1.0 \
    itsdangerous>=2.2.0 \
    blinker>=1.9.0 \
    pydantic \
    httpx \
    lxml \
    appdirs \
    xmljson \
    jsf \
    nltk \
    ijson
    
    # Copy your model/code
    COPY . /app
    
# install base requirements
COPY requirements-base.txt .
RUN --mount=type=cache,target=${PIP_CACHE_DIR},sharing=locked \
    pip install -r requirements-base.txt

# install model requirements
COPY requirements.txt .
RUN --mount=type=cache,target=${PIP_CACHE_DIR},sharing=locked \
    pip3 install -r requirements.txt

# install test requirements if needed
COPY requirements-test.txt .
# build only when TEST_ENV="true"
RUN TEST_ENV=false
RUN --mount=type=cache,target=${PIP_CACHE_DIR},sharing=locked \
    if [ "$TEST_ENV" = "true" ]; then \
      pip3 install -r requirements-test.txt; \
    fi

WORKDIR /app

COPY . ./

# Install system dependencies
RUN apt-get update && \
apt-get install -y --no-install-recommends \
libgl1 libglib2.0-0 && \
rm -rf /var/lib/apt/lists/*

RUN pip install python-dotenv

EXPOSE 9090

CMD ["label-studio-ml", "start", ".", "--host", "0.0.0.0", "--port", "9090"]