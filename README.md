# simfs - Simulated File System

A simulated file system implemented in C for CSC 4420 (Computer Operating Systems) at Wayne State University.

## Overview

simfs is a single-directory file system stored within a Unix file. It supports basic file operations with configurable limits on the number of files (MAXFILES) and storage blocks (MAXBLOCKS).

## Building

```bash
cd starter_code
make
```

## Usage

```bash
./simfs -f <filesystem> <command> [args...]
```

### Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `initfs` | none | Initialize a new file system |
| `printfs` | none | Print file system metadata |
| `createfile` | filename | Create an empty file |
| `deletefile` | filename | Delete a file and free its blocks |
| `readfile` | filename start length | Read bytes from a file to stdout |
| `writefile` | filename start length | Write bytes from stdin to a file |

### Examples

```bash
# Initialize file system
./simfs -f myfs initfs

# Create a file
./simfs -f myfs createfile hello

# Write to file
echo "Hello World" | ./simfs -f myfs writefile hello 0 12

# Read from file
./simfs -f myfs readfile hello 0 12

# Delete file
./simfs -f myfs deletefile hello

# View file system state
./simfs -f myfs printfs
```

## File System Structure

- **fentry**: File entry containing name (max 11 chars), size, and first block pointer
- **fnode**: Block node containing block index and next block pointer
- Metadata is stored in the first block(s), followed by data blocks
- Files use a linked list of fnodes to chain data blocks

## Files

- `simfs.c` - Main program and command parsing
- `simfs_ops.c` - File system operations implementation
- `initfs.c` - File system initialization
- `printfs.c` - File system state display
- `simfstypes.h` - Type definitions and constants
- `simfs.h` - Function prototypes
