export BASEDIR=${1}
shift
export TYPE=${1}
shift

if [[ x"$BASEDIR" = x"" ]]; then
    export BASEDIR=marvell_fw
fi
export BASEDIR=${PWD}/${BASEDIR}

if [[ x"$TYPE" = x"" ]]; then
    export TYPE=RELEASE
fi

if [ ! -d "${BASEDIR}" ]; then
    mkdir ${BASEDIR}
fi

cd ${BASEDIR}

if [ ! -d "gcc5" ]; then
    mkdir gcc5
    pushd gcc5
    wget https://releases.linaro.org/components/toolchain/binaries/7.2-2017.11/aarch64-linux-gnu/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu.tar.xz
    tar -xf gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu.tar.xz
    popd
fi
export GCC5_AARCH64_PREFIX=${BASEDIR}/gcc5/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-

if [ ! -d "uefi-marvell" ]; then
    git clone https://github.com/andreiw/MacchiatoBin-edk2 uefi-marvell
    pushd uefi-marvell
    git checkout -b uefi-2.7-armada-18.12-andreiw origin/uefi-2.7-armada-18.12-andreiw
    popd
fi

pushd uefi-marvell
export WORKSPACE=${PWD}
export PACKAGES_PATH=${PWD}:${PWD}/edk2-platforms
BUILD_COMMIT=`git rev-parse --short HEAD`
BUILD_DATE=`date +%m/%d/%Y`
COMMON_OPTS="-DBUILD_DATE=$BUILD_DATE -DBUILD_COMMIT=$BUILD_COMMIT -D MVEBU_PCIE_ECAM_WA -D INCLUDE_TFTP_COMMAND"
make -C BaseTools
source edksetup.sh
build -a AARCH64 -t GCC5 -b ${TYPE} -p Platform/SolidRun/Armada80x0McBin/Armada80x0McBin.dsc ${COMMON_OPTS}
export BL33=${BASEDIR}/uefi-marvell/Build/Armada80x0McBin-AARCH64/${TYPE}_GCC5/FV/ARMADA_EFI.fd
popd

if [ ! -d "mv-ddr" ]; then
    mkdir mv-ddr
    pushd mv-ddr
    git clone https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell.git .
    git checkout -b mv_ddr-armada-18.09 origin/mv_ddr-armada-18.09
    popd
fi

if [ ! -d "binaries-marvell" ]; then
    git clone https://github.com/MarvellEmbeddedProcessors/binaries-marvell.git
    pushd binaries-marvell
    git checkout -b binaries-marvell-armada-18.06 remotes/origin/binaries-marvell-armada-18.06
    popd
fi
export SCP_BL2=${BASEDIR}/binaries-marvell/mrvl_scp_bl2_mss_ap_cp1_a8040.img

if [ ! -d "atf" ]; then
    mkdir atf
    pushd atf
    git clone https://github.com/MarvellEmbeddedProcessors/atf-marvell.git .
    git checkout -b atf-v1.5-armada-18.09 origin/atf-v1.5-armada-18.09
    popd
fi

pushd atf
export ARCH=arm64
export CROSS_COMPILE=${BASEDIR}/gcc5/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
make USE_COHERENT_MEM=0 LOG_LEVEL=20 MV_DDR_PATH=${BASEDIR}/mv-ddr PLAT=a80x0_mcbin all fip
echo
echo
echo Built file in ${PWD}/build/a80x0_mcbin/release/flash-image.bin
echo
echo
popd
