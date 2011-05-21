###########################################################################
# Makefile header and help message
###########################################################################
help:
	@echo '                                                                                   '
	@echo ' Dawid Bazan <dawidbazan@gmail.com>                                                '
	@echo ' Dariusz Synowiec <devemouse@gmail.com>                                            '
	@echo '                                                                                   '
	@echo ' Last update on May 2011                                                           '
	@echo '                                                                                   '
	@echo ' Supported commands:                                                               '
	@echo '  make all   : Build software                                                      '
	@echo '  make clean : Clean out files generated by make all command                       '
	@echo '  make flash : Flash microcontroller with compiled software  - not implemented yet '
	@echo '  make doc   : Generate Doxygen documentation - not implemented yet                '
	@echo '  make help  : this help message                                                   '
	@echo '                                                                                   '
	@echo ' Files are generated in release folder                                             '

###########################################################################
# Tool chain files and shell commands
###########################################################################
TCHAIN_PREFIX = arm-none-eabi-
CC      = $(TCHAIN_PREFIX)gcc
CPP     = $(TCHAIN_PREFIX)g++
LD      = $(TCHAIN_PREFIX)ld
AR      = $(TCHAIN_PREFIX)ar
OBJCOPY = $(TCHAIN_PREFIX)objcopy
OBJDUMP = $(TCHAIN_PREFIX)objdump
SIZE    = $(TCHAIN_PREFIX)size
NM      = $(TCHAIN_PREFIX)nm

###########################################################################
# Output path definitions
###########################################################################
# Directory for output files (lst, obj, dep, elf, sym, map, hex, bin etc.)
OUTDIR = release
OBJDIR = $(OUTDIR)/obj
DEPDIR = $(OUTDIR)/dep
LSTDIR = $(OUTDIR)/lst
LOGDIR = $(OUTDIR)/log

# Target file name
TARGET = lpc1769

###########################################################################
# included makefiles, input path definitions
###########################################################################
include src/sources.mk
include src/rules.mk

# Add all subfolders with source codes and includes to the makefile path
VPATH = $(SUBDIRS)

###########################################################################
# Define all object files based on source files to be compiled
###########################################################################
COBJS      = $(addprefix $(OBJDIR)/,$(CSRCS:.c=.o))
COBJSARM   = $(addprefix $(OBJDIR)/,$(CSRCSARM:.c=.o))
CPPOBJS    = $(addprefix $(OBJDIR)/,$(CPPSRCS:.cpp=.o))
CPPOBJSARM = $(addprefix $(OBJDIR)/,$(CPPSRCSARM:.cpp=.o))
ASOBJS     = $(addprefix $(OBJDIR)/,$(ASRCS:.s=.o))
ASOBJSARM  = $(addprefix $(OBJDIR)/,$(ASRCSARM:.s=.o))
OBJS = $(COBJS) $(COBJSARM) $(CPPOBJS) $(CPPOBJSARM) $(ASOBJS) $(ASOBJSARM)

###########################################################################
# Compiler/Linker rules selection depending on file group
###########################################################################
$(COBJS)      : CFLAGS   = @$(CFLAGS_SUB) @$(CONLYFLAGS_SUB) $(THUMB) $(LSTGEN) $(DEPGEN)
$(CPPOBJS)    : CPPFLAGS = @$(CFLAGS_SUB) @$(CPPFLAGS_SUB) $(THUMB) $(LSTGEN) $(DEPGEN)
$(ASOBJS)     : ASFLAGS  = @$(ASFLAGS_SUB) $(THUMB) $(LSTGEN) $(DEPGEN)
$(COBJSARM)   : CFLAGS   = @$(CFLAGS_SUB) @$(CONLYFLAGS_SUB) $(LSTGEN) $(DEPGEN)
$(CPPOBJSARM) : CPPFLAGS = @$(CFLAGS_SUB) @$(CPPFLAGS_SUB) $(LSTGEN) $(DEPGEN)
$(ASOBJSARM)  : ASFLAGS  = @$(ASFLAGS_SUB) $(LSTGEN) $(DEPGEN)
LDFLAGS = @$(LDFLAGS_SUB)

###########################################################################
# Targets
###########################################################################
# Default target.
all: gccversion makefile createdirs build size
	@echo '---- $(TARGET) built:'

# Create output directories.
createdirs:
	-@mkdir $(OUTDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(DEPDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(LSTDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(OBJDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(LOGDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(DOCDIR) 2>/dev/null || echo "" >/dev/null

# Display compiler version information.
gccversion:
	@$(CC) --version

# Build all outputs
build: $(FLAGS_SUB) elf hex bin lss sym

# Output files to be build
elf: $(OUTDIR)/$(TARGET).elf
lss: $(OUTDIR)/$(TARGET).lss 
sym: $(OUTDIR)/$(TARGET).sym
hex: $(OUTDIR)/$(TARGET).hex
bin: $(OUTDIR)/$(TARGET).bin

# Calculate sizes of sections. Options:
#  Format Compatibility(A-system default, B-Berkeley's similar)
#  Size data type(d-digital, o-octal, h-hexadecimal)
size: build
	@echo ' '	
	@$(SIZE) -A -d --totals $(OUTDIR)/$(TARGET).elf

# Target: clean project.
clean:
	@echo '---- Cleaning:'
	$(RM) $(OUTDIR)/$(TARGET).map
	$(RM) $(OUTDIR)/$(TARGET).elf
	$(RM) $(OUTDIR)/$(TARGET).hex
	$(RM) $(OUTDIR)/$(TARGET).bin
	$(RM) $(OUTDIR)/$(TARGET).sym
	$(RM) $(OUTDIR)/$(TARGET).lss
	$(RM) $(OBJDIR)/*.o >/dev/null 2>&1
	$(RM) $(LSTDIR)/*.lst >/dev/null 2>&1
	$(RM) $(DEPDIR)/*.d >/dev/null 2>&1
	$(RM) $(FLAGS_SUB) 
	$(RM) $(LOGDIR)/*.log >/dev/null 2>&1
	@echo ' '
	@echo '---- Cleaned'

# TBD: flash
# use following dependencies after implementing this target
#flash: $(OUTDIR)/$(TARGET).elf
flash:
	$(error Flashing with OPENOCD NOT IMPLEMETED)
	#$(OOCD_EXE) $(OOCD_CL)

doc: createdirs
	@doxygen doxyfile 2>&1
	@cat release/log/doxygen.log

###########################################################################
# Build release files
###########################################################################
# Create final output file (.hex) from ELF output file.
#  -O   # TODO: describe this option
#  ihex # TODO: describe this option
$(OUTDIR)/%.hex: $(OUTDIR)/%.elf
	@echo '  OBJCOPY  $(+F) > $(@F)  - hex file'
	@$(OBJCOPY) -O ihex $< $@
	
# Create final output file (.bin) from ELF output file.
#  -O     # TODO: describe this option
#  binary # TODO: describe this option
$(OUTDIR)/%.bin: $(OUTDIR)/%.elf
	@echo '  OBJCOPY  $(+F) > $(@F)  - binary file'
	@$(OBJCOPY) -O binary $< $@

# Create extended listing file/disassambly from ELF output file.
# using objdump testing: option -C
#  -h # TODO: describe this option
#  -S # TODO: describe this option
#  -C # TODO: describe this option
#  -r # TODO: describe this option
$(OUTDIR)/%.lss: $(OUTDIR)/%.elf
	@echo '  OBJDUMP  $(+F) > $(@F)  - extended listing/disassembly file'
	@$(OBJDUMP) -h -S -C -r $< > $@

# Create a symbol table from ELF output file.
#  -n # TODO: describe this option
$(OUTDIR)/%.sym: $(OUTDIR)/%.elf
	@echo '  NM       $(+F) > $(@F)  - symbol file'
	@$(NM) -n $< > $@

# Link: create ELF output file from object files.
$(OUTDIR)/%.elf: $(OBJS) $(FLAGS_SUB)
	@echo ' '
	@echo '  LINK     $(filter %.o,$(+F)) > $(@F)'
	@$(LD) $(LDFLAGS) $(OBJS) --output $@ >> $(LOGDIR)/$(TARGET).log

###########################################################################
# Compile
###########################################################################
$(OBJDIR)/%.o: %.s
	@echo '  AS  $(+F) > $(@F)'
	@$(AS) -c $(ASFLAGS) $< -o $@; \
	sed -e 's,\($*\)\.o[ :]*,\1.o $(*F).d : ,g' < $(*F).tmp > $(DEPDIR)/$(*F).d; \
	$(RM) -f $(*F).tmp >> $(LOGDIR)/$(TARGET).log

$(OBJDIR)/%.o: %.c
	@echo '  CC  $(+F) > $(@F)'
	@$(CC) -c $(CFLAGS) $< -o $@; \
	sed -e 's,\($*\)\.o[ :]*,\1.o $(*F).d : ,g' < $(*F).tmp > $(DEPDIR)/$(*F).d; \
	$(RM) -f $(*F).tmp >> $(LOGDIR)/$(TARGET).log

$(OBJDIR)/%.o: %.cpp
	@echo '  CPP $(+F) > $(@F)'
	@$(CPP) -c $(CPPFLAGS) $< -o $@; \
	sed -e 's,\($*\)\.o[ :]*,\1.o $(*F).d : ,g' < $(*F).tmp > $(DEPDIR)/$(*F).d; \
	$(RM) -f $(*F).tmp >> $(LOGDIR)/$(TARGET).log

###########################################################################
# Options for OpenOCD flash-programming
###########################################################################
# see openocd.pdf/openocd.texi for further information
############################################################TBD: adjust to linux/lpc1769
OOCD_LOADFILE+=$(OUTDIR)/$(TARGET).elf
## Open OCD exec file
OOCD_EXE=openocd
## debug level
OOCD_CL=-d0
#OOCD_CL=-d3
# interface and board/target settings (using the OOCD target-library here)
## OOCD_CL+=-f interface/jtagkey2.cfg -f target/stm32.cfg
OOCD_CL+=-f interface/jtagkey.cfg -f target/stm32.cfg
# initialize
OOCD_CL+=-c init
# enable "fast mode" - can be disabled for tests
OOCD_CL+=-c "fast enable"
# show the targets
OOCD_CL+=-c targets
# commands to prepare flash-write
OOCD_CL+= -c "reset halt"
# increase JTAG frequency a little bit - can be disabled for tests
OOCD_CL+= -c "jtag_khz 1200"
# flash-write and -verify
OOCD_CL+=-c "flash write_image erase $(OOCD_LOADFILE)" -c "verify_image $(OOCD_LOADFILE)"
# reset target
OOCD_CL+=-c "reset run"
# terminate OOCD after programming
OOCD_CL+=-c shutdown

-include $(DEPDIR)/*

###########################################################################
# Listing of phony targets and default target.
###########################################################################
.PHONY : all help size gccversion build elf hex bin lss sym clean createdirs
.DEFAULT_GOAL := all
