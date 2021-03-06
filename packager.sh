#!/bin/bash

cwd=$(pwd)
RELEASE_VERSION=()
TOOLS_LIST=()
LIBRARY_URL_PREFIX=https://github.com/esp8266/Arduino/releases/download
DOWNLOAD_PATH=download
VERSION_PATH=version
RELEASE_PATH=release
RELEASE_FILENAME_PREFIX=espsynth86
RELEASE_REPO=https://github.com/esptiny86/espboard8266.git
RELEASE_URL=https://esptiny86.github.io/espboard8266
TEMPLATE_PATH=template

ESPSYNTH_PATH=espsynth
ESPSYNTH_REPO=https://github.com/esptiny86/espsynth86.git
ESPSYNTH_RELEASE_PATH=library

function ADD_RELEASE()
{
	RELEASE_VERSION+=("${1}")
}

function back_to_root()
{
	cd $cwd
}

function check_dir_exists()
{
	local _FILE_NAME=${1}
	
	if [ -d "${_FILE_NAME}" ]
	then
		return 0 #true
	else
		return 1 #false
	fi	
}

function check_file_exists()
{
	local _FILE_NAME=${1}
	
	if [ -f "${_FILE_NAME}" ]
	then
		return 0 #true
	else
		return 1 #false
	fi	
}

function check_folder_git()
{
	local _FOLDER_NAME=${1}
	
	if  check_dir_exists "${_FOLDER_NAME}/.git"
	then
		return 0 #true
	else
		return 1 #false
	fi	
}

function list_release()
{
	local tLen=${#RELEASE_VERSION[@]}
	echo "------------------------------------------------------------------"			
	echo "Releases:"
	for (( i=0; i<${tLen}; i++ ));
	do
	IFS=', ' read -a array <<< "${RELEASE_VERSION[$i]}"
	local _RELEASE_VERSION=${array[0]}
	echo "- release version: ${_RELEASE_VERSION}"
	done
	echo "------------------------------------------------------------------"
}

function version_is_not_released()
{	
	if [ -f "$cwd/$RELEASE_PATH/board/${RELEASE_FILENAME_PREFIX}-${1}.zip" ]
	then
		return 1 #true
	else
		return 0 #false
	fi	
}

function download_release_version()
{
	wget --directory-prefix $cwd/download ${LIBRARY_URL_PREFIX}/${1}/esp8266-${1}.zip
}

function unzip_release_version()
{
	unzip $cwd/$DOWNLOAD_PATH/esp8266-${1}.zip -d $cwd/$DOWNLOAD_PATH
	rm -fr $cwd/$DOWNLOAD_PATH/esp8266-${1}.zip
}

function zip_release_version()
{
	cd $cwd/$DOWNLOAD_PATH/
	zip -m -r $cwd/$RELEASE_PATH/board/${RELEASE_FILENAME_PREFIX}-${1}.zip esp8266-${1}
	cd $cwd
}

function patch_release_version()
{
	
	cd $cwd/$DOWNLOAD_PATH/esp8266-${1}
	rm -fr $cwd/$DOWNLOAD_PATH/esp8266-${1}/platform.txt
	cp $cwd/$VERSION_PATH/${1}/platform.txt $cwd/$DOWNLOAD_PATH/esp8266-${1}/
	# find . -name platform.txt -type f -exec sed -i.bak 's/ESP8266 Modules/Espsynth/g' '{}' \;
	cd $cwd
}

function add_espsynth_to_release_version()
{
	
	cd $cwd/$DOWNLOAD_PATH/esp8266-${1}
	rm -fr $cwd/$DOWNLOAD_PATH/esp8266-${1}/platform.txt
	cp $cwd/$VERSION_PATH/${1}/platform.txt $cwd/$DOWNLOAD_PATH/esp8266-${1}/
	# find . -name platform.txt -type f -exec sed -i.bak 's/ESP8266 Modules/Espsynth/g' '{}' \;
	cd $cwd

	cd $cwd/$ESPSYNTH_PATH
	cp -r library/espsynth86-`git describe --tag` $cwd/$DOWNLOAD_PATH/esp8266-${1}/libraries
	cd $cwd

}

function generate_package_json()
{
	echo ""
}

function publish_all_release()
{
	echo ""
}


function generate_package_sha()
{
	local _SHA=`shasum -a 256 ${cwd}/${RELEASE_PATH}/board/${RELEASE_FILENAME_PREFIX}-${1}.zip | cut -d ' ' -f 1`
	eval "cat <<EOF
	$(<${cwd}/${VERSION_PATH}/${1}/package.json)
	" 2> /dev/null
}

function generate_package_json() #platforms
{
	local _platforms
	local _SHA
	local cnt=0
	local i=0

	cd version
	for f in *; do
		let cnt++
	done	
	cd $cwd



	cd version
	for f in *; do
		let i++
		cd $f
		_platforms+=`generate_package_sha $f`
		cd .. 

		if [ "$i" -eq "$cnt" ];
		then
			_platforms+=""
		else
			_platforms+=","
		fi

	done	
	cd $cwd

	eval "cat <<EOF
	$(<${cwd}/${TEMPLATE_PATH}/package.json)
	" 2> /dev/null

}

process_package_json()
{
	json_package_output=`generate_package_json`
	echo "$json_package_output" > $RELEASE_PATH/package_espsynth_index.json

	cd $cwd/$VERSION_PATH
	for f in *; do
	find $cwd/$RELEASE_PATH -name package_espsynth_index.json -type f -exec sed -i.bak s,https://github.com/esp8266/Arduino/releases/download/$f/esp8266-$f.zip,$RELEASE_URL/board/${RELEASE_FILENAME_PREFIX}-$f.zip,g '{}' \;
	find $cwd/$RELEASE_PATH -name package_espsynth_index.json -type f -exec sed -i.bak s/\"name\"\ :\ \"esp8266\"/\"name\"\ :\ \"Espsynth86\"/g '{}' \;
	
	rm -fr $cwd/$RELEASE_PATH/*.json.bak
	done
	cd $cwd

}

init_release_folder()
{
	if check_folder_git "$cwd/$RELEASE_PATH"
	then
		echo "git already exists"
		cd "$cwd/$RELEASE_PATH"
		git pull origin master
		cd $cwd
	else
		git clone ${RELEASE_REPO} release
	fi
}

init_espsynth_folder()
{
	if check_folder_git "$cwd/$ESPSYNTH_PATH"
	then
		echo "init_espysnth_folder - git espsynth already exists - pull update"
		cd "$cwd/$ESPSYNTH_PATH"
    pwd
		git pull 
		cd $cwd
	else
    echo "init_espysnth_folder - clone espsynth lib latest"
		git clone ${ESPSYNTH_REPO} $ESPSYNTH_PATH
		git checkout merge
	fi
}

build_espsynth()
{
	echo "build_espsynth - compile library"
	cd $cwd/$ESPSYNTH_PATH
	git pull
	sh makelib.sh
    echo "build_espsynth - copy compiled library zip to packager release folder"
	mkdir -p $cwd/$RELEASE_PATH/$ESPSYNTH_RELEASE_PATH
	cp library/espsynth86-`git describe --tag`.zip $cwd/$RELEASE_PATH/$ESPSYNTH_RELEASE_PATH
	cd $cwd
}


publish_espsynth()
{
  echo "publish_espsynth - copy compiled library zip to release folder"
	mkdir -p $cwd/$RELEASE_PATH/$ESPSYNTH_RELEASE_PATH
	cp $cwd/$ESPSYNTH_PATH/library/*.zip $cwd/$RELEASE_PATH/$ESPSYNTH_RELEASE_PATH
}

push_release_folder()
{
  echo "push_release_folder - upload build result to github"
	cd "$cwd/$RELEASE_PATH"
	git add .
	git commit -m "new release"
	git push origin master
	cd $cwd 
}

function process_release()
{
	cd version
	for f in *; do

	if version_is_not_released "$f"
	then
		  download_release_version "$f"
		  unzip_release_version "$f"
		  patch_release_version "$f"	
		  zip_release_version "$f"	
	else
		  echo "Skip $f"	
	fi		
    
	done
	cd $cwd
}

# init_release_folder
#process_release
#process_package_json

init_espsynth_folder
build_espsynth
publish_espsynth
push_release_folder


#iterate release
#	download release
#	unzip release
#	patch release
#	zip release
#publish releases
