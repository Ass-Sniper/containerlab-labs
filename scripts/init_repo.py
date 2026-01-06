#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT_DIRS = {
    "docs": ["setup", "templates", "methodology"],
    "scripts": [],
    "frr": ["labs", "base"],
    "sonic": ["labs", "base"],
    "images": ["topology", "sequence", "icons"],
}

def main():
    root = Path.cwd()

    # 防误操作保护
    if root.name != "containerlab-labs":
        print(
            "[ERROR] init_repo.py must be run inside 'containerlab-labs' directory.\n"
            f"Current directory: {root}\n"
            "Please:\n"
            "  mkdir containerlab-labs && cd containerlab-labs\n"
            "  python3 scripts/init_repo.py"
        )
        sys.exit(1)

    for d, subs in ROOT_DIRS.items():
        dpath = root / d
        dpath.mkdir(exist_ok=True)
        for sub in subs:
            (dpath / sub).mkdir(exist_ok=True)

    # 根 README
    readme = root / "README.md"
    if not readme.exists():
        readme.write_text(
            "# containerlab-labs\n\n"
            "基于 containerlab 的网络协议实验仓库，覆盖 FRR / SONiC。\n",
            encoding="utf-8",
        )

    print(f"[OK] containerlab-labs initialized at {root}")

if __name__ == "__main__":
    main()
