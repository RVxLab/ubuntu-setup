import subprocess
from typing import List, Dict, Tuple
from argparse import ArgumentParser
import csv
from urllib import request


class Apt:
    def run_command(self, command: str):
        subprocess.run(command, shell=True)

    def install_packages(self, packages: List[str]):
        command = 'sudo apt-get install -yqq {}'.format(' '.join(packages))

        self.run_command(command)

    def add_repo(self, repo: str):
        command = 'sudo add-apt-repository -y {}'.format(repo)

        self.run_command(command)

    def update(self):
        self.run_command('sudo apt-get update')

    def upgrade(self):
        self.run_command('sudo apt-get dist-upgrade -y')

    def add_key(self, key: str):
        self.run_command('sudo apt-key add {}'.format(key))


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
    def __init__(self, repo: str, gpg_key: str = None):
        self.repo = repo
        self.gpg_key = gpg_key


def dict_to_apt_packages(dictionary: Dict) -> List[AptPackage]:
    valid_packages = dict(filter(lambda entry: entry[1], dictionary.items()))

    packages = map(lambda package: AptPackage(package), valid_packages)

    return list(packages)


def get_repos(args) -> List[AptRepository]:
    repos = []

    if args.with_docker:
        docker_gpg_res = request.urlopen('https://download.docker.com/linux/ubuntu/gpg')
        docker_gpg = docker_gpg_res.read().decode('UTF-8')

        repos.append(AptRepository(get_docker_apt_repo(), docker_gpg))

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
    repos = get_repos(args)

    apt = Apt()

    for repo in repos:
        apt.add_key(repo.gpg_key)
        apt.add_key(repo.repo)

    apt.update()


if __name__ == '__main__':
    main()
