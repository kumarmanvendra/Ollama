# Common definitions for the various Makefiles which set cuda settings
# No rules are defined here so this is safe to include at the beginning of other makefiles

ifeq ($(OS),windows)
	CUDA_PATH?=$(shell cygpath -m -s "C:\\Program Files\\NVIDIA GPU Computing Toolkit\\CUDA\\" 2>/dev/null)unknown
	CUDA_BASE_DIR := $(dir $(shell cygpath -m -s "$(CUDA_PATH)\\.." 2>/dev/null))
	CUDA_12:=$(shell ls -d $(CUDA_BASE_DIR)/v12.? 2>/dev/null)
	CUDA_12_COMPILER:=$(wildcard $(CUDA_12)/bin/nvcc.exe)
else ifeq ($(OS),linux)
	CUDA_PATH?=/usr/local/cuda
	CUDA_12:=$(shell ls -d $(CUDA_PATH)-12 2>/dev/null)
	CUDA_12_COMPILER:=$(wildcard $(CUDA_12)/bin/nvcc)
endif
