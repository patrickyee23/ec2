#!/bin/bash
yum install -y git util-linux-user zsh

usermod -aG docker ec2-user
chsh -s $(which zsh) ec2-user

git clone https://github.com/pyenv/pyenv.git ~ec2-user/.pyenv
chown -R ec2-user:ec2-user ~ec2-user/.pyenv

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~ec2-user/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~ec2-user/.zshrc
echo 'eval "$(pyenv init - zsh)"' >> ~ec2-user/.zshrc

echo -e "[user]\n    email = pyee@23andme.com\n    name = Patrick Yee\n" > ~ec2-user/.gitconfig

chown ec2-user:ec2-user ~ec2-user/.zshrc
chown ec2-user:ec2-user ~ec2-user/.gitconfig

yum install -y bzip2-devel htop libffi-devel mariadb105-devel readline-devel openssl-devel sqlite-devel xz-devel zlib-devel
yum groupinstall -y "Development Tools"

su - ec2-user -c "source ~/.zshrc && pyenv install 3.10.18 && pyenv install 3.11.13 && pyenv install 3.12.11"
