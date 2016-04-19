# pyv8 builder
This docker image has been created to simplify the process of building a pyv8 binary for Python3 and make it repeatable.

## Usage
```bash
docker build -t pyv8 .
docker run -it --rm -v `pwd`/bin:/pyv8 pyv8
```

## Resources
This image has been cobbled together with the help of many wonderful documents on the Internet:
* https://www.chromium.org/developers/how-tos/install-depot-tools
* http://eb2.co/blog/2012/03/building-boost-python-for-python-3-2/
* https://www.dinotools.de/2013/02/27/python-build-pyv8-for-python3-on-ubuntu/
* https://github.com/buffer/thug/blob/master/patches/PyV8-patch1.diff
* http://www.boost.org/build/doc/html/bbv2/overview/invocation.html

The diff file from the `buffer/thug` repository fixes a bug in PyV8 that leads to a segmentation fault when attempting to leave a JSLocker in Python3.

## Notes
There are variables at the top of the Dockerfile for the Python and Boost versions to download and install.  Adjust them freely as newer versions come out.

## Source modifications
The Dockerfile makes several modifications to the source code before compiling and building.  These are probably the lines that will need the most modification as time goes on, at least if anything ever changes in the pyv8 source. Therefore, the reasoning behind each modification is documented below

### Build PyV8 with BOOST_STATIC_LINK = True
This performs the PyV8 build with static linking so that the application container doesn't need the boost libraries to use PyV8

### Link to python3 boost library
This is because PyV8 is setup to build for and link to python2.7

### Add octal identifier for Python3 compatibility
Same as above.  "0755" is not a valid octal literal in Python3.

### Add indentation for Python3 compatibility
This is a block of code that imports from a Python2 only library.  It gets tabbed in so that it joins a conditional block that only runs if it's being run under Python2.

### Add "from ." to "import _PyV8" in line with the way PyV8 gets packaged here
This is not due to any bug, but I find it more useful to make PyV8 as a package that can be dropped into a directory that's in Python's path, and then it can be instantly imported and used.  So when using PyV8 as a package, this import method is needed for PyV8 to be able to find its shared object library.

This is also why there's a command in the Dockerfile that does `touch __init__.py`

### Fix bug in PyV8
This one IS due to a bug in PyV8.  Without this fix, Python3 runs into a segmentation fault when you leave a JSLocker.  Thanks to the `buffer/thug` repository for this fix!
