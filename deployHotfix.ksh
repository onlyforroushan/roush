#!/usr/bin/ksh
#===============================================================
# Name : deployHotfix
# Date : 2016/08/08
# Purpose : Used to deploy HFs / Mark as Deployed in non clustered environment
#
# Changes history:
#
# Date       | By           | Changes/New features
# -----------+--------------+-----------------------------------
# 2016/08/08 | Andreo       | Script Creation
# 2016/10/31 | Andreo       | Updated to also deploy bundles / list of HF from file
# 2016/11/16 | Pedro Pavan  | Detailed output on log file
# 2016/11/24 | Pedro Pavan  | Removed env confirmation
# 2017/02/07 | Andreo       | Updated to deploy to multiple environments / hotfixes at the same time
#===============================================================

# Setting the properties of the script. The below values need to be changed according to the HFtool DB information of the account.
{
export HOTFIX_AMC_HOST="$(hostname)"
export HOTFIX_AMC_HOTFIX_HOME="$(grep $LOGNAME /etc/passwd | cut -d ':' -f 6)"
export HOTFIX_AMC_HOTFIX_CONFIG_DIR="${HOTFIX_AMC_HOTFIX_HOME}/Amc-${HOTFIX_AMC_HOST}/config"
export HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE="${HOTFIX_AMC_HOTFIX_CONFIG_DIR}/AmcRunSqlPIConList.xml"
export HOTFIX_HOME="${HOTFIX_AMC_HOTFIX_HOME}/hotfix"
export HOTFIX_DIRECTORIES="${HOTFIX_HOME}/HOTFIX"
export HOTFIX_LOG_DIRECTORY="${HOTFIX_HOME}/tmp"

export HOTFIX_DB_USER="$(grep User ${HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE} | sort -u | cut -d '>' -f 2 | cut -d '<' -f 1)"
export HOTFIX_DB_PASSWORD="$(grep Pass ${HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE} | sort -u | cut -d '>' -f 2 | cut -d '<' -f 1)"
export HOTFIX_DB_INSTANCE="$(grep Url ${HOTFIX_AMC_HOTFIX_DB_CONFIG_FILE} | head -1 | cut -d '<' -f 2 | cut -d ':' -f 6)"
}

# Setting other variables and definitions used by the script
{
export HOTFIX_BUNDLE_NAME=""
export HOTFIX_FILELIST_NAME=""
export HOTFIX_NUMBER=""

export HOTFIX_API_SCRIPT="${HOTFIX_HOME}/HotfixRunApi.ksh"
export HOTFIX_API_AVAILABLE_OPTIONS[0]="API_AUTO_DEPLOY"
export HOTFIX_API_AVAILABLE_OPTIONS[1]="API_IS_AUTO_DEPLOY_VALID"
export VIRTUAL_MACHINE_NAME=""
export SCRIPTS_DIRECTORIES="${HOTFIX_UNIX_USER}/scripts"
export TEMP_FILE_1="/tmp/deployHotfix_TEMP_FILE_1_$$.txt"
export TEMP_FILE_2="/tmp/deployHotfix_TEMP_FILE_2_$$.txt"
export TEMP_FILE_HOTFIX_PRODUCTS="/tmp/deployHotfix_TEMP_FILE_HOTFIX_PRODUCTS_$$.txt"
export TEMP_FILE_HOTFIX_LIST="/tmp/deployHotfix_TEMP_FILE_HOTFIX_LIST_$$.txt"
export TEMP_FILE_ENV_LIST_FOR_DEPLOY="/tmp/deployHotfix_TEMP_FILE_ENV_LIST_FOR_DEPLOY_$$.txt"

export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export WHITE=$(tput setaf 7)
export BRIGHT=$(tput bold)
export NORMAL=$(tput sgr0)
}

# Checking if the script is being used correctly
usage(){
    printf "${RED}${BRIGHT}%s${NORMAL}\n" "Incorrect Usage !"
    printf "${GREEN}${BRIGHT}%s${NORMAL}\n" "Correct Usage:"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER1> -d <HOTFIX NUMBER>  (To deploy an HF in a single environment)"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER1> -d <HOTFIX NUMBER1>,<HOTFIX NUMBER2>  (To deploy 1 or more HFs in a single environment)"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER1, ENV NUMBER2 > -d <HOTFIX NUMBER>  (To deploy an HF in 1 or more 1 environment)"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER1, ENV NUMBER2 > -d <HOTFIX NUMBER>  (To deploy an HF in more than 1 environment)"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER> -md <HOTFIX NUMBER> (To mark an HF as deployed.)"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER1, ENV NUMBER2> -md <HOTFIX NUMBER>  (To mark an HF as deployed in more than 1 environment)"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER> -b <BUNDLE_NAME>"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER> -f <FILE_NAME>"
    printf "\t%s\n" "$0 -e|-ve|-g <ENV NUMBER> -f <FILE_NAME>"
    printf "\t%s\n" "By default confirmation/information will be displayed before deployment, use option below to hide: "
    printf "\t%s\n" " -c : Hide confirmation"
    printf "\t%s\n" " -i : Hide information"
    printf "\t%s\n" " -w : Do not stop in case of failure"
    printf "\t%s\n" " -p : Deploy a HF in multiple environments at the same time. (EX: HF1 deployed simultaniously at env 1 and 2, instead of sequentially)"
    printf "\n"

    printf "${GREEN}${BRIGHT}%s${NORMAL}\n" "Examples:"
    printf "\t%s\n" "$0 -e 1,2 -d 1000"
    printf "\t%s\n" "$0 -ve 1 -d 1000,1020"
    printf "\t%s\n" "$0 -e 1 -md 1000,1020"
    printf "\t%s\n" "$0 -g env_group_name_as_found_in_HF_GUI -md 1000,1020"
    printf "\t%s\n" "$0 -e 1,2 -md 1000,1020"
    printf "\t%s\n" "$0 -e 1 -b bundle -d"
    printf "\t%s\n" "$0 -e 1,2 -b bundle -md"
    printf "\t%s\n" "$0 -e 1 -f file -d"
    printf "\t%s\n" "$0 -e 1 -f file -md"
    printf "\t%s\n" "$0 -e 1 -d 1000,1020 -c -i -w"
    printf "\t%s\n" "$0 -e 1 -d 1000,1020 -c -w"
}

### This functions remove the temporary files that were created
cleanTempFiles(){
    rm -f ${TEMP_FILE_1}
    rm -f ${TEMP_FILE_2}
    rm -f ${TEMP_FILE_HOTFIX_LIST}
    rm -f ${TEMP_FILE_ENV_LIST_FOR_DEPLOY}
    rm -f ${TEMP_FILE_HOTFIX_PRODUCTS}
}

##### Functions that will be used on the script
### This function is used to deploy the AD hotfix in a non clustered environment.
deployHotfix(){
    hotfix_api_option=${HOTFIX_API_AVAILABLE_OPTIONS[0]}
    hotfix_number=$1
    environment=$2
    hotfix_log=$3

    printf "\n\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" >> ${hotfix_log}
    printf "@@@ ${hotfix_number} on ${environment}" >> ${hotfix_log}
    printf "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" >> ${hotfix_log}

    ${HOTFIX_API_SCRIPT} ${hotfix_api_option} ${hotfix_number} ${environment}
    return_code=$?
    echo "END_TIME ${environment} $(date +%s)" >> ${TEMP_FILE_2}
    return ${return_code}
}

### This function is used to mark an HF as deployed in a non clustered environment.
deployHotfix_MarkAsDeployed(){
    hotfix_number=$1
    environment=$2

    printf "${NORMAL}%-23s${GREEN}%s${NORMAL}\n" "Marking the HF: " "${hotfix_number}"
    printf "${NORMAL}%-23s${GREEN}%s${NORMAL}\n" "As Deployed in: " "${environment}"

    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    Insert into HOTFIX_EVT
    (UNIQUE_ID, EVENT_NAME, FILE_NAME, ENVIRONMENT, CREATION_DATE, DEST_PATH, LAST_MODIFIED_BY,  HF_COMMENT, DEPLOY_TYPE)
    Values
   ($hotfix_number, 'DEPLOYED', 'N/A', '$environment', sysdate, 'N/A', 'ApiAdmin', 'Deployed manually', 'MANUAL');
    commit;
SQL
}

### This functions gets all the HFs product number and deploy order from a bundle.
getBundles_Hotfixes(){
    hotfix_bundle_name=$1
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select hm.release, hm.product, hb.unique_id, hb.order_num
    from HOTFIX_BUNDLES hb, HOTFIX_MNG hm
    where 1=1
    and hb.bundle_name='$hotfix_bundle_name'
    and hb.unique_id=hm.unique_id
    order by 3 asc;
SQL
}

### This function is used to get the last X bundle names from the HFtool
getBundles_Names(){
    number_of_bundles_to_be_fetched=20
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select bundle_name
    from (select bundle_name, sys_creation_date
    from HOTFIX_BUNDLES
    where 1=1
    and order_num=1
    order by 2 desc)
    where rownum < '${number_of_bundles_to_be_fetched}';
SQL
}

### This function gets the Physical user_name@host for the environment, based on the product and groupname passed as parameter.
getEnvUserHost_GroupName(){
    product=$1
    group_name=$2
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select product, environment
    from HOTFIX_ENV_GROUPS
    where 1=1
    and group_name='${group_name}'
    and product='${product}';
SQL
}

### This function gets the Physical user_name@host for the environment, based on the product and environment numbers passed as parameters.
### It was configured to ignore "TRN" environments.
getEnvUserHost_Physical(){
    product=$1
    environment_number=$2
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select product, environment
    from HOTFIX_CTL
    where product = '$product'
    and environment not like '%trn%${environment_number}@%' and environment like '______${environment_number}@%' and environment not like '%${VIRTUAL_MACHINE_NAME}%';
SQL
}

### This function gets the Virtual user_name@host for the environment, based on the product and environment numbers passed as parameters.
getEnvUserHost_Virtual(){
    product=$1
    environment_number=$2
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select product || ' ' ||  environment
    from HOTFIX_CTL
    where product = '$product'
    and environment like '%${VIRTUAL_MACHINE_NAME}%${environment_number}';
SQL
}

### This functions gets the HF product using the HF number as parameter.
getHotfixDetails(){
    hotfix_number=$1
    sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    select hm.release, hm.product, hm.unique_id
    from HOTFIX_MNG hm
    where 1=1
    and hm.unique_id='$hotfix_number';
SQL
}

### Receives input file, output file, message string in that order, then prints the contents of the input file in a numbered option list, receives input from user placing the selected option in the output file, and prints the message received as parameter.
listValues(){
    clear
    input_file=$1
    ouput_file=$2
    string=$3
    num=1
    while read line_from_file
    do
    printf "${NORMAL}%-6s${NORMAL}%s${NORMAL}\n" '('${num}') ' "${line_from_file}"
    num=$((num+1))
    done < ${input_file}
    printf "${string}"
    read "value"  </dev/tty
    printf "$(sed -n "${value}p" ${input_file})\n" > ${ouput_file}
}

### Receives string message, start time and end time in seconds..
listTimeDifference(){
    string=${1}
    start_time=${2}
    end_time=${3}
    printf "%s\n" "${string} : $(( (${end_time} - ${start_time}) / 60)) min and $(( (${end_time} - ${start_time}) % 60)) sec"
}

### This functions asks for a random number before the execution.
#randomNumberValidator(){
#    printf "\n${BRIGHT}%s${NORMAL}\n\n" "Enter the below random number to confirm that you are not drunk."
#    used_random_number=$(echo $RANDOM % 10000 + 1 | bc)
#    printf "${BRIGHT}${GREEN}%s${NORMAL}\n\n" "${used_random_number}"
#    printf "${BRIGHT}%s${NORMAL}" "The number is :"
#    read input
#    if [[ "${input}" -ne "${used_random_number}" ]]
#    then
#        printf "${BRIGHT}${RED}%s${NORMAL}\n" "Entered number does not match!"
#        return 1
#    else
#        printf "${BRIGHT}${GREEN}%s${NORMAL}\n" "Entered number matches!"
#        return 0
#    fi
#}

### This function removes blank lines from a file
removeBlankLine(){
    perl -pi -e "s/^\n//" ${1}
}

### This function is used to select an environment, works for physical / virtual / env group name
select_Environment(){
    hotfix_product=$1
    environment_number=$2
    rm ${TEMP_FILE_1} 2> /dev/null
    rm ${TEMP_FILE_2} 2> /dev/null

    case ${ENVIRONMENT_TYPE} in
        "-e") getEnvUserHost_Physical ${hotfix_product} ${environment_number} > ${TEMP_FILE_1};;
        "-ve") getEnvUserHost_Virtual ${hotfix_product} ${environment_number} > ${TEMP_FILE_1};;
        "-g") getEnvUserHost_GroupName ${hotfix_product} ${environment_number} > ${TEMP_FILE_1};;
    esac

    #removeBlankLine ${TEMP_FILE_1}
    #listValues ${TEMP_FILE_1} ${TEMP_FILE_2} " --- Type the number to confirm the selected ENVIRONMENT for ${hfs_products}: "
    #cat ${TEMP_FILE_2} >> ${TEMP_FILE_ENV_LIST_FOR_DEPLOY}

    removeBlankLine ${TEMP_FILE_1}
    cat ${TEMP_FILE_1} >> ${TEMP_FILE_ENV_LIST_FOR_DEPLOY}
}

### This functions is used to retrieve some bundles from the DB, and prompt the user to select one.
select_Bundle(){
    getBundles_Names > ${TEMP_FILE_1}
    removeBlankLine ${TEMP_FILE_1}
    listValues ${TEMP_FILE_1} ${TEMP_FILE_2} "--- Type the number which represents the desired BUNDLE: "
    cat ${TEMP_FILE_2}
}

### This functions is used to call the function that gets the hf from the DB, validates that the hf was synched and put the valid hf in the hf_li
select_Hotfix(){
    hotfix_number=${1}
    rm ${TEMP_FILE_1} 2> /dev/null
    getHotfixDetails ${hotfix_number} > ${TEMP_FILE_1}
    validate_File "The HOTFIX ${hotfix_number} does not exist or the HF was not synched yet!" "${TEMP_FILE_1}"
    cat ${TEMP_FILE_1} >> ${TEMP_FILE_HOTFIX_LIST}
}

### This function validates if the retrieved list from the HFs is valid.
validate_File(){
    error_message=${1}
    file=${2}
    skip_return_code=$3
    removeBlankLine ${file}
    if [[ ! -s ${file} ]]
    then
        printf "${RED}${BRIGHT}%s\n${NORMAL}" "${error_message}"
        if [[ ${skip_return_code} != "Y" ]]
        then
            cleanTempFiles
            exit 1
        fi
    fi
}

### This function calls an HFTool API to check if the HF is valid for AD.
validateHotfix_API(){
    HOTFIX_API_USED_OPTION=${HOTFIX_API_AVAILABLE_OPTIONS[1]}
    HOTFIX_NUMBER=$1
    HOTFIX_PRODUCT=$2
    HOTFIX_VERSION=$3
    ${HOTFIX_API_SCRIPT} ${HOTFIX_API_USED_OPTION} ${HOTFIX_NUMBER} ${HOTFIX_PRODUCT} ${HOTFIX_VERSION}
}

## This function is used to validate HF: is rejected? has manual steps? is auto deploy?
validateHotfix_Custom() {
    hotfix_number=$1

    result=$(sqlplus -s "${HOTFIX_DB_USER}/${HOTFIX_DB_PASSWORD}@${HOTFIX_DB_INSTANCE}" << SQL
    SET PAGESIZE 1000 LINESIZE 500 ECHO OFF TRIMS ON TAB OFF FEEDBACK OFF HEADING OFF SERVEROUTPUT OFF;
    SELECT
       DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_EVT WHERE UNIQUE_ID = M.UNIQUE_ID AND EVENT_NAME = 'REJECTED'), 0,'NO', 1,'YES', 'YES') AS REJECTED,
       DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID NOT IN (SELECT UNIQUE_ID FROM HOTFIX_AUTO_DEPLOY)), 0, 'YES', 1, 'NO', 'NO') AS AUTO_DEPLOY,
       DECODE((SELECT COUNT(UNIQUE_ID) FROM HOTFIX_MNG WHERE UNIQUE_ID = M.UNIQUE_ID AND UNIQUE_ID IN (
               SELECT UNIQUE_ID FROM HOTFIX_AP_RELATIONS WHERE UNIQUE_ID = M.UNIQUE_ID AND PARAM_ID = 1 AND PARAM_VALUE = 'YES')), 0, 'NO', 1, 'YES', 'YES') AS MANUAL_STEP,
       M.PRODUCT AS PRODUCT,
       M.RELEASE AS VERSION
    FROM HOTFIX_MNG M WHERE M.UNIQUE_ID = ${hotfix_number};
SQL)

    REJECTED=$(echo ${result} | awk '{ print $1 }')
    AD=$(echo ${result} | awk '{ print $2 }')
    MN_STEP=$(echo ${result} | awk '{ print $3 }')
    PRODUCT=$(echo ${result} | awk '{ print $4 }')
    HF_VERSION=$(echo ${result} | awk '{ print $5 }')

    if [ "${REJECTED}" == "YES" ]; then
        echo 10
        return 0
    fi

    if [ "${AD}" == "NO" ]; then
        echo 20
        return 0
    fi

    if [ "${MN_STEP}" == "YES" ]; then
        echo 30
        return 0
    fi

    if [ "${PRODUCT}" == "AUA" ]; then
        echo 40
        return 0
    fi

    #if [ "${HF_VERSION}" != "${CURRENT_VERSION}" ]; then
    #    echo 50
    #    return 0
    #fi

    echo 0
    return 0

}

######################################################
##           Main execution of the script           ##
######################################################

clear

if [[ $# -lt 4 ]]
then
    usage
    exit 1
fi

## Getting parameters
export ENVIRONMENT_TYPE=$1
export ENVIRONMENTS_OR_GROUP_NAME=$2

export DEPLOY_MODE=$3
export DEPLOY_ARGUMENT=$4

shift 4

## Retrieving the hotfix details from the database.
case $DEPLOY_MODE in
  "-d"|"-md")
        ## Option used for single HF or HFs separated by ','
        HOTFIX_NUMBER=${DEPLOY_ARGUMENT}
        for hotfix_number in $(echo ${HOTFIX_NUMBER} | tr ',' '\n')
        do
            select_Hotfix ${hotfix_number}
        done
        ;;
  "-b")
        for bundle_name in $(echo ${DEPLOY_ARGUMENT} | tr ',' '\n')
        do
            getBundles_Hotfixes ${bundle_name} > ${TEMP_FILE_1}
            validate_File  "Bundle ${bundle_name} is empty or not synched." ${TEMP_FILE_1} "Y"
            cat ${TEMP_FILE_1} >> ${TEMP_FILE_HOTFIX_LIST}
        done
        if [[ "$1" == "-md"  ]]
        then
            shift 1
            export DEPLOY_MODE="-md"
        else
            export DEPLOY_MODE="-d"
        fi

        ;;
  "-f")
        ## Option used to get the hotfixes passed from a file as parameter.
        HOTFIX_FILELIST_NAME=${DEPLOY_ARGUMENT}
        validate_File "The file ${HOTFIX_FILELIST_NAME} does not exist or is empty." ${HOTFIX_FILELIST_NAME}

        while read hotfix_number
        do
            select_Hotfix ${hotfix_number}
        done < ${HOTFIX_FILELIST_NAME}

        if [[ "$1" == "-md"  ]]
        then
            shift 1
            export DEPLOY_MODE="-md"
        else
            export DEPLOY_MODE="-d"
        fi
        ;;
  "*")
        usage
        exit 1
        ;;
esac


DISPLAY_CONFIRMATION="Y"
DISPLAY_INFORMATION="Y"
FAILED_CONFIRMATION="N"
PARALLEL_DEPLOY="N"

## Checking additional parameters
for param in $*; do
    case ${param} in
        "-c") DISPLAY_CONFIRMATION="N"  ;;
        "-i") DISPLAY_INFORMATION="N"   ;;
        "-w") FAILED_CONFIRMATION="Y"   ;;
        "-p") PARALLEL_DEPLOY="Y"       ;;
    esac
done

## Getting each product from the HF list file
cat ${TEMP_FILE_HOTFIX_LIST} | awk '{print $2}' | sort -u > ${TEMP_FILE_HOTFIX_PRODUCTS}

### Based on each product on the HFs to be deployed, gets the username@host from the environments passed, and asks for confirmation if the environment is correct
while read hotfix_product
do
    for environment_number in $(echo ${ENVIRONMENTS_OR_GROUP_NAME} | tr ',' '\n')
    do
        select_Environment ${hotfix_product} ${environment_number}
    done
done < ${TEMP_FILE_HOTFIX_PRODUCTS}
printf "\n"

### Showing the list of HFs which will be deployed
if [ "${DISPLAY_INFORMATION}" == "Y" ]; then
    printf "${BRIGHT}%s\n\n" "The HFs will be deployed in the below order."
    printf "${BRIGHT}%-10s\t%-10s\t%-15s\t%-5s${NORMAL}\n" "VERSION"  "PRODUCT" "HOTFIX NUMBER" "DEPLOY ORDER"

    while read hf_list_to_deploy
    do
        printf "${BRIGHT}%-10s\t%-10s\t%-15s\t%-5s${NORMAL}\n" "  $(echo ${hf_list_to_deploy}| awk '{print $1}')" "  $(echo ${hf_list_to_deploy}| awk '{print $2}')" "  $(echo ${hf_list_to_deploy}| awk '{print $3}')" "    $(echo ${hf_list_to_deploy}| awk '{print $4}')"
    done < ${TEMP_FILE_HOTFIX_LIST}
    sleep 1
fi

## Checking for confirmation before the HF deploy.
#if [ "${DISPLAY_CONFIRMATION}" == "Y" ]; then
#    printf "\n"
#    printf "${BRIGHT}%s\n${NORMAL}" "Please CONFIRM that the deploy must be done in the below ENVIRONMENTS ACCOUNTS"
#    printf "------------------------------------\n"
#    while read hotfix_enviroment
#    do
#        printf "${BRIGHT}%-10s\t%-15s${NORMAL}\n" "  $(echo ${hotfix_enviroment}| awk '{print $1}')" "  $(echo ${hotfix_enviroment}| awk '{print $2}')"
#    done < ${TEMP_FILE_ENV_LIST_FOR_DEPLOY}
#    printf "------------------------------------\n"
#
#    randomNumberValidator
#fi

#if [[ "$?" -ne "0" ]]
#then
#    printf "${RED}${BRIGHT}%s${NORMAL}\n\n" "You are drunk, sober up."
#    cleanTempFiles
#    exit 1
#else
#    printf "${GREEN}${BRIGHT}%s${NORMAL}\n\n" "Thanks for being sober, please wait for a moment until the process begins."
#fi
#
#sleep 2


if [[ "${DEPLOY_MODE}" == "-md" ]]
then
    ### Running the commands which will mark the HFS as deployed
    while read hf_to_deploy
    do
        HF_VERSION=$(printf "${hf_to_deploy}" | awk '{print $1}')
        HF_PRODUCT=$(printf "${hf_to_deploy}" | awk '{print $2}')
        HF_NUMBER=$(printf "${hf_to_deploy}" | awk '{print $3}')
        for environment in $(grep -P "^${HF_PRODUCT}" ${TEMP_FILE_ENV_LIST_FOR_DEPLOY} | awk '{print $2}' | tr ' ' '\n')
        do
            deployHotfix_MarkAsDeployed ${HF_NUMBER} ${environment} &
            sleep 2
        done
        wait
    done < ${TEMP_FILE_HOTFIX_LIST}
    cleanTempFiles
    exit 0
fi

### Running the commands which will deploy the HFs.
HF_COUNT=0
export MANUAL_HF_FOUND="N"
export HOTFIX_LOG="${HOTFIX_AMC_HOTFIX_HOME}/hotfix/tmp/hf_deploy_$(date +%Y%m%d%H%M%S)_$$.log"

printf "%s\n\n" "FULL DEPLOY LOG for the environments can be found below at: ${HOTFIX_LOG_DIRECTORY}"


cat ${TEMP_FILE_ENV_LIST_FOR_DEPLOY} | awk '{print $2}' | cut -c 7- | sort -u > ${TEMP_FILE_1}
while read environmentHost
do
    deploy_log="${HOTFIX_LOG_DIRECTORY}/hf_deploy_$(date +%Y%m%d%H%M%S)_$$_env_$(echo ${environmentHost} | tr '@' '_').log"
    touch ${deploy_log}
    printf "\n%s\n" "   Env/Host              LogName"
    printf "%s\n" "   ${environmentHost}    ${deploy_log}"
done < ${TEMP_FILE_1}

printf "\n%s\n" "----------------------------------------------------"
printf "%s\n" "   Please wait while the HFs are being deployed."
printf "%s\n" "----------------------------------------------------"
all_hfs_start_time=$(date +%s)

while read hf_to_deploy
do
    HF_NUMBER=$(printf "${hf_to_deploy}" | awk '{print $3}')
    HF_PRODUCT=$(printf "${hf_to_deploy}" | awk '{print $2}')
    HF_COUNT=$(expr ${HF_COUNT} + 1)
    single_hf_deploy_start_time_all_envs=$(date +%s)
    printf "\n [${HF_COUNT}] HF#${HF_NUMBER}: "
    HF_VALIDATION=$(validateHotfix_Custom "${HF_NUMBER}")
    case ${HF_VALIDATION} in
        10) echo "${RED}${BRIGHT}REJECTED${NORMAL}"             ;;
        20) echo "${YELLOW}${BRIGHT}MANUAL${NORMAL}"
            export MANUAL_HF_FOUND="Y"                          ;;
        30) echo "${BLUE}${BRIGHT}ADDITIONAL STEPS${NORMAL}"    ;;
        40) echo "${YELLOW}${BRIGHT}IGNORED (OSS)${NORMAL}"     ;;
        #50) echo "${MAGENTA}${BRIGHT}WRONG VERSION${NORMAL}"    ;;
        #0)
        0|50)
            rm -f ${TEMP_FILE_1} 2> /dev/null
            rm -f ${TEMP_FILE_2} 2> /dev/null
            for environmentHost in $(grep -P "^${HF_PRODUCT}" ${TEMP_FILE_ENV_LIST_FOR_DEPLOY} | awk '{print $2}' | tr ' ' '\n')
            do
                if [[ ${PARALLEL_DEPLOY} == "N" ]]
                then
                    deploy_log="$(ls ${HOTFIX_LOG_DIRECTORY}/*_$$_env_$(echo ${environmentHost} | tr '@' '_' | cut -c 7- ).log)"
                    deployHotfix ${HF_NUMBER} ${environmentHost} ${deploy_log} >> ${deploy_log} 2>&1 &
                    echo "${environmentHost} $!" >> ${TEMP_FILE_1}
                    echo "START_TIME ${environmentHost} $(date +%s)" >> ${TEMP_FILE_2}
                    wait
                else
                    deploy_log="$(ls ${HOTFIX_LOG_DIRECTORY}/*_$$_env_$(echo ${environmentHost} | tr '@' '_' | cut -c 7- ).log)"
                    deployHotfix ${HF_NUMBER} ${environmentHost} ${deploy_log} >> ${deploy_log} 2>&1 &
                    echo "${environmentHost} $!" >> ${TEMP_FILE_1}
                    echo "START_TIME ${environmentHost} $(date +%s)" >> ${TEMP_FILE_2}
                    sleep 2
                fi
            done
            wait

            single_hf_deploy_end_time_all_envs=$(date +%s)
            listTimeDifference " Hotfix deploy time" "${single_hf_deploy_start_time_all_envs}" "${single_hf_deploy_end_time_all_envs}"
            deploy_status_of_hf="0"

            while read processinbackground
            do
                deploy_env="$(echo ${processinbackground} | cut -d ' ' -f 1)"
                deploy_pid="$(echo ${processinbackground} | cut -d ' ' -f 2)"
                hf_deploy_start_time_for_env="$(grep ${deploy_env} ${TEMP_FILE_2} | grep START_TIME | cut -d ' ' -f 3)"
                hf_deploy_end_time_for_env="$(grep ${deploy_env} ${TEMP_FILE_2} | grep END_TIME | cut -d ' ' -f 3)"
                wait ${deploy_pid}

                if [[ $? -ne 0 ]]
                then
                    deploy_status_of_hf=1
                    printf "   ${RED}${BRIGHT}FAILED${NORMAL}   - ${deploy_env}"
                    listTimeDifference " - deploy time" "${hf_deploy_start_time_for_env}" "${hf_deploy_end_time_for_env}"
                else
                    printf "   ${GREEN}${BRIGHT}DEPLOYED${NORMAL} - ${deploy_env}"
                    listTimeDifference " - deploy time" "${hf_deploy_start_time_for_env}" "${hf_deploy_end_time_for_env}"
                fi

            done < ${TEMP_FILE_1}

            if [[ ${deploy_status_of_hf} -ne 0 ]]
            then
                if [ "${FAILED_CONFIRMATION}" == "N" ]
                then
                    cleanTempFiles
                    printf "%s\n" "----------------------------------------------------"
                    listTimeDifference "TOTAL TIME ELAPSED" "${all_hfs_start_time}" "${single_hf_deploy_end_time_all_envs}"
                    printf "%s\n" "----------------------------------------------------"
                    exit 1
                fi
            fi

        ;;
    esac
done < ${TEMP_FILE_HOTFIX_LIST}

all_hfs_end_time=$(date +%s)
printf "\n%s\n" "----------------------------------------------------"
listTimeDifference "   TOTAL TIME ELAPSED FOR ALL THE HOTFIXES" "${all_hfs_start_time}" "${all_hfs_end_time}"
printf "%s\n" "----------------------------------------------------"

cleanTempFiles
exit 0
