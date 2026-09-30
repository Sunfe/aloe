/*
 * ============================================================================
 * 文件：test_gemv_4x4_fp32.c
 *
 * 功能：
 *   运行一次固定规模的 4x4 FP32 GEMV 端到端测试。
 *
 * 测试对象：
 *   FPGA 中的 gemv_4x4_test_1 实例。
 *
 * 计算内容：
 *
 *       W = [ 1,  2,  3,  4]
 *           [ 5,  6,  7,  8]
 *           [ 9, 10, 11, 12]
 *           [13, 14, 15, 16]
 *
 *       x = [1, 2, 3, 4]
 *
 *       y = W * x
 *         = [30, 70, 110, 150]
 *
 * 测试流程：
 *   1. HPS 将 W 和 x 写入共享 DDR；
 *   2. HPS 清除 GEMV 状态；
 *   3. HPS 通过 GEMV CSR 配置 W、x、y 的物理地址；
 *   4. HPS 写入 START 命令；
 *   5. FPGA 通过 AXI master 从 DDR 读取 W 和 x；
 *   6. FPGA 使用 FP32 multiplier 和 FP32 adder 完成 GEMV；
 *   7. FPGA 通过 AXI master 将 y 写回共享 DDR；
 *   8. HPS 轮询 STATUS；
 *   9. HPS 读取并校验 y。
 *
 * 当前 GEMV CSR 地址：
 *   0x20020000
 *
 * 当前共享 DDR 数据布局：
 *   W = 0xB8000000，大小 64 字节；
 *   x = 0xB8001000，大小 16 字节；
 *   y = 0xB8002000，大小 16 字节。
 *
 * 预期 FP32 位模式：
 *   y[0] = 0x41F00000，即 30.0；
 *   y[1] = 0x428C0000，即 70.0；
 *   y[2] = 0x42DC0000，即 110.0；
 *   y[3] = 0x43160000，即 150.0。
 *
 * 本测试的性质：
 *   这是 GEMV 的 HPS-FPGA 端到端功能测试。
 *   它同时验证 HPS DDR 写入、GEMV CSR 配置、FPGA AXI DDR 读取、
 *   FP32 运算、FPGA AXI DDR 写回和 HPS 结果校验。
 *
 * 前提条件：
 *   1. Linux 启动参数必须包含 mem=896M；
 *   2. FPGA 已烧写包含 gemv_4x4_test_1 的映像；
 *   3. 必须以 root 权限运行；
 *   4. GEMV 使用的共享 DDR 区域不能被其他测试同时使用。
 *
 * 注意：
 *   本程序会覆盖 W、x 和 y 对应的共享 DDR 区域。
 * ============================================================================
 */

#define _DEFAULT_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#define GEMV_CSR_BASE_DEFAULT 0x20020000ULL

#define W_PHYS_ADDR 0xB8000000ULL
#define X_PHYS_ADDR 0xB8001000ULL
#define Y_PHYS_ADDR 0xB8002000ULL

#define SHARED_MAP_BASE 0xB8000000ULL
#define SHARED_MAP_SIZE 0x3000ULL
#define CSR_MAP_SIZE    0x1000ULL

/* GEMV CSR offsets */
#define REG_CTRL       0x00
#define REG_STATUS     0x04
#define REG_W_ADDR_LO  0x08
#define REG_W_ADDR_HI  0x0C
#define REG_X_ADDR_LO  0x10
#define REG_X_ADDR_HI  0x14
#define REG_Y_ADDR_LO  0x18
#define REG_Y_ADDR_HI  0x1C
#define REG_CYCLES     0x20
#define REG_VERSION    0x24
#define REG_DEBUG      0x28

/* CTRL */
#define CTRL_START 0x00000001u
#define CTRL_CLEAR 0x00000004u

/* STATUS */
#define STATUS_BUSY      (1u << 0)
#define STATUS_DONE      (1u << 1)
#define STATUS_ERROR     (1u << 2)
#define STATUS_PARAM_ERR (1u << 3)
#define STATUS_RESP_ERR  (1u << 4)
#define STATUS_PROTO_ERR (1u << 5)

#define EXPECTED_VERSION 0x474D5631u

struct phys_map {
    void *mapping_base;
    size_t mapping_length;
    volatile uint8_t *ptr;
};

static inline void memory_barrier(void)
{
#if defined(__aarch64__)
    asm volatile("dsb sy" ::: "memory");
#else
    __sync_synchronize();
#endif
}

static int map_physical(
    int fd,
    uint64_t physical_address,
    size_t length,
    struct phys_map *result)
{
    long page_size;
    uint64_t page_mask;
    uint64_t page_base;
    size_t page_offset;
    size_t mapping_length;
    void *mapping;

    page_size = sysconf(_SC_PAGESIZE);
    if (page_size <= 0) {
        fprintf(stderr, "sysconf(_SC_PAGESIZE) failed\n");
        return -1;
    }

    page_mask = (uint64_t)page_size - 1;
    page_base = physical_address & ~page_mask;
    page_offset = (size_t)(physical_address - page_base);
    mapping_length = page_offset + length;

    mapping = mmap(
        NULL,
        mapping_length,
        PROT_READ | PROT_WRITE,
        MAP_SHARED,
        fd,
        (off_t)page_base
    );

    if (mapping == MAP_FAILED) {
        fprintf(
            stderr,
            "mmap(0x%016llX, 0x%zX) failed: %s\n",
            (unsigned long long)physical_address,
            length,
            strerror(errno)
        );
        return -1;
    }

    result->mapping_base = mapping;
    result->mapping_length = mapping_length;
    result->ptr = (volatile uint8_t *)mapping + page_offset;

    return 0;
}

static void unmap_physical(struct phys_map *mapping)
{
    if (mapping->mapping_base != NULL) {
        munmap(mapping->mapping_base, mapping->mapping_length);
        mapping->mapping_base = NULL;
        mapping->mapping_length = 0;
        mapping->ptr = NULL;
    }
}

static inline void csr_write(
    volatile uint32_t *csr,
    uint32_t offset,
    uint32_t value)
{
    csr[offset / 4] = value;
    memory_barrier();
}

static inline uint32_t csr_read(
    volatile uint32_t *csr,
    uint32_t offset)
{
    uint32_t value;

    memory_barrier();
    value = csr[offset / 4];
    memory_barrier();

    return value;
}

static void write_u64_register(
    volatile uint32_t *csr,
    uint32_t low_offset,
    uint32_t high_offset,
    uint64_t value)
{
    csr_write(csr, low_offset, (uint32_t)(value & 0xFFFFFFFFULL));
    csr_write(csr, high_offset, (uint32_t)(value >> 32));
}

static uint32_t float_bits(float value)
{
    uint32_t bits;

    memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static uint64_t monotonic_ms(void)
{
    struct timespec ts;

    clock_gettime(CLOCK_MONOTONIC, &ts);

    return (uint64_t)ts.tv_sec * 1000ULL +
           (uint64_t)ts.tv_nsec / 1000000ULL;
}

static int parse_u64(const char *text, uint64_t *value)
{
    char *end;
    unsigned long long parsed;

    errno = 0;
    parsed = strtoull(text, &end, 0);

    if (errno != 0 || end == text || *end != '\0') {
        return -1;
    }

    *value = (uint64_t)parsed;
    return 0;
}

int main(int argc, char **argv)
{
    const uint32_t expected_y[4] = {
        0x41F00000u, /* 30.0  */
        0x428C0000u, /* 70.0  */
        0x42DC0000u, /* 110.0 */
        0x43160000u  /* 150.0 */
    };

    uint64_t csr_phys = GEMV_CSR_BASE_DEFAULT;
    struct phys_map csr_map = {0};
    struct phys_map shared_map = {0};

    volatile uint32_t *csr;
    volatile uint32_t *shared32;

    int devmem_fd;
    int result_code = 1;
    int all_pass = 1;

    if (argc > 2) {
        fprintf(stderr, "Usage: %s [gemv_csr_phys_addr]\n", argv[0]);
        return 2;
    }

    if (argc == 2 && parse_u64(argv[1], &csr_phys) != 0) {
        fprintf(stderr, "Invalid CSR address: %s\n", argv[1]);
        return 2;
    }

    printf("GEMV CSR base : 0x%016llX\n",
           (unsigned long long)csr_phys);
    printf("W address     : 0x%016llX\n",
           (unsigned long long)W_PHYS_ADDR);
    printf("X address     : 0x%016llX\n",
           (unsigned long long)X_PHYS_ADDR);
    printf("Y address     : 0x%016llX\n",
           (unsigned long long)Y_PHYS_ADDR);

    devmem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (devmem_fd < 0) {
        fprintf(stderr, "open(/dev/mem) failed: %s\n", strerror(errno));
        return 1;
    }

    if (map_physical(
            devmem_fd,
            csr_phys,
            CSR_MAP_SIZE,
            &csr_map) != 0) {
        goto cleanup_fd;
    }

    if (map_physical(
            devmem_fd,
            SHARED_MAP_BASE,
            SHARED_MAP_SIZE,
            &shared_map) != 0) {
        goto cleanup_csr;
    }

    csr = (volatile uint32_t *)csr_map.ptr;
    shared32 = (volatile uint32_t *)shared_map.ptr;

    printf("VERSION      : 0x%08X\n",
           csr_read(csr, REG_VERSION));

    if (csr_read(csr, REG_VERSION) != EXPECTED_VERSION) {
        fprintf(
            stderr,
            "Unexpected GEMV VERSION. Expected 0x%08X.\n",
            EXPECTED_VERSION
        );
        goto cleanup_shared;
    }

    /*
     * Write W in row-major order:
     *
     * [ 1,  2,  3,  4]
     * [ 5,  6,  7,  8]
     * [ 9, 10, 11, 12]
     * [13, 14, 15, 16]
     */
    for (unsigned int row = 0; row < 4; row++) {
        for (unsigned int col = 0; col < 4; col++) {
            float value = (float)(row * 4 + col + 1);
            size_t index = (row * 4 + col);

            shared32[index] = float_bits(value);
        }
    }

    /* Write x = [1, 2, 3, 4]. */
    for (unsigned int col = 0; col < 4; col++) {
        shared32[(X_PHYS_ADDR - SHARED_MAP_BASE) / 4 + col] =
            float_bits((float)(col + 1));
    }

    /* Clear the output area before starting. */
    for (unsigned int i = 0; i < 4; i++) {
        shared32[(Y_PHYS_ADDR - SHARED_MAP_BASE) / 4 + i] = 0;
    }

    memory_barrier();

    /*
     * Clear previous GEMV state.
     */
    csr_write(csr, REG_CTRL, CTRL_CLEAR);

    /*
     * Program W, x and y physical addresses.
     */
    write_u64_register(
        csr,
        REG_W_ADDR_LO,
        REG_W_ADDR_HI,
        W_PHYS_ADDR
    );

    write_u64_register(
        csr,
        REG_X_ADDR_LO,
        REG_X_ADDR_HI,
        X_PHYS_ADDR
    );

    write_u64_register(
        csr,
        REG_Y_ADDR_LO,
        REG_Y_ADDR_HI,
        Y_PHYS_ADDR
    );

    memory_barrier();

    printf("Starting 4x4 FP32 GEMV...\n");
    csr_write(csr, REG_CTRL, CTRL_START);

    {
        const uint64_t timeout_ms = 5000;
        const uint64_t start_ms = monotonic_ms();
        uint32_t status = 0;

        while (monotonic_ms() - start_ms < timeout_ms) {
            status = csr_read(csr, REG_STATUS);

            if (status & STATUS_DONE) {
                break;
            }

            struct timespec delay = {
                .tv_sec = 0,
                .tv_nsec = 1000000L
            };

            nanosleep(&delay, NULL);
        }

        status = csr_read(csr, REG_STATUS);

        printf("STATUS       : 0x%08X\n", status);
        printf("CYCLES       : 0x%08X\n",
               csr_read(csr, REG_CYCLES));
        printf("DEBUG        : 0x%08X\n",
               csr_read(csr, REG_DEBUG));

        if (!(status & STATUS_DONE)) {
            fprintf(stderr, "GEMV timeout.\n");
            goto cleanup_shared;
        }

        if (status & STATUS_ERROR) {
            fprintf(
                stderr,
                "GEMV hardware error: status=0x%08X\n",
                status
            );
            goto cleanup_shared;
        }
    }

    memory_barrier();

    printf("Output y:\n");

    for (unsigned int i = 0; i < 4; i++) {
        uint32_t actual =
            shared32[(Y_PHYS_ADDR - SHARED_MAP_BASE) / 4 + i];

        printf(
            "  y[%u] = 0x%08X, expected 0x%08X%s\n",
            i,
            actual,
            expected_y[i],
            actual == expected_y[i] ? " PASS" : " FAIL"
        );

        if (actual != expected_y[i]) {
            all_pass = 0;
        }
    }

    if (all_pass) {
        printf("[PASS] 4x4 FP32 GEMV result is correct.\n");
        result_code = 0;
    } else {
        printf("[FAIL] 4x4 FP32 GEMV result is incorrect.\n");
    }

cleanup_shared:
    unmap_physical(&shared_map);

cleanup_csr:
    unmap_physical(&csr_map);

cleanup_fd:
    close(devmem_fd);
    return result_code;
}