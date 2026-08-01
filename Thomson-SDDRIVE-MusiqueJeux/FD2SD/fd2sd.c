#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h> /* for getopt */

#define PACKAGE "thomson_fd2sd"
#define VERSION "0.01"

#define NOPTS   8   /* max options for sizing opts array */
#define MAXC 1024   /* max characters for buffer */

int processopts (int argc, char **argv, long *opts);
void help (int xcode);

int main (int argc, char **argv) {

    long opts[NOPTS] = {0};  /* initialize opitons array all zero */
    char buf[MAXC] = "";
    size_t idx = 0;
    int optindex = processopts (argc, argv, opts);

    /* use filename provided as following "-f" option or provided as
     * 1st non-option argument (stdin by default)
     */
    FILE *fin = opts[0] ? fopen (argv[opts[0]], "rb") : stdin;
    if (!fin) {  /* validate file open for reading */
        fprintf (stderr, "error: file open failed '%s'.\n", argv[1]);
        return 1;
    }
    /* indicate whether the option '-o' was set */
    FILE *fout;
    if(opts[1]) {
        fout = fopen (argv[opts[0]], "wb");
    } else {
        if (fin != stdin) {
            char *fo = malloc(strlen(argv[opts[0]])+3);
            sprintf(fo, "%s.sd", argv[opts[0]]);
            fout = fopen (fo, "wb");
            free(fo);
        } else {
            fout = stdout;
        }
    }

    int end = 0;
    int s = 0;
    int i;
    /* for each sector of 256 bytes read, add 256 FF characters */ 
    while(!feof(fin)) {
        for(i = 0; i<256; i++){
            if(feof(fin)) {end=1; break;}
            if(feof(fout)) {end=2; break;}
            putc(getc(fin), fout);
        }
        for(i = 0; i<256; i++){
            if(feof(fout)) {end=2; break;}
            putc(0xff, fout);
        }
        s++;
    }
    /* pad the file up to 5120 sectors of 512 bytes */ 
    for(int j=(s-1)*512+(i+1); j<2621440; j++){
        if(feof(fout)) {end=2; break;}
        putc(0xff, fout);
    }
    fprintf (stderr, end ? "Success\n" : "Failure, last sector is %d bytes\n", i);
    fprintf(stderr, "Processed %d sectors\n", s);


    if (fin != stdin)        /* close file if not stdin */
        fclose (fin);

    if (fout != stdout)        /* close file if not stdout */
        fclose (fout);

    if (optindex < argc)    /* check whether additional options remain */
        fprintf (stderr, "\nwarning: %d options unprocessed.\n\n", argc - optindex);
    for (int i = optindex; i < argc; i++)   /* output unprocessed options */
        fprintf (stderr, " %s\n", argv[i]);

    return 0;
}

/** process command line options with getopt.
 *  values are made available through the 'opts' array.
 *  'optind' is returned for further command line processing.
 */
int processopts (int argc, char **argv, long *opts)
{
    int opt;

    /* set any default values in *opts array here */

    while ((opt = getopt (argc, argv, "f:o:hv")) != -1) {
        switch (opt) {
            case 'f':       /* input filename */
                opts[0] = optind - 1;
                break;
            case 'o':       /* output filename */
                opts[1] = optind - 1;
                break;
            case 'h':       /* help */
                help (EXIT_SUCCESS);
            case 'v':       /* show version information */
                printf ("%s, version %s\n", PACKAGE, VERSION);
                exit (EXIT_SUCCESS);
            default :       /* ? */
                fprintf (stderr, "\nerror: invalid or missing option.\n");
                help (EXIT_FAILURE);
        }
    }
    /* set argv index for filename if arguments remain */
    if (!opts[0] && argc > optind) opts[0] = optind++;

    return optind;  /* return next argument index */
}

/** display help */
void help (int xcode)
{
    xcode = xcode ? xcode : 0;

    printf ("\n %s, version %s\n\n"
            "  usage:  %s [-hv] [-o file] [-f file (stdin)] [file]\n\n"
            "  Reads each line from file, and writes line, length and contents\n"
            "  to stdout.\n\n"
            "    Options:\n\n"
            "      -f file    specifies input filename to read.\n"
            "                 (note: file can be specified with or without -f option)\n"
            "      -o file    output filename to write.\n"
            "                 (note: if missing, input filename suffixed with '.sd' will be used)\n"
            "      -h         display this help.\n"
            "      -v         display version information.\n\n",
            PACKAGE, VERSION, PACKAGE);

    exit (xcode);
}

