import subprocess
from typing import List, Dict, Tuple
from argparse import ArgumentParser
import csv


class Source:
    def __init__(self):
        if self.__class__ is Source:
            raise Exception('Cannot instantiate Source, use subclasses')

    def get(self):
        raise NotImplementedError('Source.get needs to be overwritten')


class AptPackage(Source):
    def __init__(self, package):
        super().__init__()

        self.package = package

    def get(self):
        return self.package


class AptRepository:
    def __init__(self, repo: str, gpg_key_location: str = None):
        self.repo = repo
        self.gpg_key_location = gpg_key_location


class Apt:
    def __init__(self, args):
        self.args = args

    @property
    def verbose_flags(self) -> str:
        if self.args.verbose:
            return '-y'

        return '-yqq'

    def run_command(self, command: str):
        subprocess.run(command, shell=True)

    def install(self, packages: List[AptPackage]):
        command = 'sudo apt-get install {} {}'.format(self.verbose_flags, ' '.join(list(map(lambda package: package.get(), packages))))

        self.run_command(command)

    def add_repo(self, repo: str):
        command = 'sudo add-apt-repository -y "{}"'.format(repo)

        self.run_command(command)

    def update(self):
        self.run_command('sudo apt-get update')

    def upgrade(self):
        self.run_command('sudo apt-get dist-upgrade {}'.format(self.verbose_flags))

    def add_key(self, key_location: str):
        self.run_command('curl -fsSL {} | sudo apt-key add -'.format(key_location))


def dict_to_apt_packages(dictionary: Dict) -> List[AptPackage]:
    valid_packages = dict(filter(lambda entry: entry[1], dictionary.items()))

    packages = map(lambda package: AptPackage(package), valid_packages)

    return list(packages)


def get_repos(args) -> List[AptRepository]:
    repos = []

    if args.with_docker:
        repos.append(AptRepository(get_docker_apt_repo(), 'https://download.docker.com/linux/ubuntu/gpg'))

    return repos


def get_prerequisite_packages(args) -> List[AptPackage]:
    packages = {
        'apt-transport-https': args.with_docker,
        'ca-certificates': args.with_docker,
        'curl': args.with_docker,
        'gnupg-agent': args.with_docker,
        'software-properties-common': args.with_docker,
    }

    return dict_to_apt_packages(packages)


def get_packages(args) -> List[AptPackage]:
    packages = {
        'zsh': True,
        'git': True,
        'docker-ce': args.with_docker,
        'docker-ce-cli': args.with_docker,
        'containerd.io': args.with_docker,
    }

    return dict_to_apt_packages(packages)


def get_docker_apt_repo() -> str:
    [distro, version] = get_distro()

    return 'deb [arch=amd64] https://download.docker.com/linux/{} {} stable'.format(distro, version)


def get_args():
    parser = ArgumentParser(description='Installation script for Debian based distros')
    parser.add_argument('-v', '--verbose', nargs='?', const=True, default=False, help='Whether to output more stuff')
    parser.add_argument('--with-docker', nargs='?', const=True, default=False, help='Whether to install docker-ce')

    return parser.parse_args()


def get_distro() -> Tuple:
    with open('/etc/os-release', 'r') as f:
        reader = csv.reader(f, delimiter='=')

        items = dict(reader)

        if items['ID'] == 'linuxmint':
            return items['ID_LIKE'], items['UBUNTU_CODENAME']

        return items['ID'], items['VERSION_CODENAME']


def main():
    args = get_args()
    apt = Apt(args)
    apt.update()

    apt.install(get_prerequisite_packages(args))

    repos = get_repos(args)

    for repo in repos:
        apt.add_key(repo.gpg_key_location)
        apt.add_repo(repo.repo)

    apt.update()
    apt.install(get_packages(args))


if __name__ == '__main__':
    main()
