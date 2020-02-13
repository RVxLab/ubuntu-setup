import subprocess
from typing import List

class Step:
    def __init__(self):
        if self.__class__ is Step:
            raise Exception('Cannot instantiate Step, use subclasses')

    def run(self):
        raise NotImplementedError('Step.run needs to be overwritten')

class AptStep(Step):
    def __init__(self, packages: List[str], ppa=None):
        super().__init__()

        self.packages = packages
        self.ppa = ppa

    def run(self):
        if self.ppa is not None:
            self.install_ppa()

        self.install_packages()

    def install_ppa(self):
        subprocess.run('sudo add-apt-repository -y {}'.format(self.ppa), shell=True)

    def install_packages(self):
        subprocess.run('sudo apt-get install -yqq {}'.format(' '.format(self.packages)), shell=True)



class CommandStep(Step):
    pass


def get_steps() -> List[Step]:
    return [
        AptStep(packages=['curl', 'wget', 'zsh', 'git'])
    ]


def main():
    # Install main packages

    steps = get_steps()

    for step in steps:
        step.run()


if __name__ == '__main__':
    main()
