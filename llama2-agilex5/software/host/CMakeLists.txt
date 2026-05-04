cmake_minimum_required(VERSION 3.13)
project(host_gemv C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_library(fpga_gemv
    src/fpga_gemv.c
)

add_library(dma_buf
    src/dma_buf.c
)

target_include_directories(fpga_gemv
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_include_directories(dma_buf
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_options(fpga_gemv PRIVATE -O2 -Wall -Wextra -Werror)
target_compile_options(dma_buf   PRIVATE -O2 -Wall -Wextra -Werror)

add_executable(test_fpga_gemv
    tests/test_fpga_gemv.c
)
target_link_libraries(test_fpga_gemv PRIVATE fpga_gemv)
target_compile_options(test_fpga_gemv PRIVATE -O2 -Wall -Wextra -Werror)

add_executable(test_dma_buf
    tests/test_dma_buf.c
)
target_link_libraries(test_dma_buf PRIVATE dma_buf)
target_compile_options(test_dma_buf PRIVATE -O2 -Wall -Wextra -Werror)

add_executable(test_fpga_gemv_dma
    tests/test_fpga_gemv_dma.c
)
target_link_libraries(test_fpga_gemv_dma
    PRIVATE
    fpga_gemv
    dma_buf
)
target_compile_options(test_fpga_gemv_dma PRIVATE -O2 -Wall -Wextra -Werror)
