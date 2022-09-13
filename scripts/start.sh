#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
}

function setup_pihole() {
  add_step "Setting up pihole"

  throw_if_file_not_present "/etc/timezone"

  throw_if_env_var_not_present "PIHOLE_BASE_DIRECTORY" "$PIHOLE_BASE_DIRECTORY"
  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"

  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/pihole"
  ensure_directory_exists "$PIHOLE_BASE_DIRECTORY/dnsmasq.d"
}

function setup_nginx_proxy() {
  throw_if_env_var_not_present "NGNIX_PROXY_MANAGER_BASE_DIRECTORY" "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY"

  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"
}

function setup_tailscale() {
  add_step "Setting up tailscale"

  throw_if_env_var_not_present "TAILSCALE_BASE_DIRECTORY" "$TAILSCALE_BASE_DIRECTORY"

  ensure_directory_exists "$TAILSCALE_BASE_DIRECTORY/var/lib"

  if [[ ! -c "/dev/net/tun" ]]; then
    if [[ ! -d "/dev/net" ]]; then
      mkdir -m 755 /dev/net
    fi

    mknod /dev/net/tun c 10 200
    chmod 0755 /dev/net/tun
  fi
}

function setup_plex() {
  add_step "Setting up plex"

  throw_if_env_var_not_present "PLEX_BASE_DIRECTORY" "$PLEX_BASE_DIRECTORY"

  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"

  throw_if_env_var_not_present "PLEX_CLAIM_TOKEN" "$PLEX_CLAIM_TOKEN"
}

function setup_navidrome() {
  add_step "Setting up navidrome"

  throw_if_env_var_not_present "NAVIDROME_BASE_DIRECTORY" "$NAVIDROME_BASE_DIRECTORY"

  ensure_directory_exists "$NAVIDROME_BASE_DIRECTORY/data"
}

function setup_calibre_web() {
  add_step "Setting up calibre-web"

  throw_if_env_var_not_present "CALIBRE_WEB_BASE_DIRECTORY" "$CALIBRE_WEB_BASE_DIRECTORY"

  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"
}

function setup_gogs() {
  add_step "Setting up gogs"

  throw_if_env_var_not_present "GOGS_BASE_DIRECTORY" "$GOGS_BASE_DIRECTORY"
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"

  throw_if_env_var_not_present "GOGS_DB_BASE_DIRECTORY" "$GOGS_DB_BASE_DIRECTORY"
  ensure_directory_exists "$GOGS_DB_BASE_DIRECTORY"
}

function setup_homer() {
  add_step "Setting up homer"

  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"

  throw_if_env_var_not_present "HOMER_WEB_BASE_DIRECTORY" "$HOMER_WEB_BASE_DIRECTORY"

  ensure_directory_exists "$HOMER_WEB_BASE_DIRECTORY/www/assets"

  sed \
    -e "s/%protocol-type%/http/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_WEB_BASE_DIRECTORY/www/assets/logo.png"
}

function setup_audiobookshelf() {
  add_step "Setting up audiobookshelf"

  throw_if_env_var_not_present "AUDIOBOOKSHELF_BASE_DIRECTORY" "$AUDIOBOOKSHELF_BASE_DIRECTORY"

  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"
}

function setup_podgrab() {
  add_step "Setting up podgrab"

  throw_if_env_var_not_present "PODGRAB_BASE_DIRECTORY" "$PODGRAB_BASE_DIRECTORY"

  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"
}

function setup_bitwarden() {
  add_step "Setting up bitwarden"

  throw_if_env_var_not_present "BITWARDEN_BASE_DIRECTORY" "$BITWARDEN_BASE_DIRECTORY"

  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"
}

function setup_monitoring() {
  add_step "Setting up monitoring"

  throw_if_env_var_not_present "GRAFANA_BASE_DIRECTORY" "$GRAFANA_BASE_DIRECTORY"

  ensure_directory_exists "${GRAFANA_BASE_DIRECTORY}/var/lib/grafana"
  ensure_directory_exists "${GRAFANA_BASE_DIRECTORY}/provisioning/datasources"
}

function setup_nfs_media_mount() {
  add_step "Setting up NFS mounts"

  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_IP" "$NAS_IP"

  throw_if_env_var_not_present "NAS_MEDIA_DIRECTORY" "$NAS_MEDIA_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  delay=0
  while ! mount | grep "$NAS_IP:$NAS_MEDIA_DIRECTORY on $MEDIA_BASE_DIRECTORY type nfs" > /dev/null; do
    sleep $delay

    if [ "$delay" -gt 60 ]; then
        exit 1
    fi

    sudo -u "$NONROOT_USER" mount -t nfs "$NAS_IP:$NAS_MEDIA_DIRECTORY" "$MEDIA_BASE_DIRECTORY" || true

    delay=$((delay+5))
  done

  throw_if_directory_not_present "VIDEOS_DIRECTORY" "$VIDEOS_DIRECTORY"
  throw_if_directory_not_present "MUSIC_DIRECTORY" "$MUSIC_DIRECTORY"
  throw_if_directory_not_present "PHOTOS_DIRECTORY" "$PHOTOS_DIRECTORY"
  throw_if_directory_not_present "BOOKS_DIRECTORY" "$BOOKS_DIRECTORY"
  throw_if_directory_not_present "AUDIOBOOKS_DIRECTORY" "$AUDIOBOOKS_DIRECTORY"
  throw_if_directory_not_present "PODCASTS_DIRECTORY" "$PODCASTS_DIRECTORY"
}

function main() {
  source ./scripts/common.sh

  check_requirements

  setup_nfs_media_mount

  setup_tailscale
  setup_pihole
  setup_nginx_proxy
  setup_plex
  setup_navidrome
  setup_calibre_web
  setup_gogs
  setup_homer
  setup_audiobookshelf
  setup_podgrab
  setup_bitwarden
  setup_monitoring

  if ! docker network ls | grep "macvlan_network"; then
    docker network create -d macvlan \
      -o parent=eth0 \
      --subnet 192.168.4.0/22 \
      --gateway 192.168.4.1 \
      --ip-range 192.168.4.200/32 \
      --aux-address 'host=192.168.4.210' \
      macvlan_network
  fi

  docker compose up -d --remove-orphans

  throw_if_env_var_not_present "PIHOLE_PASSWORD" "$PIHOLE_PASSWORD"
  docker exec pihole-server pihole -a -p $PIHOLE_PASSWORD

  docker exec tailscale-agent tailscale up \
    --accept-dns=false \
    --advertise-exit-node \
    --advertise-routes=192.168.4.0/22 \
    --reset
}

main
