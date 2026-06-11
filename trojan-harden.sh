#!/bin/bash
# trojan-harden.sh - Jrohy trojan-web 安全管理脚本
# 支持 Debian / Ubuntu / CentOS 7/8/9 / Rocky / AlmaLinux
#
# 选项:
#   1. 安装虚假登录界面（禁用 trojan-web，部署 nginx 伪装页）
#   2. 复原 web 管理页面（停止 nginx 伪装页，重新启用 trojan-web）
#   3. 安装修复版 web 管理页面（修复 CVE-2025-5525，保留面板功能）
#
# 用法: bash trojan-harden.sh [选项编号] [fallback端口]

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
title() { echo -e "${BLUE}$*${NC}"; }

WEBROOT="/var/www/fake-pan"
TROJAN_CONFIG="/usr/local/etc/trojan/config.json"
TROJAN_BIN="/usr/local/bin/trojan"
TROJAN_WEB_SERVICE="trojan-web"
FW_COMMENT="trojan-harden-fakepan"
BUILD_DIR="/tmp/trojan-build"
REPO_URL="https://github.com/Jrohy/trojan.git"

# ============================================================
# 检测系统
# ============================================================
detect_os() {
    [ -f /etc/os-release ] || error "无法检测操作系统"
    . /etc/os-release
    OS=$ID
    OS_VER=$VERSION_ID
    info "检测到系统: $OS $OS_VER"
}

# ============================================================
# 检测防火墙类型
# ============================================================
detect_firewall() {
    if systemctl is-active --quiet ufw 2>/dev/null && command -v ufw &>/dev/null; then
        FIREWALL="ufw"
    elif systemctl is-active --quiet firewalld 2>/dev/null && command -v firewall-cmd &>/dev/null; then
        FIREWALL="firewalld"
    else
        FIREWALL="none"
    fi
    info "防火墙类型: ${FIREWALL:-none}"
}

# ============================================================
# 清理 nginx 伪装页部署
# ============================================================
cleanup_fake_page() {
    info "===== 检查并清理旧部署 ====="
    local cleaned=0

    if [ -f /etc/nginx/sites-available/fake-pan ] || \
       [ -f /etc/nginx/conf.d/fake-pan.conf ]; then
        warn "发现旧 nginx 配置，清理中..."
        rm -f /etc/nginx/sites-available/fake-pan
        rm -f /etc/nginx/sites-enabled/fake-pan
        rm -f /etc/nginx/conf.d/fake-pan.conf
        systemctl is-active --quiet nginx 2>/dev/null && \
            nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true
        cleaned=1
    fi

    if [ -d "$WEBROOT" ]; then
        warn "发现旧伪装页面目录，清理中: $WEBROOT"
        rm -rf "$WEBROOT"
        cleaned=1
    fi

    case "$FIREWALL" in
        ufw)
            if ufw status numbered 2>/dev/null | grep -q "$FW_COMMENT"; then
                warn "发现旧 ufw 规则，清理中..."
                ufw status numbered 2>/dev/null | grep "$FW_COMMENT" | \
                    grep -oP '^\[\s*\K[0-9]+' | sort -rn | \
                    while read -r num; do
                        echo "y" | ufw delete "$num" 2>/dev/null || true
                    done
                cleaned=1
            fi
            ;;
        firewalld)
            local zone
            zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
            if firewall-cmd --permanent --zone="$zone" --list-rich-rules 2>/dev/null | \
               grep -q "$FW_COMMENT"; then
                warn "发现旧 firewalld 规则，清理中..."
                firewall-cmd --permanent --zone="$zone" --list-rich-rules 2>/dev/null | \
                    grep "$FW_COMMENT" | \
                    while IFS= read -r rule; do
                        firewall-cmd --permanent --zone="$zone" \
                            --remove-rich-rule="$rule" 2>/dev/null || true
                    done
                firewall-cmd --reload 2>/dev/null || true
                cleaned=1
            fi
            ;;
    esac

    [ "$cleaned" = "1" ] && info "旧部署清理完成" || info "未发现旧部署，跳过清理"
}

# ============================================================
# 读取 trojan 配置，确定 fallback 端口
# ============================================================
resolve_fallback_port() {
    if [ -n "$1" ]; then
        FALLBACK_PORT="$1"
        info "使用指定 fallback 端口: $FALLBACK_PORT"
        return
    fi

    if [ -f "$TROJAN_CONFIG" ]; then
        FALLBACK_PORT=$(grep '"remote_port"' "$TROJAN_CONFIG" | grep -o '[0-9]*' | head -1)
        info "从 trojan 配置读取 fallback 端口: $FALLBACK_PORT"
    else
        FALLBACK_PORT=80
        warn "未找到 trojan 配置，使用默认端口 80"
    fi

    local occupier
    occupier=$(ss -tlnp 2>/dev/null | grep ":${FALLBACK_PORT}[[:space:]\b]" | \
               grep -oP 'users:\(\("\K[^"]+' | head -1 || true)
    if [ -n "$occupier" ] && [ "$occupier" != "nginx" ]; then
        warn "端口 $FALLBACK_PORT 已被 $occupier 占用"
        NEW_PORT=8080
        while ss -tlnp 2>/dev/null | grep -q ":${NEW_PORT}[[:space:]\b]"; do
            NEW_PORT=$((NEW_PORT + 1))
        done
        warn "自动选用空闲端口: $NEW_PORT"
        warn "将修改 trojan config.json: remote_port $FALLBACK_PORT -> $NEW_PORT"
        if [ -f "$TROJAN_CONFIG" ]; then
            cp "$TROJAN_CONFIG" "${TROJAN_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
            sed -i "s/\"remote_port\": ${FALLBACK_PORT}/\"remote_port\": ${NEW_PORT}/" \
                "$TROJAN_CONFIG"
            TROJAN_CONFIG_CHANGED=1
            info "trojan config.json 已更新（原文件已备份）"
        fi
        FALLBACK_PORT=$NEW_PORT
    fi
}

# ============================================================
# 禁用 trojan-web 面板
# ============================================================
disable_trojan_web() {
    if systemctl is-active --quiet "$TROJAN_WEB_SERVICE" 2>/dev/null; then
        systemctl stop "$TROJAN_WEB_SERVICE"
        systemctl disable "$TROJAN_WEB_SERVICE"
        info "trojan-web 面板已停止并禁用"
    elif systemctl is-enabled --quiet "$TROJAN_WEB_SERVICE" 2>/dev/null; then
        systemctl disable "$TROJAN_WEB_SERVICE"
        info "trojan-web 面板已禁用"
    else
        info "trojan-web 面板未安装或已禁用，跳过"
    fi
}

# ============================================================
# 启用 trojan-web 面板
# ============================================================
enable_trojan_web() {
    if ! systemctl list-unit-files 2>/dev/null | grep -q "$TROJAN_WEB_SERVICE"; then
        error "trojan-web.service 不存在，请先通过 Jrohy 安装脚本安装"
    fi
    systemctl enable "$TROJAN_WEB_SERVICE"
    systemctl start "$TROJAN_WEB_SERVICE"
    sleep 2
    if systemctl is-active --quiet "$TROJAN_WEB_SERVICE" 2>/dev/null; then
        info "trojan-web 面板已启动"
    else
        warn "trojan-web 启动可能异常，请检查: journalctl -u trojan-web -n 20"
    fi
}

# ============================================================
# 安装 nginx
# ============================================================
install_nginx() {
    if command -v nginx &>/dev/null; then
        info "nginx 已安装，跳过"
        return
    fi
    case "$OS" in
        debian|ubuntu)
            apt-get update -qq
            DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf &>/dev/null; then
                dnf install -y nginx
            else
                yum install -y epel-release
                yum install -y nginx
            fi
            ;;
        *)
            error "不支持的系统: $OS，请手动安装 nginx"
            ;;
    esac
    info "nginx 安装完成"
}

# ============================================================
# 创建伪装页面
# ============================================================
create_fake_page() {
    mkdir -p "$WEBROOT"
    cat > "$WEBROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>文件管理系统</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#f5f6fa;display:flex;justify-content:center;align-items:center;height:100vh;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
.card{background:#fff;padding:44px 40px;border-radius:10px;box-shadow:0 4px 24px rgba(0,0,0,0.08);width:380px}
.logo{text-align:center;margin-bottom:32px}
.logo span{font-size:28px;font-weight:700;color:#2b5ce6;letter-spacing:1px}
.logo p{font-size:13px;color:#999;margin-top:4px}
.field{margin-bottom:18px}
label{display:block;font-size:13px;color:#666;margin-bottom:6px}
input{width:100%;padding:11px 14px;border:1px solid #e0e0e0;border-radius:6px;font-size:14px;outline:none;transition:border .2s}
input:focus{border-color:#2b5ce6;box-shadow:0 0 0 3px rgba(43,92,230,0.08)}
button{width:100%;padding:12px;background:#2b5ce6;color:#fff;border:none;border-radius:6px;font-size:15px;font-weight:500;cursor:pointer;transition:background .2s;margin-top:4px}
button:hover{background:#1a4bcc}
button:disabled{background:#a0b4f0;cursor:not-allowed}
.msg{font-size:13px;text-align:center;margin-top:14px;min-height:18px}
.msg.error{color:#e53935}
.msg.info{color:#999}
</style>
</head>
<body>
<div class="card">
  <div class="logo">
    <span>🗂 CloudDrive</span>
    <p>私有文件管理系统</p>
  </div>
  <div class="field"><label>用户名</label><input type="text" id="u" placeholder="请输入用户名" autocomplete="username"></div>
  <div class="field"><label>密码</label><input type="password" id="p" placeholder="请输入密码" autocomplete="current-password"></div>
  <button id="btn" onclick="doLogin()">登 录</button>
  <div class="msg" id="msg"></div>
</div>
<script>
async function doLogin(){
  const u=document.getElementById('u').value.trim();
  const p=document.getElementById('p').value.trim();
  const msg=document.getElementById('msg');
  const btn=document.getElementById('btn');
  if(!u||!p){msg.className='msg error';msg.textContent='请输入用户名和密码';return;}
  btn.disabled=true;msg.className='msg info';msg.textContent='验证中...';
  try{
    const r=await fetch('/api/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({username:u,password:p})});
    if(r.status===429){msg.className='msg error';msg.textContent='登录尝试过于频繁，请稍后再试';}
    else{msg.className='msg error';msg.textContent='用户名或密码错误';}
  }catch(e){msg.className='msg error';msg.textContent='网络错误，请稍后重试';}
  btn.disabled=false;
}
document.addEventListener('keydown',e=>{if(e.key==='Enter')doLogin();});
</script>
</body>
</html>
EOF
    if command -v getenforce &>/dev/null && [ "$(getenforce)" != "Disabled" ]; then
        chcon -R -t httpd_sys_content_t "$WEBROOT" 2>/dev/null && \
            info "SELinux 上下文已修复: httpd_sys_content_t" || \
            warn "SELinux 修复失败，若 403 请手动执行: chcon -R -t httpd_sys_content_t $WEBROOT"
    fi
    info "伪装页面创建完成: $WEBROOT"
}

# ============================================================
# 配置 nginx
# ============================================================
configure_nginx() {
    case "$OS" in
        debian|ubuntu)
            NGINX_CONF="/etc/nginx/sites-available/fake-pan"
            rm -f /etc/nginx/sites-enabled/default
            [ ! -L /etc/nginx/sites-enabled/fake-pan ] && \
                ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/fake-pan
            ;;
        centos|rhel|rocky|almalinux)
            NGINX_CONF="/etc/nginx/conf.d/fake-pan.conf"
            rm -f /etc/nginx/conf.d/default.conf
            if grep -q 'include /etc/nginx/default\.d' /etc/nginx/nginx.conf 2>/dev/null; then
                sed -i 's|include /etc/nginx/default\.d/\*\.conf|# &|' /etc/nginx/nginx.conf
            fi
            ;;
    esac

    cat > "$NGINX_CONF" << NGINXEOF
limit_req_zone \$binary_remote_addr zone=login_zone:10m rate=1r/m;

server {
    listen 127.0.0.1:${FALLBACK_PORT} default_server;
    server_name _;

    root ${WEBROOT};
    index index.html;

    location /api/login {
        limit_req zone=login_zone burst=4 nodelay;
        limit_req_status 429;
        add_header Content-Type 'application/json; charset=utf-8';
        return 200 '{"code":401,"message":"用户名或密码错误"}';
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGINXEOF

    nginx -t || error "nginx 配置测试失败，请检查 $NGINX_CONF"
    systemctl enable nginx
    systemctl restart nginx
    info "nginx 配置完成，监听 127.0.0.1:${FALLBACK_PORT}"
}

# ============================================================
# 封锁 fallback 端口外部直连
# ============================================================
block_direct_access() {
    if [ "$FALLBACK_PORT" = "80" ] || [ "$FALLBACK_PORT" = "443" ]; then
        info "标准端口 $FALLBACK_PORT，无需额外防火墙规则"
        return
    fi

    info "添加防火墙规则：封锁端口 $FALLBACK_PORT 的外部直连"

    case "$FIREWALL" in
        ufw)
            ufw allow from 127.0.0.1 to any port "$FALLBACK_PORT" proto tcp \
                comment "$FW_COMMENT"
            ufw deny from any to any port "$FALLBACK_PORT" proto tcp \
                comment "$FW_COMMENT"
            info "ufw 规则已添加（标记: $FW_COMMENT）"
            ;;
        firewalld)
            local zone
            zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
            firewall-cmd --permanent --zone="$zone" --add-rich-rule=\
"rule family='ipv4' source address='127.0.0.1' port port='${FALLBACK_PORT}' protocol='tcp' log prefix='${FW_COMMENT}' accept"
            firewall-cmd --permanent --zone="$zone" --add-rich-rule=\
"rule family='ipv4' port port='${FALLBACK_PORT}' protocol='tcp' log prefix='${FW_COMMENT}' drop"
            firewall-cmd --reload
            info "firewalld 规则已添加（标记: $FW_COMMENT，zone: $zone）"
            ;;
        none)
            warn "未检测到 ufw 或 firewalld，跳过"
            warn "nginx 已绑定 127.0.0.1:${FALLBACK_PORT}，外部无法直连"
            ;;
    esac
}

# ============================================================
# 重启 trojan（如果修改了配置）
# ============================================================
restart_trojan_if_needed() {
    if [ "${TROJAN_CONFIG_CHANGED:-0}" = "1" ]; then
        if systemctl is-active --quiet trojan 2>/dev/null; then
            systemctl restart trojan
            info "trojan 服务已重启"
        else
            warn "trojan 服务未运行，请手动启动: systemctl start trojan"
        fi
    fi
}

# ============================================================
# 验证伪装页面部署
# ============================================================
verify_fake_page() {
    echo ""
    info "===== 验证伪装页面 ====="
    sleep 1

    local title http_code login_code
    title=$(curl -s "http://127.0.0.1:${FALLBACK_PORT}/" 2>/dev/null | \
            grep -o '<title>.*</title>' || echo "")
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
                "http://127.0.0.1:${FALLBACK_PORT}/" 2>/dev/null || echo "000")

    if [ "$http_code" = "200" ] && echo "$title" | grep -q "文件管理系统"; then
        info "✓ 伪装页面响应正常: $title"
    else
        warn "伪装页面响应异常 (HTTP $http_code)，检查: journalctl -u nginx -n 20"
    fi

    login_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        "http://127.0.0.1:${FALLBACK_PORT}/api/login" \
        -H 'Content-Type: application/json' \
        -d '{"username":"test","password":"test"}' 2>/dev/null || echo "000")
    [ "$login_code" = "200" ] && \
        info "✓ 登录接口正常（始终返回失败）" || \
        warn "登录接口响应异常 (HTTP $login_code)"
}

# ============================================================
# 安装 Go 编译环境
# ============================================================
install_go() {
    if command -v go &>/dev/null; then
        info "Go 已安装: $(go version)"
        return
    fi
    info "安装 Go 编译环境..."
    case "$OS" in
        debian|ubuntu)
            apt-get update -qq
            DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf &>/dev/null; then
                dnf install -y golang
            else
                yum install -y golang
            fi
            ;;
        *)
            error "无法自动安装 Go，请手动安装后重试"
            ;;
    esac
    info "Go 安装完成: $(go version)"
}

# ============================================================
# 安装 git
# ============================================================
install_git() {
    if command -v git &>/dev/null; then
        return
    fi
    info "安装 git..."
    case "$OS" in
        debian|ubuntu)
            DEBIAN_FRONTEND=noninteractive apt-get install -y git
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf &>/dev/null; then
                dnf install -y git
            else
                yum install -y git
            fi
            ;;
    esac
}

# ============================================================
# 下载并部署修复版 trojan 二进制
# 修复内容: CVE-2025-5525 /auth/register 未授权修改密码
# 预编译二进制托管于: Rize-Nino/trojan-harden releases
# ============================================================
PATCHED_BIN_URL="https://github.com/Rize-Nino/trojan-harden/releases/download/v1.0.0/trojan-linux-amd64-patched"

build_patched_trojan() {
    info "===== 下载修复版 trojan 二进制 ====="
    info "来源: $PATCHED_BIN_URL"

    # 检查架构
    local arch
    arch=$(uname -m)
    if [ "$arch" != "x86_64" ]; then
        error "当前架构: $arch，预编译二进制仅支持 x86_64 (amd64)\n如需 arm64 支持请联系维护者"
    fi

    mkdir -p /tmp
    curl -fL "$PATCHED_BIN_URL" -o /tmp/trojan-patched ||         error "下载修复版二进制失败，请检查网络或确认 URL 有效"
    chmod +x /tmp/trojan-patched

    # 简单验证：确认是 ELF 可执行文件（检查魔数 7f 45 4c 46）
    if ! xxd /tmp/trojan-patched 2>/dev/null | head -1 | grep -q "7f45 4c46"; then
        if ! od -A x -t x1z /tmp/trojan-patched 2>/dev/null | head -1 | grep -q "7f 45 4c 46"; then
            error "下载的文件不是有效的 ELF 二进制，请检查下载链接"
        fi
    fi

    info "修复版二进制下载完成: $(ls -lh /tmp/trojan-patched | awk '{print $5}')"
}

# ============================================================
# 部署修复版二进制
# ============================================================
deploy_patched_trojan() {
    local patched_bin="/tmp/trojan-patched"

    [ -f "$patched_bin" ] || error "未找到修复版二进制: $patched_bin"

    # 备份原二进制
    if [ -f "$TROJAN_BIN" ]; then
        cp "$TROJAN_BIN" "${TROJAN_BIN}.bak.$(date +%Y%m%d%H%M%S)"
        info "原二进制已备份: ${TROJAN_BIN}.bak.*"
    fi

    # 停止 trojan 主服务，避免 "Text file busy"
    systemctl stop trojan 2>/dev/null || true
    systemctl stop "$TROJAN_WEB_SERVICE" 2>/dev/null || true
    sleep 1

    cp "$patched_bin" "$TROJAN_BIN"
    chmod +x "$TROJAN_BIN"
    rm -f "$patched_bin"
    info "修复版二进制已部署: $TROJAN_BIN"

    # 重启 trojan 主服务
    systemctl start trojan 2>/dev/null || true

    enable_trojan_web

    sleep 2
    info "验证修复效果..."
    local fallback
    fallback=$(grep '"remote_port"' "$TROJAN_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "80")

    local reg_code
    reg_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST         "http://127.0.0.1:${fallback}/auth/register"         -d "username=admin&password=test" 2>/dev/null || echo "000")

    if [ "$reg_code" = "403" ]; then
        info "✓ 修复验证通过: /auth/register 已返回 403"
    elif [ "$reg_code" = "000" ]; then
        warn "无法通过内部接口验证，请手动验证:"
        warn "  curl -sk -X POST https://<域名>/auth/register -d 'username=admin&password=test'"
        warn "  应返回 403 Forbidden"
    else
        warn "验证结果: HTTP $reg_code，请手动确认"
    fi
}



# ============================================================
# 选项1: 安装虚假登录界面
# ============================================================
action_install_fake_page() {
    info "===== 选项1: 安装虚假登录界面 ====="
    warn "此操作将禁用 trojan-web 管理面板，通过 nginx 伪装页替代"
    echo ""

    cleanup_fake_page
    resolve_fallback_port "$1"
    disable_trojan_web
    install_nginx
    create_fake_page
    configure_nginx
    block_direct_access
    restart_trojan_if_needed
    verify_fake_page

    echo ""
    info "========================================="
    info "  虚假登录界面部署完成"
    info "========================================="
    echo ""
    echo "  nginx fallback 端口 : $FALLBACK_PORT"
    echo "  防火墙类型          : $FIREWALL"
    echo "  伪装页面目录        : $WEBROOT"
    echo "  trojan-web 状态     : 已禁用"
    echo ""
    echo "  验证: curl -sk https://<域名>/ | grep title"
    echo ""
}

# ============================================================
# 选项2: 复原 web 管理页面
# ============================================================
action_restore_web() {
    info "===== 选项2: 复原 web 管理页面 ====="
    warn "此操作将停止 nginx 伪装页，重新启用 trojan-web 管理面板"
    warn "注意: 若使用原版未修复的 trojan-web，CVE-2025-5525 漏洞将重新暴露"
    echo ""

    # 停止并清理 nginx 伪装页
    cleanup_fake_page

    # 停止 nginx（如果只是为伪装页服务的话）
    if systemctl is-active --quiet nginx 2>/dev/null; then
        # 检查 nginx 是否还有其他配置
        local active_configs
        active_configs=$(ls /etc/nginx/sites-enabled/ 2>/dev/null | wc -l)
        active_configs=$((active_configs + $(ls /etc/nginx/conf.d/*.conf 2>/dev/null | wc -l)))
        if [ "$active_configs" -le 0 ]; then
            systemctl stop nginx
            systemctl disable nginx
            info "nginx 已停止（无其他配置）"
        else
            info "nginx 仍有其他配置，保持运行"
        fi
    fi

    # 恢复 trojan config.json 的 remote_port（如果有备份）
    local latest_bak
    latest_bak=$(ls -t "${TROJAN_CONFIG}.bak."* 2>/dev/null | head -1 || true)
    if [ -n "$latest_bak" ]; then
        warn "发现 trojan config.json 备份: $latest_bak"
        read -r -p "是否恢复原始 remote_port 配置？[y/N] " confirm </dev/tty
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            cp "$latest_bak" "$TROJAN_CONFIG"
            # 检查备份中的 remote_port 是否有服务在监听
            local bak_port
            bak_port=$(grep '"remote_port"' "$TROJAN_CONFIG" | grep -o '[0-9]*' | head -1)
            if [ -n "$bak_port" ]; then
                if ! ss -tlnp 2>/dev/null | grep -q ":${bak_port}[[:space:]]"; then
                    warn "备份中的 remote_port ($bak_port) 当前无服务监听"
                    warn "trojan-web 监听在 80 端口，自动修正 remote_port 为 80"
                    sed -i "s/"remote_port": ${bak_port}/"remote_port": 80/" "$TROJAN_CONFIG"
                fi
            fi
            systemctl restart trojan 2>/dev/null || true
            info "trojan config.json 已从备份恢复并验证"
        fi
    else
        # 没有备份，确保 remote_port 指向 trojan-web 实际监听的端口
        local current_port
        current_port=$(grep '"remote_port"' "$TROJAN_CONFIG" | grep -o '[0-9]*' | head -1)
        if [ -n "$current_port" ] && ! ss -tlnp 2>/dev/null | grep -q ":${current_port}[[:space:]]"; then
            warn "当前 remote_port ($current_port) 无服务监听，修正为 80"
            sed -i "s/"remote_port": ${current_port}/"remote_port": 80/" "$TROJAN_CONFIG"
            systemctl restart trojan 2>/dev/null || true
        fi
    fi

    # 启用 trojan-web
    enable_trojan_web

    echo ""
    info "========================================="
    info "  web 管理页面复原完成"
    info "========================================="
    echo ""
    echo "  trojan-web 状态 : 已启用"
    echo ""
    echo "  ⚠  警告: 当前运行的是原版 trojan-web"
    echo "     CVE-2025-5525 漏洞仍然存在"
    echo "     建议尽快运行选项3安装修复版"
    echo ""
}

# ============================================================
# 选项3: 安装修复版 web 管理页面
# ============================================================
action_install_patched_web() {
    info "===== 选项3: 安装修复版 web 管理页面 ====="
    info "修复内容: CVE-2025-5525 /auth/register 未授权密码重置"
    info "修复方式: 已存在管理员账号时 /auth/register 返回 403"
    info "面板功能: 保持完整，不受影响"
    echo ""

    # 如果当前是伪装页模式，先清理
    cleanup_fake_page

    # 编译并部署修复版
    build_patched_trojan
    deploy_patched_trojan

    echo ""
    info "========================================="
    info "  修复版 web 管理页面安装完成"
    info "========================================="
    echo ""
    echo "  修复的漏洞      : CVE-2025-5525"
    echo "  trojan-web 状态 : 已启用（修复版）"
    echo "  原二进制备份    : ${TROJAN_BIN}.bak.*"
    echo ""
    echo "  验证: curl -sk -X POST https://<域名>/auth/register"
    echo "        应返回 403 Forbidden"
    echo ""
}

# ============================================================
# 显示菜单
# ============================================================
MENU_CHOICE=""
show_menu() {
    echo ""
    title "========================================="
    title "  trojan-harden.sh  安全管理工具"
    title "========================================="
    echo ""
    echo "  1. 安装虚假登录界面"
    echo "     禁用 trojan-web，部署 nginx 伪装网盘页面"
    echo "     完全隔离外部攻击途径（牺牲 web 管理功能）"
    echo ""
    echo "  2. 复原 web 管理页面"
    echo "     停止 nginx 伪装页，重新启用 trojan-web"
    echo "     ⚠  注意: 未修复版本会重新暴露 CVE-2025-5525"
    echo ""
    echo "  3. 安装修复版 web 管理页面"
    echo "     修复 CVE-2025-5525，保留完整面板功能"
    echo "     需要 Go 编译环境和 GitHub 网络访问"
    echo ""
    echo "  0. 退出"
    echo ""
    read -r -p "  请选择 [0-3]: " MENU_CHOICE </dev/tty
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    [ "$(id -u)" != "0" ] && error "请以 root 运行此脚本"

    detect_os
    detect_firewall

    local action="$1"
    local port_arg="$2"

    # 未传参数时显示菜单
    if [ -z "$action" ]; then
        show_menu
        action="$MENU_CHOICE"
    fi

    case "$action" in
        1) action_install_fake_page "$port_arg" ;;
        2) action_restore_web ;;
        3) action_install_patched_web ;;
        0|"") info "已退出" ;;
        *) error "无效选项: $action，请输入 1、2 或 3" ;;
    esac
}

main "$@"
