#!/usr/bin/env bash
su -c "cp -n /tmp/launchButtonSettings.json /home/coder/coursera/" - coder
python3 ${VSCODE_USER}/coursera/refreshButtonConfig.py

# prevent the script from re-copying these files over in student lab
if [ "${WORKSPACE_TYPE}" = "instructor" ]; then
    # git in lab persistence + default options
    mkdir -p -m777 /home/coder/.dotfiles-coursera
    su -c "ln -s /home/coder/.dotfiles-coursera/.gitconfig /home/coder/.gitconfig" - coder
    su -c "ln -s /home/coder/.dotfiles-coursera/.git-credentials /home/coder/.git-credentials" - coder
    su -c "git config --global core.fileMode false" - coder

    # Hide certain files in the /home/coder directory
    su -c "cp -n /tmp/.hidden /home/coder/.hidden" - coder
fi

# copy reverse-proxy default template into /home/nginx/ only if it doesn't exist
if [ ! -f /home/nginx/reverse-proxy.conf ]; then
    cp /etc/nginx/sites-enabled/reverse-proxy.conf.template /home/nginx/reverse-proxy.conf
    chmod a+w /home/nginx/reverse-proxy.conf
fi

# copy nginx and proxy-related files to /home/nginx/
su -c "cp -rn /tmp/nginx-files/. /home/nginx" - coder

# install nginx-conf npm package for reverse proxy config script
cd /home/nginx
su -c "npm install --global" - coder

# link reverse-proxy from mount point to location where it actually takes effect
ln -s /home/nginx/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
export PATH=/home/npm-global/bin:$PATH

# link refreshButton script so it's more easily accessible
ln -s $VSCODE_USER/coursera/refreshButtonConfig.py /home/coder/coursera/refreshButtonConfig.py

cd /home/coder/project

if [ -f ".template" ]; then
    REPO_URL=$(head -n 1 ".template" | tr -d '\n\r' | xargs)
else
    # Fallback
    REPO_URL="https://github.com/dartmouth-cs52/starterpack-template"
fi

# Only clone if directory doesn't exist
REPO_NAME=$(basename "$REPO_URL" .git)

if [ ! -d "/home/coder/project/$REPO_NAME" ]; then
    echo "Cloning $REPO_URL into /home/coder/project..."
    su -c "cd /home/coder/project && git clone $REPO_URL && echo 'Clone completed successfully'" - coder
else
    echo "Repository $REPO_NAME already exists, skipping clone"
fi

# Install dependencies and Cypress binary for the cloned project
if [ -f "/home/coder/project/$REPO_NAME/package.json" ]; then
    echo "Installing project dependencies..."
    su -c "cd /home/coder/project/$REPO_NAME && npm install --legacy-peer-deps && npx cypress install" - coder
fi

# Start MongoDB service
sudo systemctl start mongod

# Start the supervisord service
/usr/bin/supervisord