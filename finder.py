import os
from modulefinder import ModuleFinder


def module_finder(path: str) -> dict:
    extensions = " py".split()
    modules = dict()
    for root, _, files in os.walk(path):
        for filename in files:
            ext = filename.split(".")[-1]
            if ext in extensions and not filename.startswith("_"):
                path = os.path.join(root, filename)
                mod = ModuleFinder()
                mod.run_script(path)
                for k, v in mod.modules.items():
                    print(k)
                print(path)
                assert 0

    return modules


if __name__ == "__main__":
    module_finder("./plexsim")
