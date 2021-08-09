FROM ubuntu:20.04

USER root

### BASICS ###
# Technical Environment Variables
ENV TZ=Asia/Shanghai \
    SHELL="/bin/bash" \
    HOME="/root"  \
    # Nobteook server user: https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile#L33
    NB_USER="root" \
    USER_GID=0 \
    XDG_CACHE_HOME="/root/.cache/" \
    XDG_RUNTIME_DIR="/tmp" \
    DISPLAY=":1" \
    TERM="xterm" \
    DEBIAN_FRONTEND="noninteractive" \
    RESOURCES_PATH="/resources" \
    SSL_RESOURCES_PATH="/resources/ssl" \
    WORKSPACE_HOME="/workspace" \
    CLEAN_SH='clean-layer.sh > /dev/null'

WORKDIR $HOME



# Make folders && 设置时区
RUN \
    mkdir $RESOURCES_PATH && chmod a+rwx $RESOURCES_PATH && \
    mkdir $WORKSPACE_HOME && chmod a+rwx $WORKSPACE_HOME && \
    mkdir $SSL_RESOURCES_PATH && chmod a+rwx $SSL_RESOURCES_PATH

# Layer cleanup script
COPY resources/scripts/clean-layer.sh  /usr/bin/clean-layer.sh
COPY resources/scripts/fix-permissions.sh  /usr/bin/fix-permissions.sh

 # Make clean-layer and fix-permissions executable
 RUN \
    chmod a+rwx /usr/bin/clean-layer.sh && \
    chmod a+rwx /usr/bin/fix-permissions.sh

# Generate and Set locals && tz
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container#38553499
RUN \
    apt-get update > /dev/null && \
    apt-get install -y locales tzdata && \
    # install locales-all?
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    # 设置时区
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    echo "Asia/Shanghai" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # Cleanup
    ${CLEAN_SH}

ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en"

# Install basics
RUN \
    # TODO add repos?
    # add-apt-repository ppa:apt-fast/stable
    # add-apt-repository 'deb http://security.ubuntu.com/ubuntu xenial-security main'
    apt-get update --fix-missing  > /dev/null && \
    apt-get install -y sudo apt-utils && \
    apt-get upgrade -y && \
    apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
        # This is necessary for apt to access HTTPS sources:
        apt-transport-https \
        gnupg-agent \
        gpg-agent \
        gnupg2 \
        ca-certificates \
        build-essential \
        pkg-config \
        software-properties-common \
        lsof \
        net-tools \
        libcurl4 \
        curl \
        wget \
        cron \
        openssl \
        iproute2 \
        psmisc \
        tmux \
        dpkg-sig \
        uuid-dev \
        csh \
        xclip \
        clinfo \
        time \
        libssl-dev \
        libgdbm-dev \
        libncurses5-dev \
        libncursesw5-dev \
        # required by pyenv
        libreadline-dev \
        libedit-dev \
        xz-utils \
        gawk \
        # Simplified Wrapper and Interface Generator (5.8MB) - required by lots of py-libs
        swig \
        # Graphviz (graph visualization software) (4MB)
        graphviz libgraphviz-dev \
        # Terminal multiplexer
        screen \
        # Editor
        nano \
        # Find files
        locate \
        # Dev Tools
        sqlite3 \
        # XML Utils
        xmlstarlet \
        # GNU parallel
        parallel \
        #  R*-tree implementation - Required for earthpy, geoviews (3MB)
        libspatialindex-dev \
        # Search text and binary files
        yara \
        # Minimalistic C client for Redis
        libhiredis-dev \
        # postgresql client
        libpq-dev \
        # mysql client (10MB)
        libmysqlclient-dev \
        # mariadb client (7MB)
        # libmariadbclient-dev \
        # image processing library (6MB), required for tesseract
        libleptonica-dev \
        # GEOS library (3MB)
        libgeos-dev \
        # style sheet preprocessor
        less \
        # Print dir tree
        tree \
        # Bash autocompletion functionality
        bash-completion \
        # ping support
        iputils-ping \
        # Map remote ports to localhosM
        socat \
        # Json Processor
        jq \
        rsync \
        # sqlite3 driver - required for pyenv
        libsqlite3-dev \
        # VCS:
        git \
        subversion \
        jed \
        # odbc drivers
        unixodbc unixodbc-dev \
        # Image support
        libtiff-dev \
        libjpeg-dev \
        libpng-dev \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxext-dev \
        libxrender1 \
        libzmq3-dev \
        # protobuffer support
        protobuf-compiler \
        libprotobuf-dev \
        libprotoc-dev \
        autoconf \
        automake \
        libtool \
        cmake  \
        fonts-liberation \
        google-perftools \
        # Compression Libs
        # also install rar/unrar? but both are propriatory or unar (40MB)
        zip \
        gzip \
        unzip \
        bzip2 \
        lzop \
	    # deprecates bsdtar (https://ubuntu.pkgs.org/20.04/ubuntu-universe-i386/libarchive-tools_3.4.0-2ubuntu1_i386.deb.html)
        libarchive-tools \
        zlibc \
        # unpack (almost) everything with one command
        unp \
        libbz2-dev \
        liblzma-dev \
        zlib1g-dev && \
    # Update git to newest version
    add-apt-repository -y ppa:git-core/ppa  && \
    apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends git && \
    # Fix all execution permissions
    chmod -R a+rwx /usr/local/bin/ && \
    # configure dynamic linker run-time bindings
    ldconfig && \
    # Fix permissions
    fix-permissions.sh $HOME && \
    # Add tini
    wget --no-verbose https://github.com/krallin/tini/releases/download/v0.19.0/tini -O /tini && \
    chmod +x /tini && \
    # Cleanup
    ${CLEAN_SH}

# prepare ssh for inter-container communication for remote python kernel
RUN \
    apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
        openssh-client \
        openssh-server \
        # SSLH for SSH + HTTP(s) Multiplexing
        sslh \
        # SSH Tooling
        autossh \
        mussh && \
    chmod go-w $HOME && \
    mkdir -p $HOME/.ssh/ && \
    # create empty config file if not exists
    touch $HOME/.ssh/config  && \
    sudo chown -R $NB_USER:users $HOME/.ssh && \
    chmod 700 $HOME/.ssh && \
    printenv >> $HOME/.ssh/environment && \
    chmod -R a+rwx /usr/local/bin/ && \
    # Fix permissions
    fix-permissions.sh $HOME && \
    # Cleanup
    ${CLEAN_SH}

### END BASICS ###

### RUNTIMES ###
# Install Miniconda: https://repo.continuum.io/miniconda/

ENV \
    # TODO: CONDA_DIR is deprecated and should be removed in the future
    CONDA_DIR=/opt/conda \
    CONDA_ROOT=/opt/conda \
    PYTHON_VERSION="3.8.10" \
    CONDA_PYTHON_DIR=/opt/conda/lib/python3.8 \
    MINICONDA_VERSION=4.9.2 \
    MINICONDA_MD5=122c8c9beb51e124ab32a0fa6426c656 \
    CONDA_VERSION=4.9.2

RUN wget --no-verbose https://repo.anaconda.com/miniconda/Miniconda3-py38_${CONDA_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh && \
    echo "${MINICONDA_MD5} *miniconda.sh" | md5sum -c - && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_ROOT && \
    export PATH=$CONDA_ROOT/bin:$PATH && \
    rm ~/miniconda.sh && \
    # Configure conda
    # TODO: Add conde-forge as main channel -> remove if testted
    # TODO, use condarc file
    $CONDA_ROOT/bin/conda config --system --add channels conda-forge && \
    $CONDA_ROOT/bin/conda config --system --set auto_update_conda False && \
    $CONDA_ROOT/bin/conda config --system --set show_channel_urls True && \
    $CONDA_ROOT/bin/conda config --system --set channel_priority strict && \
    # Deactivate pip interoperability (currently default), otherwise conda tries to uninstall pip packages
    $CONDA_ROOT/bin/conda config --system --set pip_interop_enabled false && \
    # Update conda
    $CONDA_ROOT/bin/conda update -y -n base -c defaults conda > /dev/null && \
    $CONDA_ROOT/bin/conda update -y setuptools > /dev/null && \
    $CONDA_ROOT/bin/conda install -y conda-build > /dev/null && \
    # Update selected packages - install python 3.8.x
    $CONDA_ROOT/bin/conda install -y --update-all python=$PYTHON_VERSION > /dev/null && \
    # Link Conda
    ln -s $CONDA_ROOT/bin/python /usr/local/bin/python && \
    ln -s $CONDA_ROOT/bin/conda /usr/bin/conda && \
    # Update
    $CONDA_ROOT/bin/conda install -y pip > /dev/null && \
    $CONDA_ROOT/bin/pip install --upgrade pip > /dev/null && \
    chmod -R a+rwx /usr/local/bin/ && \
    # Cleanup - Remove all here since conda is not in path as of now
    # find /opt/conda/ -follow -type f -name '*.a' -delete && \
    # find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    $CONDA_ROOT/bin/conda clean -y --packages && \
    $CONDA_ROOT/bin/conda clean -y -a -f  && \
    $CONDA_ROOT/bin/conda build purge-all && \
    # Fix permissions
    fix-permissions.sh $CONDA_ROOT && \
    ${CLEAN_SH}

ENV PATH=$CONDA_ROOT/bin:$PATH

# fix
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$CONDA_ROOT/lib

# Install pyenv to allow dynamic creation of python versions
RUN git clone https://github.com/pyenv/pyenv.git $RESOURCES_PATH/.pyenv && \
    # Install pyenv plugins based on pyenv installer
    git clone https://github.com/pyenv/pyenv-virtualenv.git $RESOURCES_PATH/.pyenv/plugins/pyenv-virtualenv  && \
    git clone git://github.com/pyenv/pyenv-doctor.git $RESOURCES_PATH/.pyenv/plugins/pyenv-doctor && \
    git clone https://github.com/pyenv/pyenv-update.git $RESOURCES_PATH/.pyenv/plugins/pyenv-update && \
    git clone https://github.com/pyenv/pyenv-which-ext.git $RESOURCES_PATH/.pyenv/plugins/pyenv-which-ext && \
    apt-get update > /dev/null && \
    # TODO: lib might contain high vulnerability
    # Required by pyenv
    apt-get install -y --no-install-recommends libffi-dev && \
    ${CLEAN_SH}

# Add pyenv to path
ENV PATH=$RESOURCES_PATH/.pyenv/shims:$RESOURCES_PATH/.pyenv/bin:$PATH \
    PYENV_ROOT=$RESOURCES_PATH/.pyenv

# Install pipx
RUN pip install pipx > /dev/null && \
    # Configure pipx
    python -m pipx ensurepath && \
    # Cleanup
    ${CLEAN_SH}
ENV PATH=$HOME/.local/bin:$PATH

# Install node.js
RUN \
    apt-get update > /dev/null && \
    # https://nodejs.org/en/about/releases/ use even numbered releases, i.e. LTS versions
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - && \
    apt-get install -y nodejs && \
    # As conda is first in path, the commands 'node' and 'npm' reference to the version of conda.
    # Replace those versions with the newly installed versions of node
    rm -f /opt/conda/bin/node && ln -s /usr/bin/node /opt/conda/bin/node && \
    rm -f /opt/conda/bin/npm && ln -s /usr/bin/npm /opt/conda/bin/npm && \
    # Fix permissions
    chmod a+rwx /usr/bin/node && \
    chmod a+rwx /usr/bin/npm && \
    # Fix node versions - put into own dir and before conda:
    mkdir -p /opt/node/bin && \
    ln -s /usr/bin/node /opt/node/bin/node && \
    ln -s /usr/bin/npm /opt/node/bin/npm && \
    # Update npm
    /usr/bin/npm install -g npm && \
    # Install Yarn
    /usr/bin/npm install -g yarn && \
    # Install typescript
    /usr/bin/npm install -g typescript && \
    # Install webpack - 32 MB
    /usr/bin/npm install -g webpack && \
    # Install node-gyp
    /usr/bin/npm install -g node-gyp && \
    # Update all packages to latest version
    /usr/bin/npm update -g && \
    # Cleanup
    ${CLEAN_SH}

ENV PATH=/opt/node/bin:$PATH


### DATA SCIENCE BASICS ###

## Python 3
# Data science libraries requirements
COPY resources/libraries ${RESOURCES_PATH}/libraries

### Install main data science libs
RUN \
    # Link Conda - All python are linke to the conda instances
    # Linking python 3 crashes conda -> cannot install anyting - remove instead
    # ln -s -f $CONDA_ROOT/bin/python /usr/bin/python3 && \
    # if removed -> cannot use add-apt-repository
    # rm /usr/bin/python3 && \
    # rm /usr/bin/python3.5
    ln -s -f $CONDA_ROOT/bin/python /usr/bin/python && \
    apt-get update > /dev/null && \
    # upgrade pip
    pip install --upgrade pip > /dev/null && \
    # If minimal flavor - install
    if [ "$WORKSPACE_FLAVOR" = "minimal" ]; then \
        # Install nomkl - mkl needs lots of space
        conda install -y --update-all 'python='$PYTHON_VERSION nomkl ; \
    else \
        # Install mkl for faster computations
        conda install -y --update-all 'python='$PYTHON_VERSION mkl-service mkl > /dev/null; \
    fi && \
    # Install some basics - required to run container
    conda install -y --update-all \
            'python='$PYTHON_VERSION \
            'ipython=7.24.*' \
            'notebook=6.4.*' \
            'jupyterlab=3.0.*' \
            # TODO: nbconvert 6.x makes problems with template_path
            'nbconvert=5.6.*' \
            # TODO: temp fix: yarl version 1.5 is required for lots of libraries.
            'yarl==1.5.*' \
            # TODO install scipy, numpy, sklearn, and numexpr via conda for mkl optimizaed versions: https://docs.anaconda.com/mkl-optimizations/
            'scipy==1.7.*' \
            'numpy==1.19.*' \
            scikit-learn \
            numexpr > /dev/null && \
            # installed via apt-get and pip: protobuf \
            # installed via apt-get: zlib  && \
    # Switch of channel priority, makes some trouble
    conda config --system --set channel_priority false && \
    # Install minimal pip requirements
    pip install --no-cache-dir --upgrade --upgrade-strategy only-if-needed -r ${RESOURCES_PATH}/libraries/requirements-minimal.txt > /dev/null && \
    # If minimal flavor - exit here
    if [ "$WORKSPACE_FLAVOR" = "minimal" ]; then \
        # Remove pandoc - package for markdown conversion - not needed
        # TODO: conda remove -y --force pandoc && \
        # Fix permissions
        fix-permissions.sh $CONDA_ROOT && \
        # Cleanup
        ${CLEAN_SH} && \
        exit 0 ; \
    fi && \
    # OpenMPI support
    apt-get install -y --no-install-recommends libopenmpi-dev openmpi-bin && \
    conda install -y --freeze-installed  \
        'python='$PYTHON_VERSION \
        boost \
        mkl-include > /dev/null && \
    # Install mkldnn
    conda install -y --freeze-installed -c mingfeima mkldnn > /dev/null && \
    # Install pytorch - cpu only
    conda install -y -c pytorch "pytorch==1.9.*" cpuonly > /dev/null && \
    # Install light pip requirements
    pip install --no-cache-dir --upgrade --upgrade-strategy only-if-needed -r ${RESOURCES_PATH}/libraries/requirements-light.txt > /dev/null && \
    # If light light flavor - exit here
    if [ "$WORKSPACE_FLAVOR" = "light" ]; then \
        # Fix permissions
        fix-permissions.sh $CONDA_ROOT && \
        # Cleanup
        ${CLEAN_SH} && \
        exit 0 ; \
    fi && \
    # libartals == 40MB liblapack-dev == 20 MB
    apt-get install -y --no-install-recommends liblapack-dev libatlas-base-dev libeigen3-dev libblas-dev && \
    # pandoc -> installs libluajit -> problem for openresty
    # HDF5 (19MB)
    apt-get install -y --no-install-recommends libhdf5-dev && \
    # TBB threading optimization
    apt-get install -y --no-install-recommends libtbb-dev && \
    # required for tesseract: 11MB - tesseract-ocr-dev?
    apt-get install -y --no-install-recommends libtesseract-dev && \
    pip install --no-cache-dir tesserocr > /dev/null && \
    # TODO: installs tenserflow 2.4 - Required for tensorflow graphics (9MB)
    apt-get install -y --no-install-recommends libopenexr-dev > /dev/null && \
    #pip install --no-cache-dir tensorflow-graphics==2020.5.20 && \
    # GCC OpenMP (GOMP) support library
    apt-get install -y --no-install-recommends libgomp1 > /dev/null && \
    # Install Intel(R) Compiler Runtime - numba optimization
    # TODO: don't install, results in memory error: conda install -y --freeze-installed -c numba icc_rt && \
    # Install libjpeg turbo for speedup in image processing
    conda install -y --freeze-installed libjpeg-turbo > /dev/null && \
    # Add snakemake for workflow management
    conda install -y -c bioconda -c conda-forge snakemake-minimal > /dev/null && \
    # Add mamba as conda alternativ
    conda install -y -c conda-forge mamba > /dev/null && \
    # Faiss - A library for efficient similarity search and clustering of dense vectors.
    conda install -y --freeze-installed faiss-cpu > /dev/null && \
    # Install full pip requirements
    pip install --no-cache-dir --upgrade --upgrade-strategy only-if-needed --use-deprecated=legacy-resolver -r ${RESOURCES_PATH}/libraries/requirements-full.txt > /dev/null && \
    # Setup Spacy
    # Spacy - download and large language removal
    python -m spacy download en && \
    # Fix permissions
    fix-permissions.sh $CONDA_ROOT && \
    # Cleanup
    ${CLEAN_SH}

# Fix conda version
RUN \
    # Conda installs wrong node version - relink conda node to the actual node
    rm -f /opt/conda/bin/node && ln -s /usr/bin/node /opt/conda/bin/node && \
    rm -f /opt/conda/bin/npm && ln -s /usr/bin/npm /opt/conda/bin/npm

### END DATA SCIENCE BASICS ###

### JUPYTER ###

COPY \
    resources/jupyter/start.sh \
    resources/jupyter/start-notebook.sh \
    resources/jupyter/start-singleuser.sh \
    /usr/local/bin/

# Configure Jupyter / JupyterLab
# Add as jupyter system configuration
COPY resources/jupyter/nbconfig /etc/jupyter/nbconfig
COPY resources/jupyter/jupyterlab_language_pack_zh_CN-0.0.1.dev0-py2.py3-none-any.whl /tmp/jupyterlab_language_pack_zh_CN-0.0.1.dev0-py2.py3-none-any.whl

# install jupyter extensions
# RUN \
#     # Create empty notebook configuration
#     mkdir -p $HOME/.jupyter/nbconfig/ && \
#     printf "{\"load_extensions\": {}}" > $HOME/.jupyter/nbconfig/notebook.json && \
#     # Activate and configure extensions
#     jupyter contrib nbextension install --sys-prefix && \
#     # nbextensions configurator
#     jupyter nbextensions_configurator enable --sys-prefix && \
#     # Configure nbdime
#     nbdime config-git --enable --global && \
#     # Activate Jupytext
#     jupyter nbextension enable --py jupytext --sys-prefix && \
#     # Enable useful extensions
#     jupyter nbextension enable skip-traceback/main --sys-prefix && \
#     # jupyter nbextension enable comment-uncomment/main && \
#     jupyter nbextension enable toc2/main --sys-prefix && \
#     jupyter nbextension enable execute_time/ExecuteTime --sys-prefix && \
#     jupyter nbextension enable collapsible_headings/main --sys-prefix && \
#     jupyter nbextension enable codefolding/main --sys-prefix && \
#     # Disable pydeck extension, cannot be loaded (404)
#     jupyter nbextension disable pydeck/extension && \
#     # Install and activate Jupyter Tensorboard
#     pip install --no-cache-dir git+https://github.com/InfuseAI/jupyter_tensorboard.git > /dev/null && \
#     jupyter tensorboard enable --sys-prefix && \
#     # TODO moved to configuration files = resources/jupyter/nbconfig Edit notebook config
#     # echo '{"nbext_hide_incompat": false}' > $HOME/.jupyter/nbconfig/common.json && \
#     cat $HOME/.jupyter/nbconfig/notebook.json | jq '.toc2={"moveMenuLeft": false,"widenNotebook": false,"skip_h1_title": false,"sideBar": true,"number_sections": false,"collapse_to_match_collapsible_headings": true}' > tmp.$$.json && mv tmp.$$.json $HOME/.jupyter/nbconfig/notebook.json && \
#     # If minimal flavor - exit here
#     if [ "$WORKSPACE_FLAVOR" = "minimal" ]; then \
#         # Cleanup
#         ${CLEAN_SH} && \
#         exit 0 ; \
#     fi && \
#     # TODO: Not installed. Disable Jupyter Server Proxy
#     # jupyter nbextension disable jupyter_server_proxy/tree --sys-prefix && \
#     # Install jupyter black
#     jupyter nbextension install https://github.com/drillan/jupyter-black/archive/master.zip --sys-prefix && \
#     jupyter nbextension enable jupyter-black-master/jupyter-black --sys-prefix && \
#     # If light flavor - exit here
#     if [ "$WORKSPACE_FLAVOR" = "light" ]; then \
#         # Cleanup
#         ${CLEAN_SH} && \
#         exit 0 ; \
#     fi && \
#     # Install and activate what if tool
#     pip install witwidget > /dev/null && \
#     jupyter nbextension install --py --symlink --sys-prefix witwidget && \
#     jupyter nbextension enable --py --sys-prefix witwidget && \
#     # Activate qgrid
#     jupyter nbextension enable --py --sys-prefix qgrid && \
#     # TODO: Activate Colab support
#     # jupyter serverextension enable --py jupyter_http_over_ws && \
#     # Activate Voila Rendering
#     # currently not working jupyter serverextension enable voila --sys-prefix && \
#     # Enable ipclusters
#     ipcluster nbextension enable && \
#     # Fix permissions? fix-permissions.sh $CONDA_ROOT && \
#     # Cleanup
#     ${CLEAN_SH}

# install jupyterlab
RUN \
    # without es6-promise some extension builds fail
    npm install -g es6-promise && \
    # define alias command for jupyterlab extension installs with log prints to stdout
    jupyter lab build && \
    lab_ext_install='jupyter labextension install -y --debug-log-path=/dev/stdout --log-level=WARN --minimize=False --no-build' && \
    # jupyterlab installed in requirements section
    $lab_ext_install @jupyter-widgets/jupyterlab-manager && \
    # If minimal flavor - do not install jupyterlab extensions
    if [ "$WORKSPACE_FLAVOR" = "minimal" ]; then \
        # Final build with minimization
        jupyter lab build -y --debug-log-path=/dev/stdout --log-level=WARN && \
        # Cleanup
        jupyter lab clean && \
        jlpm cache clean && \
        rm -rf $CONDA_ROOT/share/jupyter/lab/staging && \
        ${CLEAN_SH} && \
        exit 0 ; \
    fi && \
    # https://github.com/jupyterlab/jupyterlab-toc  3.0 + 自带了toc插件
    # $lab_ext_install @jupyterlab/toc && \
    # install temporarily from gitrepo due to the issue that jupyterlab_tensorboard does not work with 3.x yet as described here: https://github.com/chaoleili/jupyterlab_tensorboard/issues/28#issuecomment-783594541
    #$lab_ext_install jupyterlab_tensorboard && \
    pip install git+https://github.com/chaoleili/jupyterlab_tensorboard.git > /dev/null && \
    # install jupyterlab git
    # $lab_ext_install @jupyterlab/git && \
    pip install jupyterlab-git > /dev/null && \
    # jupyter serverextension enable --py jupyterlab_git && \
    # For Matplotlib: https://github.com/matplotlib/jupyter-matplotlib
    #$lab_ext_install jupyter-matplotlib && \
    # Do not install any other jupyterlab extensions
    if [ "$WORKSPACE_FLAVOR" = "light" ]; then \
        # Final build with minimization
        jupyter lab build -y --debug-log-path=/dev/stdout --log-level=WARN && \
        # Cleanup
        jupyter lab clean && \
        jlpm cache clean && \
        rm -rf $CONDA_ROOT/share/jupyter/lab/staging && \
        ${CLEAN_SH} && \
        exit 0 ; \
    fi \
    # Install jupyterlab language server support
    && pip install jupyterlab-lsp==3.7.0 jupyter-lsp==1.3.0 && \
    # $lab_ext_install install @krassowski/jupyterlab-lsp@2.0.8 && \
    # For Plotly
    $lab_ext_install jupyterlab-plotly && \
    $lab_ext_install install @jupyter-widgets/jupyterlab-manager plotlywidget && \
    # produces build error: jupyter labextension install jupyterlab-chart-editor && \
    $lab_ext_install jupyterlab-chart-editor && \
    # Install jupyterlab variable inspector - https://github.com/lckr/jupyterlab-variableInspector
    pip install lckr-jupyterlab-variableinspector > /dev/null && \
    # For holoview
    # TODO: pyviz is not yet supported by the current JupyterLab version
    #     $lab_ext_install @pyviz/jupyterlab_pyviz && \
    # Install Debugger in Jupyter Lab
    # pip install --no-cache-dir xeus-python && \
    # $lab_ext_install @jupyterlab/debugger && \
    # Install jupyterlab code formattor - https://github.com/ryantam626/jupyterlab_code_formatter
    $lab_ext_install @ryantam626/jupyterlab_code_formatter && \
    pip install jupyterlab_code_formatter > /dev/null && \
    jupyter serverextension enable --py jupyterlab_code_formatter \
    # install more...  monitor execute_time collapsible_headings spellchecker
    && pip install  jupyterlab-topbar \
    && pip install   jupyterlab-system-monitor \
    && pip install    jupyterlab_execute_time \
    && pip install aquirdturtle_collapsible_headings \
    && pip install  jupyterlab-spellchecker \
    && pip install jupyterlab-drawio \
    && pip install  jupyterlab_theme_solarized_dark \
    && pip install jupyterlab_theme_hale \
    && pip install jupyterlab-horizon-theme \
    && pip install theme-darcula  \
    && pip install jupyterlab-fasta \
    && pip install jupyterlab-geojson \
    &&  pip install jupyterlab-katex \
    &&  pip install jupyterlab-mathjax3 \
    &&  pip install jupyterlab-vega2 \
    &&  pip install jupyterlab-vega3 \
    # 中文语言汉化包
    &&  pip install /tmp/jupyterlab_language_pack_zh_CN-0.0.1.dev0-py2.py3-none-any.whl \
    && rm -rf /tmp/jupyterlab_language_pack_zh_CN-0.0.1.dev0-py2.py3-none-any.whl \
    # to install the topbar-text extension
    && $lab_ext_install jupyterlab-topbar-text \
    # latex support
    && $lab_ext_install  @jupyterlab/latex \
    # xls excel
    && $lab_ext_install jupyterlab-spreadsheet \
    # theme
    && $lab_ext_install @yeebc/jupyterlab_neon_theme \
    && $lab_ext_install  jupyterlab-tailwind-theme \
     && $lab_ext_install @yudai-nkt/jupyterlab_city-lights-theme \
    # Final build with minimization
    && jupyter lab build -y --debug-log-path=/dev/stdout --log-level=WARN && \
    jupyter lab build && \
    # Cleanup
    # Clean jupyter lab cache: https://github.com/jupyterlab/jupyterlab/issues/4930
    jupyter lab clean && \
    jlpm cache clean && \
    # Remove build folder -> should be remove by lab clean as well?
    rm -rf $CONDA_ROOT/share/jupyter/lab/staging && \
    ${CLEAN_SH}

# Additional jupyter configuration

COPY resources/jupyter/jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py
COPY resources/jupyter/sidebar.jupyterlab-settings $HOME/.jupyter/lab/user-settings/@jupyterlab/application-extension/
COPY resources/jupyter/plugin.jupyterlab-settings $HOME/.jupyter/lab/user-settings/@jupyterlab/extensionmanager-extension/
# 增加用户快捷键设置
COPY resources/jupyter/shortcuts.jupyterlab-settings $HOME/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extension/shortcuts.jupyterlab-settings

# 时间记录开启
COPY resources/jupyter/plugin/tracker.jupyterlab-settings $HOME/.jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings
# topbar text
COPY resources/jupyter/plugin/topbar-text.plugin.jupyterlab-settings $HOME/.jupyter/lab/user-settings/jupyterlab-topbar-text/plugin.jupyterlab-settings
COPY resources/bashrc $HOME/.bashrc
COPY resources/jupyter/SimHei.ttf $CONDA_PYTHON_DIR/site-packages/matplotlib/mpl-data/fonts/ttf/SimHei.ttf
COPY resources/branding $RESOURCES_PATH/branding

# Branding of various components
RUN \
    # Jupyter Branding
    cp -f $RESOURCES_PATH/branding/logo.png $CONDA_PYTHON_DIR"/site-packages/notebook/static/base/images/logo.png" && \
    cp -f $RESOURCES_PATH/branding/favicon.ico $CONDA_PYTHON_DIR"/site-packages/notebook/static/base/images/favicon.ico" && \
    cp -f $RESOURCES_PATH/branding/favicon.ico $CONDA_PYTHON_DIR"/site-packages/notebook/static/favicon.ico" && \
# Configure git
    git config --global core.fileMode false && \
    git config --global http.sslVerify false && \
    # Use store or credentialstore instead? timout == 365 days validity
    git config --global credential.helper 'cache --timeout=31540000' && chmod +x $HOME/.bashrc

# Configure Matplotlib
RUN echo 'font.family : SimHei \n\
font.serif : SimHei, DejaVu Serif, Bitstream Vera Serif, \
Computer Modern Roman, New Century Schoolbook, \
Century Schoolbook L, Utopia, ITC Bookman, Bookman, \
Nimbus Roman No9 L, Times New Roman, \
Times, Palatino, Charter, serif\n ' >> $CONDA_PYTHON_DIR/site-packages/matplotlib/mpl-data/matplotlibrc && \
    # Import matplotlib the first time to build the font cache.
    MPLBACKEND=Agg python -c "import matplotlib.pyplot" \
    # Stop Matplotlib printing junk to the console on first load
    sed -i "s/^.*Matplotlib is building the font cache using fc-list.*$/# Warning removed/g" $CONDA_PYTHON_DIR/site-packages/matplotlib/font_manager.py

# MKL and Hardware Optimization
# Fix problem with MKL with duplicated libiomp5: https://github.com/dmlc/xgboost/issues/1715
# Alternative - use openblas instead of Intel MKL: conda install -y nomkl
# http://markus-beuckelmann.de/blog/boosting-numpy-blas.html
# MKL:
# https://software.intel.com/en-us/articles/tips-to-improve-performance-for-popular-deep-learning-frameworks-on-multi-core-cpus
# https://github.com/intel/pytorch#bkm-on-xeon
# http://astroa.physics.metu.edu.tr/MANUALS/intel_ifc/mergedProjects/optaps_for/common/optaps_par_var.htm
# https://www.tensorflow.org/guide/performance/overview#tuning_mkl_for_the_best_performance
# https://software.intel.com/en-us/articles/maximize-tensorflow-performance-on-cpu-considerations-and-recommendations-for-inference
ENV KMP_DUPLICATE_LIB_OK="True" \
    # Control how to bind OpenMP* threads to physical processing units # verbose
    KMP_AFFINITY="granularity=fine,compact,1,0" \
    KMP_BLOCKTIME=0 \
    # KMP_BLOCKTIME="1" -> is not faster in my tests
    # TensorFlow uses less than half the RAM with tcmalloc relative to the default. - requires google-perftools
    # Too many issues: LD_PRELOAD="/usr/lib/libtcmalloc.so.4" \
    # TODO set PYTHONDONTWRITEBYTECODE
    # TODO set XDG_CONFIG_HOME, CLICOLOR?
    # https://software.intel.com/en-us/articles/getting-started-with-intel-optimization-for-mxnet
    # KMP_AFFINITY=granularity=fine, noduplicates,compact,1,0
    # MXNET_SUBGRAPH_BACKEND=MKLDNN
    # TODO: check https://github.com/oneapi-src/oneTBB/issues/190
    # TODO: https://github.com/pytorch/pytorch/issues/37377
    # use omp
    MKL_THREADING_LAYER=GNU \
    # To avoid over-subscription when using TBB, let the TBB schedulers use Inter Process Communication to coordinate:
    ENABLE_IPC=1 \
    # will cause pretty_errors to check if it is running in an interactive terminal
    PYTHON_PRETTY_ERRORS_ISATTY_ONLY=1 \
    # TODO: evaluate - Deactivate hdf5 file locking
    HDF5_USE_FILE_LOCKING=False

# ------ python 包
RUN pip install --no-cache-dir -i https://mirrors.aliyun.com/pypi/simple/  \
    easydict flask flask_cors flask-pymongo Jinja2 redis redis-py-cluster gunicorn \
    pyhive seaborn yarl scipy scikit-learn datetime_truncate mpld3 plotly  \
    && clean-layer.sh

# ------- R 环境
RUN conda install --quiet --yes \
    'r-base=4.1.0' \
    'r-caret=6.*' \
    'r-crayon=1.4*' \
    'r-devtools=2.4*' \
    'r-forecast=8.15*' \
    'r-hexbin=1.28*' \
    'r-htmltools=0.5*' \
    'r-htmlwidgets=1.5*' \
    'r-irkernel=1.2*' \
    'r-nycflights13=1.0*' \
    'r-randomforest=4.6*' \
    'r-rcurl=1.98*' \
    'r-rmarkdown=2.9*' \
    'r-rodbc=1.3*' \
    'r-rsqlite=2.2*' \
    'r-shiny=1.6*' \
    'r-tidymodels=0.1*' \
    'r-tidyverse=1.3*' \
    'unixodbc=2.3.*' \
    'r-languageserver' \
    'r-data.table' \
    'r-reshape2' \
    'r-plotly' \
    'r-readxl' \
    'r-rvest' \
    'r-jiebard' \
    'r-tibble' && \
    # Install e1071 R package (dependency of the caret R package)
    conda install --quiet --yes r-e1071 && \
    clean-layer.sh

# golang运行环境
RUN wget --no-check-certificate -O /tmp/go1.16.7.linux-amd64.tar.gz https://golang.org/dl/go1.16.7.linux-amd64.tar.gz && \
   rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go1.16.7.linux-amd64.tar.gz && \
   rm -rf /tmp/go1.16.7.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

# go notebooks
RUN env GO111MODULE=on go get github.com/gopherdata/gophernotes && \
    mkdir -p ~/.local/share/jupyter/kernels/gophernotes && \
    cd ~/.local/share/jupyter/kernels/gophernotes  && \
    cp "$(go env GOPATH)"/pkg/mod/github.com/gopherdata/gophernotes@v0.7.3/kernel/*  "." && \
    chmod +w ./kernel.json # in case copied kernel.json has no write permission && \
    sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" < kernel.json.in > kernel.json 


# Set default values for environment variables
ENV CONFIG_BACKUP_ENABLED="true" \
    SHUTDOWN_INACTIVE_KERNELS="false" \
    SHARED_LINKS_ENABLED="true" \
    AUTHENTICATE_VIA_JUPYTER="false" \
    DATA_ENVIRONMENT=$WORKSPACE_HOME"/environment" \
    WORKSPACE_BASE_URL="/" \
    # Main port used for sshl proxy -> can be changed
    WORKSPACE_PORT="8080" \
    SHELL="/bin/bash" \
    # Fix dark blue color for ls command (unreadable):
    # https://askubuntu.com/questions/466198/how-do-i-change-the-color-for-directories-with-ls-in-the-console
    # USE default LS_COLORS - Dont set LS COLORS - overwritten in zshrc
    # LS_COLORS="" \
    # set number of threads various programs should use, if not-set, it tries to use all
    # this can be problematic since docker restricts CPUs by stil showing all
    MAX_NUM_THREADS="auto"

# use global option with tini to kill full process groups: https://github.com/krallin/tini#process-group-killing
ENTRYPOINT ["/tini", "-g", "--"]

# CMD ["python", "/resources/docker-entrypoint.py"]

# Port 8080 is the main access port (also includes SSH)
# Port 5091 is the VNC port
# Port 3389 is the RDP port
# Port 8090 is the Jupyter Notebook Server
# See supervisor.conf for more ports

# EXPOSE 8080
###
