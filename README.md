# simfs - Simulated File System

A simulated file system implemented in C for CSC 4420 (Computer Operating Systems) at Wayne State University.

## Overview

simfs is a single-directory file system stored inside one ordinary Unix file. It supports basic file operations with limits on how many files (`MAXFILES`) and how many blocks (`MAXBLOCKS`) the image can hold. Metadata and data-block layout are defined in `starter_code/simfstypes.h`.

## Building

```bash
cd starter_code
make
```

The default `Makefile` required by the assignmnet enables **AddressSanitizer** (`-fsanitize=address`). On some **macOS + Apple Clang** setups, the sanitizer runtime can abort immediately with a check in `sanitizer_malloc_mac.inc` (before the program runs). That is a toolchain/runtime issue that can be worked around.

If that happens, build without AddressSanitizer:

```bash
make clean
make FLAGS='-Wall -Werror -g'
```

## Usage

```bash
./simfs -f <filesystem-image> <command> [args...]
```

**`initfs`** creates (or **overwrites**) the image file. Run it once per new disk image.

**Successful commands** such as `initfs` and `createfile` produce **no stdout**; errors go to stderr and exit non-zero.

**Simulated filenames** are limited to **11 characters** (see `fentry.name` in `simfstypes.h`).

**`writefile`** reads exactly `length` bytes from **standard input**. The byte count you pass must match what you pipe in (for example, `echo -n` omits a trailing newline, so lengths differ from plain `echo`).

### Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `initfs` | none | Initialize a new file system (overwrites the image if it exists) |
| `printfs` | none | Print file system metadata |
| `createfile` | filename | Create an empty file |
| `deletefile` | filename | Delete a file and free its blocks |
| `readfile` | filename start length | Read bytes from a file to stdout |
| `writefile` | filename start length | Read `length` bytes from stdin and write at `start` |

### Examples

```bash
cd starter_code

# New image (creates or clobbers myfs)
./simfs -f myfs initfs

./simfs -f myfs createfile hello

# Two bytes at offset 0; "hi" from echo -n is exactly 2 bytes
echo -n "hi" | ./simfs -f myfs writefile hello 0 2
./simfs -f myfs readfile hello 0 2

# "Hello World\n" is 12 bytes with default echo
echo "Hello World" | ./simfs -f myfs writefile hello 0 12
./simfs -f myfs readfile hello 0 12

./simfs -f myfs deletefile hello

./simfs -f myfs printfs
```

From the repository root, you can run the bundled test script after building `starter_code/simfs`:

```bash
cd starter_code
../test_simfs.sh
```

## File system structure (brief)

- **fentry**: Directory entry — name (max 11 characters), logical size, index of first **fnode** in the chain (`-1` if empty).
- **fnode**: Describes one block of file data — disk block index and index of the next fnode (`-1` at end of chain). Free fnodes use a negative `blockindex` whose magnitude is the fnode index.
- Metadata is written at the beginning of the image; file data lives in fixed-size blocks indexed by block number.

## Source layout

- `starter_code/simfs.c` — CLI and command dispatch  
- `starter_code/simfs_ops.c` — `createfile`, `deletefile`, `readfile`, `writefile`  
- `starter_code/initfs.c` — initialize a new image  
- `starter_code/printfs.c` — print metadata  
- `starter_code/simfstypes.h` — constants and structs (do not change per assignment)  
- `starter_code/simfs.h` — shared prototypes  
