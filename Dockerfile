FROM armhf/ubuntu

# Update system and install Supervisord, OpenSSH server, and tools needed for creepMiner
RUN apt-get update && apt-get upgrade -qy -o Dpkg::Options::="--force-confold" \
  && apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confold" \
  apt-utils supervisor sudo \
  net-tools openssh-server \
  build-essential cmake git \
  python-pip python-setuptools python-dev \
  openssl libssl-dev \
  xz-utils curl ca-certificates gnupg2 dirmngr \
  ocl-icd-opencl-dev

RUN cd /tmp/ \
  && pip install --upgrade pip \
  && pip2.7 install conan \
  && git clone -b development https://github.com/Creepsky/creepMiner \
  && cd creepMiner \
  && conan install . -s compiler.libcxx=libstdc++11 --build=missing \
  && cmake CMakeLists.txt -DCMAKE_BUILD_TYPE=RELEASE -DMINIMAL_BUILD=ON \
  && make -j$(nproc) \
  && cp -r resources/public /usr/local/sbin/ \
  && cp -r resources/frontail.json /etc/ \
  && cp -r src/shabal/opencl/mining.cl /usr/local/sbin/ \
  && cp -r bin/creepMiner /usr/local/sbin/ \
  && sed -i '2s/creepMiner/creepContainer/' /usr/local/sbin/public/js/general.js \
  && sed -i '4s/false/true/' /usr/local/sbin/public/js/general.js \
  && mkdir /config && mkdir /logs

# install frontail
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - \
  && apt-get install nodejs \
  && npm i frontail -g

# Add creepUser | creep / M1n3r and set root password
RUN useradd -m -p FIEyX7IsHWazs -s /bin/bash creep \
  && echo 'root:toor' | chpasswd

# Expose port 8124 for creepMiner UI, 9001 for supervisord or webproc and 9002 for frontail
EXPOSE 8124 9001 9002

CMD ["/sbin/init"]
