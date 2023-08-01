# Compiler settings
CC := gcc
CFLAGS := -Wall -Wextra -O2
CROSS_COMPILE ?=

# Directories
SRC_DIR := .
BUILD_DIR := .

# Application name
TARGET := writer

# Source files
SRC := $(wildcard $(SRC_DIR)/*.c)
OBJ := $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRC))

# Default target: Build the "writer" application
all: $(TARGET)

# Compile the object files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CROSS_COMPILE)$(CC) $(CFLAGS) $(CROSS_CFLAGS) -c $< -o $@

# Link the application
$(TARGET): $(OBJ)
	$(CROSS_COMPILE)$(CC) $(CFLAGS) $(CROSS_CFLAGS) $^ -o $@

# Clean target: Remove the "writer" application and all .o files
clean:
	rm -f $(TARGET) $(OBJ)

.PHONY: all clean
