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
