#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
int main(int argc, char **argv)
{
    int fd;
    uint64_t addr, page, offset;
    void *map;
    volatile uint32_t *reg;
    if (argc != 2) {
        fprintf(stderr, "usage: %s <physical-address>\n", argv[0]);
        return 2;
    }
    addr = strtoull(argv[1], NULL, 0);
    page = addr & ~0xfffULL;
    offset = addr & 0xfffULL;
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        fprintf(stderr, "open /dev/mem: %s\n", strerror(errno));
        return 1;
    }
    map = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, page);
    if (map == MAP_FAILED) {
        fprintf(stderr, "mmap 0x%016" PRIx64 ": %s\n", page, strerror(errno));
        close(fd);
        return 1;
    }
    reg = (volatile uint32_t *)((uint8_t *)map + offset);
    printf("address 0x%016" PRIx64 " = 0x%08" PRIx32 "\n", addr, *reg);
    munmap(map, 4096);
    close(fd);
    return 0;
}
