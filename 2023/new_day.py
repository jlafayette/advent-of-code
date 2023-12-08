import shutil
import sys
from pathlib import Path


def main():
    day = sys.argv[1]
    dir_ = Path(__file__).resolve().parent
    src = dir_ / "template"
    dst = dir_ / f"day{day:0>2}"
    dst.mkdir()
    shutil.copyfile(
        (src / "day__.py"),
        (dst / f"day{day:0>2}.py"),
    )
    (dst / "input").touch()


if __name__ == "__main__":
    main()
