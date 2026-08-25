#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
豆包办公端 Skill 生态健康度守卫 v0.1
功能: 检测 .user_skills 目录下 Skill 软链接的健康度
检测项: 1.软链接有效性 2.SKILL.md存在 3.frontmatter完整 4.版本号存在 5.断链修复建议
退出码: 0=全健康 1=有异常 2=参数错误
作者: 皮叔
用法: python3 doubaowork_skill_health_guard.py --mc <记忆中心路径> [--json]
"""
import os
import sys
import argparse
import json
from pathlib import Path

def find_user_skills_dir(mc: str) -> str:
    """查找豆包办公 .user_skills 目录（macOS/Windows通用）"""
    candidates = []
    home = os.path.expanduser("~")
    
    # macOS 路径
    mac_path = os.path.join(home, "Library", "Application Support", "DoubaoWork", 
                            "Default", ".doubaowork", "agent_mode", "workspace", ".user_skills")
    candidates.append(mac_path)
    
    # Windows 路径
    win_path = os.path.join(os.environ.get("APPDATA", home), "DoubaoWork", "Default",
                            ".doubaowork", "agent_mode", "workspace", ".user_skills")
    candidates.append(win_path)
    
    # 记忆中心下的软链接目录（如果有）
    mc_skills = os.path.join(mc, "技能配置")
    candidates.append(mc_skills)
    
    for c in candidates:
        if os.path.isdir(c):
            return c
    return ""

def check_skill(skill_path: str) -> dict:
    """检查单个Skill的健康度"""
    result = {
        "name": os.path.basename(skill_path),
        "path": skill_path,
        "is_symlink": os.path.islink(skill_path),
        "link_target": "",
        "link_valid": True,
        "skill_md_exists": False,
        "frontmatter_complete": False,
        "version_exists": False,
        "status": "healthy",
        "issues": []
    }
    
    # 检查软链接
    if result["is_symlink"]:
        target = os.readlink(skill_path)
        result["link_target"] = target
        if not os.path.exists(skill_path):
            result["link_valid"] = False
            result["status"] = "broken"
            result["issues"].append(f"软链接断链: {target}")
            return result
    
    # 检查SKILL.md
    skill_md = os.path.join(skill_path, "SKILL.md")
    if os.path.isfile(skill_md):
        result["skill_md_exists"] = True
        try:
            with open(skill_md, "r", encoding="utf-8") as f:
                content = f.read(2000)  # 只读前2000字符
            # 检查frontmatter
            if content.startswith("---"):
                end = content.find("---", 3)
                if end > 0:
                    fm = content[3:end]
                    if "name:" in fm and "description:" in fm:
                        result["frontmatter_complete"] = True
                    if "version:" in fm:
                        result["version_exists"] = True
        except Exception as e:
            result["issues"].append(f"读取SKILL.md失败: {e}")
    else:
        result["issues"].append("SKILL.md不存在")
    
    # 综合判定
    if not result["frontmatter_complete"]:
        result["status"] = "warning"
        result["issues"].append("frontmatter不完整")
    if not result["version_exists"]:
        if result["status"] == "healthy":
            result["status"] = "warning"
        result["issues"].append("版本号缺失")
    
    return result

def main():
    parser = argparse.ArgumentParser(description="豆包办公端Skill生态健康度守卫")
    parser.add_argument("--mc", required=True, help="记忆共享中心路径")
    parser.add_argument("--json", action="store_true", help="JSON格式输出")
    args = parser.parse_args()
    
    mc = os.path.expanduser(args.mc)
    if not os.path.isdir(mc):
        print(f"错误: 记忆中心不存在: {mc}", file=sys.stderr)
        sys.exit(2)
    
    skills_dir = find_user_skills_dir(mc)
    if not skills_dir:
        print("错误: 未找到.user_skills目录", file=sys.stderr)
        sys.exit(2)
    
    # 扫描所有Skill
    skills = []
    for item in sorted(os.listdir(skills_dir)):
        item_path = os.path.join(skills_dir, item)
        if os.path.isdir(item_path) or os.path.islink(item_path):
            skills.append(check_skill(item_path))
    
    # 统计
    total = len(skills)
    healthy = sum(1 for s in skills if s["status"] == "healthy")
    warning = sum(1 for s in skills if s["status"] == "warning")
    broken = sum(1 for s in skills if s["status"] == "broken")
    
    if args.json:
        output = {
            "skills_dir": skills_dir,
            "total": total,
            "healthy": healthy,
            "warning": warning,
            "broken": broken,
            "skills": skills
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        print(f"=== 豆包办公端Skill健康度检测 ===")
        print(f"Skill目录: {skills_dir}")
        print(f"总计: {total} | 健康: {healthy} | 警告: {warning} | 断链: {broken}")
        print()
        for s in skills:
            icon = "✅" if s["status"] == "healthy" else ("⚠️" if s["status"] == "warning" else "❌")
            link_info = f"→{s['link_target']}" if s["is_symlink"] else "(目录)"
            print(f"{icon} {s['name']} {link_info}")
            for issue in s["issues"]:
                print(f"   - {issue}")
        print()
        if broken > 0:
            print(f"❌ 有{broken}个断链Skill，建议修复软链接")
        elif warning > 0:
            print(f"⚠️ 有{warning}个Skill有警告，建议补全frontmatter/版本号")
        else:
            print(f"✅ 全部{total}个Skill健康")
    
    sys.exit(1 if broken > 0 else 0)

if __name__ == "__main__":
    main()
