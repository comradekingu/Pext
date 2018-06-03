#! /bin/bash

set -x
set -e

# use RAM disk if possible
if [ -d /dev/shm ]; then
    TEMP_BASE=/dev/shm
else
    TEMP_BASE=/tmp
fi

OLD_CWD="$(pwd)"

# install Miniconda, a self contained Python distribution
wget https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh -b -p ~/miniconda -f
rm Miniconda3-latest-MacOSX-x86_64.sh 
export PATH="$HOME/miniconda/bin:$PATH"

# create conda env
conda create -n Pext python --yes
source activate Pext

# install dependencies
pip install PyQt5==5.8 dulwich
# leave conda env
source deactivate

# create .app Framework
mkdir -p Pext.app/Contents/
mkdir Pext.app/Contents/MacOS Pext.app/Contents/Resources
touch Pext.app/Contents/Info.plist

# copy Miniconda env
cp -R ~/miniconda/envs/Pext/* Pext.app/Contents/Resources/

# install Pext
mv /Users/travis/build/Pext/Pext Pext.app/Contents/Resources/Pext

# create entry script
cat <<'EOF' >> Pext.app/Contents/MacOS/Pext
#!/usr/bin/env bash
script_dir=$(dirname "$(dirname "$0")")
$script_dir/Resources/bin/python $script_dir/Resources/Pext/pext $@
EOF

# make executable
chmod a+x Pext.app/Contents/MacOS/Pext

# generate .dmg
git clone https://github.com/andreyvit/yoursway-create-dmg.git
pushd yoursway-create-dmg
bash ./create-dmg --volname "Pext" --volicon "../Pext.app/Contents/Resources/Pext/pext/images/scalable/pext.icns" --window-pos 200 120 --window-size 800 400 --icon-size 100 --icon Pext.app 200 190 --hide-extension Pext.app --app-drop-link 600 185 Pext.dmg "../Pext.app"

# move dmg to old CWD
mv Pext.dmg "$OLD_CWD"/
