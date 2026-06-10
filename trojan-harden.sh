#!/bin/bash
# trojan-harden.sh - 禁用 Jrohy trojan-web 面板并部署伪装页面
# 支持 Debian / Ubuntu / CentOS 7/8/9 / Rocky / AlmaLinux
# 用法: bash trojan-harden.sh [fallback端口]
# 不传参数时自动从 trojan config.json 读取，冲突时自动换端口

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

WEBROOT="/var/www/fake-pan"
TROJAN_CONFIG="/usr/local/etc/trojan/config.json"

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
# 读取 trojan 配置，确定 fallback 端口
# ============================================================
resolve_fallback_port() {
    # 优先用命令行参数
    if [ -n "$1" ]; then
        FALLBACK_PORT="$1"
        info "使用指定 fallback 端口: $FALLBACK_PORT"
        return
    fi

    # 从 trojan config.json 自动读取
    if [ -f "$TROJAN_CONFIG" ]; then
        FALLBACK_PORT=$(grep '"remote_port"' "$TROJAN_CONFIG" | grep -o '[0-9]*' | head -1)
        info "从 trojan 配置读取 fallback 端口: $FALLBACK_PORT"
    else
        FALLBACK_PORT=80
        warn "未找到 trojan 配置，使用默认端口 80"
    fi

    # 检测端口是否被其他进程占用
    if ss -tlnp 2>/dev/null | grep -q ":${FALLBACK_PORT}[[:space:]]" || \
       ss -tlnp 2>/dev/null | grep -q ":${FALLBACK_PORT}$"; then
        OCCUPIED_BY=$(ss -tlnp | grep ":${FALLBACK_PORT}" | grep -oP 'users:\(\("\K[^"]+' | head -1)
        warn "端口 $FALLBACK_PORT 已被 ${OCCUPIED_BY:-其他进程} 占用"

        # 自动寻找空闲端口（从 8080 开始）
        NEW_PORT=8080
        while ss -tlnp 2>/dev/null | grep -q ":${NEW_PORT}[[:space:]]" || \
              ss -tlnp 2>/dev/null | grep -q ":${NEW_PORT}$"; do
            NEW_PORT=$((NEW_PORT + 1))
        done

        warn "自动选用空闲端口: $NEW_PORT"
        warn "将修改 trojan config.json: remote_port $FALLBACK_PORT -> $NEW_PORT"

        # 修改 trojan config.json
        if [ -f "$TROJAN_CONFIG" ]; then
            cp "$TROJAN_CONFIG" "${TROJAN_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
            sed -i "s/\"remote_port\": ${FALLBACK_PORT}/\"remote_port\": ${NEW_PORT}/" "$TROJAN_CONFIG"
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
    if systemctl is-active --quiet trojan-web 2>/dev/null; then
        systemctl stop trojan-web
        systemctl disable trojan-web
        info "trojan-web 面板已停止并禁用"
    elif systemctl is-enabled --quiet trojan-web 2>/dev/null; then
        systemctl disable trojan-web
        info "trojan-web 面板已禁用"
    else
        info "trojan-web 面板未安装或已禁用，跳过"
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
            if [ ! -L /etc/nginx/sites-enabled/fake-pan ]; then
                ln -s "$NGINX_CONF" /etc/nginx/sites-enabled/fake-pan
            fi
            ;;
        centos|rhel|rocky|almalinux)
            NGINX_CONF="/etc/nginx/conf.d/fake-pan.conf"
            rm -f /etc/nginx/conf.d/default.conf
            # 注释掉 nginx.conf 里内嵌的 server 块（CentOS 默认有）
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
    # 80/443 trojan 已独占或为标准端口，不需要封
    if [ "$FALLBACK_PORT" = "80" ] || [ "$FALLBACK_PORT" = "443" ]; then
        info "标准端口 $FALLBACK_PORT，跳过 iptables 封锁"
        return
    fi

    info "封锁端口 $FALLBACK_PORT 的外部直连"

    case "$OS" in
        debian|ubuntu)
            iptables -C INPUT -p tcp --dport "$FALLBACK_PORT" ! -s 127.0.0.1 -j DROP 2>/dev/null || \
                iptables -I INPUT -p tcp --dport "$FALLBACK_PORT" ! -s 127.0.0.1 -j DROP
            DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent -qq
            netfilter-persistent save
            info "iptables 规则已持久化"
            ;;
        centos|rhel|rocky|almalinux)
            if systemctl is-active --quiet firewalld 2>/dev/null; then
                firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=127.0.0.1 port port=${FALLBACK_PORT} protocol=tcp accept"
                firewall-cmd --permanent --add-rich-rule="rule family=ipv4 port port=${FALLBACK_PORT} protocol=tcp drop"
                firewall-cmd --reload
                info "firewalld 规则已添加"
            else
                iptables -C INPUT -p tcp --dport "$FALLBACK_PORT" ! -s 127.0.0.1 -j DROP 2>/dev/null || \
                    iptables -I INPUT -p tcp --dport "$FALLBACK_PORT" ! -s 127.0.0.1 -j DROP
                iptables-save > /etc/sysconfig/iptables 2>/dev/null || \
                    warn "iptables 规则已添加但可能未持久化，请手动执行: iptables-save > /etc/sysconfig/iptables"
            fi
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
            info "trojan 服务已重启（应用新的 remote_port）"
        else
            warn "trojan 服务未运行，请手动启动: systemctl start trojan"
        fi
    fi
}

# ============================================================
# 验证部署
# ============================================================
verify() {
    echo ""
    info "===== 验证部署 ====="
    sleep 1  # 等 nginx 完全启动

    TITLE=$(curl -s "http://127.0.0.1:${FALLBACK_PORT}/" 2>/dev/null | grep -o '<title>.*</title>' || echo "")
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${FALLBACK_PORT}/" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] && echo "$TITLE" | grep -q "文件管理系统"; then
        info "✓ 伪装页面响应正常: $TITLE"
    else
        warn "伪装页面响应异常 (HTTP $HTTP_CODE)，检查: journalctl -u nginx -n 20"
    fi

    LOGIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        "http://127.0.0.1:${FALLBACK_PORT}/api/login" \
        -H 'Content-Type: application/json' \
        -d '{"username":"test","password":"test"}' 2>/dev/null || echo "000")
    if [ "$LOGIN_CODE" = "200" ]; then
        info "✓ 登录接口正常（始终返回失败）"
    else
        warn "登录接口响应异常 (HTTP $LOGIN_CODE)"
    fi
}

# ============================================================
# 主流程
# ============================================================
main() {
    [ "$(id -u)" != "0" ] && error "请以 root 运行此脚本"

    echo ""
    info "========================================="
    info "  trojan-harden.sh"
    info "  禁用 trojan-web 面板 + 部署伪装页面"
    info "========================================="
    echo ""

    detect_os
    resolve_fallback_port "$1"
    disable_trojan_web
    install_nginx
    create_fake_page
    configure_nginx
    block_direct_access
    restart_trojan_if_needed
    verify

    echo ""
    info "========================================="
    info "  部署完成"
    info "========================================="
    echo ""
    echo "  nginx fallback 端口 : $FALLBACK_PORT"
    echo "  trojan 配置文件     : $TROJAN_CONFIG"
    echo "  伪装页面目录        : $WEBROOT"
    echo "  nginx 访问日志      : /var/log/nginx/access.log"
    echo ""
    echo "  验证命令:"
    echo "    curl -sk https://<域名>/ | grep title"
    echo ""
}

main "$@"