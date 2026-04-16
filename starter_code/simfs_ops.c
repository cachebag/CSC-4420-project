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
