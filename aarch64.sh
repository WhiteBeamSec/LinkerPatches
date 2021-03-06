#!/bin/bash

tmp_dir=$(mktemp -d);
cd $tmp_dir;

if arch|grep -qE '^aarch64$'; then
  wget https://raw.githubusercontent.com/WhiteBeamSec/LinkerPatches/master/fix_profiling.patch -q;
  glibc_ver=$(echo /usr/lib/aarch64-linux-gnu/ld-*.so|sed -e 's/.*ld-\(.*\).so.*/\1/');
  wget "https://ftp.gnu.org/gnu/glibc/glibc-${glibc_ver}.tar.gz" -q -O - | tar xzf -; cd "glibc-${glibc_ver}";
  patch -s -p1 < ../fix_profiling.patch > /dev/null;
  (
    # Build
    mkdir ../build ../install &&
    cd ../build &&
    echo "WhiteBeam: Building patched linker (this will take about 5 minutes)" &&
    "../glibc-${glibc_ver}/configure" --prefix /usr > /dev/null 2>/dev/null &&
    make -j `nproc` default-rpath="/lib:/usr/lib" > /dev/null 2>/dev/null &&
    cp elf/ld.so /usr/lib/aarch64-linux-gnu/ld-${glibc_ver}-patched.so &&
    chown root:root /usr/lib/aarch64-linux-gnu/ld-${glibc_ver}-patched.so &&
    chmod 755 /usr/lib/aarch64-linux-gnu/ld-${glibc_ver}-patched.so &&
    ln -sf /usr/lib/aarch64-linux-gnu/ld-${glibc_ver}-patched.so /lib/ld-linux-aarch64.so.1;
  )
  rm -rf "${tmp_dir}";
fi
