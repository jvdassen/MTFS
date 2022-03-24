# MTFS
> A virtual file system for host-based Moving Target Defense (MTD)

As of now, most methods (prefixed in the logs with `real`) run in loopback mode. Reading, writing and renaming files works in virtual mode. That is, reading a file will return the same number of random bytes as the requested file in the source directory. Writing and renaming a file will result simply delay the writing process with no affect on the source file system.

## Installation
Install python3-fuse either as a package or form source.
```
sudo apt-get install python3-fuse
# or

git clone git@github.com:libfuse/python-fuse.git ; cd pyython-fuse
sudo python3 setup.py  install
```

## Instantiation
```
./mtfs.sh honeypotsrc honeypotdst 
```
Reading a file from the fs:
```
cat honeypotdst/1
```
