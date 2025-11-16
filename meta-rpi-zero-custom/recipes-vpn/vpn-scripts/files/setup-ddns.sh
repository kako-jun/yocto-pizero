#!/bin/bash
# ダイナミックDNS セットアップスクリプト

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# rootチェック
if [ "$EUID" -ne 0 ]; then
    echo_error "このスクリプトはroot権限で実行してください"
    exit 1
fi

echo_info "======================================"
echo_info "ダイナミックDNS セットアップ"
echo_info "======================================"
echo ""

echo_info "対応しているDDNSサービス:"
echo "1. DuckDNS (https://www.duckdns.org/) - 推奨・無料"
echo "2. No-IP (https://www.noip.com/)"
echo "3. FreeDNS (https://freedns.afraid.org/)"
echo ""

read -p "使用するサービスを選択 [1-3]: " DDNS_CHOICE

case ${DDNS_CHOICE} in
    1)
        echo_info "DuckDNS を設定します"

        echo ""
        echo_info "事前準備:"
        echo_info "1. https://www.duckdns.org/ にアクセス"
        echo_info "2. GitHubアカウントなどでログイン"
        echo_info "3. ドメイン名を作成（例: myhome.duckdns.org）"
        echo_info "4. トークンをコピー"
        echo ""

        read -p "DuckDNSドメイン名（.duckdns.orgなし）: " DUCKDNS_DOMAIN
        read -p "DuckDNSトークン: " DUCKDNS_TOKEN

        if [ -z "${DUCKDNS_DOMAIN}" ] || [ -z "${DUCKDNS_TOKEN}" ]; then
            echo_error "ドメイン名とトークンを入力してください"
            exit 1
        fi

        # 更新スクリプトの作成
        cat > /usr/local/bin/duckdns-update.sh << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /var/log/duckdns.log -K -
EOF
        chmod 700 /usr/local/bin/duckdns-update.sh

        # cronジョブの追加（5分ごとに更新）
        CRON_JOB="*/5 * * * * /usr/local/bin/duckdns-update.sh >/dev/null 2>&1"
        (crontab -l 2>/dev/null | grep -v duckdns-update; echo "${CRON_JOB}") | crontab -

        # 初回実行
        echo_info "初回更新を実行しています..."
        /usr/local/bin/duckdns-update.sh

        DDNS_HOSTNAME="${DUCKDNS_DOMAIN}.duckdns.org"
        ;;

    2)
        echo_info "No-IP を設定します"
        echo_warn "No-IPのDUC（Dynamic Update Client）が必要です"
        echo_warn "opkg install noip でインストールしてから再度実行してください"
        exit 1
        ;;

    3)
        echo_info "FreeDNS を設定します"
        echo ""
        echo_info "事前準備:"
        echo_info "1. https://freedns.afraid.org/ でアカウント作成"
        echo_info "2. サブドメインを作成"
        echo_info "3. Dynamic DNS → Update URL をコピー"
        echo ""

        read -p "FreeDNS Update URL: " FREEDNS_URL

        if [ -z "${FREEDNS_URL}" ]; then
            echo_error "Update URLを入力してください"
            exit 1
        fi

        # 更新スクリプトの作成
        cat > /usr/local/bin/freedns-update.sh << EOF
#!/bin/bash
curl -s "${FREEDNS_URL}" > /var/log/freedns.log
EOF
        chmod 700 /usr/local/bin/freedns-update.sh

        # cronジョブの追加（5分ごとに更新）
        CRON_JOB="*/5 * * * * /usr/local/bin/freedns-update.sh >/dev/null 2>&1"
        (crontab -l 2>/dev/null | grep -v freedns-update; echo "${CRON_JOB}") | crontab -

        # 初回実行
        echo_info "初回更新を実行しています..."
        /usr/local/bin/freedns-update.sh

        read -p "設定したホスト名を入力: " DDNS_HOSTNAME
        ;;

    *)
        echo_error "無効な選択です"
        exit 1
        ;;
esac

echo_info ""
echo_info "======================================"
echo_info "セットアップ完了！"
echo_info "======================================"
echo_info ""
echo_info "DDNSホスト名: ${DDNS_HOSTNAME}"
echo_info "更新間隔: 5分ごと"
echo_info ""
echo_info "確認方法:"
echo_info "  nslookup ${DDNS_HOSTNAME}"
echo_info "  ping ${DDNS_HOSTNAME}"
echo_info ""
echo_info "ログファイル:"
if [ ${DDNS_CHOICE} -eq 1 ]; then
    echo_info "  tail -f /var/log/duckdns.log"
elif [ ${DDNS_CHOICE} -eq 3 ]; then
    echo_info "  tail -f /var/log/freedns.log"
fi
echo_info ""
echo_info "VPN設定で使用するエンドポイント:"
echo_info "  ${DDNS_HOSTNAME}:51820"
echo_info ""
