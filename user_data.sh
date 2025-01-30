#!/bin/bash
yum install -y git bzip2-devel docker htop libffi-devel mariadb105-devel readline-devel openssl-devel sqlite-devel xz-devel zlib-devel
yum groupinstall -y "Development Tools"
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

git clone https://github.com/pyenv/pyenv.git ~ec2-user/.pyenv
chown -R ec2-user:ec2-user ~ec2-user/.pyenv

sed -Ei -e '/^([^#]|$)/ {a \
export PYENV_ROOT="$HOME/.pyenv"
a \
export PATH="$PYENV_ROOT/bin:$PATH"
a \
' -e ':a' -e '$!{n;ba};}' ~ec2-user/.bash_profile
echo 'eval "$(pyenv init --path)"' >> ~ec2-user/.bash_profile

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~ec2-user/.profile
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~ec2-user/.profile
echo 'eval "$(pyenv init --path)"' >> ~ec2-user/.profile

echo 'eval "$(pyenv init -)"' >> ~ec2-user/.bashrc

echo -e "[user]\n    email = pyee@23andme.com\n    name = Patrick Yee\n" > ~ec2-user/.gitconfig

chown ec2-user:ec2-user ~ec2-user/.bash_profile
chown ec2-user:ec2-user ~ec2-user/.bashrc
chown ec2-user:ec2-user ~ec2-user/.profile
chown ec2-user:ec2-user ~ec2-user/.gitconfig

su - ec2-user -c "source ~/.bash_profile && pyenv install 3.9.21 && pyenv install 3.11.11 && pyenv install 3.12.8"
