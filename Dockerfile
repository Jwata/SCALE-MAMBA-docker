FROM alpine:latest AS mpir-build
LABEL maintainer="Lukas Prediger <lukas.prediger@rwth-aachen.de>"

RUN apk add --update --no-cache g++ make yasm m4

RUN wget http://mpir.org/mpir-3.0.0.tar.bz2 && tar -xjf mpir-3.0.0.tar.bz2 && rm mpir-3.0.0.tar.bz2
WORKDIR  mpir-3.0.0
RUN ./configure --enable-cxx --prefix=/mpir && make
RUN make check
RUN make install
RUN rm -rf /mpir/share


FROM alpine:latest AS openssl-build

RUN apk add --update --no-cache g++ make linux-headers perl
RUN wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz && tar -xzf openssl-1.1.0h.tar.gz && rm openssl-1.1.0h.tar.gz
WORKDIR openssl-1.1.0h
RUN ./config --prefix=/openssl no-async no-weak-ssl-ciphers && make
RUN make test
RUN make install
RUN rm -rf /openssl/share

FROM alpine:latest AS scale-build
LABEL maintainer="Lukas Prediger <lukas.prediger@rwth-aachen.de>"
COPY --from=mpir-build /mpir /usr/local
COPY --from=openssl-build /openssl /usr/local

RUN apk add --update --no-cache g++ make

WORKDIR /scale-mamba
ADD SCALE-MAMBA/ .
ADD CONFIG.mine .
RUN make progs
RUN mkdir /scale-mamba-bin && cp Player.x /scale-mamba-bin && cp Setup.x /scale-mamba-bin && cp src/libMPC.a /scale-mamba-bin && cp compile.py /scale-mamba-bin && cp -r Compiler /scale-mamba-bin && cp Copyright.txt /scale-mamba-bin && cp License.txt /scale-mamba-bin

FROM alpine:latest
LABEL maintainer="Lukas Prediger <lukas.prediger@rwth-aachen.de>"

RUN apk add --update --no-cache libgcc libstdc++ python

COPY --from=mpir-build /mpir /usr/local
COPY --from=openssl-build /openssl /usr/local
COPY --from=scale-build /scale-mamba-bin /scale-mamba

VOLUME ["/scale-mamba/Cert-Store", "/scale-mamba/Data", "/scale-mamba/Programs"]

WORKDIR /scale-mamba
CMD ["/bin/sh"]
