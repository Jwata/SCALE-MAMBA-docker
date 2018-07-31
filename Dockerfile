FROM alpine:latest AS mpir-build
LABEL maintainer="Lukas Prediger <lukas.prediger@rwth-aachen.de>"

RUN apk add --update --no-cache g++ make yasm m4

#RUN addgroup -S scale && adduser -S -G scale scale && mkdir -p /scale && chown scale:scale /scale
#WORKDIR scale
#USER scale

RUN wget http://mpir.org/mpir-3.0.0.tar.bz2 && tar -xjf mpir-3.0.0.tar.bz2 && rm mpir-3.0.0.tar.bz2
WORKDIR  mpir-3.0.0
RUN ./configure --enable-cxx --prefix=/mpir && make
RUN make check
RUN make install

FROM alpine:latest AS scale-build
LABEL maintainer="Lukas Prediger <lukas.prediger@rwth-aachen.de>"
COPY --from=mpir-build /mpir /usr/local

RUN apk add --update --no-cache git g++ make libressl-dev bash python

RUN git clone https://github.com/KULeuven-COSIC/SCALE-MAMBA.git scale-mamba
WORKDIR scale-mamba
ADD CONFIG.mine .
RUN make progs
RUN make test
#RUN ./run_tests.sh

#FROM alpine:latest
#LABEL maintainer="Lukas Prediger <lukas.prediger@rwth-aachen.de>"
#COPY --from=mpir-build /mpir /usr/local/
#ENTRYPOINT ["/bin/sh"]
