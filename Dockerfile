FROM debian:jessie

ENV PYTHON_VERSION 3.6.0
ENV BOOST_VERSION 1.60.0
ENV BOOST_NAME 1_60_0

# System tools
RUN apt-get update
RUN apt-get install -y curl subversion git build-essential libssl-dev openssl python

# Python
RUN curl -fLs https://www.python.org/ftp/python/"$PYTHON_VERSION"/Python-"$PYTHON_VERSION".tar.xz | tar xJv -C /tmp
RUN cd /tmp/Python-"$PYTHON_VERSION" && ./configure
RUN cd /tmp/Python-"$PYTHON_VERSION" && make
RUN cd /tmp/Python-"$PYTHON_VERSION" && make install
RUN ln -s /usr/local/include/python3.6m /usr/local/include/python3.6

# Get source
RUN curl -fLs https://github.com/v8/v8/archive/5.8.121.tar.gz | tar xz -C /tmp
RUN curl -fLs https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pyv8/PyV8-0.9.tar.gz | tar xz -C /tmp
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /tmp/depot_tools

# Boost
RUN curl -fLs http://ufpr.dl.sourceforge.net/project/boost/boost/"$BOOST_VERSION"/boost_"$BOOST_NAME".tar.bz2 | tar xjv -C /tmp
RUN cd /tmp/boost_"$BOOST_NAME" && ./bootstrap.sh --with-python=python3 --with-libraries=system,thread,python
RUN cd /tmp/boost_"$BOOST_NAME" && ./b2 cxxflags="-fPIC"

# Build v8
RUN mv /tmp/v8-5.8.121 /tmp/v8 && cd /tmp/v8 && PATH=/tmp/depot_tools:"$PATH" make dependencies

RUN mv /tmp/PyV8-0.9 /tmp/pyv8

### Modify a few files
# Build PyV8 with BOOST_STATIC_LINK = True
RUN sed -i "43s/False/True/" /tmp/pyv8/setup.py
# Link to python3 boost library
RUN sed -i "s/boost_python/boost_python3/" /tmp/pyv8/setup.py
# Add octal identifier for Python3 compatibility
RUN sed -i "s/0755/0o755/" /tmp/pyv8/setup.py
# Add indentation for Python3 compatibility
RUN sed -i "23,26s/^/    /" /tmp/pyv8/PyV8.py
# Add "from ." to "import _PyV8" in line with the way PyV8 gets packaged here
RUN sed -i "33s/^/from . /" /tmp/pyv8/PyV8.py
# Fix bug in PyV8
RUN sed -i "s/Py_DECREF(global.ptr());//" /tmp/pyv8/src/Context.cpp

# Build and package PyV8
RUN cd /tmp/pyv8 && \
    V8_HOME=/tmp/v8 \
    BOOST_HOME=/tmp/boost_"$BOOST_NAME" \
    LD_LIBRARY_PATH=/tmp/boost_"$BOOST_NAME"/stage/lib \
    PATH=/tmp/depot_tools:"$PATH" \
    python3.6 setup.py build
RUN mv /tmp/pyv8/build/lib.linux-x86_64-3.6 /tmp/pyv8/build/pyv8
RUN mv /tmp/pyv8/build/pyv8/_PyV8.cpython-36m-x86_64-linux-gnu.so /tmp/pyv8/build/pyv8/_PyV8.so
RUN touch /tmp/pyv8/build/pyv8/__init__.py
RUN mkdir /build
RUN cd /tmp/pyv8/build && tar czvf /build/pyv8.tgz pyv8
RUN chmod +r /build/*

VOLUME /pyv8
CMD ["cp", "/build/pyv8.tgz", "/pyv8/pyv8.tgz"]
