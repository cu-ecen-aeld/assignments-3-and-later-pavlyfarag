#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    openlog("writer_utility", LOG_PID, LOG_USER);
    if (argc < 3) {
        syslog(LOG_ERR, "Not enough arguments. Usage: %s <writefile> <writestr>", argv[0]);
        return 1;
    }

    char* writefile = argv[1];
    char* writestr = argv[2];

    FILE* file = fopen(writefile, "w");
    if (file == NULL) {
        syslog(LOG_ERR, "Error opening file: %s", writefile);
        closelog();
        return 1;
    }

    if (fprintf(file, "%s\n", writestr) < 0) {
        syslog(LOG_ERR, "Error writing to file: %s", writefile);
        fclose(file);
        closelog();
        return 1;
    }
    if (fclose(file) != 0) {
        syslog(LOG_ERR, "Error closing file: %s", writefile);
        closelog();
        return 1;
    }

    syslog(LOG_DEBUG, "Writing \"%s\" to file: %s", writestr, writefile);

    closelog();
    return 0;
}
