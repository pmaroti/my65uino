FROM debian:latest
RUN apt update && apt install -y git g++ \
    cmake build-essential clang lld bison flex \
    libreadline-dev gawk tcl-dev libffi-dev git \
    graphviz xdot pkg-config python3 libboost-system-dev \
    libboost-python-dev libboost-filesystem-dev zlib1g-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-thread-dev \
    libboost-program-options-dev \
    libboost-iostreams-dev \
    libboost-dev \
    libeigen3-dev \
    pip

WORKDIR /app
RUN git clone https://github.com/YosysHQ/yosys.git
WORKDIR /app/yosys
RUN git submodule update --init --recursive
RUN make
RUN pip install --break-system-packages apycula

WORKDIR /app
RUN git clone https://github.com/YosysHQ/nextpnr.git
WORKDIR /app/nextpnr
RUN ls -lrt
RUN git submodule update --init --recursive
WORKDIR /app/nextpnr/build
RUN cmake .. -DARCH="himbaechel" -DHIMBAECHEL_UARCH="gowin"
RUN make
ENV PATH="/app/yosys:/app/nextpnr/build:${PATH}"

WORKDIR /app
RUN git clone https://github.com/mikeakohn/naken_asm.git
WORKDIR /app/naken_asm
RUN ./configure 
RUN make
RUN make install

WORKDIR /app
RUN git clone https://bitbucket.org/megatokio/zasm.git
WORKDIR /app/zasm
RUN rm -rf Libraries 
RUN git clone https://bitbucket.org/megatokio/libraries.git Libraries
WORKDIR /app/zasm/Linux/
RUN make
RUN cp zasm /bin/


WORKDIR /app
RUN apt install -y bsdmainutils iverilog
