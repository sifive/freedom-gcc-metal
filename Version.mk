# Version number, which should match the official version of the tool we are building
RISCV_GCC_VERSION := 10.2.0

# Customization ID, which should identify the customization added to the original by SiFive
FREEDOM_GCC_METAL_ID := dev-$(shell cd src/riscv-gcc/ && git log --pretty=format:'%h' -1)-$(shell cd src/riscv-newlib/ && git log --pretty=format:'%h' -1)

# Characteristic tags, which should be usable for matching up providers and consumers
FREEDOM_GCC_METAL_RISCV_TAGS = rv32i rv64i m a f d c v zfh zba zbb
FREEDOM_GCC_METAL_TOOLS_TAGS = gcc10-metal
