#!/bin/bash

main_dir=`which creatify`
if [[ $main_dir == "" ]]
then
    main_dir="$PWD" 
else
    IFS='/' read -ra ADDR <<< "$main_dir"
    main_dir=""
    for i in "${!ADDR[@]}"; do
        x=$((${#ADDR[@]}-$i-1))
        [[ $x != 0 && $i != 0 ]] && main_dir="$main_dir/${ADDR[i]}" || :
    done
fi
[[ -e "$main_dir/creatify" ]] && : || main_dir="$PWD$main_dir"


path_file="$main_dir/paths.sh"
config_file="$main_dir/configure.sh"
gitignore_file="$main_dir/.gitignore"
webtemplate_file="$main_dir/webtemplate.sh"

[[ -e "$path_file" ]] && : || `bash "$config_file" "path"`
[[ -e "$gitignore_file" ]] && : || echo "Gitignore file will Not be given as a file is missing...."


declare -a languages
languages=( "python" "flutter" "web" "node" "default" )

if [[ $1 == "--config" ]]
then
    [[ -e "$config_file" ]] && : || (echo "Your Config File is Missing.. So You Can Not Change Settings Anymore.."; exit 1)
    bash "$config_file" "$2"
    exit
fi


while getopts ":l:e:p" o; do
    case "${o}" in
        l) lang=${OPTARG};;
        e) ide=${OPTARG};;
        p)  
            . "$path_file"

            declare -a pathName
            pathName=( "'Python' projects" "'Flutter' projects" "'Web' projects" "'Node.js' projects" "Default Directory" )

            declare -a languages2
            languages2=( "$python" "$flutter" "$web" "$node" "$default" )
            
            for i in ${!pathName[@]}
            do  
                echo "Path of ${pathName[i]}: ${languages2[i]}"
            done          
            exit;;
        *) 
            echo "Sorry '$OPTARG' is not valid"
            exit
            ;;
    esac
done

function gitIgnore(){
    if [[ -e "$gitignore_file" ]];then
        _lang=$1
        touch ".gitignore"
        [[ $_lang == "python" ]] && start=2 end=139 || :
        [[ $_lang == "node" ]] && start=143 end=258 || :
        x=0
        while read line; do
        x=$(( x+1 ))
        if [[ $x -ge $start && $x -le $end ]]; then
            echo $line >> "./.gitignore"
        fi
        done < "$gitignore_file"
    fi
}


function webTemplate(){
    title=$1
    target="$PWD"
    if [[ -e "$webtemplate_file" ]]
    then
        bash "$webtemplate_file" $title "$target"
        echo "Creatify creates a template on every web project creation... Hope you like it.."
    else
        echo "Web template will not be given as a file is missing...."
    fi
}


function createProject(){
    path="$1"
    name="$2"
    lang="$3"

    
    if cd "$path"
    then
        if [[ $lang == "flutter" ]]
        then
            title=""
            IFS=' ' read -ra ADDR <<< "$name"
            for i in "${ADDR[@]}"; do
                title="$title$i"
            done
            [[ "${#ADDR[@]}" -gt 1 ]] && (printf "Your Project name would be '$title' instead of '$name'. Cause Flutter project name cannot contain space. \nBut you can change the name of the directory later...\n") || :
            echo "Creating a $lang project named $title"
            read -p "Package Name for your flutter app: " pname
            
            if [[ $pname == "" ]]
            then
                flutter create $title > /dev/null 2>&1
            else
                flutter create --org $pname $title > /dev/null 2>&1
            fi
            cd "./$title"
            gh repo create "$title" -y
            cp -r "./$title/.git" ./
            rm -r "./$title"
            touch "README.md"
            git add .
            git commit -m"Initial Commit" > /dev/null 2>&1
        else
            echo "Creating a $lang project named $name"

            if [[ $lang == "python" ]]
            then
                mkdir "$name"
                cd "./$name"
                virtualenv .
                gitIgnore $lang
            elif [[ $lang == "node" ]]
            then
                title=""
                x=0
                IFS=' ' read -ra ADDR <<< "$name"
                for i in "${ADDR[@]}"; do
                    if [[ $x == 0 ]]
                    then
                        title="$i"
                    else
                        title="$title-$i"
                    fi
                    x=$(( x+1 ))
                done
                mkdir "$title"
                cd "./$title"
                npm init -y
                gitIgnore $lang
            elif [[ $lang == "web" ]]
            then
                mkdir "$name"
                cd "./$name"
                webTemplate "$name" "$path"
            else
                mkdir "$name"
                cd "./$name"
            fi
            if [[ $lang == "node" ]]; then
                gh repo create "$title" -y
                cp -r "./$title/.git" ./
                rm -r "./$title"
            else
                title=""
                x=0
                IFS=' ' read -ra ADDR <<< "$name"
                for i in "${ADDR[@]}"; do
                    if [[ $x == 0 ]]
                    then
                        title="$i"
                    else
                        title="$title-$i"
                    fi
                    x=$(( x+1 ))
                done
                gh repo create "$title" -y
                cp -r "./$title/.git" ./
                rm -r "./$title"
            fi
            touch "README.md"
            git add . > /dev/null 2>&1
            git commit -m"Initial Commit" > /dev/null 2>&1
            
        fi 
    else
        echo "Check your path for $lang project."
        echo "You can check your paths using 'creatify -p'"
        echo "run 'creatify --config to correct your path'"
        exit
    fi
}

    
[[ $lang != "" || $ide != "" ]] && title=$3 || :
[[ $lang != "" && $ide != "" ]] && title=$5 || :
[[ $lang == "" && $ide == "" ]] && title=$1 || :


if [[ $title == "" ]]
then
    echo "Title is required"
    exit
else
    if [[ $lang == "" ]]
    then
        echo "Creating a project in the default directory"
        lang="default"
    elif [[ $lang != "python" && $lang != "flutter" && $lang != "web" && $lang != "node" ]]
    then
        echo "Creatify is not configured for $lang. Using default project path...."
        lang="default"
    fi
fi


[[ $ide == "" ]] && ide="code" || :

[[ $lang == "" ]] && lang="default" || :

. "$path_file"
eval "path=\$$lang"


if [[ $path == "" ]]
then
    echo "Path for $lang projects was not given while configuring Creatify."
    echo "run \"creatify --config path\" to configure paths again.."
    exit 1
fi

createProject "$path" "$title" "$lang"
echo "Creatify is successful in creating your \"$title\" project! Enjoy Coding..."
eval "$ide ." > /dev/null 2>&1
exit 0
