###########################################################################
# Dawid Bazan <dawidbazan@gmail.com>
#
# makefile
#
# Supported commands:
# make all = Build software
# make clean = Clean out files generated by make all command
# make flash = Flash microcontroller with compiled software
#
###########################################################################
include sources.mk
include rules.mk

###########################################################################
# Tool chain files and shell commands
###########################################################################
TCHAIN_PREFIX = arm-none-eabi-
CC      = $(TCHAIN_PREFIX)gcc
CPP     = $(TCHAIN_PREFIX)g++
LD      = $(TCHAIN_PREFIX)g++
AR      = $(TCHAIN_PREFIX)ar
OBJCOPY = $(TCHAIN_PREFIX)objcopy
OBJDUMP = $(TCHAIN_PREFIX)objdump
SIZE    = $(TCHAIN_PREFIX)size
NM      = $(TCHAIN_PREFIX)nm

###########################################################################
# Target name and input/output path definitions
###########################################################################
# Directory for output files (lst, obj, dep, elf, sym, map, hex, bin etc.)
OUTDIR = release
OUTOBJDIR = $(OUTDIR)/obj
OUTDEPDIR = $(OUTDIR)/dep
OUTLSTDIR = $(OUTDIR)/lst

# Add all subfolders with source codes and includes to the makefile path
VPATH = $(SUBDIRS)

# Define all object files based on source files to be compiled
OBJS = $(addprefix $(OUTOBJDIR)/, $(CSRCS:.c=.o) $(CSRCSARM:.c=.o) \
	   $(CPPSRCS:.cpp=.o) $(CPPSRCSARM:.cpp=.o) $(ASRCS:.s=.o) \
	   $(ASRCSARM:.s=.o))

# Target file name
TARGET = lpc1769

###########################################################################
# Targets
###########################################################################
# Listing of phony targets.
.PHONY : all begin end size gccversion build elf hex bin lss sym clean createdirs

# Default target.
all: begin createdirs gccversion $(CFLAGS_SUB) build size end
	
# Output files to be build
elf: $(OUTDIR)/$(TARGET).elf
lss: $(OUTDIR)/$(TARGET).lss 
sym: $(OUTDIR)/$(TARGET).sym
hex: $(OUTDIR)/$(TARGET).hex
bin: $(OUTDIR)/$(TARGET).bin

# Build all outputs
build: elf hex bin lss sym

# Create output directories.
createdirs:
	-@mkdir $(OUTDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(OUTDEPDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(OUTLSTDIR) 2>/dev/null || echo "" >/dev/null
	-@mkdir $(OUTOBJDIR) 2>/dev/null || echo "" >/dev/null
	
# Begin message
begin:
	@echo '!!!!!!!!!!!!!!!!!!! Building target !!!!!!!!!!!!!!!!!!!'
	@echo ' '

# End message
end:
	@echo ' '
	@echo '!!!!!!!!!!!!!!!!!!! Finished building target !!!!!!!!!!!!!!!!!!!'

# Calculate sizes of sections
size:
	@echo ' '	
	@echo '---- Calculating size of sections in elf file:'
	$(SIZE) -A -x $(OUTDIR)/$(TARGET).elf
	
# Display compiler version information.
gccversion : 
	@$(CC) --version

# Target: clean project.
clean:
	@echo ' '
	@echo '!!!!!!!!!!!!!!!!!!! Removing target !!!!!!!!!!!!!!!!!!!'
	$(RM) $(OUTDIR)/$(TARGET).map
	$(RM) $(OUTDIR)/$(TARGET).elf
	$(RM) $(OUTDIR)/$(TARGET).hex
	$(RM) $(OUTDIR)/$(TARGET).bin
	$(RM) $(OUTDIR)/$(TARGET).sym
	$(RM) $(OUTDIR)/$(TARGET).lss
	$(RM) $(OUTOBJDIR)/*.o >nul 2>&1
	$(RM) $(OUTLSTDIR)/*.lst >nul 2>&1
	$(RM) $(OUTDEPDIR)/*.o.d >nul 2>&1
#	$(RM) $(CFLAGS_SUB) 
	@echo '!!!!!!!!!!!!!!!!!!! Target removed !!!!!!!!!!!!!!!!!!!'
	
# TBD: flash
flash: #$(OUTDIR)/$(TARGET).elf
	@echo "Flashing with OPENOCD"
	#$(OOCD_EXE) $(OOCD_CL)

###########################################################################
# Build release files
###########################################################################
# Create final output file (.hex) from ELF output file.
%.hex: %.elf
	@echo ' '
	@echo '---- Creating HEX file: ' $@
	$(OBJCOPY) -O ihex $< $@
	
# Create final output file (.bin) from ELF output file.
%.bin: %.elf
	@echo ' '
	@echo '---- Creating BINARY file: ' $@
	$(OBJCOPY) -O binary $< $@

# Create extended listing file/disassambly from ELF output file.
# using objdump testing: option -C
%.lss: %.elf
	@echo ' '
	@echo '---- Creating Extended Listing/Disassembly file: ' $@
	$(OBJDUMP) -h -S -C -r $< > $@

# Create a symbol table from ELF output file.
%.sym: %.elf
	@echo ' '
	@echo '---- Creating SYMBOL file: ' $@
	$(NM) -n $< > $@

# Link: create ELF output file from object files.
%.elf:  $(OBJS)
	@echo ' '
	@echo '---- Linking, creating ELF file: ' $@
	$(LD)  $(CFLAGS) $(OBJS) --output $@ $(LDFLAGS)

###########################################################################
# Compile
###########################################################################
# Assembler: create object files from assembler source files.
define ASSEMBLE_TEMPLATE
$(OUTOBJDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo ' '
	@echo '---- Assembling: ' $$< to $$@
	$(CC) -c -mthumb -mthumb-interwork $$(ASFLAGS) $$< -o $$@ 
endef
$(foreach src, $(ASRCS), $(eval $(call ASSEMBLE_TEMPLATE, $(src)))) 

# Assemble: create object files from assembler source files. ARM-only
define ASSEMBLE_ARM_TEMPLATE
$(OUTOBJDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo ' '
	@echo '---- Assembling ARM-only: ' $$< to $$@
	$(CC) -c $$(ASFLAGS) $$< -o $$@ 
endef
$(foreach src, $(ASRCSARM), $(eval $(call ASSEMBLE_ARM_TEMPLATE, $(src)))) 

# Compile: create object files from C source files.
define COMPILE_C_TEMPLATE
$(OUTOBJDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo ' '
	@echo '---- Compiling C: ' $$< to $$@
	$(CC) -c -mthumb $$(CFLAGS) $$(CONLYFLAGS) $$< -o $$@ 
endef
$(foreach src, $(CSRCS), $(eval $(call COMPILE_C_TEMPLATE, $(src)))) 
#%.o : %.c Makefile $(CFLAGS)
#	$(CC) $(CFLAGS) -c -o $*.o $<
	
# Compile: create object files from C source files. ARM-only
define COMPILE_C_ARM_TEMPLATE
$(OUTOBJDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo ' '
	@echo '---- Compiling C ARM-only: ' $$< to $$@
	$(CC) -c $$(CFLAGS) $$(CONLYFLAGS) $$< -o $$@ 
endef
$(foreach src, $(CSRCSARM), $(eval $(call COMPILE_C_ARM_TEMPLATE, $(src)))) 


# Compile: create object files from C++ source files.
define COMPILE_CPP_TEMPLATE
$(OUTOBJDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo ' '
	@echo '---- Compiling C++: ' $$< to $$@
	$(CC) -c -mthumb $$(CFLAGS) $$(CPPFLAGS) $$< -o $$@ 
endef
$(foreach src, $(CPPSRCS), $(eval $(call COMPILE_CPP_TEMPLATE, $(src)))) 

# Compile: create object files from C++ source files. ARM-only
define COMPILE_CPP_ARM_TEMPLATE
$(OUTOBJDIR)/$(notdir $(basename $(1))).o : $(1)
	@echo ' '
	@echo '---- Compiling C++ ARM-only: ' $$< to $$@
	$(CC) -c $$(CFLAGS) $$(CPPFLAGS) $$< -o $$@ 
endef
$(foreach src, $(CPPSRCSARM), $(eval $(call COMPILE_CPP_ARM_TEMPLATE, $(src)))) 

# Compile: create assembler files from C source files. ARM/Thumb
$(CSRC:.c=.s) : %.s : %.c
	@echo ' '
	@echo '---- Creating asm-File from C-Source: ' $< to $@
	$(CC) -mthumb -S $(CFLAGS) $(CONLYFLAGS) $< -o $@

# Compile: create assembler files from C source files. ARM only
$(CSRCARM:.c=.s) : %.s : %.c
	@echo ' '
	@echo '---- Creating asm-File from C-Source (ARM-only): ' $< to $@
	$(CC) -S $(CFLAGS) $(CONLYFLAGS) $< -o $@


###########################################################################
# Options for OpenOCD flash-programming
###########################################################################
# see openocd.pdf/openocd.texi for further information
############################################################TBD: adjust to linux/lpc1769
#OOCD_LOADFILE+=$(OUTDIR)/$(TARGET).elf
## Open OCD exec file
#OOCD_EXE=./OpenOCD/bin/openocd
## debug level
#OOCD_CL=-d0
##OOCD_CL=-d3
## interface and board/target settings (using the OOCD target-library here)
### OOCD_CL+=-f interface/jtagkey2.cfg -f target/stm32.cfg
#OOCD_CL+=-f interface/jtagkey.cfg -f target/stm32.cfg
## initialize
#OOCD_CL+=-c init
## enable "fast mode" - can be disabled for tests
#OOCD_CL+=-c "fast enable"
## show the targets
#OOCD_CL+=-c targets
## commands to prepare flash-write
#OOCD_CL+= -c "reset halt"
## increase JTAG frequency a little bit - can be disabled for tests
#OOCD_CL+= -c "jtag_khz 1200"
## flash-write and -verify
#OOCD_CL+=-c "flash write_image erase $(OOCD_LOADFILE)" -c "verify_image $(OOCD_LOADFILE)"
## reset target
#OOCD_CL+=-c "reset run"
## terminate OOCD after programming
#OOCD_CL+=-c shutdown