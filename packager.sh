#!/bin/bash

cwd=$(pwd)
RELEASE_VERSION=()
TOOLS_LIST=()
LIBRARY_URL_PREFIX=https://github.com/esp8266/Arduino/releases/download
DOWNLOAD_PATH=download
VERSION_PATH=version
RELEASE_PATH=release
RELEASE_REPO=https://github.com/esptiny86/espboard8266.git
RELEASE_URL=https://esptiny86.github.io/espboard8266
TEMPLATE_PATH=template

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
	if [ -f "$cwd/$RELEASE_PATH/board/esp8266-${1}.zip" ]
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
	zip -m -r $cwd/$RELEASE_PATH/board/esp8266-${1}.zip esp8266-${1}
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
	local _SHA=`shasum -a 256 ${cwd}/${RELEASE_PATH}/board/esp8266-${1}.zip | cut -d ' ' -f 1`
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
	find $cwd/$RELEASE_PATH -name package_espsynth_index.json -type f -exec sed -i.bak s,https://github.com/esp8266/Arduino/releases/download/$f/esp8266-$f.zip,$RELEASE_URL/board/esp8266-$f.zip,g '{}' \;
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

push_release_folder()
{
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

init_release_folder
# process_release
process_package_json
push_release_folder

#iterate release
#	download release
#	unzip release
#	patch release
#	zip release
#publish releases