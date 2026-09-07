# 与 GHRD 自带的 sdc 一起加载. Pro 版 IOPLL 的输出时钟由 IP 自己约束, 不要再写 derive_pll_clocks.
# 板载参考时钟 (引脚名以 DE25-Standard 手册 / GHRD .qsf 为准)
create_clock -name clk_ref_100 -period 10.000 [get_ports CLK_100_B3I]
derive_clock_uncertainty
# 加速器在 HPS 输出的 h2f_user0_clk 域或 PLL 输出域; 先在 PLL 设 100MHz, 时序收敛后再改 200MHz.