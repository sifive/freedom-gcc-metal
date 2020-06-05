# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := freedom-gcc-metal
PACKAGE_VERSION := $(RISCV_GCC_VERSION)-$(FREEDOM_GCC_METAL_ID)

# Source code directory references
SRCNAME_GCC := riscv-gcc
SRCPATH_GCC := $(SRCDIR)/$(SRCNAME_GCC)
SRCNAME_BINUTILS := riscv-binutils
SRCPATH_BINUTILS := $(SRCDIR)/$(SRCNAME_BINUTILS)
BARE_METAL_ABI := lp64d
BARE_METAL_ARCH := rv64imafdc
BARE_METAL_CMODEL := medany
BARE_METAL_TUPLE := riscv64-unknown-elf
BARE_METAL_CC_FOR_TARGET ?= $(BARE_METAL_TUPLE)-gcc
BARE_METAL_CXX_FOR_TARGET ?= $(BARE_METAL_TUPLE)-g++
BARE_METAL_CFLAGS_FOR_TARGET := -mcmodel=$(BARE_METAL_CMODEL)
BARE_METAL_CXXFLAGS_FOR_TARGET := -mcmodel=$(BARE_METAL_CMODEL)
BARE_METAL_MULTILIBS_GEN := \
	rv32e-ilp32e--c \
	rv32ea-ilp32e--m \
	rv32em-ilp32e--c \
	rv32eac-ilp32e-- \
	rv32emac-ilp32e-- \
	rv32i-ilp32--c,f,fc,fd,fdc \
	rv32ia-ilp32-rv32ima,rv32iaf,rv32imaf,rv32iafd,rv32imafd- \
	rv32im-ilp32--c,f,fc,fd,fdc \
	rv32iac-ilp32--f,fd \
	rv32imac-ilp32-rv32imafc,rv32imafdc- \
	rv32if-ilp32f--c,d,dc \
	rv32iaf-ilp32f--c,d,dc \
	rv32imf-ilp32f--d \
	rv32imaf-ilp32f-rv32imafd- \
	rv32imfc-ilp32f--d \
	rv32imafc-ilp32f-rv32imafdc- \
	rv32ifd-ilp32d--c \
	rv32imfd-ilp32d--c \
	rv32iafd-ilp32d-rv32imafd,rv32iafdc- \
	rv32imafdc-ilp32d-- \
	rv64i-lp64--c,f,fc,fd,fdc \
	rv64ia-lp64-rv64ima,rv64iaf,rv64imaf,rv64iafd,rv64imafd- \
	rv64im-lp64--c,f,fc,fd,fdc \
	rv64iac-lp64--f,fd \
	rv64imac-lp64-rv64imafc,rv64imafdc- \
	rv64if-lp64f--c,d,dc \
	rv64iaf-lp64f--c,d,dc \
	rv64imf-lp64f--d \
	rv64imaf-lp64f-rv64imafd- \
	rv64imfc-lp64f--d \
	rv64imafc-lp64f-rv64imafdc- \
	rv64ifd-lp64d--c \
	rv64imfd-lp64d--c \
	rv64iafd-lp64d-rv64imafd,rv64iafdc- \
	rv64imafdc-lp64d--

# Some special package configure flags for specific targets
$(WIN64)-gcc-host           := --host=$(WIN64)
$(WIN64)-gcc-configure      := --without-system-zlib
$(UBUNTU64)-gcc-host        := --host=x86_64-linux-gnu
$(UBUNTU64)-gcc-configure   := --with-system-zlib
$(DARWIN)-gcc-configure     := --with-system-zlib
$(REDHAT)-gcc-configure     := --with-system-zlib

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp
	mkdir -p $(dir $@)
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_REC)
	mkdir -p $($@_REC)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp -a $(SRCPATH_BINUTILS) $(SRCPATH_GCC) $(dir $@)
	cd $(dir $@)/riscv-gcc; ./contrib/download_prerequisites
	cd $(dir $@)/riscv-gcc/gcc/config/riscv; rm t-elf-multilib; ./multilib-generator $(BARE_METAL_MULTILIBS_GEN) > t-elf-multilib
	cp $(dir $@)/riscv-gcc/gcc/config/riscv/riscv-gcc-t-elf-multilib $($@_REC)
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) ./configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gcc-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GCC Metal $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-werror \
		--disable-gdb \
		--disable-sim \
		--disable-libdecnumber \
		--disable-libreadline \
		--with-included-gettext \
		--with-mpc=no \
		--with-mpfr=no \
		--with-gmp=no \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" &>$($@_REC)/$(SRCNAME_BINUTILS)-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/$(SRCNAME_BINUTILS)-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/$(SRCNAME_BINUTILS)-make-install.log
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cd $(dir $@) && $(abspath $($@_BUILD))/riscv-gcc/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gcc-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GCC Metal $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-shared \
		--disable-threads \
		--disable-tls \
		--enable-languages=c,c++ \
		--with-newlib \
		--with-sysroot=$(abspath $($@_INSTALL))/$(BARE_METAL_TUPLE) \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libgomp \
		--disable-nls \
		--disable-tm-clone-registry \
		--src=../riscv-gcc \
		$($($@_TARGET)-gcc-configure) \
		--enable-checking=yes \
		--enable-multilib \
		--with-abi=$(BARE_METAL_WITH_ABI) \
		--with-arch=$(BARE_METAL_WITH_ARCH) \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" \
		CFLAGS_FOR_TARGET="-Os $(BARE_METAL_CFLAGS_FOR_TARGET)" \
		CXXFLAGS_FOR_TARGET="-Os $(BARE_METAL_CXXFLAGS_FOR_TARGET)" &>$($@_REC)/build-gcc-stage1-make-configure.log
	$(MAKE) -C $(dir $@) all-gcc &>$($@_REC)/build-gcc-stage1-make-build.log
	$(MAKE) -C $(dir $@) -j1 install-gcc &>$($@_REC)/build-gcc-stage1-make-install.log
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cd $(dir $@) && $(abspath $($@_BUILD))/riscv-gcc/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gcc-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GCC Metal $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-shared \
		--disable-threads \
		--enable-languages=c,c++ \
		--enable-tls \
		--with-newlib \
		--with-sysroot=$(abspath $($@_INSTALL))/$(NEWLIB_TUPLE) \
		--with-native-system-header-dir=/include \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libgomp \
		--disable-nls \
		--disable-tm-clone-registry \
		--src=../riscv-gcc \
		$($($@_TARGET)-gcc-configure) \
		--enable-checking=yes \
		--enable-multilib \
		--with-abi=$(BARE_METAL_WITH_ABI) \
		--with-arch=$(BARE_METAL_WITH_ARCH) \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" \
		CFLAGS_FOR_TARGET="-Os $(BARE_METAL_CFLAGS_FOR_TARGET)" \
		CXXFLAGS_FOR_TARGET="-Os $(BARE_METAL_CXXFLAGS_FOR_TARGET)" &>$($@_REC)/build-gcc-stage2-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-gcc-stage2-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-gcc-stage2-make-install.log
	date > $@

# The Windows build requires the native toolchain.  The dependency is enforced
# here, PATH allows the tools to get access.
$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp: \
	$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
