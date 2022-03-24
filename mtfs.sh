#!/usr/bin/env python3

from __future__ import with_statement

import os
import sys
import errno
import random
import time

from fuse import FUSE, FuseOSError, Operations


class Passthrough(Operations):
    def __init__(self, root):
        self.root = root

    def _full_path(self, partial):
        partial = partial.lstrip("/")
        path = os.path.join(self.root, partial)
        return path

    # Filesystem methods
    def access(self, path, mode):
        print('Real access ' + path)
        full_path = self._full_path(path)
        if not os.access(full_path, mode):
            raise FuseOSError(errno.EACCES)

    def chmod(self, path, mode):
        print('Real chmod ' + path)
        full_path = self._full_path(path)
        return os.chmod(full_path, mode)

    def chown(self, path, uid, gid):
        print('Real chown ' + path)
        full_path = self._full_path(path)
        return os.chown(full_path, uid, gid)

    def getattr(self, path, fh=None):
        print('Real getattr ' + path)
        full_path = self._full_path(path)
        st = os.lstat(full_path)
        return dict((key, getattr(st, key)) for key in ('st_atime', 'st_ctime',
                     'st_gid', 'st_mode', 'st_mtime', 'st_nlink', 'st_size', 'st_uid'))

    def readdir(self, path, fh):
        print('Real readdir ' + path)
        full_path = self._full_path(path)

        dirents = ['.', '..']
        if os.path.isdir(full_path):
            dirents.extend(os.listdir(full_path))
        for r in dirents:
            yield r

    def readlink(self, path):
        print('Real readlink ' + path)
        pathname = os.readlink(self._full_path(path))
        if pathname.startswith("/"):
            # Path name is absolute, sanitize it.
            return os.path.relpath(pathname, self.root)
        else:
            return pathname

    def mknod(self, path, mode, dev):
        print('Real mknod ' + path)
        return os.mknod(self._full_path(path), mode, dev)

    def rmdir(self, path):
        print('Real rmdir ' + path)
        full_path = self._full_path(path)
        ret = os.rmdir(full_path)
        print("Real removing + " + path + " " + ret)
        return ret

    def mkdir(self, path, mode):
        print('Real mkdir ' + path)
        return os.mkdir(self._full_path(path), mode)

    def statfs(self, path):
        print('Real statfs ' + path)
        full_path = self._full_path(path)
        stv = os.statvfs(full_path)
        return dict((key, getattr(stv, key)) for key in ('f_bavail', 'f_bfree',
            'f_blocks', 'f_bsize', 'f_favail', 'f_ffree', 'f_files', 'f_flag',
            'f_frsize', 'f_namemax'))

    def unlink(self, path):
        print('Real unlinking ' + path)
        return os.unlink(self._full_path(path))

    def symlink(self, name, target):
        print('Real symlink ' + path)
        return os.symlink(name, self._full_path(target))

    def rename(self, old, new):
        print('Real rename ' + old + ' to ' + new)
        #ret = os.rename(self._full_path(old), self._full_path(new))
        return None

    def link(self, target, name):
        print('Real link ' + path)
        return os.link(self._full_path(target), self._full_path(name))

    def utimens(self, path, times=None):
        print('Real utimens ' + path)
        return os.utime(self._full_path(path), times)

    # File methods
    def open(self, path, flags):
        print('Real open ' + path)
        full_path = self._full_path(path)
        return os.open(full_path, flags)

    def create(self, path, mode, fi=None):
        print('Real create ' + path)
        full_path = self._full_path(path)
        return os.open(full_path, os.O_WRONLY | os.O_CREAT, mode)

    def read(self, path, length, offset, fh):
        print('Fake reading ' + str(length) + path + ' with delay of 2s')
#        return bytearray(os.urandom(length))
#        os.lseek(fh, offset, os.SEEK_SET)
#        r = os.read(fh, length)
#        print(type(r))
        time.sleep(2)
        return bytes(os.urandom(length))

    def write(self, path, buf, offset, fh):
        print("Fake-writing " + str(len(buf)) + " bytes for " + path +  " with delay of 2s")
#        os.lseek(fh, offset, os.SEEK_SET)
#        ret = os.write(fh, buf)
#        print(type(ret))
#        print(len(buf), ret)
        time.sleep(2)
        return len(buf)

    def truncate(self, path, length, fh=None):
        print('Real truncating ' + path)
        full_path = self._full_path(path)
        with open(full_path, 'r+') as f:
            f.truncate(length)

    def flush(self, path, fh):
        print('Real flushing ' + path)
        return os.fsync(fh)

    def release(self, path, fh):
        print('Real release ' + path)
        return os.close(fh)

    def fsync(self, path, fdatasync, fh):
        print('Real fsync ' + path)
        return self.flush(path, fh)


def main(mountpoint, root):
    FUSE(Passthrough(root), mountpoint, nothreads=True, foreground=True)

if __name__ == '__main__':
    print("Creating a virtual file system from " + sys.argv[1] + " at " + sys.argv[2])
    main(sys.argv[2], sys.argv[1])
