import dataclasses
from pathlib import Path
from typing import Optional


TEST_INPUT = """$ cd /
$ ls
dir a
14848514 b.txt
8504156 c.dat
dir d
$ cd a
$ ls
dir e
29116 f
2557 g
62596 h.lst
$ cd e
$ ls
584 i
$ cd ..
$ cd ..
$ cd d
$ ls
4060174 j
8033020 d.log
5626152 d.ext
7214296 k
"""

# - / (dir)
#   - a (dir)
#     - e (dir)
#       - i (file, size=584)
#     - f (file, size=29116)
#     - g (file, size=2557)
#     - h.lst (file, size=62596)
#   - b.txt (file, size=14848514)
#   - c.dat (file, size=8504156)
#   - d (dir)
#     - j (file, size=4060174)
#     - d.log (file, size=8033020)
#     - d.ext (file, size=5626152)
#     - k (file, size=7214296)


@dataclasses.dataclass
class File:
    size: int


@dataclasses.dataclass
class Dir:
    name: str
    files: list[File]
    dirs: dict[str: "Dir"]
    parent: Optional["Dir"]
    size: int = 0
    ls_ran: bool = False

    def find(self, condition, results: list["Dir"]):
        if condition(self):
            results.append(self)
        for _, d in self.dirs.items():
            d.find(condition, results)


class Tree:
    def __init__(self):
        self.root = Dir(files=[], dirs={}, parent=None, name="")
        self.cwd = self.root

    def ls(self, results: list[str]):
        if self.cwd.ls_ran:
            return
        self.cwd.ls_ran = True
        for result in results:
            a, b = result.split()
            if a == "dir":
                self.cwd.dirs[b] = Dir(files=[], dirs={}, parent=self.cwd, name=b)
            else:
                self.cwd.files.append(File(size=int(a)))
                self._back_propagate_size(int(a))

    def _back_propagate_size(self, size: int):
        d = self.cwd
        while d is not None:
            d.size += size
            d = d.parent

    def cd(self, new_d: str):
        if new_d == "/":
            self.cwd = self.root
            return
        if new_d == "..":
            self.cwd = self.cwd.parent
        else:
            self.cwd = self.cwd.dirs[new_d]

    def find(self, condition):
        d = self.root
        results = []
        d.find(condition, results)
        return results


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT

    commands = []
    current = []
    for line in data.strip().split("\n"):
        if line.startswith("$"):
            if current:
                commands.append(current)
                current = []
            current.append(line[2:])
            continue
        current.append(line)
    if current:
        commands.append(current)
    return commands


def build_tree() -> Tree:
    tree = Tree()
    commands = read_input()
    # print(commands)
    for command in commands:
        cmd, *results = command
        # print(f"$ {cmd}")
        # print(results)

        if cmd.startswith("cd"):
            _, new_dir = cmd.split()
            tree.cd(new_dir)
        elif cmd == "ls":
            tree.ls(results)
    return tree


def part1():
    tree = build_tree()
    results = tree.find(lambda d: d.size <= 100_000)
    # print(len(results))
    # for r in results:
    #     print(r.name, r.size)
    print(sum([d.size for d in results]))


def part2():
    tree = build_tree()
    max_space = 70_000_000
    update_space_needed = 30_000_000

    print(f"size: {tree.root.size:,}")
    free_space = max_space - tree.root.size
    print(f"free space: {free_space:,}")
    amount_to_delete = update_space_needed - free_space
    print(f"amount to delete: {amount_to_delete:,}")
    dirs = tree.find(lambda d: d.size >= amount_to_delete)
    print([d.name for d in dirs])
    print(min([d.size for d in dirs]))


part1()
part2()
