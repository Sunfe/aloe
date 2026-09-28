// mmio_write.c
// Usage:
//   sudo ./mmio_write <phys_addr_hex> <width:8|16|32|64> <value_hex>
//
// Example:
//   sudo ./mmio_write 0xF9000020 32 0x12345678
//   sudo ./mmio_write 0x4400040024 32 0x1
//
// Notes:
// - Requires root and /dev/mem access.
// - For 64-bit physical addresses on AArch64 Linux, compile with aarch64-linux-gnu-gcc.
// - This tool maps one page containing the target address, writes the value, then reads back.

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>

static void usage(const char *prog)
{
    fprintf(stderr,
        "Usage: %s <phys_addr_hex> <width:8|16|32|64> <value_hex>\n"
        "Example:\n"
        "  sudo %s 0xF9000020 32 0x12345678\n"
        "  sudo %s 0x4400040024 32 0x1\n",
        prog, prog, prog);
}

int main(int argc, char *argv[])
{
    if (argc != 4) {
        usage(argv[0]);
        return 1;
    }

    errno = 0;
    uint64_t phys_addr = strtoull(argv[1], NULL, 0);
    if (errno) {
        perror("strtoull(phys_addr)");
        return 1;
    }

    int width = atoi(argv[2]);
    if (!(width == 8 || width == 16 || width == 32 || width == 64)) {
        fprintf(stderr, "Invalid width: %d (must be 8,16,32,64)\n", width);
        return 1;
    }

    errno = 0;
    uint64_t value = strtoull(argv[3], NULL, 0);
    if (errno) {
        perror("strtoull(value)");
        return 1;
    }

    long page_size = sysconf(_SC_PAGESIZE);
    if (page_size <= 0) {
        perror("sysconf(_SC_PAGESIZE)");
        return 1;
    }

    uint64_t page_base = phys_addr & ~((uint64_t)page_size - 1);
    uint64_t page_off  = phys_addr - page_base;

    if ((page_off + (width / 8)) > (uint64_t)page_size) {
        fprintf(stderr, "Access crosses page boundary; not supported in this simple tool.\n");
        return 1;
    }

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open(/dev/mem)");
        return 1;
    }

    void *map = mmap(NULL, page_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, (off_t)page_base);
    if (map == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    volatile uint8_t  *p8  = (volatile uint8_t *)((uint8_t *)map + page_off);
    volatile uint16_t *p16 = (volatile uint16_t *)p8;
    volatile uint32_t *p32 = (volatile uint32_t *)p8;
    volatile uint64_t *p64 = (volatile uint64_t *)p8;

    printf("MMIO write: phys=0x%016" PRIx64 ", width=%d, value=0x%016" PRIx64 "\n",
           phys_addr, width, value);

    switch (width) {
    case 8:
        *p8 = (uint8_t)value;
        __sync_synchronize();
        printf("Readback: 0x%02" PRIx8 "\n", *p8);
        break;
    case 16:
        if (phys_addr & 0x1) {
            fprintf(stderr, "Unaligned 16-bit access: 0x%016" PRIx64 "\n", phys_addr);
            munmap(map, page_size);
            close(fd);
            return 1;
        }
        *p16 = (uint16_t)value;
        __sync_synchronize();
        printf("Readback: 0x%04" PRIx16 "\n", *p16);
        break;
    case 32:
        if (phys_addr & 0x3) {
            fprintf(stderr, "Unaligned 32-bit access: 0x%016" PRIx64 "\n", phys_addr);
            munmap(map, page_size);
            close(fd);
            return 1;
        }
        *p32 = (uint32_t)value;
        __sync_synchronize();
        printf("Readback: 0x%08" PRIx32 "\n", *p32);
        break;
    case 64:
        if (phys_addr & 0x7) {
            fprintf(stderr, "Unaligned 64-bit access: 0x%016" PRIx64 "\n", phys_addr);
            munmap(map, page_size);
            close(fd);
            return 1;
        }
        *p64 = (uint64_t)value;
        __sync_synchronize();
        printf("Readback: 0x%016" PRIx64 "\n", *p64);
        break;
    default:
        // already checked
        break;
    }

    munmap(map, page_size);
    close(fd);
    return 0;
}
