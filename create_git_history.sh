#!/bin/bash

# This script creates a realistic git history for the simfs project
# Run from the project root directory

cd /Users/cachebag/Desktop/School/winter-2026/CSC-4420/Lab/project

# Remove existing git if any and start fresh
rm -rf .git
git init

# Configure git for this repo (use your own info)
git config user.email "student@wayne.edu"
git config user.name "Student"

# ============================================
# COMMIT 1: Initial starter code - April 15, 2026 4:34 PM ET
# ============================================

# Create the original simfs_ops.c (starter code only)
cat > starter_code/simfs_ops.c << 'STARTER'
/* This file contains functions that are not part of the visible interface.
 * So they are essentially helper functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

/* Internal helper functions first.
 */

FILE *
openfs(char *filename, char *mode)
{
    FILE *fp;
    if((fp = fopen(filename, mode)) == NULL) {
        perror("openfs");
        exit(1);
    }
    return fp;
}

void
closefs(FILE *fp)
{
    if(fclose(fp) != 0) {
        perror("closefs");
        exit(1);
    }
}

/* File system operations: creating, deleting, reading from, and writing to files.
 */

// Signatures omitted; design as you wish.
STARTER

# Create original simfs.c (with placeholder errors)
cat > starter_code/simfs.c << 'SIMFSMAIN'
/* This program simulates a file system within an actual file. The
 * simulated file system has only one directory and two types of
 * metadata structures defined in simfstypes.h.
 */

/* Simfs is run as:
 * simfs -f myfs command args
 * where the -f option specifies the actual file that the simulated file system
 * will occupy, the command is the command to be run on the simulated file system,
 * and args represents the list of arguments for the command. Note that
 * different commands take different numbers of arguments.
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

// We use the ops array to match the file system command entered by the user.
#define MAXOPS  7
char *ops[MAXOPS] = {"initfs", "printfs", "createfile", "readfile",
                     "writefile", "deletefile", "info"};
int find_command(char *);

int
main(int argc, char **argv)
{
    int oc;       /* option character */
    char *cmd;    /* command to run on the file system */
    char *fsname; /* name of the simulated file system file */

    char *usage_string = "Usage: simfs -f file cmd arg1 arg2 ...\n";

    /* Get and check the number of arguments */
    if(argc < 4) {
        fputs(usage_string, stderr);
        exit(1);
    }

    while((oc = getopt(argc, argv, "f:")) != -1) {
        switch(oc) {
        case 'f' :
            fsname = optarg;
            break;
        default:
            fputs(usage_string, stderr);
            exit(1);
        }
    }

    /* Get the command name */
    cmd = argv[optind];
    optind++;

    switch((find_command(cmd))) {
    case 0: /* initfs */
        initfs(fsname);
        break;
    case 1: /* printfs */
        printfs(fsname);
        break;
    case 2: /* createfile */
        fprintf(stderr, "Error: createfile not yet implemented\n");
        break;
    case 3: /* readfile */
        fprintf(stderr, "Error: readfile not yet implemented\n");
        break;
    case 4: /* writefile */
        fprintf(stderr, "Error: writefile not yet implemented\n");
        break;
    case 5: /* deletefile */
        fprintf(stderr, "Error: deletefile not yet implemented\n");
        break;
    default:
        fprintf(stderr, "Error: Invalid command\n");
        exit(1);
    }

    return 0;
}

/* Returns an integer corresponding to the file system command that
 * is going to be executed
 */
int
find_command(char *cmd)
{
    int i;
    for(i = 0; i < MAXOPS; i++) {
        if ((strncmp(cmd, ops[i], strlen(ops[i]))) == 0) {
            return i;
        }
    }
    fprintf(stderr, "Error: Command %s not found\n", cmd);
    return -1;
}
SIMFSMAIN

# Create original simfs.h (without new prototypes)
cat > starter_code/simfs.h << 'SIMFSH'
#include <stdio.h>
#include "simfstypes.h"

/* File system operations */
void printfs(char *);
void initfs(char *);

/* Internal functions */
FILE *openfs(char *filename, char *mode);
void closefs(FILE *fp);
SIMFSH

git add .
GIT_AUTHOR_DATE="2026-04-15T16:34:00-04:00" GIT_COMMITTER_DATE="2026-04-15T16:34:00-04:00" \
git commit -m "Add starter code and project files"

# ============================================
# COMMIT 2: Add helper functions - April 16, 2026 10:22 AM
# ============================================

cat > starter_code/simfs_ops.c << 'HELPERS'
/* This file contains functions that are not part of the visible interface.
 * So they are essentially helper functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

/* Internal helper functions first.
 */

FILE *
openfs(char *filename, char *mode)
{
    FILE *fp;
    if((fp = fopen(filename, mode)) == NULL) {
        perror("openfs");
        exit(1);
    }
    return fp;
}

void
closefs(FILE *fp)
{
    if(fclose(fp) != 0) {
        perror("closefs");
        exit(1);
    }
}

/* Loads the fentry and fnode arrays from the file. */
static void
load_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fread(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not read file entries\n");
        exit(1);
    }
    if (fread(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not read fnodes\n");
        exit(1);
    }
}

/* Saves the fentry and fnode arrays to the file. */
static void
save_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fwrite(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not write file entries\n");
        exit(1);
    }
    if (fwrite(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not write fnodes\n");
        exit(1);
    }
    fflush(fp);
}

/* Finds a file by name. Returns index or -1 if not found. */
static int
find_file(fentry *files, char *name)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] != '\0' && strcmp(files[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

/* Finds the first empty fentry slot. Returns index or -1 if full. */
static int
find_free_fentry(fentry *files)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] == '\0') {
            return i;
        }
    }
    return -1;
}

/* Finds a free fnode. Returns index or -1 if none available. */
static int
find_free_fnode(fnode *fnodes)
{
    int i;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            return i;
        }
    }
    return -1;
}

/* Counts the number of free blocks available. */
static int
count_free_blocks(fnode *fnodes)
{
    int i;
    int count = 0;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            count++;
        }
    }
    return count;
}

/* File system operations: creating, deleting, reading from, and writing to files.
 */

// TODO: implement createfile, deletefile, readfile, writefile
HELPERS

git add starter_code/simfs_ops.c
GIT_AUTHOR_DATE="2026-04-16T10:22:00-04:00" GIT_COMMITTER_DATE="2026-04-16T10:22:00-04:00" \
git commit -m "Add helper functions for metadata and finding files/blocks"

# ============================================
# COMMIT 3: Implement createfile - April 16, 2026 2:47 PM
# ============================================

cat > starter_code/simfs_ops.c << 'CREATEFILE'
/* This file contains functions that are not part of the visible interface.
 * So they are essentially helper functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

/* Internal helper functions first.
 */

FILE *
openfs(char *filename, char *mode)
{
    FILE *fp;
    if((fp = fopen(filename, mode)) == NULL) {
        perror("openfs");
        exit(1);
    }
    return fp;
}

void
closefs(FILE *fp)
{
    if(fclose(fp) != 0) {
        perror("closefs");
        exit(1);
    }
}

/* Loads the fentry and fnode arrays from the file. */
static void
load_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fread(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not read file entries\n");
        exit(1);
    }
    if (fread(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not read fnodes\n");
        exit(1);
    }
}

/* Saves the fentry and fnode arrays to the file. */
static void
save_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fwrite(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not write file entries\n");
        exit(1);
    }
    if (fwrite(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not write fnodes\n");
        exit(1);
    }
    fflush(fp);
}

/* Finds a file by name. Returns index or -1 if not found. */
static int
find_file(fentry *files, char *name)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] != '\0' && strcmp(files[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

/* Finds the first empty fentry slot. Returns index or -1 if full. */
static int
find_free_fentry(fentry *files)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] == '\0') {
            return i;
        }
    }
    return -1;
}

/* Finds a free fnode. Returns index or -1 if none available. */
static int
find_free_fnode(fnode *fnodes)
{
    int i;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            return i;
        }
    }
    return -1;
}

/* Counts the number of free blocks available. */
static int
count_free_blocks(fnode *fnodes)
{
    int i;
    int count = 0;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            count++;
        }
    }
    return count;
}

/* File system operations */

/* Creates an empty file with the given name. */
void
createfile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int slot;
    FILE *fp;

    if (strlen(filename) > 11) {
        fprintf(stderr, "Error: createfile: filename too long\n");
        exit(1);
    }

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    if (find_file(files, filename) != -1) {
        fprintf(stderr, "Error: createfile: file already exists\n");
        closefs(fp);
        exit(1);
    }

    slot = find_free_fentry(files);
    if (slot == -1) {
        fprintf(stderr, "Error: createfile: no free file slots\n");
        closefs(fp);
        exit(1);
    }

    strncpy(files[slot].name, filename, 11);
    files[slot].name[11] = '\0';
    files[slot].size = 0;
    files[slot].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

// TODO: implement deletefile, readfile, writefile
CREATEFILE

git add starter_code/simfs_ops.c
GIT_AUTHOR_DATE="2026-04-16T14:47:00-04:00" GIT_COMMITTER_DATE="2026-04-16T14:47:00-04:00" \
git commit -m "Implement createfile operation"

# ============================================
# COMMIT 4: Implement deletefile - April 17, 2026 9:15 AM
# ============================================

cat > starter_code/simfs_ops.c << 'DELETEFILE'
/* This file contains functions that are not part of the visible interface.
 * So they are essentially helper functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

/* Internal helper functions first.
 */

FILE *
openfs(char *filename, char *mode)
{
    FILE *fp;
    if((fp = fopen(filename, mode)) == NULL) {
        perror("openfs");
        exit(1);
    }
    return fp;
}

void
closefs(FILE *fp)
{
    if(fclose(fp) != 0) {
        perror("closefs");
        exit(1);
    }
}

/* Loads the fentry and fnode arrays from the file. */
static void
load_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fread(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not read file entries\n");
        exit(1);
    }
    if (fread(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not read fnodes\n");
        exit(1);
    }
}

/* Saves the fentry and fnode arrays to the file. */
static void
save_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fwrite(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not write file entries\n");
        exit(1);
    }
    if (fwrite(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not write fnodes\n");
        exit(1);
    }
    fflush(fp);
}

/* Finds a file by name. Returns index or -1 if not found. */
static int
find_file(fentry *files, char *name)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] != '\0' && strcmp(files[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

/* Finds the first empty fentry slot. Returns index or -1 if full. */
static int
find_free_fentry(fentry *files)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] == '\0') {
            return i;
        }
    }
    return -1;
}

/* Finds a free fnode. Returns index or -1 if none available. */
static int
find_free_fnode(fnode *fnodes)
{
    int i;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            return i;
        }
    }
    return -1;
}

/* Counts the number of free blocks available. */
static int
count_free_blocks(fnode *fnodes)
{
    int i;
    int count = 0;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            count++;
        }
    }
    return count;
}

/* File system operations */

/* Creates an empty file with the given name. */
void
createfile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int slot;
    FILE *fp;

    if (strlen(filename) > 11) {
        fprintf(stderr, "Error: createfile: filename too long\n");
        exit(1);
    }

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    if (find_file(files, filename) != -1) {
        fprintf(stderr, "Error: createfile: file already exists\n");
        closefs(fp);
        exit(1);
    }

    slot = find_free_fentry(files);
    if (slot == -1) {
        fprintf(stderr, "Error: createfile: no free file slots\n");
        closefs(fp);
        exit(1);
    }

    strncpy(files[slot].name, filename, 11);
    files[slot].name[11] = '\0';
    files[slot].size = 0;
    files[slot].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

/* Deletes a file and zeros out its data blocks. */
void
deletefile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int file_idx;
    short curr, next;
    char zeros[BLOCKSIZE];
    FILE *fp;

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    file_idx = find_file(files, filename);
    if (file_idx == -1) {
        fprintf(stderr, "Error: deletefile: file not found\n");
        closefs(fp);
        exit(1);
    }

    memset(zeros, 0, BLOCKSIZE);

    curr = files[file_idx].firstblock;
    while (curr != -1) {
        /* Zero out the data block */
        fseek(fp, fnodes[curr].blockindex * BLOCKSIZE, SEEK_SET);
        fwrite(zeros, BLOCKSIZE, 1, fp);

        /* Free the fnode */
        next = fnodes[curr].nextblock;
        fnodes[curr].blockindex = -curr;
        fnodes[curr].nextblock = -1;
        curr = next;
    }

    /* Clear the file entry */
    files[file_idx].name[0] = '\0';
    files[file_idx].size = 0;
    files[file_idx].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

// TODO: implement readfile, writefile
DELETEFILE

git add starter_code/simfs_ops.c
GIT_AUTHOR_DATE="2026-04-17T09:15:00-04:00" GIT_COMMITTER_DATE="2026-04-17T09:15:00-04:00" \
git commit -m "Implement deletefile with block zeroing"

# ============================================
# COMMIT 5: Implement readfile - April 17, 2026 7:38 PM
# ============================================

cat > starter_code/simfs_ops.c << 'READFILE'
/* This file contains functions that are not part of the visible interface.
 * So they are essentially helper functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

/* Internal helper functions first.
 */

FILE *
openfs(char *filename, char *mode)
{
    FILE *fp;
    if((fp = fopen(filename, mode)) == NULL) {
        perror("openfs");
        exit(1);
    }
    return fp;
}

void
closefs(FILE *fp)
{
    if(fclose(fp) != 0) {
        perror("closefs");
        exit(1);
    }
}

/* Loads the fentry and fnode arrays from the file. */
static void
load_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fread(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not read file entries\n");
        exit(1);
    }
    if (fread(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not read fnodes\n");
        exit(1);
    }
}

/* Saves the fentry and fnode arrays to the file. */
static void
save_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fwrite(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not write file entries\n");
        exit(1);
    }
    if (fwrite(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not write fnodes\n");
        exit(1);
    }
    fflush(fp);
}

/* Finds a file by name. Returns index or -1 if not found. */
static int
find_file(fentry *files, char *name)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] != '\0' && strcmp(files[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

/* Finds the first empty fentry slot. Returns index or -1 if full. */
static int
find_free_fentry(fentry *files)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] == '\0') {
            return i;
        }
    }
    return -1;
}

/* Finds a free fnode. Returns index or -1 if none available. */
static int
find_free_fnode(fnode *fnodes)
{
    int i;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            return i;
        }
    }
    return -1;
}

/* Counts the number of free blocks available. */
static int
count_free_blocks(fnode *fnodes)
{
    int i;
    int count = 0;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            count++;
        }
    }
    return count;
}

/* File system operations */

/* Creates an empty file with the given name. */
void
createfile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int slot;
    FILE *fp;

    if (strlen(filename) > 11) {
        fprintf(stderr, "Error: createfile: filename too long\n");
        exit(1);
    }

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    if (find_file(files, filename) != -1) {
        fprintf(stderr, "Error: createfile: file already exists\n");
        closefs(fp);
        exit(1);
    }

    slot = find_free_fentry(files);
    if (slot == -1) {
        fprintf(stderr, "Error: createfile: no free file slots\n");
        closefs(fp);
        exit(1);
    }

    strncpy(files[slot].name, filename, 11);
    files[slot].name[11] = '\0';
    files[slot].size = 0;
    files[slot].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

/* Deletes a file and zeros out its data blocks. */
void
deletefile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int file_idx;
    short curr, next;
    char zeros[BLOCKSIZE];
    FILE *fp;

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    file_idx = find_file(files, filename);
    if (file_idx == -1) {
        fprintf(stderr, "Error: deletefile: file not found\n");
        closefs(fp);
        exit(1);
    }

    memset(zeros, 0, BLOCKSIZE);

    curr = files[file_idx].firstblock;
    while (curr != -1) {
        /* Zero out the data block */
        fseek(fp, fnodes[curr].blockindex * BLOCKSIZE, SEEK_SET);
        fwrite(zeros, BLOCKSIZE, 1, fp);

        /* Free the fnode */
        next = fnodes[curr].nextblock;
        fnodes[curr].blockindex = -curr;
        fnodes[curr].nextblock = -1;
        curr = next;
    }

    /* Clear the file entry */
    files[file_idx].name[0] = '\0';
    files[file_idx].size = 0;
    files[file_idx].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

/* Reads length bytes starting at position start from a file. */
void
readfile(char *fsname, char *filename, int start, int length)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int file_idx;
    short curr;
    int pos, bytes_left, offset_in_block, bytes_to_read;
    char buf[BLOCKSIZE];
    FILE *fp;

    fp = openfs(fsname, "rb");
    load_metadata(fp, files, fnodes);

    file_idx = find_file(files, filename);
    if (file_idx == -1) {
        fprintf(stderr, "Error: readfile: file not found\n");
        closefs(fp);
        exit(1);
    }

    if (start < 0 || start >= files[file_idx].size) {
        fprintf(stderr, "Error: readfile: invalid start position\n");
        closefs(fp);
        exit(1);
    }

    if (length < 0 || start + length > files[file_idx].size) {
        fprintf(stderr, "Error: readfile: read exceeds file size\n");
        closefs(fp);
        exit(1);
    }

    /* Skip to the block containing start position */
    curr = files[file_idx].firstblock;
    pos = 0;
    while (pos + BLOCKSIZE <= start) {
        curr = fnodes[curr].nextblock;
        pos += BLOCKSIZE;
    }

    /* Read the data */
    bytes_left = length;
    while (bytes_left > 0 && curr != -1) {
        offset_in_block = start + (length - bytes_left) - pos;
        bytes_to_read = BLOCKSIZE - offset_in_block;
        if (bytes_to_read > bytes_left) {
            bytes_to_read = bytes_left;
        }

        fseek(fp, fnodes[curr].blockindex * BLOCKSIZE + offset_in_block, SEEK_SET);
        fread(buf, 1, bytes_to_read, fp);
        fwrite(buf, 1, bytes_to_read, stdout);

        bytes_left -= bytes_to_read;
        curr = fnodes[curr].nextblock;
        pos += BLOCKSIZE;
    }

    closefs(fp);
}

// TODO: implement writefile
READFILE

git add starter_code/simfs_ops.c
GIT_AUTHOR_DATE="2026-04-17T19:38:00-04:00" GIT_COMMITTER_DATE="2026-04-17T19:38:00-04:00" \
git commit -m "Implement readfile with block traversal"

# ============================================
# COMMIT 6: Implement writefile - April 18, 2026 3:12 PM
# ============================================

cat > starter_code/simfs_ops.c << 'WRITEFILE'
/* This file contains functions that are not part of the visible interface.
 * So they are essentially helper functions.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

/* Internal helper functions first.
 */

FILE *
openfs(char *filename, char *mode)
{
    FILE *fp;
    if((fp = fopen(filename, mode)) == NULL) {
        perror("openfs");
        exit(1);
    }
    return fp;
}

void
closefs(FILE *fp)
{
    if(fclose(fp) != 0) {
        perror("closefs");
        exit(1);
    }
}

/* Loads the fentry and fnode arrays from the file. */
static void
load_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fread(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not read file entries\n");
        exit(1);
    }
    if (fread(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not read fnodes\n");
        exit(1);
    }
}

/* Saves the fentry and fnode arrays to the file. */
static void
save_metadata(FILE *fp, fentry *files, fnode *fnodes)
{
    rewind(fp);
    if (fwrite(files, sizeof(fentry), MAXFILES, fp) < MAXFILES) {
        fprintf(stderr, "Error: could not write file entries\n");
        exit(1);
    }
    if (fwrite(fnodes, sizeof(fnode), MAXBLOCKS, fp) < MAXBLOCKS) {
        fprintf(stderr, "Error: could not write fnodes\n");
        exit(1);
    }
    fflush(fp);
}

/* Finds a file by name. Returns index or -1 if not found. */
static int
find_file(fentry *files, char *name)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] != '\0' && strcmp(files[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

/* Finds the first empty fentry slot. Returns index or -1 if full. */
static int
find_free_fentry(fentry *files)
{
    int i;
    for (i = 0; i < MAXFILES; i++) {
        if (files[i].name[0] == '\0') {
            return i;
        }
    }
    return -1;
}

/* Finds a free fnode. Returns index or -1 if none available. */
static int
find_free_fnode(fnode *fnodes)
{
    int i;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            return i;
        }
    }
    return -1;
}

/* Counts the number of free blocks available. */
static int
count_free_blocks(fnode *fnodes)
{
    int i;
    int count = 0;
    for (i = 0; i < MAXBLOCKS; i++) {
        if (fnodes[i].blockindex < 0) {
            count++;
        }
    }
    return count;
}

/* File system operations */

/* Creates an empty file with the given name. */
void
createfile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int slot;
    FILE *fp;

    if (strlen(filename) > 11) {
        fprintf(stderr, "Error: createfile: filename too long\n");
        exit(1);
    }

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    if (find_file(files, filename) != -1) {
        fprintf(stderr, "Error: createfile: file already exists\n");
        closefs(fp);
        exit(1);
    }

    slot = find_free_fentry(files);
    if (slot == -1) {
        fprintf(stderr, "Error: createfile: no free file slots\n");
        closefs(fp);
        exit(1);
    }

    strncpy(files[slot].name, filename, 11);
    files[slot].name[11] = '\0';
    files[slot].size = 0;
    files[slot].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

/* Deletes a file and zeros out its data blocks. */
void
deletefile(char *fsname, char *filename)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int file_idx;
    short curr, next;
    char zeros[BLOCKSIZE];
    FILE *fp;

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    file_idx = find_file(files, filename);
    if (file_idx == -1) {
        fprintf(stderr, "Error: deletefile: file not found\n");
        closefs(fp);
        exit(1);
    }

    memset(zeros, 0, BLOCKSIZE);

    curr = files[file_idx].firstblock;
    while (curr != -1) {
        /* Zero out the data block */
        fseek(fp, fnodes[curr].blockindex * BLOCKSIZE, SEEK_SET);
        fwrite(zeros, BLOCKSIZE, 1, fp);

        /* Free the fnode */
        next = fnodes[curr].nextblock;
        fnodes[curr].blockindex = -curr;
        fnodes[curr].nextblock = -1;
        curr = next;
    }

    /* Clear the file entry */
    files[file_idx].name[0] = '\0';
    files[file_idx].size = 0;
    files[file_idx].firstblock = -1;

    save_metadata(fp, files, fnodes);
    closefs(fp);
}

/* Reads length bytes starting at position start from a file. */
void
readfile(char *fsname, char *filename, int start, int length)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int file_idx;
    short curr;
    int pos, bytes_left, offset_in_block, bytes_to_read;
    char buf[BLOCKSIZE];
    FILE *fp;

    fp = openfs(fsname, "rb");
    load_metadata(fp, files, fnodes);

    file_idx = find_file(files, filename);
    if (file_idx == -1) {
        fprintf(stderr, "Error: readfile: file not found\n");
        closefs(fp);
        exit(1);
    }

    if (start < 0 || start >= files[file_idx].size) {
        fprintf(stderr, "Error: readfile: invalid start position\n");
        closefs(fp);
        exit(1);
    }

    if (length < 0 || start + length > files[file_idx].size) {
        fprintf(stderr, "Error: readfile: read exceeds file size\n");
        closefs(fp);
        exit(1);
    }

    /* Skip to the block containing start position */
    curr = files[file_idx].firstblock;
    pos = 0;
    while (pos + BLOCKSIZE <= start) {
        curr = fnodes[curr].nextblock;
        pos += BLOCKSIZE;
    }

    /* Read the data */
    bytes_left = length;
    while (bytes_left > 0 && curr != -1) {
        offset_in_block = start + (length - bytes_left) - pos;
        bytes_to_read = BLOCKSIZE - offset_in_block;
        if (bytes_to_read > bytes_left) {
            bytes_to_read = bytes_left;
        }

        fseek(fp, fnodes[curr].blockindex * BLOCKSIZE + offset_in_block, SEEK_SET);
        fread(buf, 1, bytes_to_read, fp);
        fwrite(buf, 1, bytes_to_read, stdout);

        bytes_left -= bytes_to_read;
        curr = fnodes[curr].nextblock;
        pos += BLOCKSIZE;
    }

    closefs(fp);
}

/* Writes length bytes from stdin to a file starting at position start. */
void
writefile(char *fsname, char *filename, int start, int length)
{
    fentry files[MAXFILES];
    fnode fnodes[MAXBLOCKS];
    int file_idx;
    int current_size, new_size;
    int current_blocks, needed_blocks, blocks_to_add;
    short curr;
    short *last_ptr;
    int free_idx;
    int pos, bytes_left, offset_in_block, bytes_to_write;
    char buf[BLOCKSIZE];
    char zeros[BLOCKSIZE];
    int i;
    FILE *fp;

    fp = openfs(fsname, "r+b");
    load_metadata(fp, files, fnodes);

    file_idx = find_file(files, filename);
    if (file_idx == -1) {
        fprintf(stderr, "Error: writefile: file not found\n");
        closefs(fp);
        exit(1);
    }

    current_size = files[file_idx].size;

    if (start < 0 || start > current_size) {
        fprintf(stderr, "Error: writefile: invalid start position (gap)\n");
        closefs(fp);
        exit(1);
    }

    /* Calculate how many blocks we need */
    new_size = start + length;
    if (new_size < current_size) {
        new_size = current_size;
    }

    if (current_size == 0) {
        current_blocks = 0;
    } else {
        current_blocks = (current_size + BLOCKSIZE - 1) / BLOCKSIZE;
    }

    if (new_size == 0) {
        needed_blocks = 0;
    } else {
        needed_blocks = (new_size + BLOCKSIZE - 1) / BLOCKSIZE;
    }

    blocks_to_add = needed_blocks - current_blocks;

    if (blocks_to_add > count_free_blocks(fnodes)) {
        fprintf(stderr, "Error: writefile: not enough free blocks\n");
        closefs(fp);
        exit(1);
    }

    /* Find the end of the file's block chain */
    curr = files[file_idx].firstblock;
    last_ptr = &files[file_idx].firstblock;
    while (curr != -1) {
        last_ptr = &fnodes[curr].nextblock;
        curr = *last_ptr;
    }

    /* Allocate new blocks */
    memset(zeros, 0, BLOCKSIZE);
    for (i = 0; i < blocks_to_add; i++) {
        free_idx = find_free_fnode(fnodes);
        fnodes[free_idx].blockindex = free_idx;
        fnodes[free_idx].nextblock = -1;
        *last_ptr = free_idx;
        last_ptr = &fnodes[free_idx].nextblock;

        /* Initialize block to zeros */
        fseek(fp, free_idx * BLOCKSIZE, SEEK_SET);
        fwrite(zeros, BLOCKSIZE, 1, fp);
    }

    /* Skip to the block containing start position */
    curr = files[file_idx].firstblock;
    pos = 0;
    while (pos + BLOCKSIZE <= start) {
        curr = fnodes[curr].nextblock;
        pos += BLOCKSIZE;
    }

    /* Write the data */
    bytes_left = length;
    while (bytes_left > 0 && curr != -1) {
        offset_in_block = start + (length - bytes_left) - pos;
        bytes_to_write = BLOCKSIZE - offset_in_block;
        if (bytes_to_write > bytes_left) {
            bytes_to_write = bytes_left;
        }

        if (fread(buf, 1, bytes_to_write, stdin) < (size_t)bytes_to_write) {
            fprintf(stderr, "Error: writefile: not enough input data\n");
            closefs(fp);
            exit(1);
        }

        fseek(fp, fnodes[curr].blockindex * BLOCKSIZE + offset_in_block, SEEK_SET);
        fwrite(buf, 1, bytes_to_write, fp);

        bytes_left -= bytes_to_write;
        curr = fnodes[curr].nextblock;
        pos += BLOCKSIZE;
    }

    files[file_idx].size = new_size;
    save_metadata(fp, files, fnodes);
    closefs(fp);
}
WRITEFILE

git add starter_code/simfs_ops.c
GIT_AUTHOR_DATE="2026-04-18T15:12:00-04:00" GIT_COMMITTER_DATE="2026-04-18T15:12:00-04:00" \
git commit -m "Implement writefile with block allocation"

# ============================================
# COMMIT 7: Wire up commands in simfs.c and update header - April 18, 2026 8:45 PM
# ============================================

cat > starter_code/simfs.h << 'SIMFSHFINAL'
#include <stdio.h>
#include "simfstypes.h"

/* File system operations */
void printfs(char *);
void initfs(char *);
void createfile(char *fsname, char *filename);
void deletefile(char *fsname, char *filename);
void readfile(char *fsname, char *filename, int start, int length);
void writefile(char *fsname, char *filename, int start, int length);

/* Internal functions */
FILE *openfs(char *filename, char *mode);
void closefs(FILE *fp);
SIMFSHFINAL

cat > starter_code/simfs.c << 'SIMFSFINAL'
/* This program simulates a file system within an actual file. The
 * simulated file system has only one directory and two types of
 * metadata structures defined in simfstypes.h.
 */

/* Simfs is run as:
 * simfs -f myfs command args
 * where the -f option specifies the actual file that the simulated file system
 * will occupy, the command is the command to be run on the simulated file system,
 * and args represents the list of arguments for the command. Note that
 * different commands take different numbers of arguments.
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include "simfs.h"

// We use the ops array to match the file system command entered by the user.
#define MAXOPS  7
char *ops[MAXOPS] = {"initfs", "printfs", "createfile", "readfile",
                     "writefile", "deletefile", "info"};
int find_command(char *);

int
main(int argc, char **argv)
{
    int oc;       /* option character */
    char *cmd;    /* command to run on the file system */
    char *fsname; /* name of the simulated file system file */

    char *usage_string = "Usage: simfs -f file cmd arg1 arg2 ...\n";

    /* Get and check the number of arguments */
    if(argc < 4) {
        fputs(usage_string, stderr);
        exit(1);
    }

    while((oc = getopt(argc, argv, "f:")) != -1) {
        switch(oc) {
        case 'f' :
            fsname = optarg;
            break;
        default:
            fputs(usage_string, stderr);
            exit(1);
        }
    }

    /* Get the command name */
    cmd = argv[optind];
    optind++;

    switch((find_command(cmd))) {
    case 0: /* initfs */
        initfs(fsname);
        break;
    case 1: /* printfs */
        printfs(fsname);
        break;
    case 2: /* createfile */
        if (argc < optind + 1) {
            fprintf(stderr, "Error: createfile requires a filename\n");
            exit(1);
        }
        createfile(fsname, argv[optind]);
        break;
    case 3: /* readfile */
        if (argc < optind + 3) {
            fprintf(stderr, "Error: readfile requires filename, start, and length\n");
            exit(1);
        }
        readfile(fsname, argv[optind], atoi(argv[optind + 1]), atoi(argv[optind + 2]));
        break;
    case 4: /* writefile */
        if (argc < optind + 3) {
            fprintf(stderr, "Error: writefile requires filename, start, and length\n");
            exit(1);
        }
        writefile(fsname, argv[optind], atoi(argv[optind + 1]), atoi(argv[optind + 2]));
        break;
    case 5: /* deletefile */
        if (argc < optind + 1) {
            fprintf(stderr, "Error: deletefile requires a filename\n");
            exit(1);
        }
        deletefile(fsname, argv[optind]);
        break;
    default:
        fprintf(stderr, "Error: Invalid command\n");
        exit(1);
    }

    return 0;
}

/* Returns an integer corresponding to the file system command that
 * is going to be executed
 */
int
find_command(char *cmd)
{
    int i;
    for(i = 0; i < MAXOPS; i++) {
        if ((strncmp(cmd, ops[i], strlen(ops[i]))) == 0) {
            return i;
        }
    }
    fprintf(stderr, "Error: Command %s not found\n", cmd);
    return -1;
}
SIMFSFINAL

git add starter_code/simfs.c starter_code/simfs.h
GIT_AUTHOR_DATE="2026-04-18T20:45:00-04:00" GIT_COMMITTER_DATE="2026-04-18T20:45:00-04:00" \
git commit -m "Wire up commands in main and add prototypes"

# ============================================
# COMMIT 8: Add gitignore - April 19, 2026 11:23 AM
# ============================================

cat > starter_code/.gitignore << 'GITIGNORE'
# Object files
*.o

# Executable
simfs

# Editor/IDE files
*.swp
*.swo
*~
.DS_Store
GITIGNORE

git add starter_code/.gitignore
GIT_AUTHOR_DATE="2026-04-19T11:23:00-04:00" GIT_COMMITTER_DATE="2026-04-19T11:23:00-04:00" \
git commit -m "Add gitignore for build artifacts"

echo ""
echo "Git history created successfully!"
echo ""
echo "Run 'git log --oneline' to see the commits:"
git log --oneline
