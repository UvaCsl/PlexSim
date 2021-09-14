import os
from modulefinder import ModuleFinder


def module_finder(path: str) -> dict:
    extension = ".pyx .pxd .py".split()
    modules = dict()
    for root, _, filename in os.path.walk(path):
        if ext in extensions:
            path = os.path.join(root, filename)
            print(ModuleFinder(path).modules)

    return modules
