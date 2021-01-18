# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_WORDING := Bare Metal GCC
PACKAGE_HEADING := riscv64-unknown-elf-gcc
PACKAGE_VERSION := $(RISCV_GCC_VERSION)-$(FREEDOM_GCC_METAL_ID)$(EXTRA_SUFFIX)

# Source code directory references
SRCNAME_GCC := riscv-gcc
SRCPATH_GCC := $(SRCDIR)/$(SRCNAME_GCC)
SRCNAME_NEWLIB := riscv-newlib
SRCPATH_NEWLIB := $(SRCDIR)/$(SRCNAME_NEWLIB)
SRCNAME_BINUTILS := binutils-metal
SRCPATH_BINUTILS := $(SRCDIR)/$(SRCNAME_BINUTILS)
BARE_METAL_ABI := lp64d
BARE_METAL_ARCH := rv64imafdc
BARE_METAL_CMODEL := medany
BARE_METAL_TUPLE := riscv64-unknown-elf
BARE_METAL_CC_FOR_TARGET ?= $(BARE_METAL_TUPLE)-gcc
BARE_METAL_CXX_FOR_TARGET ?= $(BARE_METAL_TUPLE)-g++
BARE_METAL_CFLAGS_FOR_TARGET := -mcmodel=$(BARE_METAL_CMODEL)
BARE_METAL_CXXFLAGS_FOR_TARGET := -mcmodel=$(BARE_METAL_CMODEL)
BARE_METAL_BINUTILS = riscv-binutils

ifeq ($(EXTRA_OPTION),minimal)
BARE_METAL_MULTILIBS_GEN := \
	rv32emac-ilp32e-- \
	rv32imac-ilp32-- \
	rv32imafc-ilp32f-- \
	rv32imafdc-ilp32d-- \
	rv64imac-lp64-- \
	rv64imafc-lp64f-- \
	rv64imafdc-lp64d-- \
	--cmodel=compact
else ifeq ($(EXTRA_OPTION),basic)
BARE_METAL_MULTILIBS_GEN := \
	rv32e-ilp32e-- \
	rv32emac-ilp32e-- \
	rv32i-ilp32-- \
	rv32imac-ilp32-- \
	rv32if-ilp32f-- \
	rv32imafc-ilp32f-- \
	rv32ifd-ilp32d-- \
	rv32imafdc-ilp32d-- \
	rv64i-lp64-- \
	rv64imac-lp64-- \
	rv64if-lp64f-- \
	rv64imafc-lp64f-- \
	rv64ifd-lp64d-- \
	rv64imafdc-lp64d-- \
	--cmodel=compact
else
BARE_METAL_MULTILIBS_GEN := \
	rv32ec-ilp32e-- \
	rv32ec_zba_zbb-ilp32e-- \
	rv32eac-ilp32e-- \
	rv32eac_zba_zbb-ilp32e-- \
	rv32emc-ilp32e-- \
	rv32emc_zba_zbb-ilp32e-- \
	rv32emac-ilp32e-- \
	rv32emac_zba_zbb-ilp32e-- \
	rv32ic-ilp32-- \
	rv32ic_zba_zbb-ilp32-- \
	rv32iac-ilp32-- \
	rv32iac_zba_zbb-ilp32-- \
	rv32imc-ilp32-- \
	rv32imc_zba_zbb-ilp32-- \
	rv32imac-ilp32-- \
	rv32imac_zba_zbb-ilp32-- \
	rv32imfc-ilp32f-- \
	rv32imfc_zba_zbb-ilp32f-- \
	rv32imafc-ilp32f-- \
	rv32imafc_zba_zbb-ilp32f-- \
	rv32imfdc-ilp32d-- \
	rv32imfdc_zba_zbb-ilp32d-- \
	rv32imafdc-ilp32d-- \
	rv32imafdc_zba_zbb-ilp32d-- \
	rv64iac-lp64-- \
	rv64iac_zba_zbb-lp64-- \
	rv64imac-lp64-- \
	rv64imac_zba_zbb-lp64-- \
	rv64imafc-lp64f-- \
	rv64imafc_zba_zbb-lp64f-- \
	rv64imafdc-lp64d-- \
	rv64imafdc_zba_zbb-lp64d-- \
	--cmodel=compact
endif

# Some special package configure flags for specific targets
$(WIN64)-binutils-host          := --host=$(WIN64)
$(WIN64)-binutils-configure     := --with-included-gettext
$(WIN64)-gcc-host               := --host=$(WIN64)
$(WIN64)-gcc-configure          := --without-system-zlib
$(UBUNTU64)-binutils-host       := --host=x86_64-linux-gnu
$(UBUNTU64)-binutils-configure  := --with-included-gettext
$(UBUNTU64)-gcc-host            := --host=x86_64-linux-gnu
$(UBUNTU64)-gcc-configure       := --with-system-zlib
$(DARWIN)-binutils-configure    := --with-included-gettext
$(DARWIN)-gcc-configure         := --with-system-zlib
$(REDHAT)-binutils-configure    := --with-included-gettext
$(REDHAT)-gcc-configure         := --with-system-zlib

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

# The package build needs the tools in the PATH, and the windows build might use the ubuntu (native)
PATH := $(abspath $(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install-gcc/bin):$(PATH)
export PATH

# The Windows build requires the native toolchain.  The dependency is enforced
# here, PATH allows the tools to get access.
$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/source.stamp: \
	$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-gcc-stage2/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	mkdir -p $(dir $@)
	mkdir -p $(dir $@)/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle/features
	git log --format="[%ad] %s" > $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).changelog
	cp README.md $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).readme.md
	tclsh scripts/generate-feature-xml.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_GCC_VERSION)" "$(FREEDOM_GCC_METAL_ID)" $($@_TARGET) $(abspath $($@_INSTALL))
	tclsh scripts/generate-chmod755-sh.tcl $(abspath $($@_INSTALL))
	tclsh scripts/generate-site-xml.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_GCC_VERSION)" "$(FREEDOM_GCC_METAL_ID)" $($@_TARGET) $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle
	tclsh scripts/generate-bundle-mk.tcl $(abspath $($@_INSTALL)) RISCV_TAGS "$(FREEDOM_GCC_METAL_RISCV_TAGS)" TOOLS_TAGS "$(FREEDOM_GCC_METAL_TOOLS_TAGS)"
	cp $(abspath $($@_INSTALL))/bundle.mk $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle
	cd $($@_INSTALL); zip -rq $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle/features/$(PACKAGE_HEADING)_$(FREEDOM_GCC_METAL_ID)_$(RISCV_GCC_VERSION).jar *
	tclsh scripts/check-maximum-path-length.tcl $(abspath $($@_INSTALL)) "$(PACKAGE_HEADING)" "$(RISCV_GCC_VERSION)" "$(FREEDOM_GCC_METAL_ID)"
	tclsh scripts/check-same-name-different-case.tcl $(abspath $($@_INSTALL))
	rm -rf $(abspath $($@_BUILD))/install-gcc
	cp -a $(abspath $($@_INSTALL)) $(abspath $($@_BUILD))/install-gcc
	cat $($@_REC)/install-binutils-file-list | xargs rm -rf
	echo $(PATH)
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	-$(WIN64)-gcc -print-search-dirs | grep ^programs | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libwinpthread*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libgcc_s_seh*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libstdc*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libssp*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	tclsh scripts/check-naming-and-version-syntax.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_GCC_VERSION)" "$(FREEDOM_GCC_METAL_ID)"
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_REC)
	mkdir -p $($@_REC)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	git log > $($@_REC)/$(PACKAGE_HEADING)-git-commit.log
	cp .gitmodules $($@_REC)/$(PACKAGE_HEADING)-git-modules.log
	git remote -v > $($@_REC)/$(PACKAGE_HEADING)-git-remote.log
	git submodule status > $($@_REC)/$(PACKAGE_HEADING)-git-submodule.log
	cp -a $(SRCPATH_BINUTILS)/src/$(BARE_METAL_BINUTILS) $(SRCPATH_NEWLIB) $(SRCPATH_GCC) $(dir $@)
	cd $(dir $@)/riscv-gcc; ./contrib/download_prerequisites
	cd $(dir $@)/riscv-gcc/gcc/config/riscv; rm t-elf-multilib; ./multilib-generator $(BARE_METAL_MULTILIBS_GEN) > t-elf-multilib
	cp $(dir $@)/riscv-gcc/gcc/config/riscv/t-elf-multilib $($@_REC)/riscv-gcc-t-elf-multilib
	date > $@

# Reusing binutils build script across binutils-metal, gcc-metal and trace-decoder
include $(SRCPATH_BINUTILS)/scripts/Support.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/support.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
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
	# Workaround for CentOS random build fail issue
	#
	# Corresponding bugzilla entry on upstream:
	# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=92008
	touch $(abspath $($@_BUILD))/riscv-gcc/intl/plural.c
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
		--with-abi=$(BARE_METAL_ABI) \
		--with-arch=$(BARE_METAL_ARCH) \
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
	for bnls in `find $${bnl} -name crt0.o`; \
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
		--with-abi=$(BARE_METAL_ABI) \
		--with-arch=$(BARE_METAL_ARCH) \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" \
		CFLAGS_FOR_TARGET="-Os $(BARE_METAL_CFLAGS_FOR_TARGET)" \
		CXXFLAGS_FOR_TARGET="-Os $(BARE_METAL_CXXFLAGS_FOR_TARGET)" &>$($@_REC)/build-gcc-stage2-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-gcc-stage2-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-gcc-stage2-make-install.log
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-c++
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-g++
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-gcc
	date > $@

$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/test.stamp: \
		$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/launch.stamp
	mkdir -p $(dir $@)
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-c++ -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-g++ -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-gcc -v
	@echo "Finished testing $(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE).tar.gz tarball"
	date > $@
