#define _GNU_SOURCE


#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>


static void usage(const char *name)
{
    fprintf(stderr,
            "用法:\n"
            "  %s fill  <phys_addr> <bytes> <pattern>\n"
            "  %s check <phys_addr> <bytes> <pattern>\n",
            name, name);
    exit(EXIT_FAILURE);
}


static uint64_t parse_u64(const char *s)
{
    char *end = NULL;
    errno = 0;


    unsigned long long value = strtoull(s, &end, 0);


    if (errno != 0 || end == s || *end != '\0') {
        fprintf(stderr, "无法解析数值: %s\n", s);
        exit(EXIT_FAILURE);
    }


    return (uint64_t)value;
}


static inline void dsb_sy(void)
{
#if defined(__aarch64__)
    __asm__ volatile("dsb sy" ::: "memory");
#else
    __sync_synchronize();
#endif
}


int main(int argc, char **argv)
{
    if (argc != 5)
        usage(argv[0]);


    const char *operation = argv[1];
    uint64_t phys_addr = parse_u64(argv[2]);
    uint64_t bytes64 = parse_u64(argv[3]);
    uint32_t pattern = (uint32_t)parse_u64(argv[4]);


    if (bytes64 == 0 || bytes64 > SIZE_MAX) {
        fprintf(stderr, "非法长度\n");
        return EXIT_FAILURE;
    }


    if ((phys_addr & 0x3) != 0 || (bytes64 & 0x3) != 0) {
        fprintf(stderr, "地址和长度必须是 4 字节对齐\n");
        return EXIT_FAILURE;
    }


    size_t bytes = (size_t)bytes64;
    long page_size = sysconf(_SC_PAGE_SIZE);


    if (page_size <= 0) {
        perror("sysconf");
        return EXIT_FAILURE;
    }


    uint64_t page_mask = (uint64_t)page_size - 1;
    uint64_t page_addr = phys_addr & ~page_mask;
    size_t page_offset = (size_t)(phys_addr - page_addr);


    if (bytes > SIZE_MAX - page_offset) {
        fprintf(stderr, "映射长度溢出\n");
        return EXIT_FAILURE;
    }


    size_t map_len = page_offset + bytes;
    map_len = (map_len + (size_t)page_size - 1) &
              ~((size_t)page_size - 1);


    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open /dev/mem");
        return EXIT_FAILURE;
    }


    void *map_base = mmap(NULL,
                          map_len,
                          PROT_READ | PROT_WRITE,
                          MAP_SHARED,
                          fd,
                          (off_t)page_addr);


    if (map_base == MAP_FAILED) {
        perror("mmap shared DDR");
        close(fd);
        return EXIT_FAILURE;
    }


    volatile uint32_t *mem =
        (volatile uint32_t *)((char *)map_base + page_offset);


    size_t words = bytes / sizeof(uint32_t);


    if (strcmp(operation, "fill") == 0) {
        for (size_t i = 0; i < words; ++i)
            mem[i] = pattern;


        dsb_sy();


        printf("FILL PASS: address=0x%llx bytes=0x%llx pattern=0x%08x\n",
               (unsigned long long)phys_addr,
               (unsigned long long)bytes64,
               pattern);
    } else if (strcmp(operation, "check") == 0) {
        size_t error_count = 0;


        dsb_sy();


        for (size_t i = 0; i < words; ++i) {
            uint32_t actual = mem[i];


            if (actual != pattern) {
                if (error_count < 8) {
                    fprintf(stderr,
                            "Mismatch at 0x%llx: expected=0x%08x actual=0x%08x\n",
                            (unsigned long long)(phys_addr +
                                                 i * sizeof(uint32_t)),
                            pattern,
                            actual);
                }
                ++error_count;
            }
        }


        if (error_count != 0) {
            fprintf(stderr, "CHECK FAIL: errors=%zu\n", error_count);
            munmap(map_base, map_len);
            close(fd);
            return EXIT_FAILURE;
        }


        printf("CHECK PASS: address=0x%llx bytes=0x%llx pattern=0x%08x\n",
               (unsigned long long)phys_addr,
               (unsigned long long)bytes64,
               pattern);
    } else {
        usage(argv[0]);
    }


    munmap(map_base, map_len);
    close(fd);
    return EXIT_SUCCESS;
}
