ORIGINAL_USER=$(whoami)

echo "Hello $(whoami),"
sleep 1
echo "I'm going to configure your computer now."
sleep 1
echo "I'll need a couple of things from you throughout the process"
echo "So I'll get them from you now..."
sleep 2

echo "Github requires a few global settings to be configured"
echo "Enter the email address associated with your GitHub account: "
read -r email
echo "Enter your full name (Ex. John Doe): "
read -r username

if [ -x "$(command -v brew)" ]; then
    echo "✔️ Homebrew installed"
else
    echo "Installing homebrew now..."
    mkdir -p /usr/local/var/homebrew
    sudo chown -R $(whoami) /usr/local/var/homebrew
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi;

sudo mkdir -p /usr/local/sbin
sudo chown -R $(whoami) /usr/local/sbin

echo "Making sure homebrew is up to date"
brew update --force
brew upgrade --cleanup
brew doctor

#  Configure Git
if [ -x "$(command -v brew)" ]; then
    echo "✔️ git installed"
else
    echo "Installing git"
    brew install git
fi;

echo "Setting global git config with email $email and username $username"
git config --global --replace-all user.email "$email"
git config --global --replace-all user.name "$username"

# SSH Key
if [ -f "~/.ssh/id_rsa" ]; then
    echo "SSH Key exists"
else
    echo "Generating an SSH Key - this will be added to your agent for you"
    ssh-keygen -t rsa -b 4096 -C "$email"
    echo "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ~/.ssh/id_rsa" | tee ~/.ssh/config
    eval "$(ssh-agent -s)"
fi

echo "Configuring Oh My ZSH"
{ # your 'try' block
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
} || { # your 'catch' block
    echo 'Oh My Zsh like to exit for some reasons so this prevents it'
}

# Configure ZSH  plugins
echo "Configuring ZSH plugins"
{
    git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    sed -i 's/plugins=(git)/plugins=(\n  git\n)/g' ~/.zshrc
    sed -i 's/git$/git\'$'\n  zsh-autosuggestions/g' ~/.zshrc
    sed -i 's/zsh-autosuggestions$/zsh-autosuggestions\'$'\n  zsh-syntax-highlighting/g' ~/.zshrc
} || {
    echo 'Failed to configure zsh plugins'
}

# caskroom https://caskroom.github.io
echo "Installing Brew apps"
{
    brew tap caskroom/cask
    brew tap jenkins-x/jx
    brew cask install google-chrome
    brew cask install docker
    brew cask install kitematic
    brew cask install hyper
    brew cask install visual-studio-code
    brew cask install vagrant
    brew cask install spotify
    brew cask install minikube
    brew cask install virtualbox
    brew cask install google-cloud-sdk
    brew cask install ngrok
    brew cask install zoomus
    brew install terraform
    brew install node
    brew install python
    brew install jq
    brew install kops
    brew install kafka
    brew install tmux
    brew install tree
    brew install kubectx
} || {
    echo "One or more brew formulas failed to install"
}

# JX
if [ -x "$(command -v jx)" ]; then
    echo "jx installed"
else
    brew install jx
    echo "\nsource <(jx completion zsh)" >> ~/.zshrc
    echo "\nexport PATH=$HOME/.jx/bin:$PATH" >> ~/.zshrc
fi;

# kubectl
if [ -x "$(command -v kubectl)" ]; then
    echo "kubectl installed"
else
    brew install kubernetes-cli
    echo "\nsource <(kubectl completion zsh)" >> ~/.zshrc
fi;

if [ -x "$(command -v sops)" ]; then
    echo "sops installed"
else
    brew install sops
fi;

# safe
if [ -x "$(command -v safe)" ]; then
    echo "safe installed"
else
    brew tap starkandwayne/cf
    brew install starkandwayne/cf/safe
fi;

# Make sure user is owner of homebrew directory
echo "For n to work properly, you need to own homebrew stuff - setting $(whoami) as owner of $(brew --prefix)/*"
sudo chown -R $(whoami) $(brew --prefix)/*

# N
if [ -x "$(command -v n)" ]; then
    echo "N - Node version manager installed with latest LTS of Node"
else
    npm install -g n
    sudo mkdir -p /usr/local/n
    sudo chown -R $(whoami) /usr/local/n
    # take ownership of node install destination folders
    sudo chown -R $(whoami) /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share
    # Use the latest version of Node
    echo "Using latest version of Node"
    n latest
fi;

if [ -x "$(command -v aws)" ]; then
    echo "aws cli installed"
else
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /
fi;

echo "Installing hyper term package manager and meta"
npm i -g hpm-cli meta

# setup dev directory
echo "Creating development directory at ~/Documents/dev"
mkdir -p ~/Documents/dev

# set up vscode
echo "Configure VS Code extensions"
sleep 1
code    --install-extension ms-azuretools.vscode-docker \
        --install-extension marcostazi.VS-code-vagrantfile \
        --install-extension mauve.terraform \
        --install-extension secanis.jenkinsfile-support \
        --install-extension formulahendry.code-runner \
        --install-extension mikestead.dotenv \
        --install-extension oderwat.indent-rainbow \
        --install-extension orta.vscode-jest \
        --install-extension jenkinsxio.vscode-jx-tools \
        --install-extension mathiasfrohlich.kotlin \
        --install-extension christian-kohler.npm-intellisense \
        --install-extension sujan.code-blue \
        --install-extension waderyan.gitblame \
        --install-extension ms-vscode.go \
        --install-extension in4margaret.compareit \
        --install-extension andys8.jest-snippets \
        --install-extension euskadi31.json-pretty-printer \
        --install-extension yatki.vscode-surround \
        --install-extension wmaurer.change-case

echo "Copying your SSH key to your clipboard"
pbcopy < ~/.ssh/id_rsa.pub
sleep 1
echo "Add the generated SSH key to your GitHub account. It has been copied to your clipboard"
echo "https://github.com/settings/keys"
sleep 1
sed -i .bak "s/shell:[[:space:]]'',$/shell: 'zsh',/g" ~/.hyper.js
sleep 1
echo "export PATH=\$HOME/.jx/bin/:\$PATH" >> ~/.zshrc
sleep 1
source ~/.zshrc
