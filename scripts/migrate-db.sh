#!/usr/bin/env bash

usage() {
  echo "  usage: $0 -e {cf-endpoint} -o {cf-org} -s {cf-space} -n {db-name} -p {db-plan} -a {app-name} [ -h (help)]"
}

error_exit() {
  local msg="${1:-ERROR}"
  echo "$msg"
  exit 1
}

while getopts ":e:o:s:n:p:a:h" opt; do
  case $opt in
    e) cf_endpoint="$OPTARG" ;;
    o) cf_org="$OPTARG" ;;
    s) cf_space="$OPTARG" ;;
    n) source_db_name="$OPTARG" ;;
    p) target_db_plan="$OPTARG" ;;
    a) app_name="$OPTARG" ;;
    h) usage && exit 1 ;;
    \?) error_exit "ERROR: invalid option --$OPTARG" ;;
    :) error_exit "ERROR: option --$OPTARG requires an argument" ;;
  esac
done

if [[ -z $cf_endpoint || -z $cf_org || -z $cf_space || -z $source_db_name || -z $target_db_plan || -z $app_name ]]; then
  usage
  error_exit "ERROR: missing arg(s)"
fi

uuid=$(uuidgen)
source_db_rename="$source_db_name-MIGRATION_SOURCE_DB-$uuid"
target_db_name="$source_db_name-MIGRATION_TARGET_DB-$uuid"
pg_dump_file="$source_db_rename.pg_dump"

if [[ -f "$pg_dump_file" ]]; then
  error_exit "ERROR: pg_dump file exists: $pg_dump_file"
fi

cf_endpoint_targeted=$(jq -r '.Target' < ~/.cf/config.json)
if [[ "$cf_endpoint" != "$cf_endpoint_targeted" ]]; then
  error_exit "ERROR: the currently targeted cf endpoint does not match the argument given at script invocation!"
fi

cf_org_targeted=$(jq -r '.OrganizationFields.Name' < ~/.cf/config.json)
if [[ "$cf_org" != "$cf_org_targeted" ]]; then
  error_exit "ERROR: the currently targeted cf org does not match the argument given at script invocation!"
fi

cf_space_targeted=$(jq -r '.SpaceFields.Name' < ~/.cf/config.json)
if [[ "$cf_space" != "$cf_space_targeted" ]]; then
  error_exit "ERROR: the currently targeted cf space does not match the argument given at script invocation!"
fi

if ! cf orgs >/dev/null 2>&1; then
  error_exit "ERROR: no valid session for currently targetted cf env: $cf_endpoint"
fi

if ! cf service "$source_db_name" >/dev/null 2>&1; then
  error_exit "ERROR: source db does not exist: $source_db_name"
fi

if cf service "$source_db_rename" >/dev/null 2>&1; then
  error_exit "ERROR: service already exists with the migration temp name: $source_db_rename"
fi

if cf service "$target_db_name" >/dev/null 2>&1; then
  echo "WARNING: target db already exists: $target_db_name"
  read -r -p "Continue? (y/N): " confirm && [[ $confirm = "y" ]] || exit 1
fi

if ! cf app "$app_name" >/dev/null 2>&1; then
  error_exit "ERROR: app does not exist: $app_name"
fi

echo "starting migration process..."

echo "creating target db: $target_db_name..."
if ! cf create-service -w postgres "$target_db_plan $target_db_name" >/dev/null 2>&1; then
  error_exit
fi

echo "stopping app: $app_name..."
if ! cf stop "$app_name" >/dev/null 2>&1; then
  error_exit
fi

echo "renaming db: $source_db_name -> $source_db_rename..."
if ! cf rename-service "$source_db_name" "$source_db_rename" >/dev/null 2>&1; then
  error_exit
fi

echo "unbinding: $app_name -> $source_db_rename"
if ! cf unbind-service "$app_name" "$source_db_rename" >/dev/null 2>&1; then
  error_exit
fi

echo "starting pg_dump: $source_db_rename -> $pg_dump_file"
if ! cf conduit "$source_db_rename" -- pg_dump --file "$pg_dump_file" --no-acl --no-owner >/dev/null 2>&1; then
  error_exit
fi

echo "loading pg_dump data: $pg_dump_file -> $target_db_name"
if ! cf conduit "$target_db_name" -- psql < "$pg_dump_file" >/dev/null 2>&1; then
  error_exit
fi

echo "binding $app_name -> $target_db_name"
if ! cf bind-service "$app_name" "$target_db_name" >/dev/null 2>&1; then
  error_exit
fi

echo "renaming db: $target_db_name -> $source_db_name"
if ! cf rename-service "$target_db_name" "$source_db_name" >/dev/null 2>&1; then
  error_exit
fi

echo "starting app: $app_name"
if ! cf start "$app_name" >/dev/null 2>&1; then
  error_exit
fi

echo "deleting db: $source_db_rename"
if ! cf delete-service -f "$source_db_rename" >/dev/null 2>&1; then
  error_exit
fi

echo "deleting pg_dump file: $pg_dump_file"
if ! rm -f "$pg_dump_file" >/dev/null 2>&1; then
  error_exit
fi

echo "done."
