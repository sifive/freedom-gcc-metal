# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := freedom-gcc-metal
PACKAGE_VERSION := $(RISCV_GCC_VERSION)-$(FREEDOM_GCC_METAL_ID)$(EXTRA_SUFFIX)

# Source code directory references
SRCNAME_GCC := riscv-gcc
SRCPATH_GCC := $(SRCDIR)/$(SRCNAME_GCC)
SRCNAME_NEWLIB := riscv-newlib
SRCPATH_NEWLIB := $(SRCDIR)/$(SRCNAME_NEWLIB)
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

ifeq ($(EXTRA_OPTION),minimal)
BARE_METAL_MULTILIBS_GEN := \
	rv32emac-ilp32e-- \
	rv32imac-ilp32-- \
	rv32imafc-ilp32f-- \
	rv32imafdc-ilp32d-- \
	rv64imac-lp64-- \
	rv64imafc-lp64f-- \
	rv64imafdc-lp64d--
else ifeq ($(EXTRA_OPTION),basic)
BARE_METAL_MULTILIBS_GEN := \
	rv32e-ilp32e--m,a,ma,c,mc,ac \
	rv32emac-ilp32e-- \
	rv32i-ilp32--m,a,ma,c,mc,ac \
	rv32imac-ilp32-- \
	rv32if-ilp32f--mf,af,maf,fc,mfc,afc \
	rv32imafc-ilp32f-- \
	rv32ifd-ilp32d--mfd,afd,mafd,fdc,mfdc,afdc \
	rv32imafdc-ilp32d-- \
	rv64i-lp64--m,a,ma,c,mc,ac \
	rv64imac-lp64-- \
	rv64if-lp64f--mf,af,maf,fc,mfc,afc \
	rv64imafc-lp64f-- \
	rv64ifd-lp64d--mfd,afd,mafd,fdc,mfdc,afdc \
	rv64imafdc-lp64d--
else
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
endif

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

# The package build needs the tools in the PATH, and the windows build might use the ubuntu (native)
PATH := $(abspath $(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install-binutils/bin):$(PATH)
export PATH

# The Windows build requires the native toolchain.  The dependency is enforced
# here, PATH allows the tools to get access.
$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp: \
	$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	mkdir -p $(dir $@)
	git log > $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).commitlog
	cp README.md $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).readme.md
	rm -rf $(abspath $($@_BUILD))/install-binutils
	cp -a $(abspath $($@_INSTALL)) $(abspath $($@_BUILD))/install-binutils
	cat $($@_REC)/install-binutils-file-list | xargs rm -rf
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
	cp -a $(SRCPATH_BINUTILS) $(SRCPATH_NEWLIB) $(SRCPATH_GCC) $(dir $@)
	cd $(dir $@)/riscv-gcc; ./contrib/download_prerequisites
	cd $(dir $@)/riscv-gcc/gcc/config/riscv; rm t-elf-multilib; ./multilib-generator $(BARE_METAL_MULTILIBS_GEN) > t-elf-multilib
	cp $(dir $@)/riscv-gcc/gcc/config/riscv/t-elf-multilib $($@_REC)/riscv-gcc-t-elf-multilib
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) $(abspath $($@_BUILD))/$(SRCNAME_BINUTILS)/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gcc-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive GCC-Metal $(PACKAGE_VERSION)" \
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
		CXXFLAGS="-O2" &>$($@_REC)/build-binutils-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-binutils-make-build.log
	$(MAKE) -C $(dir $@) -j1 install &>$($@_REC)/build-binutils-make-install.log
	find $(abspath $($@_INSTALL)) -type f > $($@_REC)/install-binutils-file-list
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp
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
		--with-pkgversion="SiFive GCC-Metal $(PACKAGE_VERSION)" \
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

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	@echo "PATH: $(PATH)"
	cd $(dir $@) && $(abspath $($@_BUILD))/riscv-newlib/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gcc-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--enable-newlib-io-long-double \
		--enable-newlib-io-long-long \
		--enable-newlib-io-c99-formats \
		--enable-newlib-register-fini \
		CFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE $(BARE_METAL_CFLAGS_FOR_TARGET)" \
		CXXFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE $(BARE_METAL_CXXFLAGS_FOR_TARGET)" &>$($@_REC)/build-newlib-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-newlib-make-build.log
	$(MAKE) -C $(dir $@) -j1 install &>$($@_REC)/build-newlib-make-install.log
# These install multiple copies of the same docs into the same destination
# for a multilib build.  So we must not parallelize them.
# TODO: Rewrite so that we only install one copy of the docs.
	$(MAKE) -j1 -C $(dir $@) install-pdf install-html &>$($@_REC)/build-newlib-make-install-doc.log
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib-nano/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage1/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib-nano/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib-nano/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib-nano/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib-nano/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	@echo "PATH: $(PATH)"
	cd $(dir $@) && $(abspath $($@_BUILD))/riscv-newlib/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-gcc-host) \
		--prefix=$(abspath $($@_BUILD)/build-newlib-nano-install) \
		--enable-newlib-reent-small \
		--disable-newlib-fvwrite-in-streamio \
		--disable-newlib-fseek-optimization \
		--disable-newlib-wide-orient \
		--enable-newlib-nano-malloc \
		--disable-newlib-unbuf-stream-opt \
		--enable-lite-exit \
		--enable-newlib-global-atexit \
		--enable-newlib-nano-formatted-io \
		--disable-newlib-supplied-syscalls \
		--disable-nls \
		CFLAGS_FOR_TARGET="-Os -ffunction-sections -fdata-sections $(BARE_METAL_CFLAGS_FOR_TARGET)" \
		CXXFLAGS_FOR_TARGET="-Os -ffunction-sections -fdata-sections $(BARE_METAL_CXXFLAGS_FOR_TARGET)" &>$($@_REC)/build-newlib-nano-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-newlib-nano-make-build.log
	$(MAKE) -C $(dir $@) -j1 install &>$($@_REC)/build-newlib-nano-make-install.log
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib-nano-install/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib-nano/build.stamp \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib-nano-install/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib-nano-install/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib-nano-install/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-newlib-nano-install/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
# Copy nano library files into newlib install dir.
	set -e; \
	bnl="$(abspath $($@_BUILD))/build-newlib-nano-install/$(BARE_METAL_TUPLE)/lib"; \
	inl="$(abspath $($@_INSTALL))/$(BARE_METAL_TUPLE)/lib"; \
	for bnlc in `find $${bnl} -name libc.a`; \
	do \
		inlc=`echo $${bnlc} | $(SED) -e "s:$${bnl}::" | $(SED) -e "s:libc\.a:libc_nano.a:g"`; \
		cp $${bnlc} $${inl}$${inlc}; \
	done; \
	for bnlm in `find $${bnl} -name libm.a`; \
	do \
		inlm=`echo $${bnlm} | $(SED) -e "s:$${bnl}::" | $(SED) -e "s:libm\.a:libm_nano.a:g"`; \
		cp $${bnlm} $${inl}$${inlm}; \
	done; \
	for bnlg in `find $${bnl} -name libg.a`; \
	do \
		inlg=`echo $${bnlg} | $(SED) -e "s:$${bnl}::" | $(SED) -e "s:libg\.a:libg_nano.a:g"`; \
		cp $${bnlg} $${inl}$${inlg}; \
	done; \
	for bnls in `find $${bnl} -name libgloss.a`; \
	do \
		inls=`echo $${bnls} | $(SED) -e "s:$${bnl}::" | $(SED) -e "s:libgloss\.a:libgloss_nano.a:g"`; \
		cp $${bnls} $${inl}$${inls}; \
	done
	for bnls in `find $${bnl} -name crt0.0`; \
	do \
		inls=`echo $${bnls} | $(SED) -e "s:$${bnl}::"`; \
		cp $${bnls} $${inl}$${inls}; \
	done
# Copy nano header files into newlib install dir.
	mkdir -p $(abspath $($@_INSTALL))/$(BARE_METAL_TUPLE)/include/newlib-nano; \
	cp $(abspath $($@_BUILD))/build-newlib-nano-install/$(BARE_METAL_TUPLE)/include/newlib.h \
		$(abspath $($@_INSTALL))/$(BARE_METAL_TUPLE)/include/newlib-nano/newlib.h; \
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-newlib-nano-install/build.stamp
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
		--with-pkgversion="SiFive GCC-Metal $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-shared \
		--disable-threads \
		--enable-languages=c,c++ \
		--enable-tls \
		--with-newlib \
		--with-sysroot=$(abspath $($@_INSTALL))/$(BARE_METAL_TUPLE) \
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

$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/test.stamp: \
		$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/launch.stamp
	mkdir -p $(dir $@)
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-c++ -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-g++ -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-gcc -v
	@echo "Finished testing $(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE).tar.gz tarball"
	date > $@
