#!/usr/bin/bash

echo X19fX19fX19fX18gICAgICAgICAgICAgICAgICAgICAgICAgICAuX18gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgClxfICAgX19fX18vX18gIF9fXyBfX19fICAgX19fXyAgIF9fX18gfCAgfCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogfCAgICBfXylfXCAgXC8gIC8vIF9fIFwgLyBfX19cIC8gIF8gXHwgIHwgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKIHwgICAgICAgIFw+ICAgIDxcICBfX18vLyAvXy8gID4gIDxfPiApICB8X18gICAgICAgICAgICAgICAgICAgICAgICAgICAgCi9fX19fX19fICAvX18vXF8gXFxfX18gID5fX18gIC8gXF9fX18vfF9fX18vICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgIFwvICAgICAgXC8gICAgXC9fX19fXy8gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKLl9fXyAgICAgICAgICAgICAgICAgX18gICAgICAgICAuX18gIC5fXyAgICAgICAgICBfXyAgLl9fICAgICAgICAgICAgICAgCnwgICB8IF9fX18gICBfX19fX19fLyAgfF9fX19fXyAgfCAgfCB8ICB8IF9fX19fIF8vICB8X3xfX3wgX19fXyAgIF9fX18gIAp8ICAgfC8gICAgXCAvICBfX18vXCAgIF9fXF9fICBcIHwgIHwgfCAgfCBcX18gIFxcICAgX19cICB8LyAgXyBcIC8gICAgXCAKfCAgIHwgICB8ICBcXF9fXyBcICB8ICB8ICAvIF9fIFx8ICB8X3wgIHxfXy8gX18gXHwgIHwgfCAgKCAgPF8+ICkgICB8ICBcCnxfX198X19ffCAgL19fX18gID4gfF9ffCAoX19fXyAgL19fX18vX19fXyhfX19fICAvX198IHxfX3xcX19fXy98X19ffCAgLwogICAgICAgICBcLyAgICAgXC8gICAgICAgICAgICBcLyAgICAgICAgICAgICAgIFwvICAgICAgICAgICAgICAgICAgICBcLyAKICBfX19fX19fX18gICAgICAgICAgICAuX18gICAgICAgIF9fICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAvICAgX19fX18vIF9fX19fX19fX19ffF9ffF9fX19fXy8gIHxfICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogXF9fX19fICBcXy8gX19fXF8gIF9fIFwgIFxfX19fIFwgICBfX1wgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKIC8gICAgICAgIFwgIFxfX198ICB8IFwvICB8ICB8Xz4gPiAgfCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCi9fX19fX19fICAvXF9fXyAgPl9ffCAgfF9ffCAgIF9fL3xfX3wgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgIFwvICAgICBcLyAgICAgICAgIHxfX3wgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKCg== | base64 -d

echo "Would you like to install Exegol on your system ?(y/n)"
read answer
if [ $answer != "y" ] ; then echo 'aborting install !' ; exit 1 ; fi

rm -f /tmp/exegol-deps.yml
isDebian=$(uname -a | egrep -c -i "debian|kali")
isPython3=$(python -V | grep -c "Python 3")


if [ $isDebian -lt 1 ] ; then echo "This script only runs on Debian System !" ; exit 1 ; fi
if [ $isPython3 -lt 1 ] ; then echo "This script needs Python3 !" ; exit 1 ; fi
echo "Let's install Ansible first !"

echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu focal main' >/tmp/ansible.list
sudo mv /tmp/ansible.list /etc/apt/sources.list.d/ansible.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 || wget -O- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x93C4A3FD7BB9C367" | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y ansible     




cat << EOF >>/tmp/exegol-deps.yml
---
  - name: "Install exegol dependencies"
    hosts: localhost
    connection: local 
    tasks:

    - name: Install git
      apt:
        name: git
        state: present
        update_cache: yes
      become: true
    
    - name: install docker
      apt:
        name: docker.io
        state: present
        update_cache: yes
      become: true
    
    - name: adding $USER to docker group
      ansible.builtin.user:
        name: $USER
        group: docker
        append: yes
      become: true
    
    - name: upgrade pip
      pip:
        name: pip
        extra_args: -U
      become: true
    
    - name: Install Exegol pip package
      pip:
        name: exegol
        extra_args: -U
      become: true
     
    - name: Install Bash completion for exegol
      apt:
        name: bash-completion
        state: present
        update_cache: yes
      become: true

EOF

echo "Running ansible, you need to provide your root password !"

ansible-playbook -K /tmp/exegol-deps.yml

echo "Finalizing zsh/bash completion configuration for Exegol."
register-python-argcomplete --no-defaults exegol | sudo tee /etc/bash_completion.d/exegol > /dev/null

echo "If you want to use autocompletion in zsh run the following commands :"

echo 'autoload -U bashcompinit ; bashcompinit'
echo 'eval "$(register-python-argcomplete --no-defaults exegol)" >>~/.zshrc'

echo "\n\n\n"

exegol install || echo "'exegol install' command failed.
 This may fail if the system does not take into account your user's membership of the docker group.
 In this case, you need to close the current session. You can then use 'exegol install' to complete the installation."




