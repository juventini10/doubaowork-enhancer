version: 1.2.0
date: 2026-08-25
author: 皮叔
name: 豆包办公加强包
name_en: DoubaoWork Enhancer
compatible_platforms: [macOS, Windows, Linux]
compatible_tools: [豆包办公, DoubaoWork]
prerequisite: 布洛陀五层记忆系统(基础安装包)
changelog:
  - version: 1.2.0
    date: 2026-08-25
    changes:
      - 布洛陀-豆包办公规则 Skill 模板 v1.0→v1.1：route_audit 守卫从1维度（命中审计）扩到4维度（命中审计/未知未知/知识库检索/路由家族健康度），覆盖6守卫审计面，不独立成3个守卫（最小方案优先）
      - 全局蒸馏体系对齐：豆包办公端定位=留痕生产者（系统日志每日记录+成长箱事件驱动），不独立做每日蒸馏，蒸馏产物通过全局三套月度蒸馏体系反哺到规范/五系统文件→新会话T0加载
      - 五系统文件模板保持通用版本（不含数字分身，用户按需自行扩展）
      - setup/verify/rollback 脚本无需变更（安装包不创建蒸馏定时任务，仅提供巡逻脚本挂载建议）
  - version: 1.1.0
    date: 2026-08-25
    changes:
      - 新增 custom-prompt-to-copy.md（通俗话术说明+可复制指令文本+常见问题）
      - setup.sh/setup.ps1 安装完成后自动复制自定义指令到剪贴板（Mac=pbcopy/Win=Set-Clipboard）+ 自动打开豆包办公
      - 完成报告改用通俗话术（为什么要配置/不配置会怎样/3步操作指引），兼顾Mac（⌘V）和Win（Ctrl+V）
      - verify.sh/verify.ps1 末尾新增手动验证提示（开新对话问愿景验证云端配置是否生效）
      - README 新增「安装后必做：配置工作任务偏好指令」醒目章节
      - 全量通用化：移除个人化称呼（→你/用户）和专属数字分身（→数字分身可选/直接移除），发布包零个人化内容，仅保留记忆系统通用框架和规则
  - version: 1.0.0
    date: 2026-08-25
    changes:
      - 首发版本
