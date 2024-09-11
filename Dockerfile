ARG BASE_IMAGE=quay.io/jupyter/minimal-notebook:2024-07-29
FROM ${BASE_IMAGE}

USER root
WORKDIR /opt

RUN mkdir /opt/mesa \
 && mkdir /opt/mesasdk \
 && chown -R jovyan:users /opt/mesa*

RUN apt-get update -y \
 && apt-get install -y \
    zlib1g \
    zlib1g-dev \
    libx11-6 \
    libx11-dev \
    binutils \
    make \
    tcsh \
    unzip

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Download & Install MESA SDK
# See docs: http://user.astro.wisc.edu/~townsend/static.php?ref=mesasdk#Compatibility
RUN curl -O "http://user.astro.wisc.edu/~townsend/resource/download/mesasdk/mesasdk-x86_64-linux-23.7.3.tar.gz"

RUN tar xvfz mesasdk-x86_64-linux-23.7.3.tar.gz -C /opt/mesasdk \
 && rm mesasdk-x86_64-linux-23.7.3.tar.gz \
 && mv /opt/mesasdk/mesasdk/* /opt/mesasdk \
 && rmdir /opt/mesasdk/mesasdk/ \
 && export MESASDK_ROOT=/opt/mesasdk \
 && source $MESASDK_ROOT/bin/mesasdk_init.sh

# Download and install MESA
# See docs: https://docs.mesastar.org/en/release-r24.03.1/using_mesa/running.html
RUN curl -O "https://zenodo.org/records/10783349/files/mesa-r24.03.1.zip?download=1"
 
RUN mv mesa-r24.03.1.zip?download=1 mesa-r24.03.1.zip \
 && unzip mesa-r24.03.1.zip -d /opt/mesa \
 && rm mesa-r24.03.1.zip \
 && export MESA_DIR=/opt/mesa/mesa-r24.03.1 \
 && export OMP_NUM_THREADS=2 \
 && export MESASDK_ROOT=/opt/mesasdk \
 && source $MESASDK_ROOT/bin/mesasdk_init.sh \
 && export PATH=$PATH:$MESA_DIR/scripts/shmesa \
 && cd $MESA_DIR \
 && ./install 

# Switch back to root user after MESA install
USER root
WORKDIR /opt

# Return MESA directories ownership to root
# RUN chown -R root:root /opt/mesa*

ENV MESASDK_ROOT=/opt/mesasdk
ENV MESA_DIR=/opt/mesa/mesa-r24.03.1

# Add MESA Environment variables to skeleton .bashrc
RUN echo -e "# MESA Environment variables \n export MESA_DIR=/opt/mesa/mesa-r24.03.1 \n export OMP_NUM_THREADS=2 \n export MESASDK_ROOT=/opt/mesasdk \n source $MESASDK_ROOT/bin/mesasdk_init.sh \n export PATH=$PATH:$MESA_DIR/scripts/shmesa" >> /etc/skel/.bashrc

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}
RUN cp /etc/skel/.bashrc .
