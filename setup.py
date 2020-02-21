import subprocess
from typing import List, Dict, Tuple, Callable
from argparse import ArgumentParser
import csv
import os


class CommandError(Exception):
    def __init__(self, exit_code):
        self.exit_code = exit_code


class CommandRunner:
    @staticmethod
    def run(command):
        completed_process = subprocess.run(command, shell=True)

        if completed_process.returncode > 0:
            raise CommandError(completed_process.returncode)


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
        CommandRunner.run(command)

    def install(self, packages: List[AptPackage]):
        package_string = ' '.join(list(map(lambda package: package.get(), packages)))
        command = 'sudo apt-get install {} {}'.format(self.verbose_flags, package_string)

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


def parse_dict_to_list(dictionary: Dict, callback: Callable) -> List[AptPackage]:
    valid_entries = dict(filter(lambda entry: entry[1], dictionary.items()))

    parsed_entries = map(callback, valid_entries)

    return list(parsed_entries)


def get_repos(args) -> List[AptRepository]:
    repos = []

    if args.docker:
        repos.append(AptRepository(get_docker_apt_repo(), 'https://download.docker.com/linux/ubuntu/gpg'))

    return repos


def get_prerequisite_packages(args) -> List[AptPackage]:
    packages = {
        'apt-transport-https': args.docker,
        'ca-certificates': args.docker,
        'curl': args.docker,
        'gnupg-agent': args.docker,
        'software-properties-common': args.docker,
    }

    return parse_dict_to_list(packages, lambda package: AptPackage(package))


def get_packages(args) -> List[AptPackage]:
    packages = {
        'zsh': True,
        'git': True,
        'docker-ce': args.docker,
        'docker-ce-cli': args.docker,
        'containerd.io': args.docker,
    }

    return parse_dict_to_list(packages, lambda package: AptPackage(package))


def get_docker_apt_repo() -> str:
    [distro, version] = get_distro()

    return 'deb [arch=amd64] https://download.docker.com/linux/{} {} stable'.format(distro, version)


def get_args():
    parser = ArgumentParser(description='Installation script for Debian based distros')
    parser.add_argument('-v', '--verbose', nargs='?', const=True, default=False, help='Whether to output more stuff')
    parser.add_argument('--docker', nargs='?', const=True, default=False, help='Whether to install docker-ce')
    parser.add_argument('--nvm', nargs='?', const=True, default=False, help='Whether to install nvm')
    parser.add_argument('--zsh-theme', nargs='?', default='simple', help='Which zsh theme to use')
    parser.add_argument('--overwrite-zsh', nargs='?', const=True, default=False, help='Whether to overwrite the .zshrc file')

    return parser.parse_args()


def get_distro() -> Tuple:
    with open('/etc/os-release', 'r') as f:
        reader = csv.reader(f, delimiter='=')

        items = dict(reader)

        if items['ID'] == 'linuxmint':
            return items['ID_LIKE'], items['UBUNTU_CODENAME']

        return items['ID'], items['VERSION_CODENAME']


def change_shell():
    CommandRunner.run('sudo chsh -s "$(command -v zsh)" "$USER"')


def add_groups(args):
    groups = parse_dict_to_list({
        'docker': args.docker
    }, lambda group: group)

    group_flags = ' '.join(list(map(lambda group: '-G {}'.format(group), groups)))

    CommandRunner.run('sudo usermod -a {} "$USER"'.format(group_flags))


def install_ohmyzsh():
    command = 'curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s - --unattended'
    CommandRunner.run(command)


def get_zshrc(args):
    plugins = ['git']

    if args.nvm:
        plugins.append('nvm')

    return '''
ZSH_THEME="{}"
HIST_STAMPS="yyyy-mm-dd"

plugins=({})

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh
'''.format(args.zsh_theme, ' '.join(plugins))


def install_nvm():
    CommandRunner.run('curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash')


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

    change_shell()
    add_groups(args)

    install_ohmyzsh()

    zshrc_file = os.path.expanduser('~/.zshrc')

    if not os.path.isfile(zshrc_file) or args.overwrite_zsh:
        with open(zshrc_file, 'w') as f:
            f.write(get_zshrc(args))
            f.close()


if __name__ == '__main__':
    main()
