#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
TOOLCHAIN_DIR=/usr/local/arm-cross-compiler/

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # PATCH for Ubuntu 22.04:
    sudo apt-get update && sudo apt-get install -y lsb-release && sudo apt-get clean all
    if lsb_release -d | grep -q "Ubuntu 22.04"; then
        echo "Patching files for Ubuntu 22.04 release"
        if [ -f "scripts/dtc/dtc-lexer.lex.c" ]; then
            sed -i '/YYLTYPE yylloc;/d' scripts/dtc/dtc-lexer.lex.c
        fi
        if [ -f "scripts/dtc/dtc-lexer.l" ]; then
            sed -i '/YYLTYPE yylloc;/d' scripts/dtc/dtc-lexer.l
        fi
    fi

    # TODO: Add your kernel build steps here
    echo "Building kernel..."
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper      # Deep clean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig     # prepare .config file
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all       # Build image
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules       # Building kernel modules
    make  ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs         # Building device tree
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p rootfs && cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
make distclean
make defconfig
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"


# TODO: Add library dependencies to rootfs
cd $OUTDIR/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter" | awk -F ': ' '{print $2}' | tr -d '[]' | awk -F '/' '{print $NF}' | xargs -I [] find $TOOLCHAIN_DIR -name [] -exec cp {} ${OUTDIR}/rootfs/lib64/ \;
cp ${OUTDIR}/rootfs/lib64/* ${OUTDIR}/rootfs/lib/
shared_libs=$(${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library" | awk -F ': ' '{print $2}' | tr -d '[]')
for lib in $shared_libs
do
    find $TOOLCHAIN_DIR -name $lib -exec cp {} ${OUTDIR}/rootfs/lib64/ \;
    find $TOOLCHAIN_DIR -name $lib -exec cp {} ${OUTDIR}/rootfs/lib/ \;
done

# TODO: Make device nodes

cd $OUTDIR/rootfs/
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1
# TODO: Clean and build the writer utility
echo "Removing the old writer utility and compiling as a native application"
cd $FINDER_APP_DIR
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cp -r * $OUTDIR/rootfs/home/
# TODO: Chown the root directory

sudo chown root:root -R $OUTDIR/rootfs
# TODO: Create initramfs.cpio.gz
cd $OUTDIR/rootfs
find . | cpio -H newc -ov --owner root:root > $OUTDIR/initramfs.cpio
gzip -f $OUTDIR/initramfs.cpio
