import{_ as e,s as t,a,v as o}from"./index-d892937d.js";import{u}from"./user-0051511c.js";const d={data:()=>({timer:null,trojanVersion:"",trojanUptime:"",keyOffset:0,valueOffset:0,userList:[],downloadData:0,uploadData:0,totalData:0,cpu:{percentage:0,color:""},memory:{percentage:0,used:0,total:0,color:""},swap:{percentage:0,used:0,total:0,color:""},disk:{percentage:0,used:0,total:0,color:""},load:"",netSpeed:{up:"",down:""},netCount:""}),computed:{...Vuex.mapState(["isAdmin"])},created(){this.$store.commit("SET_NPROGRESS",!1),this.setOffset(),this.getVersion(),this.getUserList()},mounted(){this.isAdmin&&this.getServerInfo(),this.timer=setInterval((()=>{this.isAdmin&&this.getServerInfo(),this.getVersion(),this.getUserList()}),6e3),window.onresize=()=>(()=>{this.setOffset()})()},unmounted(){this.$store.commit("SET_NPROGRESS",!0),clearInterval(this.timer)},methods:{setOffset(){document.body.clientWidth<1e3?(this.keyOffset=1,this.valueOffset=2,this.iconShow=!1):(this.keyOffset=0,this.valueOffset=0,this.iconShow=!0)},navigate(e){this.$router.push({path:e})},getServerInfo(){t().then((e=>{const t=e.Data;this.cpu.percentage=parseFloat(t.cpu[0].toFixed(2)),this.cpu.color=this.computeColor(this.cpu.percentage),this.memory=this.computePercent(t.memory),this.swap=this.computePercent(t.swap),this.disk=this.computePercent(t.disk),this.netSpeed.up=a(t.speed.Up)+"/s",this.netSpeed.down=a(t.speed.Down)+"/s",this.netCount=t.netCount.tcp+" / "+t.netCount.udp,this.load=t.load.load1+", "+t.load.load5+", "+t.load.load15}))},computePercent(e){const t=parseFloat(e.usedPercent.toFixed(2));return{percentage:t,used:a(e.used),total:a(e.total),color:this.computeColor(t)}},computeColor:e=>e<80?"#67C23A":e<90?"#E6A23C":"#F56C6C",async getUserList(){const e=await u();if("success"===e.Msg){const t=e.Data;this.userList=t.userList;let o=0,u=0;for(let e=0;e<this.userList.length;e++)o+=this.userList[e].Download,u+=this.userList[e].Upload;this.downloadData=a(o),this.uploadData=a(u),this.totalData=a(o+u)}else this.$message.error(e.Msg)},async getVersion(){const e=(await o()).Data;this.trojanVersion=e.trojanVersion,this.trojanUptime=this.parseUptime(e.trojanUptime)},parseUptime(e){let t="";if(-1!==e.indexOf("-")){const a=e.split("-");t+=a[0]+`${this.$t("dashboard.day")} `;const o=a[1].split(":");t+=o[0]+`${this.$t("dashboard.hour")} `,t+=o[1]+`${this.$t("dashboard.minute")} `,t+=o[2]+`${this.$t("dashboard.second")} `}else{const a=e.split(":");3===a.length?(t+=a[0]+`${this.$t("dashboard.hour")} `,t+=a[1]+`${this.$t("dashboard.minute")} `,t+=a[2]+`${this.$t("dashboard.second")} `):2===a.length&&(t+=a[0]+`${this.$t("dashboard.minute")} `,t+=a[1]+`${this.$t("dashboard.second")} `)}return t}}},s=(e=>(Vue.pushScopeId("data-v-17a80800"),e=e(),Vue.popScopeId(),e))((()=>Vue.createElementVNode("div",null,"CPU",-1))),r={class:"el-icon-top",style:{"margin-right":"8px"}},l={class:"el-icon-bottom"};const V=e(d,[["render",function(e,t,a,o,u,d){const V=Vue.resolveComponent("el-progress"),i=Vue.resolveComponent("el-col"),n=Vue.resolveComponent("el-row"),c=Vue.resolveComponent("el-card"),p=Vue.resolveComponent("el-link"),h=Vue.resolveComponent("el-tooltip"),m=Vue.resolveComponent("el-tag");return Vue.openBlock(),Vue.createElementBlock("div",null,[e.isAdmin?(Vue.openBlock(),Vue.createBlock(n,{key:0},{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:24},{default:Vue.withCtx((()=>[Vue.createVNode(c,{shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:12,style:{"text-align":"center"}},{default:Vue.withCtx((()=>[Vue.createVNode(V,{type:"dashboard",percentage:u.cpu.percentage,color:u.cpu.color},null,8,["percentage","color"]),s])),_:1}),Vue.createVNode(i,{span:12,style:{"text-align":"center"}},{default:Vue.withCtx((()=>[Vue.createVNode(V,{type:"dashboard",percentage:u.memory.percentage,color:u.memory.color},null,8,["percentage","color"]),Vue.createElementVNode("div",null,Vue.toDisplayString(e.$t("dashboard.memory"))+": "+Vue.toDisplayString(u.memory.used)+"/"+Vue.toDisplayString(u.memory.total),1)])),_:1})])),_:1})])),_:1}),Vue.createVNode(i,{sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:12,style:{"text-align":"center"}},{default:Vue.withCtx((()=>[Vue.createVNode(V,{type:"dashboard",percentage:u.swap.percentage,color:u.swap.color},null,8,["percentage","color"]),Vue.createElementVNode("div",null,"swap: "+Vue.toDisplayString(u.swap.used)+"/"+Vue.toDisplayString(u.swap.total),1)])),_:1}),Vue.createVNode(i,{span:12,style:{"text-align":"center"}},{default:Vue.withCtx((()=>[Vue.createVNode(V,{type:"dashboard",percentage:u.disk.percentage,color:u.disk.color},null,8,["percentage","color"]),Vue.createElementVNode("div",null,Vue.toDisplayString(e.$t("dashboard.disk"))+": "+Vue.toDisplayString(u.disk.used)+"/"+Vue.toDisplayString(u.disk.total),1)])),_:1})])),_:1})])),_:1})])),_:1})])),_:1})])),_:1})])),_:1})):Vue.createCommentVNode("",!0),Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(c,{class:"home-card",shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:10},{default:Vue.withCtx((()=>[Vue.createElementVNode("b",null,Vue.toDisplayString(e.$t("dashboard.trojanVersion"))+": ",1)])),_:1}),Vue.createVNode(i,{span:12,style:{"padding-top":"1px"}},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.trojanVersion),1)])),_:1})])),_:1})])),_:1})])),_:1}),Vue.createVNode(i,{sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(c,{class:"home-card",shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:10},{default:Vue.withCtx((()=>[Vue.createElementVNode("b",null,Vue.toDisplayString(e.$t("dashboard.trojanUser"))+":",1)])),_:1}),Vue.createVNode(i,{span:12,style:{"padding-top":"1px"}},{default:Vue.withCtx((()=>[Vue.createVNode(p,{type:"primary",onClick:t[0]||(t[0]=e=>d.navigate("/user"))},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.userList.length),1)])),_:1})])),_:1})])),_:1})])),_:1})])),_:1})])),_:1}),Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(c,{class:"home-card",shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:10},{default:Vue.withCtx((()=>[Vue.createElementVNode("b",null,Vue.toDisplayString(e.$t("dashboard.trojanUptime"))+":",1)])),_:1}),Vue.createVNode(i,{span:12,style:{"padding-top":"1px"}},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.trojanUptime),1)])),_:1})])),_:1})])),_:1})])),_:1}),e.isAdmin?(Vue.openBlock(),Vue.createBlock(i,{key:0,sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(c,{class:"home-card",shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:10},{default:Vue.withCtx((()=>[Vue.createElementVNode("b",null,Vue.toDisplayString(e.$t("dashboard.load"))+":",1)])),_:1}),Vue.createVNode(h,{class:"item",effect:"dark",content:"load1, load5, load15",placement:"top-start"},{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:12,style:{"padding-top":"1px"}},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.load),1)])),_:1})])),_:1})])),_:1})])),_:1})])),_:1})):Vue.createCommentVNode("",!0)])),_:1}),Vue.createVNode(n,null,{default:Vue.withCtx((()=>[e.isAdmin?(Vue.openBlock(),Vue.createBlock(i,{key:0,sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(c,{class:"home-card",shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:10},{default:Vue.withCtx((()=>[Vue.createElementVNode("b",null,Vue.toDisplayString(e.$t("dashboard.netSpeed"))+":",1)])),_:1}),Vue.createVNode(i,{span:12,style:{"padding-top":"1px"}},{default:Vue.withCtx((()=>[Vue.createElementVNode("i",r,Vue.toDisplayString(u.netSpeed.up),1),Vue.createElementVNode("i",l,Vue.toDisplayString(u.netSpeed.down),1)])),_:1})])),_:1})])),_:1})])),_:1})):Vue.createCommentVNode("",!0),e.isAdmin?(Vue.openBlock(),Vue.createBlock(i,{key:1,sm:24,md:12},{default:Vue.withCtx((()=>[Vue.createVNode(c,{class:"home-card",shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createVNode(n,null,{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:10},{default:Vue.withCtx((()=>[Vue.createElementVNode("b",null,Vue.toDisplayString(e.$t("dashboard.netCount"))+":",1)])),_:1}),Vue.createVNode(h,{class:"item",effect:"dark",content:"tcp / udp",placement:"top-start"},{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:12,style:{"padding-top":"1px"}},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.netCount),1)])),_:1})])),_:1})])),_:1})])),_:1})])),_:1})):Vue.createCommentVNode("",!0)])),_:1}),Vue.createVNode(n,{style:{"margin-top":"10px"}},{default:Vue.withCtx((()=>[Vue.createVNode(i,{span:7},{default:Vue.withCtx((()=>[Vue.createVNode(c,{shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(e.$t("dashboard.upload"))+": ",1),Vue.createVNode(m,{effect:"dark",type:"success"},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.uploadData),1)])),_:1})])),_:1})])),_:1}),Vue.createVNode(i,{span:7,offset:1},{default:Vue.withCtx((()=>[Vue.createVNode(c,{shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(e.$t("dashboard.download"))+": ",1),Vue.createVNode(m,{effect:"dark",type:"success"},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.downloadData),1)])),_:1})])),_:1})])),_:1}),Vue.createVNode(i,{span:7,offset:1},{default:Vue.withCtx((()=>[Vue.createVNode(c,{shadow:"hover"},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(e.$t("dashboard.total"))+": ",1),Vue.createVNode(m,{effect:"dark",type:"success"},{default:Vue.withCtx((()=>[Vue.createTextVNode(Vue.toDisplayString(u.totalData),1)])),_:1})])),_:1})])),_:1})])),_:1})])}],["__scopeId","data-v-17a80800"]]);export{V as default};
# bash completion V2 for %-36[1]s -*- shell-script -*-

__%[1]s_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Macs have bash3 for which the bash-completion package doesn't include
# _init_completion. This is a minimal version of that function.
__%[1]s_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

# This function calls the %[1]s program to obtain the completion
# results and the directive.  It fills the 'out' and 'directive' vars.
__%[1]s_get_completion_results() {
    local requestComp lastParam lastChar args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly %[1]s allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} %[2]s ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __%[1]s_debug "lastParam ${lastParam}, lastChar ${lastChar}"

    if [[ -z ${cur} && ${lastChar} != = ]]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __%[1]s_debug "Adding extra empty parameter"
        requestComp="${requestComp} ''"
    fi

    # When completing a flag with an = (e.g., %[1]s -n=<TAB>)
    # bash focuses on the part after the =, so we need to remove
    # the flag part from $cur
    if [[ ${cur} == -*=* ]]; then
        cur="${cur#*=}"
    fi

    __%[1]s_debug "Calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%%:*}
    if [[ ${directive} == "${out}" ]]; then
        # There is not directive specified
        directive=0
    fi
    __%[1]s_debug "The completion directive is: ${directive}"
    __%[1]s_debug "The completions are: ${out}"
}

__%[1]s_process_completion_results() {
    local shellCompDirectiveError=%[3]d
    local shellCompDirectiveNoSpace=%[4]d
    local shellCompDirectiveNoFileComp=%[5]d
    local shellCompDirectiveFilterFileExt=%[6]d
    local shellCompDirectiveFilterDirs=%[7]d
    local shellCompDirectiveKeepOrder=%[8]d

    if (((directive & shellCompDirectiveError) != 0)); then
        # Error code.  No completion.
        __%[1]s_debug "Received error from custom completion go code"
        return
    else
        if (((directive & shellCompDirectiveNoSpace) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                __%[1]s_debug "Activating no space"
                compopt -o nospace
            else
                __%[1]s_debug "No space directive not supported in this version of bash"
            fi
        fi
        if (((directive & shellCompDirectiveKeepOrder) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                # no sort isn't supported for bash less than < 4.4
                if [[ ${BASH_VERSINFO[0]} -lt 4 || ( ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 4 ) ]]; then
                    __%[1]s_debug "No sort directive not supported in this version of bash"
                else
                    __%[1]s_debug "Activating keep order"
                    compopt -o nosort
                fi
            else
                __%[1]s_debug "No sort directive not supported in this version of bash"
            fi
        fi
        if (((directive & shellCompDirectiveNoFileComp) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                __%[1]s_debug "Activating no file completion"
                compopt +o default
            else
                __%[1]s_debug "No file completion directive not supported in this version of bash"
            fi
        fi
    fi

    # Separate activeHelp from normal completions
    local completions=()
    local activeHelp=()
    __%[1]s_extract_activeHelp

    if (((directive & shellCompDirectiveFilterFileExt) != 0)); then
        # File extension filtering
        local fullFilter filter filteringCmd

        # Do not use quotes around the $completions variable or else newline
        # characters will be kept.
        for filter in ${completions[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __%[1]s_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif (((directive & shellCompDirectiveFilterDirs) != 0)); then
        # File completion for directories only

        local subdir
        subdir=${completions[0]}
        if [[ -n $subdir ]]; then
            __%[1]s_debug "Listing directories in $subdir"
            pushd "$subdir" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
        else
            __%[1]s_debug "Listing directories in ."
            _filedir -d
        fi
    else
        __%[1]s_handle_completion_types
    fi

    __%[1]s_handle_special_char "$cur" :
    __%[1]s_handle_special_char "$cur" =

    # Print the activeHelp statements before we finish
    if ((${#activeHelp[*]} != 0)); then
        printf "\n";
        printf "%%s\n" "${activeHelp[@]}"
        printf "\n"

        # The prompt format is only available from bash 4.4.
        # We test if it is available before using it.
        if (x=${PS1@P}) 2> /dev/null; then
            printf "%%s" "${PS1@P}${COMP_LINE[@]}"
        else
            # Can't print the prompt.  Just print the
            # text the user had typed, it is workable enough.
            printf "%%s" "${COMP_LINE[@]}"
        fi
    fi
}

# Separate activeHelp lines from real completions.
# Fills the $activeHelp and $completions arrays.
__%[1]s_extract_activeHelp() {
    local activeHelpMarker="%[9]s"
    local endIndex=${#activeHelpMarker}

    while IFS='' read -r comp; do
        if [[ ${comp:0:endIndex} == $activeHelpMarker ]]; then
            comp=${comp:endIndex}
            __%[1]s_debug "ActiveHelp found: $comp"
            if [[ -n $comp ]]; then
                activeHelp+=("$comp")
            fi
        else
            # Not an activeHelp line but a normal completion
            completions+=("$comp")
        fi
    done <<<"${out}"
}

__%[1]s_handle_completion_types() {
    __%[1]s_debug "__%[1]s_handle_completion_types: COMP_TYPE is $COMP_TYPE"

    case $COMP_TYPE in
    37|42)
        # Type: menu-complete/menu-complete-backward and insert-completions
        # If the user requested inserting one completion at a time, or all
        # completions at once on the command-line we must remove the descriptions.
        # https://github.com/spf13/cobra/issues/1508
        local tab=$'\t' comp
        while IFS='' read -r comp; do
            [[ -z $comp ]] && continue
            # Strip any description
            comp=${comp%%%%$tab*}
            # Only consider the completions that match
            if [[ $comp == "$cur"* ]]; then
                COMPREPLY+=("$comp")
            fi
        done < <(printf "%%s\n" "${completions[@]}")
        ;;

    *)
        # Type: complete (normal completion)
        __%[1]s_handle_standard_completion_case
        ;;
    esac
}

__%[1]s_handle_standard_completion_case() {
    local tab=$'\t' comp

    # Short circuit to optimize if we don't have descriptions
    if [[ "${completions[*]}" != *$tab* ]]; then
        IFS=$'\n' read -ra COMPREPLY -d '' < <(compgen -W "${completions[*]}" -- "$cur")
        return 0
    fi

    local longest=0
    local compline
    # Look for the longest completion so that we can format things nicely
    while IFS='' read -r compline; do
        [[ -z $compline ]] && continue
        # Strip any description before checking the length
        comp=${compline%%%%$tab*}
        # Only consider the completions that match
        [[ $comp == "$cur"* ]] || continue
        COMPREPLY+=("$compline")
        if ((${#comp}>longest)); then
            longest=${#comp}
        fi
    done < <(printf "%%s\n" "${completions[@]}")

    # If there is a single completion left, remove the description text
    if ((${#COMPREPLY[*]} == 1)); then
        __%[1]s_debug "COMPREPLY[0]: ${COMPREPLY[0]}"
        comp="${COMPREPLY[0]%%%%$tab*}"
        __%[1]s_debug "Removed description from single completion, which is now: ${comp}"
        COMPREPLY[0]=$comp
    else # Format the descriptions
        __%[1]s_format_comp_descriptions $longest
    fi
}

__%[1]s_handle_special_char()
{
    local comp="$1"
    local char=$2
    if [[ "$comp" == *${char}* && "$COMP_WORDBREAKS" == *${char}* ]]; then
        local word=${comp%%"${comp##*${char}}"}
        local idx=${#COMPREPLY[*]}
        while ((--idx >= 0)); do
            COMPREPLY[idx]=${COMPREPLY[idx]#"$word"}
        done
    fi
}

__%[1]s_format_comp_descriptions()
{
    local tab=$'\t'
    local comp desc maxdesclength
    local longest=$1

    local i ci
    for ci in ${!COMPREPLY[*]}; do
        comp=${COMPREPLY[ci]}
        # Properly format the description string which follows a tab character if there is one
        if [[ "$comp" == *$tab* ]]; then
            __%[1]s_debug "Original comp: $comp"
            desc=${comp#*$tab}
            comp=${comp%%%%$tab*}

            # $COLUMNS stores the current shell width.
            # Remove an extra 4 because we add 2 spaces and 2 parentheses.
            maxdesclength=$(( COLUMNS - longest - 4 ))

            # Make sure we can fit a description of at least 8 characters
            # if we are to align the descriptions.
            if ((maxdesclength > 8)); then
                # Add the proper number of spaces to align the descriptions
                for ((i = ${#comp} ; i < longest ; i++)); do
                    comp+=" "
                done
            else
                # Don't pad the descriptions so we can fit more text after the completion
                maxdesclength=$(( COLUMNS - ${#comp} - 4 ))
            fi

            # If there is enough space for any description text,
            # truncate the descriptions that are too long for the shell width
            if ((maxdesclength > 0)); then
                if ((${#desc} > maxdesclength)); then
                    desc=${desc:0:$(( maxdesclength - 1 ))}
                    desc+="