#!/usr/bin/env python3
"""
new_lab.py

用于在 containerlab-labs 中创建标准化实验目录结构。
支持 FRR / SONiC 实验，自动注入方法论约束与模板。

使用示例：
  python3 scripts/new_lab.py --nos frr --id 01 --name egp_igp_rr
"""

import argparse
from pathlib import Path
from shutil import copyfile

# ----------------------------
# 实验目录结构定义
# ----------------------------
LAB_STRUCTURE = {
    "topo": ["topo.yml", "address-plan.md"],
    "configs": [],
    "captures": ["bgp", "ospf"],
    "diagrams": ["topology", "sequence", "control-plane"],
    "analysis": ["analysis.md", "notes.md"],
    "results": ["summary.md"],
}

# ----------------------------
# README 模板（自动引用方法论）
# ----------------------------
README_TEMPLATE = """# {lab_id}_{lab_name}

> 本实验遵循以下规范：
> - docs/methodology/experiment-directory-structure.md
> - docs/methodology/experiment-lifecycle.md
> - docs/methodology/experiment-design.md

## 实验目标

## 实验拓扑

## 实验假设

## 结论摘要
"""

# ----------------------------
# 模板注入函数
# ----------------------------
def copy_analysis_template(lab_dir: Path, root: Path):
    """
    将 docs/templates/analysis-template.md 复制为
    当前实验的 analysis/analysis.md（若存在则不覆盖）
    """
    tpl = root / "docs" / "templates" / "analysis-template.md"
    dst = lab_dir / "analysis" / "analysis.md"
    if tpl.exists() and not dst.exists():
        copyfile(tpl, dst)


def init_plantuml_templates(lab_dir: Path):
    """
    为实验初始化 PlantUML 图模板
    """
    diagram_dir = lab_dir / "diagrams"
    for sub in ["topology", "sequence", "control-plane"]:
        p = diagram_dir / sub / "template.puml"
        if not p.exists():
            p.write_text(
                "@startuml\n"
                "' TODO: 描述本实验相关图\n"
                "@enduml\n",
                encoding="utf-8",
            )


# ----------------------------
# 实验创建逻辑
# ----------------------------
def create_lab(base: Path, lab_id: str, lab_name: str, root: Path):
    lab_dir = base / f"{lab_id}_{lab_name}"
    lab_dir.mkdir(parents=True, exist_ok=False)

    # README
    (lab_dir / "README.md").write_text(
        README_TEMPLATE.format(lab_id=lab_id, lab_name=lab_name),
        encoding="utf-8",
    )

    # 子目录与文件
    for folder, items in LAB_STRUCTURE.items():
        folder_path = lab_dir / folder
        folder_path.mkdir()

        for item in items:
            p = folder_path / item
            if "." in item:
                p.write_text("", encoding="utf-8")
            else:
                p.mkdir()

    # 注入模板
    copy_analysis_template(lab_dir, root)
    init_plantuml_templates(lab_dir)

    print(f"[OK] Lab created at: {lab_dir}")


# ----------------------------
# CLI 入口
# ----------------------------
def main():
    ap = argparse.ArgumentParser(
        description="Create a new standardized containerlab experiment",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    ap.add_argument(
        "--nos",
        required=True,
        choices=["frr", "sonic"],
        help="目标 NOS 类型",
    )
    ap.add_argument(
        "--id",
        required=True,
        help="实验编号，如 01",
    )
    ap.add_argument(
        "--name",
        required=True,
        help="实验名称，如 egp_igp_rr",
    )

    args = ap.parse_args()

    # 仓库根目录（containerlab-labs）
    root = Path(__file__).resolve().parents[1]
    lab_base = root / args.nos / "labs"

    if not lab_base.exists():
        raise RuntimeError(
            f"{lab_base} does not exist.\n"
            "请先在 containerlab-labs 根目录执行 scripts/init_repo.py"
        )

    create_lab(lab_base, args.id, args.name, root)


if __name__ == "__main__":
    main()
