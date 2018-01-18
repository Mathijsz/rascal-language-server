
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <curl/curl.h>

const char *rascal_web_addr = "http://127.0.0.1:12366/%s";

#if defined(WIN32)
#include <fcntl.h>
#include <io.h>
#endif

typedef struct data_t {
    char *mem;
    size_t alloc;
    size_t size;
} data_t;

size_t get_response_data(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    size_t newdata_sz = size * nmemb;
    data_t *p = (data_t *)userdata;

    if (p->size + newdata_sz + 1 > p->alloc) {
        p->mem = realloc(p->mem, p->size + newdata_sz + 1);
        if (!p->mem) {
            fprintf(stderr, "failed to realloc");
            return 0;
        }
        p->alloc = p->size + newdata_sz + 1;
    }

    memcpy(&(p->mem[p->size]), ptr, newdata_sz);
    p->size += newdata_sz;
    p->mem[p->size] = '\0';

    return newdata_sz;
}

char *read_msg(size_t *length)
{
    char *data = NULL;
    char line[512];

    while (fgets(line, 512, stdin) != NULL) {
        if (strncmp(line, "Content-Length: ", 16) == 0)
            *length = atoi(line + 16);

        if (*length <= 0)
            continue;

        if (strcmp(line, "\r\n") == 0)
            break;

    }

    if (*length == 0)
        return NULL;

    data = malloc((*length + 1) * sizeof(char));

    if (data == NULL) {
        fprintf(stderr, "alloc failed\n");
        exit(EXIT_FAILURE);
    }

    fread(data, *length, 1, stdin);
    data[*length] = '\0';

    return data;
}

int main(int argc, char *argv[])
{

#if defined(WIN32)
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
#endif

    CURL *curl = curl_easy_init();
    struct curl_slist *headers = NULL;

    char *language = "rascal";

    if (argc > 1)
        language = argv[1];

    size_t size = strlen(rascal_web_addr) + strlen(language);
    char *address = malloc(size * sizeof(char));

    if (address == NULL) {
        fprintf(stderr, "malloc failed\n");
        return EXIT_FAILURE;
    }

    snprintf(address, size, rascal_web_addr, language);

    curl_easy_setopt(curl, CURLOPT_URL, address);

    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    curl_easy_setopt(curl, CURLOPT_POST, 1L);
    curl_easy_setopt(curl, CURLOPT_VERBOSE, 0L);

    while (1) {
        char *data = NULL;
        size_t length = 0;

        data = read_msg(&length);

        if (length == 0)
            continue;

        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, length);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);

        data_t response;
        response.mem = malloc(16);
        response.alloc = 0;
        response.size = 0;

        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, get_response_data);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&response);

        CURLcode res = curl_easy_perform(curl);

        if (res != CURLE_OK) {
            fprintf(stderr, "error: %s\n", curl_easy_strerror(res));
            exit(1);
        }

        fprintf(stdout, "Content-Length: %d\r\n\r\n", response.size);
        fwrite(response.mem, response.size, 1, stdout);
        fflush(stdout);

        free(data);
        free(response.mem);
    }

    free(address);

    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    curl_global_cleanup();

    return EXIT_SUCCESS;
}
